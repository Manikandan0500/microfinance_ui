import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset_classification_gl_map.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class AssetClassificationGlMapApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<AssetClassificationGlMap>> getMaps(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getGLMappingData/$orgCode'), headers: headers);
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
    throw Exception('Failed to load GL maps: ${response.statusCode}');
  }

  static Future<AssetClassificationGlMap> createMap(AssetClassificationGlMap map) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createGLMapping'),
      headers: headers,
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create GL map: ${response.statusCode}');
  }

  static Future<AssetClassificationGlMap> updateMap(AssetClassificationGlMap map) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateGLMapping'),
      headers: headers,
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update GL map: ${response.statusCode}');
  }

  static Future<void> deleteMap(String productCode, String delinquencyCode) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static AssetClassificationGlMap _fromJson(Map<String, dynamic> json) {
    return AssetClassificationGlMap(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['product_code'] ?? json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquency_code'] ?? json['delinquencyCode'] ?? '') as String,
      prinGl: (json['prin_gl'] ?? json['prinGl'] ?? '') as String,
      intGl: (json['int_gl'] ?? json['intGl'] ?? '') as String,
      provisionGl: (json['provision_gl'] ?? json['provisionGl'] ?? '') as String,
      mapStatus: _parseBool(json['map_status'] ?? json['mapStatus']),
    );
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return true;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'active' || strVal == 'a' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static Map<String, dynamic> _toJson(AssetClassificationGlMap map) {
    return {
      'orgcode': int.tryParse(map.orgCode) ?? 1,
      'product_code': map.productCode,
      'delinquency_code': map.delinquencyCode,
      'prin_gl': map.prinGl,
      'int_gl': map.intGl,
      'provision_gl': map.provisionGl,
      'map_status': map.mapStatus ? '1' : '0',
    };
  }
}
