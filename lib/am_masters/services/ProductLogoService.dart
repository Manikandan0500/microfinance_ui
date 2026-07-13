import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ProductLogoService {
  final _authService = AuthService();

  static final ProductLogoService _instance = ProductLogoService._internal();
  factory ProductLogoService() => _instance;
  ProductLogoService._internal();

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

 
  Future<String> uploadLogo({
    required int orgCode,
    required int productCode,
    required Uint8List logoBytes,
    required String fileName,
  }) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/upload/$orgCode',
    );
    final token = await _getAuthToken();

    final request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['pathName'] = 'logo';

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      logoBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final s3Url = (data['url'] ?? '').toString();
      if (s3Url.isEmpty) throw Exception('No URL returned from upload');
      return s3Url;
    }

    throw Exception('Failed to upload product logo (${response.statusCode})');
  }

  Future<Uint8List?> fetchLogo({
    required int orgCode,
    required String storedPath, 
  }) async {
    final presignedUrl = await fetchLogoUrl(
      orgCode: orgCode,
      storedPath: storedPath,
    );
    if (presignedUrl == null) return null;

    final response = await http.get(Uri.parse(presignedUrl));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    return null;
  }


  Future<String?> fetchLogoUrl({
    required int orgCode,
    required String storedPath, 
  }) async {
    if (storedPath.isEmpty) return null;
    if (storedPath.startsWith('http') && storedPath.contains('?')) {
      return storedPath;
    }


    String cleanPath = storedPath;

    if (storedPath.startsWith('http')) {
      final uri = Uri.parse(storedPath);
      final segments = uri.pathSegments;
    
      cleanPath = segments.skip(1).join('/');
    }

    if (cleanPath.startsWith('$orgCode/')) {
      cleanPath = cleanPath.substring('$orgCode/'.length);
    }

    final encodedFileName = Uri.encodeQueryComponent(cleanPath);

    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/view/$orgCode?fileName=$encodedFileName',
    );

    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
      if (response.statusCode == 404) return null;
      return null;
    } catch (_) {
      return null;
    }
  }


  Future<void> deleteLogo({
    required int orgCode,
    required String storedPath, 
  }) async {
    if (storedPath.isEmpty) return;

    String cleanPath = storedPath;

    if (storedPath.startsWith('http')) {
      final uri = Uri.parse(storedPath);
      cleanPath = uri.pathSegments.skip(1).join('/'); 
    }

    if (cleanPath.startsWith('$orgCode/')) {
      cleanPath = cleanPath.substring('$orgCode/'.length);
    }

    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/$orgCode/$cleanPath',
    );

    final headers = await _getHeaders();
    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete product logo (${response.statusCode})');
    }
  }
}

