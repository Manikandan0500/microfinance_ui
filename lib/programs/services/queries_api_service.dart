import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';
import '../models/loan_status_history.dart';
import '../models/loan_outstanding_balance.dart';
import '../models/loan_repayment_schedule.dart';
import '../mock_database.dart';

class QueriesApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();
  static final MockDatabase _db = MockDatabase();

  static Future<List<LoanRepaymentSchedule>> getLoanRepaymentSchedules() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _db.loanRepaymentSchedules;
  }


  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<LoanOutstandingBalance?> getLoanOutstandingBalance(String loanAccountNo) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/getLoanAccountOutstanding/$loanAccountNo'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      if (data.isNotEmpty) {
        return LoanOutstandingBalance.fromJson(data.first);
      }
      return null;
    }
    throw Exception('Failed to load outstanding balance: ${response.statusCode}');
  }

  static Future<List<LoanStatusHistory>> getLoanStatusHistory(String loanAccountNo) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/getLoanStatusHistory/$loanAccountNo'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      return data.map((json) => LoanStatusHistory.fromJson(json)).toList();
    }
    throw Exception('Failed to load loan status history: ${response.statusCode}');
  }
}

