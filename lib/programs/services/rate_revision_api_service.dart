import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rate_revision_history.dart';

class RateRevisionApiService {
  static const String _baseUrl = 'http://localhost:8085/api/rate-revisions';

  static Future<List<RateRevisionHistory>> getRevisions() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load rate revisions: ${response.statusCode}');
  }

  static Future<RateRevisionHistory> createRevision(RateRevisionHistory revision) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(revision)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create rate revision: ${response.statusCode}');
  }

  static Future<void> deleteRevision(String productCode, String effDateStr) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}/${Uri.encodeComponent(effDateStr)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete rate revision: ${response.statusCode}');
    }
  }

  static RateRevisionHistory _fromJson(Map<String, dynamic> json) {
    return RateRevisionHistory(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      effDate: DateTime.parse(json['effDate'] as String),
      revisedRate: (json['revisedRate'] ?? 0.0) as double,
      benchmarkRateCode: (json['benchmarkRateCode'] ?? '') as String,
      spreadPct: (json['spreadPct'] ?? 0.0) as double,
      revisionReason: (json['revisionReason'] ?? '') as String,
      revisionStatus: (json['revisionStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(RateRevisionHistory revision) {
    return {
      'orgCode': 1,
      'productCode': revision.productCode,
      'effDate': revision.effDate.toIso8601String().substring(0, 10),
      'revisedRate': revision.revisedRate,
      'benchmarkRateCode': revision.benchmarkRateCode,
      'spreadPct': revision.spreadPct,
      'revisionReason': revision.revisionReason,
      'revisionStatus': revision.revisionStatus,
    };
  }
}
