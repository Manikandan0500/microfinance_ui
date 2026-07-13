import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  final _authService = AuthService();

  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

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

  // â”€â”€ Upload product logo (returns S3 URL) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<String?> uploadProductLogo({
    required int orgId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/upload/$orgId',
    );
    try {
      final token = await _getAuthToken();
      final request = http.MultipartRequest('POST', url);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['pathName'] = 'logo';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return (data['url'] ?? '').toString();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // â”€â”€ Get presigned view URL for product logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<String?> getProductLogoUrl({
    required int orgId,
    required String filePath,
  }) async {
    if (filePath.startsWith('http') && filePath.contains('?')) {
      return filePath;
    }
    String cleanPath = filePath;
    if (filePath.startsWith('http')) {
      final uri = Uri.parse(filePath);
      final segments = uri.pathSegments;
      cleanPath = segments.skip(1).join('/');
    }
    if (cleanPath.startsWith('$orgId/')) {
      cleanPath = cleanPath.substring('$orgId/'.length);
    }

    final encodedFileName = Uri.encodeQueryComponent(cleanPath);
    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/view/$orgId?fileName=$encodedFileName',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // â”€â”€ Fetch logo bytes (presigned URL â†’ raw bytes) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<Uint8List?> fetchProductLogo({
    required int orgId,
    required String filePath,
  }) async {
    try {
      final presignedUrl = await getProductLogoUrl(
        orgId: orgId,
        filePath: filePath,
      );
      if (presignedUrl == null) return null;

      final response = await http.get(Uri.parse(presignedUrl));
      return response.statusCode == 200 ? response.bodyBytes : null;
    } catch (e) {
      return null;
    }
  }

  // â”€â”€ Delete product logo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> deleteProductLogo({
    required int orgId,
    required String filePath,
  }) async {
    String cleanPath = filePath;
    if (filePath.startsWith('http')) {
      final uri = Uri.parse(filePath);
      cleanPath = uri.pathSegments.skip(1).join('/');
    }
    if (cleanPath.startsWith('$orgId/')) {
      cleanPath = cleanPath.substring('$orgId/'.length);
    }

    final url = Uri.parse(
      '${AppConfig.instance.baseUrl}/api/s3/$orgId/$cleanPath',
    );
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    throw Exception('Failed to load products');
  }

  Future<Map<String, dynamic>> getProductsPaginated({
    required int offset,
    required int limit,
    String? search,
    int? orgCode,
    String? userId,
  }) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (orgCode != null) 'orgCode': orgCode.toString(),
      if (userId != null) 'userId': userId,
    };
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch paginated products: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected paginated products response format');
  }

  Future<List<String>> getProductNames({required int orgCode, required String userScd}) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product/product-names');
    final headers = await _getHeaders();

    final body = jsonEncode({
      'orgCode': orgCode,
      'userScd': userScd,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['productNames'] as List<dynamic>?;
      if (list != null) {
        return list.map((e) => e.toString()).toList();
      }
      return [];
    }
    throw Exception('Failed to load product names');
  }

  Future<ProductModel> createProduct(ProductModel product) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product');
    final headers = await _getHeaders();

    final user = await _authService.getUser();
    product.userName = user?.userName?.toString() ?? '';

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ProductModel.fromJson(jsonDecode(response.body));
    }
    try {
      final err = jsonDecode(response.body);
      if (err != null && err['message'] != null) {
        throw Exception(err['message'].toString());
      }
    } catch (e) {
      if (e is! FormatException) rethrow;
    }
    throw Exception('Failed to create product');
  }

  Future<ProductModel> updateProduct(int prodCode, ProductModel product) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/product/$prodCode');
    final headers = await _getHeaders();

    final user = await _authService.getUser();
    product.userName = user?.userName?.toString() ?? '';

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return ProductModel.fromJson(jsonDecode(response.body));
    }
    try {
      final err = jsonDecode(response.body);
      if (err != null && err['message'] != null) {
        throw Exception(err['message'].toString());
      }
    } catch (e) {
      if (e is! FormatException) rethrow;
    }
    throw Exception('Failed to update product');
  }

  Future<void> deleteProduct(int prodCode) async {
    final prefs = await SharedPreferences.getInstance();
    final orgCode = prefs.getInt('orgCode') ?? 1;
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "PRODUCT",
      "orgcode": orgCode,
      "prodcode": prodCode,
      "cascade": true
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product');
    }
  }
}

