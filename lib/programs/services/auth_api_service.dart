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
  static Future<Map<String, Auth101Config>> getAuthConfigs() async {
    // Return mock configs
    await Future.delayed(const Duration(milliseconds: 300));
    final Map<String, Auth101Config> map = {};
    for (var cfg in MockDatabase().authConfigs) {
      map[cfg.id] = cfg;
    }
    return map;
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
