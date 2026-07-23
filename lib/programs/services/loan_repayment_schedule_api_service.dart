import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_repayment_schedule.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class LoanRepaymentScheduleApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<LoanRepaymentSchedule>> getLoanRepaymentSchedules({String? loanAccountNo}) async {
    final headers = await _getHeaders();
    final String url;
    if (loanAccountNo != null && loanAccountNo.trim().isNotEmpty) {
      url = '$_baseUrl/getLoanRepaymentSchedule/${Uri.encodeComponent(loanAccountNo.trim())}';
    } else {
      url = '$_baseUrl/getLoanRepaymentSchedule';
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      return data.map((json) => LoanRepaymentSchedule.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load repayment schedule: ${response.statusCode}');
  }
}
