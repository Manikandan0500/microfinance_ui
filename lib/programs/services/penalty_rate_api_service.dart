import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/penalty_rate_history.dart';

class PenaltyRateApiService {
  static const String _baseUrl = 'http://localhost:8085/api/penalty-rates';

  static Future<List<PenaltyRateHistory>> getRates() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load penalty rate histories: ${response.statusCode}');
  }

  static Future<PenaltyRateHistory> createRate(PenaltyRateHistory rate) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(rate)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create penalty rate history: ${response.statusCode}');
  }

  static Future<void> deleteRate(String productCode, String delinquencyCode, String effDateStr) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}/${Uri.encodeComponent(delinquencyCode)}/${Uri.encodeComponent(effDateStr)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete penalty rate history: ${response.statusCode}');
    }
  }

  static PenaltyRateHistory _fromJson(Map<String, dynamic> json) {
    return PenaltyRateHistory(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquencyCode'] ?? '') as String,
      effDate: DateTime.parse(json['effDate'] as String),
      penaltyType: (json['penaltyType'] ?? 'Percentage') as String,
      penaltyValue: (json['penaltyValue'] ?? 0.0) as double,
      rateStatus: (json['rateStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(PenaltyRateHistory rate) {
    return {
      'orgCode': 1,
      'productCode': rate.productCode,
      'delinquencyCode': rate.delinquencyCode,
      'effDate': rate.effDate.toIso8601String().substring(0, 10),
      'penaltyType': rate.penaltyType,
      'penaltyValue': rate.penaltyValue,
      'rateStatus': rate.rateStatus,
    };
  }
}
