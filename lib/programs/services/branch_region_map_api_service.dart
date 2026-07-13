import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/branch_region_map.dart';

class BranchRegionMapApiService {
  static const String _baseUrl = 'http://localhost:8085/api/branch-region-maps';

  static Future<List<BranchRegionMap>> getMaps() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load branch-region maps: ${response.statusCode}');
  }

  static Future<BranchRegionMap> createMap(BranchRegionMap map) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to map branch to region: ${response.statusCode}');
  }

  static Future<void> deleteMap(String branchCode) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(branchCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete branch map: ${response.statusCode}');
    }
  }

  static BranchRegionMap _fromJson(Map<String, dynamic> json) {
    return BranchRegionMap(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      branchCode: (json['branchCode'] ?? '') as String,
      regionCode: (json['regionCode'] ?? '') as String,
      status: (json['status'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(BranchRegionMap map) {
    return {
      'orgCode': 1,
      'branchCode': map.branchCode,
      'regionCode': map.regionCode,
      'status': map.status,
    };
  }
}
