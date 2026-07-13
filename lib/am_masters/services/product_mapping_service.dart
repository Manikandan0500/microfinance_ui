import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import '../models/product_map_dto.dart';

class ProductMappingService {
  final _authService = AuthService();

  static final ProductMappingService _instance = ProductMappingService._internal();
  factory ProductMappingService() => _instance;
  ProductMappingService._internal();

  Future<String?> _getAuthToken() async {
    final token = await _authService.getToken();
    if (token == null) return null;
    return token.replaceAll('"', '');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getAllMappings() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product-mapping');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch product mappings: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected product mappings response format');
  }

  Future<Map<String, dynamic>> getMappingsPaginated(int offset, int limit, {String? search, String? orgCode}) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (orgCode != null && orgCode.isNotEmpty) 'orgCode': orgCode,
    };
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product-mapping').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch product mappings: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      final List<dynamic> content = data['content'] ?? [];
      return {
        'content': List<Map<String, dynamic>>.from(content.cast<Map<String, dynamic>>()),
        'totalElements': data['totalElements'] ?? 0,
        'activeCount': data['activeCount'] ?? 0,
        'inactiveCount': data['inactiveCount'] ?? 0,
      };
    }

    throw Exception('Unexpected product mappings response format');
  }

  Future<void> saveMapping(List<ProductMapDto> mappedProducts, int? pgmId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product-mapping/createProductMapping');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    final userName = user?.userName?.toString() ?? '';
    
    final payload = {
      'pgmId': pgmId,
      'userName': userName,
      'mappedProducts': mappedProducts.map((e) => e.toJson()).toList(),
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(payload));

    if (response.statusCode != 201 && response.statusCode != 200) {
      String errorMessage = 'Failed to save mapping';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        errorMessage = 'Failed to save mapping:';
      }
      throw Exception(errorMessage);
    }
  }
 Future<void> updateMapping(Map<String, dynamic> mappingData) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product-mapping/updateProductMapping');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    mappingData['userName'] = user?.userName?.toString() ?? '';
    final response = await http.put(url, headers: headers, body: jsonEncode(mappingData));

    if (response.statusCode != 201 && response.statusCode != 200) {
      String errorMessage = 'Failed to update mapping';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      } catch (_) {
        errorMessage = 'Failed to update mapping:';
      }
      throw Exception(errorMessage);
    }
  }
  Future<Map<String, dynamic>?> getMappingByOrg(int orgCode) async {
    try {
      final url = Uri.parse('${AppConfig.instance.baseUrl}/product-mapping/$orgCode');
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is List && data.isNotEmpty) {
          return Map<String, dynamic>.from(data.first as Map);
        }
      }
    } catch (_) {}

    // Fallback: fetch all mappings and filter
    try {
      final all = await getAllMappings();
      final match = all.firstWhere(
        (m) => (m['orgCode'] ?? m['orgcode'])?.toString() == orgCode.toString(),
        orElse: () => <String, dynamic>{},
      );
      return match.isEmpty ? null : match;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteMapping(int orgCode) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "PRODUCT_MAPPING",
      "orgcode": orgCode
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete mapping: ${response.statusCode} - ${response.body}');
    }
  }
}


