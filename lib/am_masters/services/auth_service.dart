import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'profile_service.dart';

// ignore: avoid_web_libraries_in_flutter
// dart:html removed – use SharedPreferences for all platforms in microfinance_ui

class AuthService {
  static const String _tokenKey = 'child_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _cachedUser;
  User? get currentUser => _cachedUser;

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await _prefs;
    String? deviceId = prefs.getString('device_id');
    if (deviceId != null && deviceId.isNotEmpty) return deviceId;
    deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString('device_id', deviceId);
    return deviceId;
  }

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<AuthResponse?> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/auth/login');
    try {
      final deviceId = await _getOrCreateDeviceId();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Id': deviceId,
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'productCode': AppConfig.instance.productCode,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);
        if (authResponse.motherToken != null) {
          final exchangeData = await exchangeToken(authResponse.motherToken!);
          String userName = '';
          String? roleTypeVal = authResponse.roleType;
          if (exchangeData != null) {
            final exchangeResponse = AuthResponse.fromJson(exchangeData);
            authResponse.childToken = exchangeResponse.childToken;
            authResponse.sessionData = exchangeResponse.sessionData;
            userName = exchangeResponse.sessionData?['userName'] ?? '';
            roleTypeVal = exchangeResponse.roleType ?? authResponse.roleType;
          }

          final user = User(
            id: authResponse.userScd?.toString() ?? '',
            email: authResponse.email ?? '',
            name: '${authResponse.firstName ?? ''} ${authResponse.lastName ?? ''}'.trim(),
            orgCode: authResponse.orgCode,
            userScd: authResponse.userScd,
            roleType: roleTypeVal ?? authResponse.sessionData?['roleType'] as String?,
            userName: userName,
          );

          await _saveAuthData(
            authResponse.motherToken!,
            authResponse.childToken,
            authResponse.refreshToken,
            roleTypeVal,
            user,
          );

          _cachedUser = user;

          if (user.userScd != null) {
            try {
              final loadedUser = await ProfileService()
                  .getUserDetails(user.userScd!, user.orgCode!, forceRefresh: true);
              if (loadedUser != null) {
                var finalProfileUser = loadedUser;
                if (user.roleType != null) {
                  finalProfileUser = User(
                    id: loadedUser.id,
                    email: loadedUser.email,
                    name: loadedUser.name,
                    orgCode: loadedUser.orgCode,
                    userScd: loadedUser.userScd,
                    roleType: user.roleType,
                    products: loadedUser.products,
                    menuType: loadedUser.menuType,
                    gender: loadedUser.gender,
                    title: loadedUser.title,
                    fName: loadedUser.fName,
                    mName: loadedUser.mName,
                    lName: loadedUser.lName,
                    mobile: loadedUser.mobile,
                    country: loadedUser.country,
                    userName: loadedUser.userName,
                    isOnline: loadedUser.isOnline,
                    lastSeen: loadedUser.lastSeen,
                    picture: loadedUser.picture,
                  );
                }
                _cachedUser = finalProfileUser;
                final prefs = await _prefs;
                await prefs.setString(_userKey, jsonEncode(finalProfileUser.toJson()));
              }
            } catch (_) {}
          }
        }
        return authResponse;
      }
      if (data != null && data['message'] != null) {
        throw Exception(data['message']);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ── Signup ─────────────────────────────────────────────────────────────────

  Future<AuthResponse?> signup(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);
        if (authResponse.motherToken != null) {
          final exchangeData = await exchangeToken(authResponse.motherToken!);
          String? roleTypeVal = authResponse.roleType;
          if (exchangeData != null) {
            final exchangeResponse = AuthResponse.fromJson(exchangeData);
            authResponse.childToken = exchangeResponse.childToken;
            authResponse.sessionData = exchangeResponse.sessionData;
            roleTypeVal = exchangeResponse.roleType ?? authResponse.roleType;
          }
          final user = User(
            id: authResponse.userScd?.toString() ?? '',
            email: authResponse.email ?? '',
            name: authResponse.firstName ?? '',
            orgCode: authResponse.orgCode,
            userScd: authResponse.userScd,
            userName: authResponse.userName,
            roleType: roleTypeVal,
          );
          await _saveAuthData(authResponse.motherToken!, authResponse.childToken,
              authResponse.refreshToken, roleTypeVal, user);
        }
        return authResponse;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Storage ────────────────────────────────────────────────────────────────

  Future<void> _saveAuthData(
    String motherToken,
    String? childToken,
    String? refreshToken,
    String? roleType,
    User user,
  ) async {
    final prefs = await _prefs;
    await prefs.setString('mother_token', motherToken);
    if (childToken != null) await prefs.setString(_tokenKey, childToken);
    if (refreshToken != null) await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<String?> getMotherToken() async {
    final prefs = await _prefs;
    return prefs.getString('mother_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _prefs;
    return prefs.getString(_refreshTokenKey);
  }

  Future<User?> getUser() async {
    final prefs = await _prefs;
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      _cachedUser = User.fromJson(jsonDecode(userData));
      return _cachedUser;
    }
    return null;
  }

  Future<void> updateCachedUser(User user) async {
    _cachedUser = user;
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await http.post(
          Uri.parse('${AppConfig.instance.baseUrl}/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {}

    _cachedUser = null;
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove('mother_token');
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  // ── Exchange Token ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> exchangeToken(String token) async {
    final deviceId = await _getOrCreateDeviceId();
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/exchange/exchange-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-Device-Id': deviceId,
        },
        body: jsonEncode({'productCode': AppConfig.instance.productCode}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (_) {}
    return null;
  }

  // ── Verify Email ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> verifyEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200 || response.statusCode == 401) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // ── Reset Password ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resetPassword(
    String userScd,
    int orgCode,
    String newPassword,
    String confirmPassword, {
    String? oldPassword,
  }) async {
    try {
      final endpoint = (oldPassword != null && oldPassword.isNotEmpty)
          ? '/user/reset-password/'
          : '/auth/reset-password/';
      final url = '${AppConfig.instance.baseUrl}$endpoint$userScd/$orgCode';
      final requestBody = <String, String>{
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
      if (oldPassword != null && oldPassword.isNotEmpty) {
        requestBody['oldPassword'] = oldPassword;
      }
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (oldPassword != null && oldPassword.isNotEmpty) {
        final token = await getToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'status': 200, 'message': 'Password reset successfully'};
      }
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'status': errorData['status'] ?? response.statusCode,
          'message': errorData['message'] ?? 'Failed to reset password',
        };
      } catch (_) {
        return {
          'success': false,
          'status': response.statusCode,
          'message': 'Failed to reset password',
        };
      }
    } catch (e) {
      return {'success': false, 'status': 500, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> adminResetPassword(
    String userScd, int orgCode, String newPassword, String confirmPassword,
  ) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/user/admin-reset-password/$userScd/$orgCode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Password reset successfully'};
      }
      return {'success': false, 'message': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── OTP Flow ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> generateOtp(Map<String, dynamic> requestData) async {
    try {
      final data = Map<String, dynamic>.from(requestData);
      if (!data.containsKey('productCode')) {
        data['productCode'] = AppConfig.instance.productCode;
      }
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/auth/forgot-password/generate-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        final errorData = jsonDecode(response.body);
        return {'error': true, 'message': errorData['message'] ?? 'Failed to generate OTP.'};
      } catch (_) {
        return {'error': true, 'message': 'Failed to generate OTP.'};
      }
    } catch (e) {
      return {'error': true, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String tokenKey, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/auth/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tokenKey': tokenKey, 'otp': otp}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        final errorData = jsonDecode(response.body);
        return {'error': true, 'message': errorData['message'] ?? 'Invalid OTP or expired.'};
      } catch (_) {
        return {'error': true, 'message': 'Invalid OTP or expired.'};
      }
    } catch (e) {
      return {'error': true, 'message': 'An error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithToken(
    String tokenKey, String newPassword, String confirmPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.instance.baseUrl}/auth/forgot-password/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokenKey': tokenKey,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );
      if (response.statusCode == 200) {
        return {'success': true, 'status': 200, 'message': 'Password reset successfully'};
      }
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'status': errorData['status'] ?? response.statusCode,
          'message': errorData['message'] ?? 'Failed to reset password',
        };
      } catch (_) {
        return {'success': false, 'status': response.statusCode, 'message': 'Failed to reset password'};
      }
    } catch (e) {
      return {'success': false, 'status': 500, 'message': 'An error occurred: $e'};
    }
  }
}
