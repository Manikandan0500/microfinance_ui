import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/user_account_model.dart';
import '../models/product_model.dart';
import 'auth_service.dart';
import 'package:flutter/material.dart';
import '../widgets/bulk_upload_dialog.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'product_service.dart';
import '../Datas/countries.dart';
import 'organization_service.dart';
import 'branch_service.dart';

class UserAccountService {
  final _authService = AuthService();

  static final UserAccountService _instance = UserAccountService._internal();
  factory UserAccountService() => _instance;
  UserAccountService._internal();

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

  Future<List<UserAccount>> getAllUsers() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/user-account');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data
          .map((item) => UserAccount.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    throw Exception('Unexpected users response format');
  }

  Future<Map<String, dynamic>> getUsersPaginated({
    required int offset,
    required int limit,
    String? search,
    int? orgCode,
    int? brncd,
  }) async {
    final queryParams = {
      'offset': offset.toString(),
      'limit': limit.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (orgCode != null) 'orgCode': orgCode.toString(),
      if (brncd != null) 'brncd': brncd.toString(),
    };
    final url = Uri.parse('${AppConfig.instance.baseUrl}/user-account').replace(queryParameters: queryParams);
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch paginated users: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected paginated users response format');
  }

  Future<UserAccount> createUser(UserAccount user) async {
 final url = Uri.parse('${AppConfig.instance.baseUrl}/user-account/createUserAccount');
    final headers = await _getHeaders();
    final currentUser = await _authService.getUser();
    user.userName = currentUser?.userName?.toString() ?? '';
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          throw errorData['message'];
        }
      } catch (e) {
        if (e is String) rethrow;
      }
      throw 'Failed to create user: ${response.statusCode}';
    }

    return UserAccount.fromJson(jsonDecode(response.body));
  }

  Future<UserAccount> updateUser(UserAccount user) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/user-account/${user.orgCode}/${user.userCode}');
    final headers = await _getHeaders();
    final currentUser = await _authService.getUser();
    user.userName = currentUser?.userName?.toString() ?? '';
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['message'] != null) {
          throw errorData['message'];
        }
      } catch (e) {
        if (e is String) rethrow;
      }
      throw 'Failed to update user: ${response.statusCode}';
    }

    return UserAccount.fromJson(jsonDecode(response.body));
  }

  Future<void> deleteUser(int orgCode, String userCode) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final Map<String, dynamic> body = {
      "deleteType": "USER",
      "orgcode": orgCode,
      "userscd": userCode,
      "cascade": true
    };
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete user: ${response.statusCode} ${response.body}');
    }
  }

  void showBulkUpload(BuildContext context, VoidCallback onComplete) {
    BulkUploadDialog.show(
      context,
      title: 'Bulk Upload Users',
      entityName: 'Users',
      validateEndpoint: '/user-account/bulk-upload',
      uploadEndpoint: '/user-account/bulk-process',
      templateAssetPath: 'assets/User_Bulk_Upload_Template.xlsx',
      templateFileName: 'User_Bulk_Upload_Template.xlsx',
      templateSheetName: 'User Bulk Upload',
      programName: 'User_Account',
      onComplete: onComplete,
    );
  }

   Future<List<Map<String, dynamic>>> userRecordMapper(
    SpreadsheetTable sheet,
    void Function(String message, {bool isError}) addLog,
    void Function() incrementFailure,
    Map<String, String> displayNamesMap,
  ) async {
    final currentUser = await _authService.getUser();
    final isAdmin = currentUser?.roleType?.toUpperCase() == 'ADMIN';
    final adminOrgCode = currentUser?.orgCode;

    final accessManagerProd = ProductModel(
      orgCode: 0,
      productCode: 1,
      productName: 'Access Manager',
      homeUrl: '',
      status: true,
    );

    // Pre-fetch reference data for validation
    // Organization and Branch validation moved to DB procedure

    final List<Map<String, dynamic>> payloads = [];
    
    for (int i = 1; i < sheet.maxRows; i++) {
      if (i % 1000 == 0) {
        await Future.delayed(Duration.zero);
      }
      final row = sheet.rows[i];
      if (row.isEmpty || row.every((c) => c == null)) continue;

      String getStr(int col) => col < row.length ? (row[col]?.toString().trim() ?? '') : '';

      final orgCodeStr = getStr(0);
      final orgNameStr = getStr(1);
      final branchCodeStr = getStr(2);
      final branchNameStr = getStr(3);
      final userCode = getStr(4);
      final roleStr = getStr(5).toLowerCase().trim();

      final title = getStr(6);
      final fName = getStr(7);
      final mName = getStr(8);
      final lName = getStr(9);
      final dob = getStr(10);
      final genderStr = getStr(11);
      final countryCode = getStr(12);
      final mobile = getStr(13);
      final email = getStr(14);
      final statusStr = getStr(15);
      final regDate = getStr(16);

      if (orgCodeStr.isEmpty && userCode.isEmpty && fName.isEmpty && lName.isEmpty && email.isEmpty) {
        continue;
      }

      final fullNameParts = [fName, mName, lName].where((n) => n.isNotEmpty).toList();
      final fullName = fullNameParts.join(' ').trim();
      displayNamesMap[userCode] = fullName;

      if (orgCodeStr.isEmpty || userCode.isEmpty || fName.isEmpty || lName.isEmpty || email.isEmpty) {
        final displayUser = userCode.isNotEmpty
            ? (fullName.isNotEmpty ? "$userCode ($fullName)" : userCode)
            : "Row ${i + 1}";
        addLog('Row ${i + 1} skipped ($displayUser): Required fields missing.', isError: true);
        incrementFailure();
        continue;
      }

      final orgCode = int.tryParse(orgCodeStr);
      if (orgCode == null) {
        addLog('Row ${i + 1} skipped ($userCode - $fullName): Org Code must be numeric.', isError: true);
        incrementFailure();
        continue;
      }

      if (isAdmin && adminOrgCode != null && orgCode != adminOrgCode) {
        addLog('Row ${i + 1} skipped ($userCode - $fullName): Admin users can only upload records for their own organization.', isError: true);
        incrementFailure();
        continue;
      }

      final branchCode = int.tryParse(branchCodeStr);
      if (branchCodeStr.isNotEmpty && branchCode == null) {
        addLog('Row ${i + 1} skipped ($userCode - $fullName): Branch Code must be numeric.', isError: true);
        incrementFailure();
        continue;
      }

      if (!['system admin', 'system administrator', 'admin', 'administrator', 'end user'].contains(roleStr)) {
        addLog('Row ${i + 1} skipped ($userCode - $fullName): Invalid role "$roleStr". Must be System Admin, Admin, or End User.', isError: true);
        incrementFailure();
        continue;
      }

      int roleType;
      if (roleStr == 'system admin' || roleStr == 'system administrator') {
        roleType = 1;
      } else if (roleStr == 'admin' || roleStr == 'administrator') {
        roleType = 2;
      } else {
        roleType = 3;
      }

      final statusVal = (statusStr.toLowerCase() == 'active' || statusStr == '1') ? 1 : 0;
      String genderChar = 'M';
      if (genderStr.isNotEmpty) {
        final g = genderStr.toUpperCase()[0];
        if (g == 'F' || g == 'O') genderChar = g;
      }
      final countryName = CountryData.countryNameFromCode(countryCode);
      final callCode = CountryData.phoneCodes[countryName]?.replaceAll('+', '') ?? '91';

      payloads.add({
        'excelRowNo': i + 1,
        'orgCode': orgCode,
        'userScd': userCode,
        'title': title,
        'fName': fName,
        'mName': mName,
        'lName': lName,
        'emailid': email,
        'mobile': mobile,
        'gender': genderChar,
        'regDate': regDate,
        'status': statusVal,
        'brncd': branchCode,
        'dob': dob,
        'country': countryCode.toUpperCase(),
        'callCode': callCode,
        'productCode': accessManagerProd.productCode,
        'roleType': roleType,
      });
    }
    return payloads;
  }
}




