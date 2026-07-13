import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/asset_classification_gl_map.dart';

class AssetClassificationGlMapApiService {
  static const String _baseUrl = 'http://localhost:8085/api/asset-classification-gl-maps';

  static Future<List<AssetClassificationGlMap>> getMaps() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load asset GL maps: ${response.statusCode}');
  }

  static Future<AssetClassificationGlMap> createMap(AssetClassificationGlMap map) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to map asset GL: ${response.statusCode}');
  }

  static Future<AssetClassificationGlMap> updateMap(AssetClassificationGlMap map) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(map.productCode)}/${Uri.encodeComponent(map.delinquencyCode)}';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(map)),
    );
    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update asset GL map: ${response.statusCode}');
  }

  static Future<void> deleteMap(String productCode, String delinquencyCode) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}/${Uri.encodeComponent(delinquencyCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete asset GL map: ${response.statusCode}');
    }
  }

  static AssetClassificationGlMap _fromJson(Map<String, dynamic> json) {
    return AssetClassificationGlMap(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      delinquencyCode: (json['delinquencyCode'] ?? '') as String,
      prinGl: (json['prinGl'] ?? '') as String,
      intGl: (json['intGl'] ?? '') as String,
      provisionGl: (json['provisionGl'] ?? '') as String,
      mapStatus: (json['mapStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(AssetClassificationGlMap map) {
    return {
      'orgCode': 1,
      'productCode': map.productCode,
      'delinquencyCode': map.delinquencyCode,
      'prinGl': map.prinGl,
      'intGl': map.intGl,
      'provisionGl': map.provisionGl,
      'mapStatus': map.mapStatus,
    };
  }
}
