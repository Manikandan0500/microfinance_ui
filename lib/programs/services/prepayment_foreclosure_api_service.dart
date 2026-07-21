import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prepayment_foreclosure_config.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class PrepaymentForeclosureApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<PrepaymentForeclosureConfig>> getConfigs(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getPrepaymentForeclosureConfigData/$orgCode'), headers: headers);
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
    throw Exception('Failed to load configs: ${response.statusCode}');
  }

  static Future<PrepaymentForeclosureConfig> createConfig(PrepaymentForeclosureConfig config) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createPrepaymentForeclosureConfig'),
      headers: headers,
      body: jsonEncode(_toJson(config)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create config: ${response.statusCode}');
  }

  static Future<PrepaymentForeclosureConfig> updateConfig(PrepaymentForeclosureConfig config) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updatePrepaymentForeclosureConfig'),
      headers: headers,
      body: jsonEncode(_toJson(config)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update config: ${response.statusCode}');
  }

  static Future<void> deleteConfig(String productCode) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static PrepaymentForeclosureConfig _fromJson(Map<String, dynamic> json) {
    return PrepaymentForeclosureConfig(
      orgCode: (json['orgCode'] ?? json['orgcode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? json['product_code'] ?? '') as String,
      lockInPeriodMonths: (json['lockInPeriodMonths'] ?? json['lock_in_period_months'] ?? 0) as int,
      prepaymentPenaltyType: (json['prepaymentPenaltyType'] ?? json['prepayment_penalty_type'] ?? 'Percentage') as String,
      prepaymentPenaltyValue: ((json['prepaymentPenaltyValue'] ?? json['prepayment_penalty_value'] ?? 0.0) as num).toDouble(),
      foreclosureFeeType: (json['foreclosureFeeType'] ?? json['foreclosure_fee_type'] ?? 'Percentage') as String,
      foreclosureFeeValue: ((json['foreclosureFeeValue'] ?? json['foreclosure_fee_value'] ?? 0.0) as num).toDouble(),
      scheduleRecalcMethod: (json['scheduleRecalcMethod'] ?? json['schedule_recalc_method'] ?? 'Re-amortization') as String,
      configStatus: _parseBool(json['configStatus'] ?? json['config_status']),
    );
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return true;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'active' || strVal == 'a' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static Map<String, dynamic> _toJson(PrepaymentForeclosureConfig config) {
    return {
      'orgcode': int.tryParse(config.orgCode) ?? 1,
      'product_code': config.productCode,
      'lock_in_period_months': config.lockInPeriodMonths,
      'prepayment_penalty_type': config.prepaymentPenaltyType,
      'prepayment_penalty_value': config.prepaymentPenaltyValue,
      'foreclosure_fee_type': config.foreclosureFeeType,
      'foreclosure_fee_value': config.foreclosureFeeValue,
      'schedule_recalc_method': config.scheduleRecalcMethod,
      'config_status': config.configStatus ? '1' : '0',
    };
  }
}
