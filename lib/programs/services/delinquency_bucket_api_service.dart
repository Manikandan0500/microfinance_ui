import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/delinquency_bucket_master.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class DelinquencyBucketApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<DelinquencyBucketMaster>> getBuckets(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getDelinquencyBucketData/$orgCode'), headers: headers);
    
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      
      // Handle either direct list or wrapped ResponseDTO
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load delinquency buckets: ${response.statusCode}');
  }

  static Future<DelinquencyBucketMaster> createBucket(DelinquencyBucketMaster bucket) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createDelinquencyBucket'),
      headers: headers,
      body: jsonEncode(_toJson(bucket)),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create delinquency bucket: ${response.statusCode}');
  }

  static Future<DelinquencyBucketMaster> updateBucket(DelinquencyBucketMaster bucket) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateDelinquencyBucket'),
      headers: headers,
      body: jsonEncode(_toJson(bucket)),
    );
    
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update delinquency bucket: ${response.statusCode}');
  }

  static Future<void> deleteBucket(String productCode, String delinquencyCode) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static DelinquencyBucketMaster _fromJson(Map<String, dynamic> json) {
    return DelinquencyBucketMaster(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? '101').toString(),
      productCode: (json['product_code'] ?? json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquency_code'] ?? json['delinquencyCode'] ?? '') as String,
      bucketLabel: (json['bucket_label'] ?? json['bucketLabel'] ?? '') as String,
      overdueDaysFrom: _parseInt(json['overdue_days_from'] ?? json['overdueDaysFrom']),
      overdueDaysTo: _parseInt(json['overdue_days_to'] ?? json['overdueDaysTo']),
      stageOrder: _parseInt(json['stage_order'] ?? json['stageOrder']),
      isNpaFlag: _parseBool(json['is_npa_flag'] ?? json['isNpaFlag']),
      provisionPct: _parseDouble(json['provision_pct'] ?? json['provisionPct']),
      bucketStatus: _parseBool(json['bucket_status'] ?? json['bucketStatus']),
    );
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is double) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'y' || strVal == 'yes' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static Map<String, dynamic> _toJson(DelinquencyBucketMaster bucket) {
    return {
      'orgcode': int.tryParse(bucket.orgCode) ?? 101,
      'product_code': bucket.productCode,
      'delinquency_code': bucket.delinquencyCode,
      'bucket_label': bucket.bucketLabel,
      'overdue_days_from': bucket.overdueDaysFrom,
      'overdue_days_to': bucket.overdueDaysTo,
      'stage_order': bucket.stageOrder,
      'is_npa_flag': bucket.isNpaFlag ? 'Y' : 'N',
      'provision_pct': bucket.provisionPct,
      'bucket_status': bucket.bucketStatus ? '1' : '0',
    };
  }
}
