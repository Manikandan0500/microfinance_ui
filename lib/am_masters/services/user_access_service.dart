import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user_access_mapping.dart';
import '../models/user_mapping_request.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import '../widgets/bulk_upload_dialog.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class UserAccessService {
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

  Future<List<UserAccessMapping>> getAllMappings() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/user-access-mappings');
      print('Fetching from: $url with headers: $headers');

      final response = await http.get(url, headers: headers);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => UserAccessMapping.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to load user access mappings: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getAllMappings: $e');
      throw Exception('Failed to load user access mappings: $e');
    }
  }

  Future<Map<String, dynamic>> getMappingsPaginated({
    required int offset,
    required int limit,
    String? search,
    String? orgCode,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = {
        'offset': offset.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (orgCode != null && orgCode.isNotEmpty) 'orgCode': orgCode,
      };
      final uri = Uri.parse(
        '$baseUrl/user-access-mappings',
      ).replace(queryParameters: queryParams);
      print('Fetching paginated: $uri');

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> content = data['content'] ?? [];
        return {
          'content': content
              .map((json) => UserAccessMapping.fromJson(json))
              .toList(),
          'totalElements': data['totalElements'] ?? 0,
          'activeCount': data['activeCount'] ?? 0,
          'inactiveCount': data['inactiveCount'] ?? 0,
        };
      } else {
        throw Exception(
          'Failed to load user access mappings: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in getMappingsPaginated: $e');
      throw Exception('Failed to load user access mappings: $e');
    }
  }

  Future<UserAccessMapping> createMapping(UserAccessMapping mapping) async {
    try {
      final headers = await _getHeaders();
      final currentUser = await _authService.getUser();
      mapping.userName = currentUser?.userName?.toString() ?? '';
      final body = jsonEncode(mapping.toJson());
      final url = Uri.parse('$baseUrl/user-access-mappings');

      print('ðŸ“¤ [POST] $url');
      print('ðŸ“‹ Headers: $headers');
      print('ðŸ“ Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('ðŸ“¥ Response Status: ${response.statusCode}');
      print('ðŸ“¥ Response Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return UserAccessMapping.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized: Please login again. Response: ${response.body}',
        );
      } else {
        throw Exception(
          'Failed to create mapping (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('âŒ [POST Error] $e');
      rethrow;
    }
  }

  Future<void> createMappings(
    List<UserAccessMapping> mappings, {
    int? pgmId,
  }) async {
    try {
      final headers = await _getHeaders();
      final currentUser = await _authService.getUser();
      mappings.forEach((mapping) {
        mapping.userName = currentUser?.userName?.toString() ?? '';
      });
      final body = jsonEncode(
        UserMappingRequest(userMappingReq: mappings, pgmId: pgmId).toJson(),
      );
      final url = Uri.parse('$baseUrl/user-access-mappings/createUserAccess');

      print('[POST] $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(url, headers: headers, body: body);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized: Please login again. Response: ${response.body}',
        );
      }

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Failed to create mappings (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('[POST Error] $e');
      rethrow;
    }
  }

  Future<void> updateMappings(
    List<UserAccessMapping> mappings, {
    int? pgmId,
  }) async {
    try {
      final headers = await _getHeaders();
      final currentUser = await _authService.getUser();
      mappings.forEach((mapping) {
        mapping.userName = currentUser?.userName?.toString() ?? '';
      });
      final body = jsonEncode(
        UserMappingRequest(userMappingReq: mappings, pgmId: pgmId).toJson(),
      );
      final url = Uri.parse('$baseUrl/user-access-mappings/updateUserAccess');

      print('[PUT] $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.put(url, headers: headers, body: body);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception(
          'Unauthorized: Please login again. Response: ${response.body}',
        );
      }

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Failed to create mappings (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('[POST Error] $e');
      rethrow;
    }
  }

  Future<UserAccessMapping> updateMapping(
    int accesscd,
    UserAccessMapping mapping,
  ) async {
    final headers = await _getHeaders();
    final currentUser = await _authService.getUser();
    mapping.userName = currentUser?.userName?.toString() ?? '';
    final response = await http.put(
      Uri.parse('$baseUrl/user-access-mappings/$accesscd'),
      headers: headers,
      body: jsonEncode(mapping.toJson()),
    );
    if (response.statusCode == 200) {
      return UserAccessMapping.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to update user access mapping: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteMapping(int accesscd, int prodcode, String userscd) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/delete'),
      headers: headers,
      body: jsonEncode({
        "deleteType": "USER_ACCESS_MAPPING",
        "accesscd": accesscd,
        "prodcode": prodcode,
        "userscd": userscd
      })
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to delete user access mapping: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteMappingsForUser(int orgCode, String userId) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/delete'),
      headers: headers,
      body: jsonEncode({
        "deleteType": "USER_ACCESS_MAPPING_USER",
        "orgcode": orgCode,
        "userscd": userId
      })
    );
    if (response.statusCode != 204) {
      throw Exception(
        'Failed to delete user access mappings: ${response.statusCode} - ${response.body}',
      );
    }
  }

  void showBulkUpload(BuildContext context, VoidCallback onComplete) {
    BulkUploadDialog.show(
      context,
      title: 'Bulk Upload Products',
      entityName: 'Products',
      validateEndpoint: '/user-access-mappings/bulk-upload',
      uploadEndpoint: '/user-access-mappings/bulk-process',
      templateAssetPath:
          'assets/User_Product_Mapping_Bulk_Upload_Template.xlsx',
      templateFileName: 'User_Product_Mapping_Bulk_Upload_Template.xlsx',
      templateSheetName: 'User Product Mapping Upload',
      programName: 'User_Product_Mapping',
      onComplete: onComplete,
    );
  }

  Future<List<Map<String, dynamic>>> productRecordMapper(
    SpreadsheetTable sheet,
    void Function(String message, {bool isError}) addLog,
    void Function() incrementFailure,
    Map<String, String> displayNamesMap,
  ) async {
    final currentUser = await _authService.getUser();
    final isAdmin = currentUser?.roleType?.toUpperCase() == 'ADMIN';
    final adminOrgCode = currentUser?.orgCode;

    final List<Map<String, dynamic>> payloads = [];
    
    for (int i = 1; i < sheet.maxRows; i++) {
      if (i % 1000 == 0) {
        await Future.delayed(Duration.zero);
      }
      final row = sheet.rows[i];
      if (row.isEmpty || row.every((c) => c == null)) continue;

      String getStr(int col) => col < row.length ? (row[col]?.toString().trim() ?? '') : '';

      final orgCodeStr = getStr(0);
      final orgNameStr = getStr(1);
      final userCodeStr = getStr(2);
      final userNameStr = getStr(3);
      final prodCodeStr = getStr(4);
      final prodNameStr = getStr(5);
      final statusStr = getStr(6);

      if (orgCodeStr.isEmpty && userCodeStr.isEmpty && prodCodeStr.isEmpty) {
        continue;
      }

      final displayName = userCodeStr.isNotEmpty ? '$userCodeStr - $userNameStr' : 'Row ${i + 1}';
      displayNamesMap[userCodeStr] = displayName;

      if (orgCodeStr.isEmpty || userCodeStr.isEmpty || prodCodeStr.isEmpty) {
addLog('Row ${i + 1} skipped ($displayName): Missing required fields (Organization Code, User Code, or Product Code).', isError: true);
        incrementFailure();
        continue;
      }

      final orgCode = int.tryParse(orgCodeStr);
      final prodCode = int.tryParse(prodCodeStr);
      final statusVal = (statusStr.toLowerCase() == 'active' || statusStr == '1' || statusStr.toLowerCase() == 'true');

      if (orgCode == null || prodCode == null) {
addLog('Row ${i + 1} skipped ($displayName): Organization Code and Product Code must be numeric.', isError: true);
        incrementFailure();
        continue;
      }

      if (isAdmin && adminOrgCode != null && orgCode != adminOrgCode) {
        addLog('Row ${i + 1} skipped ($displayName): Admin users can only upload mappings for their own organization.', isError: true);
        incrementFailure();
        continue;
      }

      payloads.add({
        'excelRowNo': i + 1,
        'accesscd': 3,
        'orgcode': orgCode,
        'orgName': orgNameStr,
        'userscd': userCodeStr,
        'userName': userNameStr,
        'prodcode': prodCode,
        'prodName': prodNameStr,
        'status': statusVal,
      });
    }
    return payloads;
  }
}


