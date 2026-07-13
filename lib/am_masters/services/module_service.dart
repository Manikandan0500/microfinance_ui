import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/module_model.dart';
import 'auth_service.dart';

class ModuleService {
  final _authService = AuthService();

  static final ModuleService _instance = ModuleService._internal();
  factory ModuleService() => _instance;
  ModuleService._internal();

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

  Future<List<Module>> getAllModules() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/module');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Module.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load modules');
    }
  }

  Future<Module?> getModuleById(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/module/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Module.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load module');
    }
  }

  Future<Module> createModule(Module module) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/module');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    module = module.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(module.toJson()),
    );

    if (response.statusCode == 200) {
      return Module.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create module: ${response.statusCode} - ${response.body}');
  }

  Future<Module> updateModule(int moduleId, Module module) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/module/$moduleId');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    module = module.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(module.toJson()),
    );

    if (response.statusCode == 200) {
      return Module.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update module: ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteModule(int moduleId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "MODULE",
      "moduleId": moduleId,
      "cascade": true
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete module: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getModulesPaginated(int offset, int limit, {String? search}) async {
    final searchParam = (search != null && search.trim().isNotEmpty) ? '&search=${Uri.encodeComponent(search.trim())}' : '';
    final url = Uri.parse('${AppConfig.instance.baseUrl}/module?offset=$offset&limit=$limit$searchParam');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> content = data['content'] ?? [];
      final totalElements = data['totalElements'] ?? 0;
      return {
        'content': content.map((json) => Module.fromJson(json)).toList(),
        'totalElements': totalElements,
      };
    } else {
      throw Exception('Failed to load paginated modules');
    }
  }
}

