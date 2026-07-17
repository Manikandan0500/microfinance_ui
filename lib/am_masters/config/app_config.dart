import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppConfig {
  final String baseUrl;
  final String connectUrl;
  final int productCode;

  AppConfig._({required this.baseUrl, required this.connectUrl, required this.productCode});

  static AppConfig? _instance;

  static Future<AppConfig> getInstance() async {
    if (_instance != null) return _instance!;

    Map<String, dynamic> data;

    try {
      if (kIsWeb) {
        final response = await http.get(Uri.parse('./config.json'));
        data = json.decode(response.body);
      } else {
        final jsonString = await rootBundle.loadString('assets/config.json');
        data = json.decode(jsonString);
      }
    } catch (_) {
      // Fallback to microfinance backend default
      data = {
        'baseUrl': 'http://localhost:8085',
        'connectUrl': '',
        'productCode': 12,
      };
    }

    _instance = AppConfig._(
      baseUrl: data['baseUrl'] ?? 'http://localhost:8085',
      connectUrl: data['connectUrl'] ?? '',
      productCode: data['productCode'] ?? 12,
    );

    return _instance!;
  }

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig not initialized. Call getInstance() first.');
    }
    return _instance!;
  }

  /// Force reload config
  static void reset() => _instance = null;
}