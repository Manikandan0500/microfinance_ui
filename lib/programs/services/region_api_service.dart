import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/region_master.dart';

class RegionApiService {
  static const String _baseUrl = 'http://localhost:8085/api/master';
  static const int _defaultOrgCode = 101;

  /// Fetch all regions for the default orgCode
  static Future<List<RegionMaster>> getRegions() async {
    final response = await http.get(Uri.parse('$_baseUrl/getRegionData/$_defaultOrgCode'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      final List<dynamic> data = body['data'] ?? [];
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load regions: ${response.statusCode}');
  }

  /// Create a new region
  static Future<RegionMaster> createRegion(RegionMaster region) async {
    final body = jsonEncode(_toJson(region));
    final response = await http.post(
      Uri.parse('$_baseUrl/createRegion?orgCode=$_defaultOrgCode'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 400) {
      try {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        if (errorBody.containsKey('message')) {
          throw Exception(errorBody['message']);
        }
      } catch (e) {
        // Fallback if parsing fails
      }
    }
    throw Exception('Failed to create region: ${response.statusCode}');
  }

  /// Update an existing region
  static Future<RegionMaster> updateRegion(RegionMaster region) async {
    final url = '$_baseUrl/$_defaultOrgCode/${Uri.encodeComponent(region.regionCode)}';
    final body = jsonEncode(_toJson(region));
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update region: ${response.statusCode}');
  }

  /// Delete a region
  static Future<void> deleteRegion(String regionCode) async {
    final url = '$_baseUrl/$_defaultOrgCode/${Uri.encodeComponent(regionCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete region: ${response.statusCode}');
    }
  }

  static RegionMaster _fromJson(Map<String, dynamic> json) {
    final id = json['id'] as Map<String, dynamic>?;
    return RegionMaster(
      orgCode: (id?['orgCode'] ?? json['orgcode'] ?? 101).toString(),
      regionCode: (id?['regionCode'] ?? json['region_code'] ?? json['regionCode'] ?? '') as String,
      regionName: (json['region_name'] ?? json['regionName'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      zone: (json['zone'] ?? '') as String,
      status: true,
    );
  }

  static Map<String, dynamic> _toJson(RegionMaster region) {
    return {
      'id': {
        'orgCode': _defaultOrgCode,
        'regionCode': region.regionCode,
      },
      'region_name': region.regionName,
      'state': region.state,
      'zone': region.zone,
      'orgcode': _defaultOrgCode,
      'region_code': region.regionCode,
    };
  }
}
