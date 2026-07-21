import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/penalty_rate_history.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class PenaltyRateApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<PenaltyRateHistory>> getRates(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getPenaltyRateHistoryData/$orgCode'), headers: headers);
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load penalty rate histories: ${response.statusCode}');
  }

  static Future<PenaltyRateHistory> createRate(PenaltyRateHistory rate) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createPenaltyRateHistory'),
      headers: headers,
      body: jsonEncode(_toJson(rate)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create penalty rate history: ${response.statusCode}');
  }

  static Future<PenaltyRateHistory> updateRate(PenaltyRateHistory rate) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updatePenaltyRateHistory'),
      headers: headers,
      body: jsonEncode(_toJson(rate)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update penalty rate history: ${response.statusCode}');
  }

  static Future<void> deleteRate(String productCode, String delinquencyCode, String effDateStr) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static PenaltyRateHistory _fromJson(Map<String, dynamic> json) {
    return PenaltyRateHistory(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['product_code'] ?? json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquency_code'] ?? json['delinquencyCode'] ?? '') as String,
      effDate: DateTime.parse(json['eff_date'] ?? json['effDate'] ?? DateTime.now().toIso8601String()),
      penaltyType: (json['penalty_type'] ?? json['penaltyType'] ?? 'Percentage') as String,
      penaltyValue: _parseDouble(json['penalty_value'] ?? json['penaltyValue']),
      rateStatus: _parseBool(json['rate_status'] ?? json['rateStatus']),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return true;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'active' || strVal == 'a' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static Map<String, dynamic> _toJson(PenaltyRateHistory rate) {
    return {
      'orgcode': int.tryParse(rate.orgCode) ?? 1,
      'product_code': rate.productCode,
      'delinquency_code': rate.delinquencyCode,
      'eff_date': rate.effDate.toIso8601String().substring(0, 10),
      'penalty_type': rate.penaltyType,
      'penalty_value': rate.penaltyValue,
      'rate_status': rate.rateStatus ? '1' : '0',
    };
  }
}
