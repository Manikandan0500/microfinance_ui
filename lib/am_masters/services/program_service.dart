import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/program_model.dart';
import 'auth_service.dart';

class ProgramService {
  final _authService = AuthService();

  static final ProgramService _instance = ProgramService._internal();
  factory ProgramService() => _instance;
  ProgramService._internal();

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

  Future<List<Program>> getAllPrograms() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Program.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load programs');
    }
  }

  Future<Program?> getProgramById(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program/$id');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Program.fromJson(data);
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load program');
    }
  }

  Future<Program> createProgram(Program program) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    program = program.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(program.toJson()),
    );

    if (response.statusCode == 200) {
      return Program.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create program: ${response.statusCode} - ${response.body}');
  }

  Future<Program> updateProgram(int subModuleId, Program program) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program/$subModuleId');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    program = program.copyWith(userName: user?.userName?.toString() ?? '');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(program.toJson()),
    );

    if (response.statusCode == 200) {
      return Program.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update program: ${response.statusCode} - ${response.body}');
  }

  Future<void> deleteProgram(int subModuleId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "PROGRAM",
      "pgmId": subModuleId.toString()
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete program: ${response.statusCode} - ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getProgramsPaginated(int offset, int limit, {String? search}) async {
    final searchParam = (search != null && search.trim().isNotEmpty) ? '&search=${Uri.encodeComponent(search.trim())}' : '';
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program?offset=$offset&limit=$limit$searchParam');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> content = data['content'] ?? [];
      final totalElements = data['totalElements'] ?? 0;
      return {
        'content': content.map((json) => Program.fromJson(json)).toList(),
        'totalElements': totalElements,
      };
    } else {
      throw Exception('Failed to load paginated programs');
    }
  }
}


