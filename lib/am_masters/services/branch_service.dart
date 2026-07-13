import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/branch_model.dart';
import 'auth_service.dart';

class BranchService {
  final _authService = AuthService();

  static final BranchService _instance = BranchService._internal();
  factory BranchService() => _instance;
  BranchService._internal();

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

  Future<List<Branch>> getAllBranches() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/branch');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Branch.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load branches');
    }
  }

  Future<Map<String, dynamic>> getBranchesPaginated({
    required int offset,
    required int limit,
    String? search,
    int? orgCode,
    String? userId,
  }) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (orgCode != null) 'orgCode': orgCode.toString(),
      if (userId != null) 'userId': userId,
    };
    final url = Uri.parse('${AppConfig.instance.baseUrl}/branch').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch paginated branches: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected paginated branches response format');
  }

  Future<Branch?> getBranchById(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/branch/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Branch.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load branch');
    }
  }

  Future<Branch> createBranch(Branch branch) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/branch');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    branch.userName = user?.userName?.toString() ?? '';
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(branch.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.body.trim().isEmpty) return branch;
      return Branch.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Failed to create branch: ${response.statusCode} - ${response.body}',
    );
  }

  Future<Branch> updateBranch(int branchCode, Branch branch) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/branch/$branchCode?orgCode=${branch.orgCode}',
    );
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    branch.userName = user?.userName?.toString() ?? '';
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(branch.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.trim().isEmpty) return branch;
      return Branch.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Failed to update branch: ${response.statusCode} - ${response.body}',
    );
  }

  Future<void> deleteBranch(int orgCode, int branchCode, {int? pgmId}) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "BRANCH",
      "orgcode": orgCode,
      "brncd": branchCode,
      "cascade": true
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Failed to delete branch: ${response.statusCode} - ${response.body}',
      );
    }
  }
}


