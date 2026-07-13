import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/delinquency_bucket_master.dart';

class DelinquencyBucketApiService {
  static const String _baseUrl = 'http://localhost:8085/api/delinquency-buckets';

  static Future<List<DelinquencyBucketMaster>> getBuckets() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load delinquency buckets: ${response.statusCode}');
  }

  static Future<DelinquencyBucketMaster> createBucket(DelinquencyBucketMaster bucket) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(bucket)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create delinquency bucket: ${response.statusCode}');
  }

  static Future<DelinquencyBucketMaster> updateBucket(DelinquencyBucketMaster bucket) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(bucket.productCode)}/${Uri.encodeComponent(bucket.delinquencyCode)}';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(bucket)),
    );
    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update delinquency bucket: ${response.statusCode}');
  }

  static Future<void> deleteBucket(String productCode, String delinquencyCode) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}/${Uri.encodeComponent(delinquencyCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete delinquency bucket: ${response.statusCode}');
    }
  }

  static DelinquencyBucketMaster _fromJson(Map<String, dynamic> json) {
    return DelinquencyBucketMaster(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquencyCode'] ?? '') as String,
      bucketLabel: (json['bucketLabel'] ?? '') as String,
      overdueDaysFrom: (json['overdueDaysFrom'] ?? 0) as int,
      overdueDaysTo: (json['overdueDaysTo'] ?? 0) as int,
      stageOrder: (json['stageOrder'] ?? 0) as int,
      isNpaFlag: (json['isNpaFlag'] ?? false) as bool,
      provisionPct: (json['provisionPct'] ?? 0.0) as double,
      bucketStatus: (json['bucketStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(DelinquencyBucketMaster bucket) {
    return {
      'orgCode': 1,
      'productCode': bucket.productCode,
      'delinquencyCode': bucket.delinquencyCode,
      'bucketLabel': bucket.bucketLabel,
      'overdueDaysFrom': bucket.overdueDaysFrom,
      'overdueDaysTo': bucket.overdueDaysTo,
      'stageOrder': bucket.stageOrder,
      'isNpaFlag': bucket.isNpaFlag,
      'provisionPct': bucket.provisionPct,
      'bucketStatus': bucket.bucketStatus,
    };
  }
}
