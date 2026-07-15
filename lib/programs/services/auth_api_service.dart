import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_models.dart';
import '../mock_database.dart';

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
  static const String baseUrl = 'http://localhost:8085/api/master';
  static Future<Map<String, Auth101Config>> getAuthConfigs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/getAuthConfigData/101'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
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
      final response = await http.post(
        Uri.parse('$baseUrl/authConfig'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(config.toJson()),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to save configuration');
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
