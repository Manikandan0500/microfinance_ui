import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rate_revision_history.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class RateRevisionApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<RateRevisionHistory>> getRevisions(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getRateRevisionHistoryData/$orgCode'), headers: headers);
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
    throw Exception('Failed to load rate revisions: ${response.statusCode}');
  }

  static Future<RateRevisionHistory> createRevision(RateRevisionHistory revision) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createRateRevisionHistory'),
      headers: headers,
      body: jsonEncode(_toJson(revision)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create rate revision: ${response.statusCode}');
  }

  static Future<RateRevisionHistory> updateRevision(RateRevisionHistory revision) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateRateRevisionHistory'),
      headers: headers,
      body: jsonEncode(_toJson(revision)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update rate revision: ${response.statusCode}');
  }

  static Future<void> deleteRevision(String productCode, String effDateStr) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static RateRevisionHistory _fromJson(Map<String, dynamic> json) {
    return RateRevisionHistory(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['product_code'] ?? json['productCode'] ?? '') as String,
      effDate: DateTime.parse(json['eff_date'] ?? json['effDate'] ?? DateTime.now().toIso8601String()),
      revisedRate: _parseDouble(json['revised_rate'] ?? json['revisedRate']),
      benchmarkRateCode: (json['benchmark_rate_code'] ?? json['benchmarkRateCode'] ?? '') as String,
      spreadPct: _parseDouble(json['spread_pct'] ?? json['spreadPct']),
      revisionReason: (json['revision_reason'] ?? json['revisionReason'] ?? '') as String,
      revisionStatus: _parseBool(json['revision_status'] ?? json['revisionStatus']),
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

  static Map<String, dynamic> _toJson(RateRevisionHistory revision) {
    return {
      'orgcode': int.tryParse(revision.orgCode) ?? 1,
      'product_code': revision.productCode,
      'eff_date': revision.effDate.toIso8601String().substring(0, 10),
      'revised_rate': revision.revisedRate,
      'benchmark_rate_code': revision.benchmarkRateCode,
      'spread_pct': revision.spreadPct,
      'revision_reason': revision.revisionReason,
      'revision_status': revision.revisionStatus ? '1' : '0',
    };
  }
}
