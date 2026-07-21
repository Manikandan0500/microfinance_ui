import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Login/services/auth_service 4.dart';
import '../models/auth_models.dart';

class QueueApiService {
  static const String baseUrl = 'http://localhost:8085/api/master';

  static int get _userOrgCode => AuthService().currentUser?.orgCode ?? 101;

  /// Fetch the pending authorization queue
  static Future<List<AuthRecord>> getAuthQueue({
    String? programId,
    String? authSl,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/getAuthQueueData/$_userOrgCode');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        var records = data.map((json) => AuthRecord.fromJson(json)).toList();

        if (programId != null && programId.isNotEmpty) {
          records = records.where((r) => r.programId == programId).toList();
        }
        if (authSl != null && authSl.isNotEmpty) {
          records = records.where((r) => r.authSl.contains(authSl)).toList();
        }

        return records;
      }
      throw Exception('Failed to load queue: ${response.statusCode}');
    } catch (e) {
      print('Error fetching auth queue: $e');
      rethrow;
    }
  }

  /// Approve or reject an authorization record
  static Future<void> processAuth({
    required String authSl,
    required String action, // '1' or '0'
    required int level,
    required String user,
  }) async {
    final endpoint = action == '1' ? 'authSubmit' : 'authReject';
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint/$authSl?level=$level&userId=$user'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to process auth record: ${response.statusCode}');
    }
  }

  /// Request correction for an authorization record
  static Future<void> requestCorrection({
    required String authSl,
    required int level,
    required String user,
    required String remarks,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/correction'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'authSl': authSl,
        'level': level,
        'user': user,
        'remarks': remarks,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to request correction: ${response.statusCode}');
    }
  }

  /// Lock an authorization record
  static Future<void> lockRecord(String authSl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authSl': authSl}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to lock record: ${response.statusCode}');
    }
  }
}
