import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/access_code_model.dart';
import 'auth_service.dart';

class AccessCodeService {
  final String baseUrl = AppConfig.instance.baseUrl;
  final _authService = AuthService();
  static const String _tokenKey = 'child_token';

  Future<String?> _getAuthToken() async {
    // First try to get from AuthService
    final token = await _authService.getToken();
    if (token != null) {
      return token.replaceAll('"', '');
    }
    // Fall back to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AccessCode>> getAllAccessCodes() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/access-code');
      print('Fetching access codes from: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AccessCode.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load access codes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getAllAccessCodes: $e');
      rethrow;
    }
  }

  Future<List<AccessCode>> getRolesByOrganization(String orgCode) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/access-code/getRoleByOrganization');
      print('Fetching roles for org: $orgCode from $url (POST)');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'orgcode': int.tryParse(orgCode) ?? orgCode}),
      );
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => AccessCode.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load roles: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getRolesByOrganization: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccessCodesPaginated(int offset, int limit, {String? search, String? orgCode}) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (orgCode != null && orgCode.isNotEmpty) 'orgCode': orgCode,
      };
      final uri = Uri.parse('$baseUrl/access-code').replace(queryParameters: queryParams);
      print('Fetching paginated access codes from: $uri');

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load access codes: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getAccessCodesPaginated: $e');
      rethrow;
    }
  }

  Future<AccessCode> getAccessCodeById(int id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/access-code/$id');
      print('Fetching access code from: $url');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AccessCode.fromJson(data);
      } else {
        throw Exception('Failed to load access code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getAccessCodeById: $e');
      rethrow;
    }
  }

  Future<AccessCode> createAccessCode(AccessCode accessCode, {int? pgmId}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/access-code');
      print('Creating access code at: $url');
      print('Request body: ${jsonEncode(accessCode.toJson())}');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(accessCode.toJson()),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AccessCode.fromJson(data);
      } else {
        try {
          final err = jsonDecode(response.body);
          if (err != null && err['message'] != null) {
            throw Exception(err['message'].toString());
          }
        } catch (e) {
          if (e is! FormatException) rethrow;
        }
        throw Exception('Failed to create access code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createAccessCode: $e');
      rethrow;
    }
  }

  Future<AccessCode> updateAccessCode(int id, AccessCode accessCode, {int? pgmId}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/access-code/$id');
      print('Updating access code at: $url');
      print('Request body: ${jsonEncode(accessCode.toJson())}');

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(accessCode.toJson()),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AccessCode.fromJson(data);
      } else {
        try {
          final err = jsonDecode(response.body);
          if (err != null && err['message'] != null) {
            throw Exception(err['message'].toString());
          }
        } catch (e) {
          if (e is! FormatException) rethrow;
        }
        throw Exception('Failed to update access code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in updateAccessCode: $e');
      rethrow;
    }
  }

  Future<void> deleteAccessCode(int id) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/delete');
      final Map<String, dynamic> body = {
        "deleteType": "ACCESS",
        "accesscd": id,
        "cascade": true
      };
      print('Deleting access code via /delete API');

      final response = await http.post(
        url, 
        headers: headers,
        body: jsonEncode(body),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        // Success
      } else {
        throw Exception('Failed to delete access code: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in deleteAccessCode: $e');
      rethrow;
    }
  }
}

