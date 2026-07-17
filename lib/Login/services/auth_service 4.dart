import 'dart:convert';
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:microfinance_ui/am_masters/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:microfinance_ui/am_masters/models/auth_response.dart';
import 'package:microfinance_ui/am_masters/models/user.dart';
import 'package:microfinance_ui/am_masters/services/profile_service.dart';
import 'dart:async';
class AuthService {
  static const String _tokenKey = 'child_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
 
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
 
  User? _cachedUser;
  User? get currentUser => _cachedUser;
 
Future<String> _getOrCreateDeviceId() async {
  if (kIsWeb) {
    String? deviceId = html.window.localStorage['device_id'];

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    deviceId = const Uuid().v4(); // âœ… pure UUID
    html.window.localStorage['device_id'] = deviceId;

    return deviceId;

  } else {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');

    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    deviceId = const Uuid().v4(); // âœ… pure UUID
    await prefs.setString('device_id', deviceId);

    return deviceId;
  }
}
  Future<AuthResponse?> login(String email, String password) async {
    print("LOG: auth_service.login started. Email: $email");
    try {
      final baseUrl = AppConfig.instance.baseUrl;
      print("LOG: baseUrl is $baseUrl");
      final url = Uri.parse('$baseUrl/api/auth/login');
      print("LOG: Resolved login URL: $url");
      
      final deviceId = await _getOrCreateDeviceId();
      print("LOG: Device ID: $deviceId");
 
      final bodyPayload = jsonEncode({
        'email': email,
        'emailid': email,
        'password': password,
        'productCode': AppConfig.instance.productCode,
      });
      print("LOG: Request Body payload: $bodyPayload");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Device-Id': deviceId,
        },
        body: bodyPayload,
      );
 
      print("LOG: HTTP Post Response status: ${response.statusCode}");
      final data = jsonDecode(response.body);
      print("RAW LOGIN JSON: $data");
 
    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(data);
      if (authResponse.motherToken != null) {
        final exchangeData = await exchangeToken(authResponse.motherToken!);
        String userName="";
        String? roleTypeVal = authResponse.roleType;
        if (exchangeData != null) {
          final exchangeResponse = AuthResponse.fromJson(exchangeData);
          authResponse.childToken = exchangeResponse.childToken;
          authResponse.sessionData = exchangeResponse.sessionData;
          userName=  exchangeResponse.sessionData?['userName'];
          roleTypeVal = exchangeResponse.roleType ?? authResponse.roleType;
        }
 
        final user = User(
          id: authResponse.userScd?.toString() ?? '',
          email: authResponse.email ?? '',
          name: "${authResponse.firstName ?? ''} ${authResponse.lastName ?? ''}",
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
          print('ðŸ”„ Fetching profile user details for userScd=${user.userScd}');
          final loadedUser = await ProfileService()
              .getUserDetails(user.userScd!, user.orgCode!, forceRefresh: true);
 
          if (loadedUser != null) {
            print('âœ… Profile refresh successful');
 
            var finalProfileUser = loadedUser;
            if (user.roleType != null) {
              print('âš ï¸ Preserving original roleType: ${user.roleType}');
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
            if (kIsWeb) {
              // flutter.user_data removed - handled by separate storage
            } else {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(_userKey, jsonEncode(finalProfileUser.toJson()));
            }
 
            // âœ… Record login history â€” profile fetch succeeded
            // unawaited(LoginHistoryService().recordMotherLogin(
            //   childToken: authResponse.childToken ?? '',
            //   sessionData: authResponse.sessionData ?? {},
            // ));
 
          } else {
            print('âš ï¸ Profile refresh returned null, keeping login user');
            _cachedUser = user;
 
            // // âœ… Record login history â€” profile fetch failed but login OK
            // unawaited(LoginHistoryService().recordMotherLogin(
            //   childToken: authResponse.childToken ?? '',
            //   sessionData: authResponse.sessionData ?? {},
            // ));
          }
        } else {
          print('âš ï¸ No userScd â€” skipping profile fetch');
 
          // // âœ… Record login history â€” no userScd case
          // unawaited(LoginHistoryService().recordMotherLogin(
          //   childToken: authResponse.childToken ?? '',
          //   sessionData: authResponse.sessionData ?? {},
          // ));
        }
      }
      return authResponse;
    }
    if (data != null && data['message'] != null) {
      throw Exception(data['message']);
    }
    return null;
  } catch (e) {
    print("LOGIN ERROR: $e");
    rethrow;
  }
}
 
  // â”€â”€ Signup â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
  Future<AuthResponse?> signup(String email, String password) async {
    try {
      final url = '${AppConfig.instance.baseUrl}/auth/signup';
      print("Calling: $url");
 
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
 
      final data = jsonDecode(response.body);
      print("RAW SIGNUP JSON: $data");
 
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
          await _saveAuthData(
            authResponse.motherToken!,
            authResponse.childToken,
            authResponse.refreshToken,
            roleTypeVal,
            user,
          );
        }
        return authResponse;
      }
      return null;
    } catch (e) {
      print("SIGNUP ERROR: $e");
      return null;
    }
  }
 
  // â”€â”€ Storage â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
  Future<void> _saveAuthData(
    String motherToken,
    String? childToken,
    String? refreshToken,
    String? roleType,
    User user,
  ) async {
    if (kIsWeb) {
      html.window.sessionStorage.remove('flutter.child_token');
      html.window.sessionStorage.remove('flutter.mother_token');
      html.window.sessionStorage.remove('flutter.refresh_token');
      html.window.sessionStorage.remove('flutter.user_data');
 
      html.window.sessionStorage['mother_token'] = motherToken;
      if (childToken != null) html.window.sessionStorage['child_token'] = childToken;
      if (refreshToken != null) html.window.sessionStorage['refresh_token'] = refreshToken;
      html.window.sessionStorage['role_type'] = roleType ?? '';
      html.window.sessionStorage['user_data'] = jsonEncode(user.toJson());
      print("✅ User saved to SessionStorage (Web)");
      
      // Also save to SharedPreferences for shared services
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mother_token', motherToken);
      if (childToken != null) await prefs.setString(_tokenKey, childToken);
      if (refreshToken != null) await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mother_token', motherToken);
      if (childToken != null) await prefs.setString(_tokenKey, childToken);
      if (refreshToken != null) await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      print("âœ… User saved to SharedPreferences (Non-Web)");
    }
  }
 
  Future<String?> getToken() async {
    if (kIsWeb) {
      final token = html.window.sessionStorage['child_token'];
      if (token != null) {
        html.window.sessionStorage.remove('flutter.child_token');
        return token;
      }
      final legacy = html.window.sessionStorage['flutter.child_token'];
      if (legacy != null) {
        html.window.sessionStorage['child_token'] = legacy;
        html.window.sessionStorage.remove('flutter.child_token');
        return legacy;
      }
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
 
  Future<String?> getMotherToken() async {
    if (kIsWeb) {
      final token = html.window.sessionStorage['mother_token'];
      if (token != null) {
        html.window.sessionStorage.remove('flutter.mother_token');
        return token;
      }
      final legacy = html.window.sessionStorage['flutter.mother_token'];
      if (legacy != null) {
        html.window.sessionStorage['mother_token'] = legacy;
        html.window.sessionStorage.remove('flutter.mother_token');
        return legacy;
      }
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mother_token');
  }
 
  Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final token = html.window.sessionStorage['refresh_token'];
      if (token != null) {
        html.window.sessionStorage.remove('flutter.refresh_token');
        return token;
      }
      final legacy = html.window.sessionStorage['flutter.refresh_token'];
      if (legacy != null) {
        html.window.sessionStorage['refresh_token'] = legacy;
        html.window.sessionStorage.remove('flutter.refresh_token');
        return legacy;
      }
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
 
  Future<User?> getUser() async {
    String? userData;
    if (kIsWeb) {
      userData = html.window.sessionStorage['user_data'];
      if (userData == null) {
        final legacy = html.window.sessionStorage['flutter.user_data'];
        if (legacy != null) {
          html.window.sessionStorage['user_data'] = legacy;
          html.window.sessionStorage.remove('flutter.user_data');
          userData = legacy;
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      userData = prefs.getString('user_data');
    }
 
    print("ðŸ”µ Loading user...");
    print("Stored user_data: $userData");
 
    if (userData != null) {
      final user = User.fromJson(jsonDecode(userData));
      print("ðŸŸ¢ User loaded: ${user.email}");
      return user;
    }
 
    print("ðŸ”´ No user found in SharedPreferences");
    return null;
  }
 
  Future<void> updateCachedUser(User user) async {
    _cachedUser = user;
    if (kIsWeb) {
      // flutter.user_data removed - handled by separate storage
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    }
  }
 
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
 
  // â”€â”€ Logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
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
        print("âœ… Logout recorded in backend");
      } else {
        print("âš ï¸ No child token found, skipping backend logout");
      }
    } catch (e) {
      print("âš ï¸ Logout API error (non-critical): $e");
    }
 
    _cachedUser = null;
 
    if (kIsWeb) {
      html.window.sessionStorage.remove('child_token');
      html.window.sessionStorage.remove('mother_token');
      html.window.sessionStorage.remove('refresh_token');
      html.window.sessionStorage.remove('role_type');
      html.window.sessionStorage.remove('user_data');
      html.window.sessionStorage.remove('flutter.child_token');
      html.window.sessionStorage.remove('flutter.mother_token');
      html.window.sessionStorage.remove('flutter.refresh_token');
      html.window.sessionStorage.remove('flutter.user_data');
      print("ðŸ—‘ï¸ User data removed from SessionStorage (Web)");
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove('mother_token');
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userKey);
      print("ðŸ—‘ï¸ User data removed from SharedPreferences (Non-Web)");
    }
  }
 
  // â”€â”€ Verify Email â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
  Future<Map<String, dynamic>?> verifyEmail(String email) async {
    try {
      final url = '${AppConfig.instance.baseUrl}/auth/verify-email';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200 || response.statusCode == 401) return jsonDecode(response.body);
      return null;
    } catch (e) {
      print("VERIFY EMAIL ERROR: $e");
      return null;
    }
  }
 
  // â”€â”€ Reset Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
  Future<Map<String, dynamic>> resetPassword(
    String userScd,
    int orgCode,
    String newPassword,
    String confirmPassword, {
    String? oldPassword,
  }) async {
    try {
      final baseUrl = AppConfig.instance.baseUrl.replaceFirst('/api', '');
      final endpoint = (oldPassword != null && oldPassword.isNotEmpty)
          ? '/user/reset-password/'
          : '/auth/reset-password/';
      final url = '$baseUrl$endpoint$userScd/$orgCode';
 
      print("ðŸ”„ Calling reset password API: $url");
 
      final requestBody = {
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      };
      if (oldPassword != null && oldPassword.isNotEmpty) {
        requestBody['oldPassword'] = oldPassword;
      }
 
      final headers = {'Content-Type': 'application/json'};
      if (oldPassword != null && oldPassword.isNotEmpty) {
        final token = await getToken();
        if (token != null) headers['Authorization'] = 'Bearer $token';
      }
 
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );
 
      print("ðŸ“¨ Reset Password Response Status: ${response.statusCode}");
      print("ðŸ“¨ Reset Password Response Body: ${response.body}");
 
      if (response.statusCode == 200) {
        return {'success': true, 'status': 200, 'message': 'Password reset successfully'};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'status': errorData['status'] ?? response.statusCode,
            'message': errorData['message'] ?? 'Failed to reset password',
          };
        } catch (e) {
          return {
            'success': false,
            'status': response.statusCode,
            'message': 'Failed to reset password: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print("RESET PASSWORD ERROR: $e");
      return {'success': false, 'status': 500, 'message': 'An error occurred: $e'};
    }
  }
 
  // â”€â”€ Exchange Token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
  Future<Map<String, dynamic>?> exchangeToken(String token) async {
     final deviceId = await _getOrCreateDeviceId();
    final response = await http.post(
      Uri.parse("${AppConfig.instance.baseUrl}/exchange/exchange-token"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
         "X-Device-Id": deviceId
      },
      body: jsonEncode({"productCode": AppConfig.instance.productCode}),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return responseData;
    }
    return null;
  }
 
  // â”€â”€ Admin Reset Password â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
 
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
      } else {
        return {'success': false, 'message': response.body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

   // â”€â”€ Forgot Password OTP Flow â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>?> generateOtp(Map<String, dynamic> requestData) async {
    try {
      final url = '${AppConfig.instance.baseUrl}/auth/forgot-password/generate-otp';
      
      // Ensure productCode is included
      final data = Map<String, dynamic>.from(requestData);
      if (!data.containsKey('productCode')) {
        data['productCode'] = AppConfig.instance.productCode;
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);

      // Return error message if any
      try {
        final errorData = jsonDecode(response.body);
        return {
          'error': true,
          'message': errorData['message'] ?? 'Failed to generate OTP. Please try again.',
        };
      } catch (_) {
        return {'error': true, 'message': 'Failed to generate OTP. Please try again.'};
      }
    } catch (e) {
      print("GENERATE OTP ERROR: $e");
      return {'error': true, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>?> verifyOtp(String tokenKey, String otp) async {
    try {
      final url = '${AppConfig.instance.baseUrl}/auth/forgot-password/verify-otp';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tokenKey': tokenKey, 'otp': otp}),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);

      // â”€â”€ Return error message instead of null â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      try {
        final errorData = jsonDecode(response.body);
        return {
          'error': true,
          'message': errorData['message'] ?? 'Invalid OTP or expired.',
        };
      } catch (_) {
        return {'error': true, 'message': 'Invalid OTP or expired.'};
      }

    } catch (e) {
      print("VERIFY OTP ERROR: $e");
      return {'error': true, 'message': 'An error occurred. Please try again.'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithToken(
    String tokenKey,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final url = '${AppConfig.instance.baseUrl}/auth/forgot-password/reset-password';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tokenKey': tokenKey,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        }),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'status': 200, 'message': 'Password reset successfully'};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'status': errorData['status'] ?? response.statusCode,
            'message': errorData['message'] ?? 'Failed to reset password',
          };
        } catch (e) {
          return {
            'success': false,
            'status': response.statusCode,
            'message': 'Failed to reset password: ${response.reasonPhrase}',
          };
        }
      }
    } catch (e) {
      print("RESET PASSWORD WITH TOKEN ERROR: $e");
      return {'success': false, 'status': 500, 'message': 'An error occurred: $e'};
    }
  }
}

