import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch_region_map.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class BranchRegionMapApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<BranchRegionMap>> getMaps(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getBranchRegionMapData/$orgCode'), headers: headers);
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
    throw Exception('Failed to load branch-region maps: ${response.statusCode}');
  }

  static Future<BranchRegionMap> createMap(BranchRegionMap map) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createBranchRegionMap'),
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
    String errorMsg = 'Failed to map branch to region: ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body['message'] != null) errorMsg = body['message'];
    } catch (_) {}
    throw Exception(errorMsg);
  }

  static Future<BranchRegionMap> updateMap(BranchRegionMap map) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateBranchRegionMap'),
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
    String errorMsg = 'Failed to update branch map: ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body['message'] != null) errorMsg = body['message'];
    } catch (_) {}
    throw Exception(errorMsg);
  }

  static Future<void> deleteMap(String branchCode) async {
    // Left as mock/placeholder, typically handled by Auth queue
  }

  static BranchRegionMap _fromJson(Map<String, dynamic> json) {
    return BranchRegionMap(
      orgCode: (json['orgcode'] ?? 101).toString(),
      branchCode: (json['branch_code'] ?? '').toString(),
      regionCode: (json['region_code'] ?? '') as String,
      status: true,
    );
  }

  static Map<String, dynamic> _toJson(BranchRegionMap map) {
    int orgcode = int.tryParse(map.orgCode) ?? 101;
    int branchCode = int.tryParse(map.branchCode) ?? 0;
    
    return {
      'id': {
        'orgcode': orgcode,
        'branch_code': branchCode
      },
      'orgcode': orgcode,
      'branch_code': branchCode,
      'region_code': map.regionCode,
    };
  }
}
