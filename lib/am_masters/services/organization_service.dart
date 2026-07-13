import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class OrganizationService {
  final _authService = AuthService();

  static final OrganizationService _instance = OrganizationService._internal();
  factory OrganizationService() => _instance;
  OrganizationService._internal();

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

  Future<List<Map<String, dynamic>>> getAllOrganizations() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/organization/org');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch organizations: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected organizations response format');
  }

  Future<Map<String, dynamic>> getOrganizationsPaginated({
    required int offset,
    required int limit,
    String? search,
  }) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final url = Uri.parse('${AppConfig.instance.baseUrl}/organization/org').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch paginated organizations: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected paginated organizations response format');
  }

  Future<Map<String, dynamic>?> getOrganizationByCode(int orgCode) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/organization/org/$orgCode');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
     final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data.containsKey('organization')) {
        return data['organization'] as Map<String, dynamic>?;
      }
      return data as Map<String, dynamic>?;

    }

    return null;
  }

  Future<Map<String, dynamic>> createOrganization(Map<String, dynamic> orgData) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/organization/org');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    orgData['userName'] = user?.name?.toString() ?? user?.userName?.toString() ?? '';
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(orgData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['responseData'] as Map<String, dynamic>;
    }

    String errorMessage = 'Failed to create organization';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['message'] != null) {
        errorMessage = errorData['message'];
      }
    } catch (_) {}
    throw Exception(errorMessage);
  }

  Future<String> updateOrganization(int orgCode, Map<String, dynamic> orgData) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/organization/org/$orgCode');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    orgData['userName'] = user?.name?.toString() ?? user?.userName?.toString() ?? '';
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(orgData),
    );

    if (response.statusCode == 200) {
      return response.body;
    }

    String errorMessage = 'Failed to update organization';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['message'] != null) {
        errorMessage = errorData['message'];
      }
    } catch (_) {}
    throw Exception(errorMessage);
  }

  Future<String> deleteOrganization(int orgCode) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "ORG",
      "orgcode": orgCode,
      "cascade": true
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return response.body;
    }

    String errorMessage = 'Failed to delete organization';
    try {
      final errorData = jsonDecode(response.body);
      if (errorData['message'] != null) {
        errorMessage = errorData['message'];
      }
    } catch (_) {}
    throw Exception(errorMessage);
  }

  /// Get organizations mapped to a specific user
  /// Returns only organizations that the user has access to
  Future<List<Map<String, dynamic>>> getOrganizationsByUser(int orgCode, String userScd) async {
    try {
      final url = Uri.parse(
        '${AppConfig.instance.baseUrl}/user-access-mappings/user/$orgCode/$userScd',
      );
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch user access mappings: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is! List) {
        return [];
      }

      // Extract unique organization codes from user access mappings
      // Note: The field name is 'orgcode' (lowercase) in the API response
      final userOrgCodes = <int>{};
      for (final mapping in data) {
        if (mapping is Map) {
          // Try both 'orgcode' and 'orgCode' for flexibility
          var orgCodeValue = mapping['orgcode'] ?? mapping['orgCode'];
          if (orgCodeValue != null) {
            try {
              userOrgCodes.add(int.parse(orgCodeValue.toString()));
            } catch (e) {
              // Skip invalid values
            }
          }
        }
      }

      // If no organization codes found, return empty
      if (userOrgCodes.isEmpty) {
        return [];
      }

      // Fetch all organizations and filter by user's accessible ones
      final allOrgs = await getAllOrganizations();
      return allOrgs
          .where((org) {
            try {
              final orgCodeInt = int.parse((org['orgcode'] ?? org['orgCode']).toString());
              return userOrgCodes.contains(orgCodeInt);
            } catch (e) {
              return false;
            }
          })
          .toList();
    } catch (e) {
      print('Error getting user organizations: $e');
      // If there's an error, return empty list (user has no mapped organizations)
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getIndustries() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/industries');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch industries: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected industries response format');
  }

  Future<List<Map<String, dynamic>>> getIndustryClassifications(String industrycd) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/industries/$industrycd/classifications');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch industry classifications: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected industry classifications response format');
  }
}


