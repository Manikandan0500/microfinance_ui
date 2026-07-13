import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class BulkUploadService {
  final _authService = AuthService();

  static final BulkUploadService _instance = BulkUploadService._internal();
  factory BulkUploadService() => _instance;
  BulkUploadService._internal();

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

  Future<Map<String, dynamic>> validateRecords(String validateEndpoint, List<Map<String, dynamic>> records, {String? checksum}) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}$validateEndpoint');
    final headers = await _getHeaders();
    
    final payload = {
      'checksum': checksum,
      'user_records': records
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Bulk validation failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> uploadRecords(String uploadEndpoint, List<Map<String, dynamic>> records, {String? checksum}) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}$uploadEndpoint');
    final headers = await _getHeaders();
    
    final currentUser = await _authService.getUser();
    final currentUserName = currentUser?.userScd?.toString() ?? '';

    for (var record in records) {

      record['userName'] = currentUserName;
    }

    final payload = {
      'checksum': checksum,
      'user_records': records
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Bulk upload failed: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> processBatch(String processEndpoint, int batchId, {String? checksum}) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}$processEndpoint');
    
    final headers = await _getHeaders();
    final currentUser = await _authService.getUser();
    final currentUserName = currentUser?.userScd?.toString() ?? '';

    final payload = {
      'batchId': batchId,
      'userName': currentUserName,
      if (checksum != null) 'checksum': checksum,
    };

    final response = await http.post(
      url, 
      headers: headers,
      body: jsonEncode(payload)
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to process batch: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadExcelFile(
    String uploadEndpoint,
    List<int> fileBytes,
    String fileName, {
    String? checksum,
  }) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}$uploadEndpoint-file');
    final token = await _getAuthToken();
    final currentUser = await _authService.getUser();
    final currentUserName = currentUser?.userScd?.toString() ?? 'system';

    final request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['userName'] = currentUserName;
    if (checksum != null) {
      request.fields['checksum'] = checksum;
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Bulk file upload and processing failed: ${response.statusCode} - ${response.body}');
  }

  Future<List<int>> downloadReport(String baseEndpoint, int batchId, String reportType) async {
    String prefix = '/user-account';
    if (baseEndpoint.contains('/user-access-mappings')) {
      prefix = '/user-access-mappings';
    }
    
    final url = Uri.parse('${AppConfig.instance.baseUrl}$prefix/download-report/$batchId/$reportType');
    final token = await _getAuthToken();
    final response = await http.get(
      url,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw Exception('Failed to download report: ${response.statusCode}');
  }
}


