import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../mock_database.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class PaginatedResult<T> {
  final List<T> items;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  PaginatedResult({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });
}

class AuthApiService {
  static String get baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<Map<String, Auth101Config>> getAuthConfigs() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/getAuthConfigData/101'), headers: headers);
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> data = [];
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'] as List<dynamic>? ?? [];
        }
        
        final Map<String, Auth101Config> map = {};
        for (var item in data) {
          final cfg = Auth101Config.fromJson(item);
          map[cfg.id] = cfg;
        }
        return map;
      }
    } catch (e) {
      print('Error fetching auth configs: $e');
    }
    // Fallback to mock
    final Map<String, Auth101Config> map = {};
    for (var cfg in MockDatabase().authConfigs) {
      map[cfg.id] = cfg;
    }
    return map;
  }

  static Future<bool> saveAuthConfig(Auth101Config config) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/authConfig'),
        headers: headers,
        body: jsonEncode(config.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to save configuration: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving auth config: $e');
      rethrow;
    }
  }

  static Future<PaginatedResult<AuthRecord>?> getAuthQueue({
    int page = 0,
    int size = 100,
    String? programId,
    String? authSl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    var list = MockDatabase().authQueue;
    if (programId != null && programId.isNotEmpty) {
      list = list.where((r) => r.programId == programId).toList();
    }
    if (authSl != null && authSl.isNotEmpty) {
      list = list.where((r) => r.authSl.contains(authSl)).toList();
    }
    
    return PaginatedResult<AuthRecord>(
      items: list,
      totalElements: list.length,
      totalPages: 1,
      currentPage: 0,
    );
  }

  static Future<bool> processAuth(String authSl, String action, int level, String user) async {
    await Future.delayed(const Duration(milliseconds: 400));
    MockDatabase().processAuth(authSl, action);
    return true;
  }

  static Future<bool> requestCorrection(String authSl, int level, String user, String remarks) async {
    await Future.delayed(const Duration(milliseconds: 400));
    MockDatabase().removeAuth(authSl);
    return true;
  }

  static Future<int> updateAuthLock(String authSl, String user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 200;
  }
}
