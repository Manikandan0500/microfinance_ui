import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/sub_module_model.dart';
import 'auth_service.dart';

class SubModuleService {
  final _authService = AuthService();

  static final SubModuleService _instance = SubModuleService._internal();
  factory SubModuleService() => _instance;
  SubModuleService._internal();

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

  Future<List<SubModule>> getAllSubModules() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/submodule');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => SubModule.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load submodules');
    }
  }

  Future<SubModule?> getSubModuleById(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/submodule/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return SubModule.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load submodule');
    }
  }

  Future<SubModule> createSubModule(SubModule subModule) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/submodule');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    subModule = subModule.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(subModule.toJson()),
    );

    if (response.statusCode == 200) {
      return SubModule.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create submodule: ${response.statusCode} - ${response.body}');
  }

  Future<SubModule> updateSubModule(int subModuleId, SubModule subModule) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/submodule/$subModuleId');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    subModule = subModule.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(subModule.toJson()),
    );

    if (response.statusCode == 200) {
      return SubModule.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update submodule: ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteSubModule(int subModuleId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "SUB_MODULE",
      "subModuleId": subModuleId
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete submodule: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getSubModulesPaginated(int offset, int limit, {String? search}) async {
    final searchParam = (search != null && search.trim().isNotEmpty) ? '&search=${Uri.encodeComponent(search.trim())}' : '';
    final url = Uri.parse('${AppConfig.instance.baseUrl}/submodule?offset=$offset&limit=$limit$searchParam');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> content = data['content'] ?? [];
      final totalElements = data['totalElements'] ?? 0;
      return {
        'content': content.map((json) => SubModule.fromJson(json)).toList(),
        'totalElements': totalElements,
      };
    } else {
      throw Exception('Failed to load paginated submodules');
    }
  }
}

