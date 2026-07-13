import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prepayment_foreclosure_config.dart';

class PrepaymentForeclosureApiService {
  static const String _baseUrl = 'http://localhost:8085/api/prepayment-foreclosure-configs';

  static Future<List<PrepaymentForeclosureConfig>> getConfigs() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load prepayment configs: ${response.statusCode}');
  }

  static Future<PrepaymentForeclosureConfig> createConfig(PrepaymentForeclosureConfig config) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(config)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create prepayment config: ${response.statusCode}');
  }

  static Future<PrepaymentForeclosureConfig> updateConfig(PrepaymentForeclosureConfig config) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(config.productCode)}';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(config)),
    );
    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update prepayment config: ${response.statusCode}');
  }

  static Future<void> deleteConfig(String productCode) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete prepayment config: ${response.statusCode}');
    }
  }

  static PrepaymentForeclosureConfig _fromJson(Map<String, dynamic> json) {
    return PrepaymentForeclosureConfig(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      lockInPeriodMonths: (json['lockInPeriodMonths'] ?? 0) as int,
      prepaymentPenaltyType: (json['prepaymentPenaltyType'] ?? 'Percentage') as String,
      prepaymentPenaltyValue: (json['prepaymentPenaltyValue'] ?? 0.0) as double,
      foreclosureFeeType: (json['foreclosureFeeType'] ?? 'Percentage') as String,
      foreclosureFeeValue: (json['foreclosureFeeValue'] ?? 0.0) as double,
      scheduleRecalcMethod: (json['scheduleRecalcMethod'] ?? 'Re-amortization') as String,
      configStatus: (json['configStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(PrepaymentForeclosureConfig config) {
    return {
      'orgCode': 1,
      'productCode': config.productCode,
      'lockInPeriodMonths': config.lockInPeriodMonths,
      'prepaymentPenaltyType': config.prepaymentPenaltyType,
      'prepaymentPenaltyValue': config.prepaymentPenaltyValue,
      'foreclosureFeeType': config.foreclosureFeeType,
      'foreclosureFeeValue': config.foreclosureFeeValue,
      'scheduleRecalcMethod': config.scheduleRecalcMethod,
      'configStatus': config.configStatus,
    };
  }
}
