import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class AddressService {
  final _authService = AuthService();

  static final AddressService _instance = AddressService._internal();
  factory AddressService() => _instance;
  AddressService._internal();

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

  Future<List<Map<String, dynamic>>> getCountries() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/address/countries');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch countries: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected countries response format');
  }

  Future<List<Map<String, dynamic>>> getStates(int countryId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/address/states');
    final headers = await _getHeaders();
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'countryid': countryId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch states: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected states response format');
  }

  Future<List<Map<String, dynamic>>> getCities(int stateId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/address/cities');
    final headers = await _getHeaders();
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'stateid': stateId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch cities: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected cities response format');
  }

  Future<List<Map<String, dynamic>>> getPincodes(int cityId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/address/pincodes');
    final headers = await _getHeaders();
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'cityid': cityId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch pincodes: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.cast<Map<String, dynamic>>());
    }

    throw Exception('Unexpected pincodes response format');
  }
}


