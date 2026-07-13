import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/loan_product_master.dart';

class LoanProductApiService {
  static const String _baseUrl = 'http://localhost:8085/api/loan-products';

  static Future<List<LoanProductMaster>> getProducts() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load loan products: ${response.statusCode}');
  }

  static Future<LoanProductMaster> createProduct(LoanProductMaster product) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(product)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create loan product: ${response.statusCode}');
  }

  static Future<LoanProductMaster> updateProduct(LoanProductMaster product) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(product.productCode)}';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(product)),
    );
    if (response.statusCode == 200) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to update loan product: ${response.statusCode}');
  }

  static Future<void> deleteProduct(String productCode) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(productCode)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete loan product: ${response.statusCode}');
    }
  }

  static LoanProductMaster _fromJson(Map<String, dynamic> json) {
    return LoanProductMaster(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      productCode: (json['productCode'] ?? '') as String,
      productName: (json['productName'] ?? '') as String,
      minAmount: (json['minAmount'] ?? 0.0) as double,
      maxAmount: (json['maxAmount'] ?? 0.0) as double,
      interestRate: (json['interestRate'] ?? 0.0) as double,
      interestType: (json['interestType'] ?? 'Reducing') as String,
      rateType: (json['rateType'] ?? 'Fixed') as String,
      benchmarkRateCode: (json['benchmarkRateCode'] ?? '') as String,
      minTenureMonths: (json['minTenureMonths'] ?? 0) as int,
      maxTenureMonths: (json['maxTenureMonths'] ?? 0) as int,
      repayFrequency: (json['repayFrequency'] ?? 'Monthly') as String,
      prinGl: (json['prinGl'] ?? '') as String,
      intGl: (json['intGl'] ?? '') as String,
      penalGl: (json['penalGl'] ?? '') as String,
      productStatus: (json['productStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(LoanProductMaster product) {
    return {
      'orgCode': 1,
      'productCode': product.productCode,
      'productName': product.productName,
      'minAmount': product.minAmount,
      'maxAmount': product.maxAmount,
      'interestRate': product.interestRate,
      'interestType': product.interestType,
      'rateType': product.rateType,
      'benchmarkRateCode': product.benchmarkRateCode,
      'minTenureMonths': product.minTenureMonths,
      'maxTenureMonths': product.maxTenureMonths,
      'repayFrequency': product.repayFrequency,
      'prinGl': product.prinGl,
      'intGl': product.intGl,
      'penalGl': product.penalGl,
      'productStatus': product.productStatus,
    };
  }
}
