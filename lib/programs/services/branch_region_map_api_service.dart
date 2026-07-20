import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch_region_map.dart';

class BranchRegionMapApiService {
  static const String _baseUrl = 'http://localhost:8085/api/master';

  static Future<List<BranchRegionMap>> getMaps(String orgCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/getBranchRegionMapData/$orgCode'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load branch-region maps: ${response.statusCode}');
  }

  static Future<BranchRegionMap> createMap(BranchRegionMap map) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/createBranchRegionMap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    String errorMsg = 'Failed to map branch to region: ${response.statusCode}';
    try {
      final body = jsonDecode(response.body);
      if (body['message'] != null) errorMsg = body['message'];
    } catch (_) {}
    throw Exception(errorMsg);
  }

  static Future<BranchRegionMap> updateMap(BranchRegionMap map) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/updateBranchRegionMap'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
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
