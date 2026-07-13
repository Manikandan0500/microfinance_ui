import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/organization_model.dart';
import '../models/user.dart';
import 'auth_service.dart';

class ProfileService {
  final _authService = AuthService();

  static final Map<String, Future<User?>> _userDetailsCache = {};

  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  Future<String?> _getAuthToken() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return token.replaceAll('"', '');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Organization?> getOrganizationByCode(int orgCode) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/organization/org/$orgCode',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('organization')) {
          return Organization.fromJson(data['organization']);
        }
        return Organization.fromJson(data);
      }
      return null;
    } catch (e) {
      // debugPrint('âŒ Error fetching organization: $e');
      return null;
    }
  }

  Future<User?> getUserDetails(String userId, int orgCode, {bool forceRefresh = false}) async {
    final cacheKey = '$userId-$orgCode';
    
    if (!forceRefresh) {
      final cached = _userDetailsCache[cacheKey];
      if (cached != null) return cached;
    } else {
      _userDetailsCache.remove(cacheKey);
    }

    final future = _fetchUserDetails(userId, orgCode);
    _userDetailsCache[cacheKey] = future;
    final result = await future;
    if (result == null) _userDetailsCache.remove(cacheKey);
    return result;
  }

  // Future<User?> _fetchUserDetails(String userId, int orgCode) async {
  //   final url = Uri.parse(
  //     '${AppConfig.instance.baseUrl}/user/get-user/?userCode=$userId&orgCode=$orgCode',
  //   );
  //   try {
  //     final headers = await _getHeaders();
  //     final response = await http.get(url, headers: headers);
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return User.fromJson(data);
  //     }
  //     return null;
  //   } catch (e) {
  //     // debugPrint('âŒ Error fetching user details: $e');
  //     return null;
  //   }
  // }
Future<User?> _fetchUserDetails(String userId, int orgCode) async {
  final url = Uri.parse(
    '${AppConfig.instance.baseUrl}/user/get-user',
  );
 
  try {
    final headers = await _getHeaders();
 
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({
        'userScd': userId,
        'orgCode': orgCode,
      }),
    );
 
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final user = User.fromJson(data);
      if (user.products != null) {
        for (var p in user.products!) {
          final logo = p['logo']?.toString();
          if (logo != null && logo.isNotEmpty) {
            try {
              final url = await getProfilePictureUrl(
                orgId: orgCode,
                filePath: logo,
              );
              if (url != null) {
                p['networkLogoUrl'] = url;
              }
            } catch (_) {}
          }
        }
      }
      return user;
    }
 
    return null;
  } catch (e) {
    // debugPrint('âŒ Error fetching user details: $e');
    return null;
  }
}
  Future<({Organization? organization, User? user})> getProfileData({
    required int orgCode,
    required String userId,
  }) async {
    try {
      final results = await Future.wait([
        getOrganizationByCode(orgCode),
        getUserDetails(userId, orgCode),
      ]);
      return (
        organization: results[0] as Organization?,
        user: results[1] as User?,
      );
    } catch (e) {
      return (organization: null, user: null);
    }
  }

  Future<String?> uploadProfilePicture({
    required int orgId,
    required Uint8List fileBytes,
    required String fileName,
    String pathName = 'profile',
  }) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/upload/$orgId',
    );
    try {
      final token = await _getAuthToken();
      final request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['pathName'] = pathName;

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (data['url'] ?? '').toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getProfilePictureUrl({
    required int orgId,
    required String filePath,
  }) async {
    if (filePath.startsWith('http') && filePath.contains('?')) {
      return filePath;
    }
    String cleanPath = filePath;
    if (filePath.startsWith('http')) {
      final uri = Uri.parse(filePath);
      final segments = uri.pathSegments;
      cleanPath = segments.skip(1).join('/'); 
    }
    if (cleanPath.startsWith('$orgId/')) {
      cleanPath = cleanPath.substring('$orgId/'.length); 
    }

    final encodedFileName = Uri.encodeQueryComponent(cleanPath);
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/view/$orgId?fileName=$encodedFileName',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> fetchProfilePicture({
    required int orgId,
    required String filePath,
  }) async {
    try {
      final presignedUrl = await getProfilePictureUrl(
        orgId: orgId,
        filePath: filePath,
      );
      if (presignedUrl == null) return null;
      
      final response = await http.get(Uri.parse(presignedUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<bool> deleteProfilePicture({
  required int orgId,
  required String filePath,
}) async {
  String cleanPath = filePath;
  if (filePath.startsWith('http')) {
    final uri = Uri.parse(filePath);
    cleanPath = uri.pathSegments.skip(1).join('/'); 
  }

  if (cleanPath.startsWith('$orgId/')) {
    cleanPath = cleanPath.substring('$orgId/'.length); 
  }

  final url = Uri.parse(
    '${AppConfig.instance.baseUrl}/api/s3/$orgId/$cleanPath',
  );
  try {
    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
  // â”€â”€ Update user details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> updateUserDetails({
    required String userId,
    required int orgCode,
    required String fName,
    required String lName,
    required String email,
    required String mobile,
    String? picturePath,
  }) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/user/updateUserDetails',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'userScd': userId,
          'orgCode': orgCode,
          'fName': fName,
          'lName': lName,
          'email': email,
          'mobile': mobile,
          'picture': picturePath,
        }),
      );
      if (response.statusCode == 200) {
        _userDetailsCache.clear();
        return true;
      }
      return false;
    } catch (e) {
      // debugPrint('âŒ Error updating user details: $e');
      return false;
    }
  }
}


