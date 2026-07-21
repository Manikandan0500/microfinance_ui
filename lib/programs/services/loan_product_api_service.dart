import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_product_master.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class LoanProductApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<LoanProductMaster>> getProducts(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getLoanProductData/$orgCode'), headers: headers);
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
    throw Exception('Failed to load loan products: ${response.statusCode}');
  }

  static Future<LoanProductMaster> createProduct(LoanProductMaster product) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createLoanProduct'),
      headers: headers,
      body: jsonEncode(_toJson(product)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create loan product: ${response.statusCode}');
  }

  static Future<LoanProductMaster> updateProduct(LoanProductMaster product) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateLoanProduct'),
      headers: headers,
      body: jsonEncode(_toJson(product)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update loan product: ${response.statusCode}');
  }

  static Future<void> deleteProduct(String productCode) async {
    // Delete is not implemented in the current backend API provided by the user.
    // Throwing an exception or we can just ignore it for now.
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static LoanProductMaster _fromJson(Map<String, dynamic> json) {
    return LoanProductMaster(
      orgCode: (json['orgcode'] ?? json['orgCode'] ?? '1').toString(),
      productCode: (json['product_code'] ?? json['productCode'] ?? '') as String,
      productName: (json['product_name'] ?? json['productName'] ?? '') as String,
      minAmount: _parseDouble(json['min_amount'] ?? json['minAmount']),
      maxAmount: _parseDouble(json['max_amount'] ?? json['maxAmount']),
      interestRate: _parseDouble(json['interest_rate'] ?? json['interestRate']),
      interestType: _parseInterestType(json['interest_type'] ?? json['interestType']),
      rateType: _parseRateType(json['rate_type'] ?? json['rateType']),
      benchmarkRateCode: (json['benchmark_rate_code'] ?? json['benchmarkRateCode'] ?? '') as String,
      minTenureMonths: _parseInt(json['min_tenure_months'] ?? json['minTenureMonths']),
      maxTenureMonths: _parseInt(json['max_tenure_months'] ?? json['maxTenureMonths']),
      repayFrequency: _parseRepayFreq(json['repay_frequency'] ?? json['repayFrequency']),
      prinGl: (json['prin_gl'] ?? json['prinGl'] ?? '') as String,
      intGl: (json['int_gl'] ?? json['intGl'] ?? '') as String,
      penalGl: (json['penal_gl'] ?? json['penalGl'] ?? '') as String,
      productStatus: _parseBool(json['product_status'] ?? json['productStatus']),
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
    if (val == null) return true;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'active' || strVal == 'a' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static String _parseInterestType(dynamic val) {
    if (val == null) return 'Reducing';
    final strVal = val.toString().toUpperCase();
    if (strVal == 'F' || strVal == 'FLAT') return 'Flat';
    return 'Reducing';
  }

  static String _parseRateType(dynamic val) {
    if (val == null) return 'Fixed';
    final strVal = val.toString().toUpperCase();
    if (strVal == 'V' || strVal == 'L' || strVal == 'FLOATING') return 'Floating';
    return 'Fixed';
  }

  static String _parseRepayFreq(dynamic val) {
    if (val == null) return 'Monthly';
    final strVal = val.toString().toUpperCase();
    if (strVal == 'W') return 'Weekly';
    if (strVal == 'F') return 'Fortnightly';
    return 'Monthly';
  }

  static Map<String, dynamic> _toJson(LoanProductMaster product) {
    return {
      'orgcode': int.tryParse(product.orgCode) ?? 1,
      'product_code': product.productCode,
      'product_name': product.productName,
      'min_amount': product.minAmount,
      'max_amount': product.maxAmount,
      'interest_rate': product.interestRate,
      'interest_type': product.interestType.toUpperCase().startsWith('F') ? 'F' : 'R',
      'rate_type': product.rateType.toLowerCase() == 'floating' ? 'V' : 'F',
      'benchmark_rate_code': product.benchmarkRateCode,
      'min_tenure_months': product.minTenureMonths,
      'max_tenure_months': product.maxTenureMonths,
      'repay_frequency': product.repayFrequency.isNotEmpty ? product.repayFrequency[0].toUpperCase() : 'M',
      'prin_gl': product.prinGl,
      'int_gl': product.intGl,
      'penal_gl': product.penalGl,
      'product_status': product.productStatus ? '1' : '0',
    };
  }
}
