import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import '../models/menu_models.dart';
import '../models/access_privileges.dart';
import 'package:flutter/foundation.dart';

class MenuMasterService {
  final _authService = AuthService();

  static final MenuMasterService _instance = MenuMasterService._internal();
  factory MenuMasterService() => _instance;
  MenuMasterService._internal();

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

  Future<List<HeadMenuModel>> getHeadMenus() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-all-head-menus');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch head menus: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse is List) {
      return jsonResponse.map((json) => HeadMenuModel.fromJson(json)).toList();
    }
    throw Exception('Unexpected head menus response format');
  }

  Future<HeadMenuModel> getHeadMenu(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-head-menu');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({'hmenuCd': id}));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch head menu: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse != null) {
      return HeadMenuModel.fromJson(jsonResponse);
    }
    throw Exception('Unexpected head menu response format');
  }

  Future<List<MenuModel>> getMenus() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-all-menus');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch menus: ${response.statusCode}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((e) => MenuModel.fromJson(e)).toList();
  }

  Future<MenuModel> getMenu(int hId, int mId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-menu');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({'hmenuCd': hId, 'menuCd': mId}));
    
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch menu: ${response.statusCode}');
    }
    
    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse != null) {
      return MenuModel.fromJson(jsonResponse);
    }
    throw Exception('Unexpected menu response format');
  }

  Future<List<MenuProgramModel>> getMenuPrograms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'ORG001', description: 'Organizations', status: true, menuLogo: 'org.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'BRN001', description: 'Branches', status: true, menuLogo: 'brn.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'PRD001', description: 'Products', status: true, menuLogo: 'prd.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'PRM001', description: 'Products Mapping', status: true, menuLogo: 'prm.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'USR001', description: 'User Accounts', status: true, menuLogo: 'usr.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'UPM001', description: 'User Product Mapping', status: true, menuLogo: 'upm.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'PWD001', description: 'Password Policy', status: true, menuLogo: 'pwd.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'ACC001', description: 'Access Code', status: true, menuLogo: 'acc.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'BLK001', description: 'Block / Unblock', status: false, menuLogo: 'blk.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'SMTP00', description: 'SMTP Config', status: true, menuLogo: 'smtp.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'OTP001', description: 'OTP Config', status: true, menuLogo: 'otp.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'MOD001', description: 'Modules', status: true, menuLogo: 'mod.png'),
      MenuProgramModel(hMenuCd: 1, menuCd: 2, subMenuCd: 1, pgmId: 'MNU001', description: 'Menu Master', status: true, menuLogo: 'mnu.png'),
    ];
  }

  Future<void> updateHeadMenu(HeadMenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/edit-head-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    final response = await http.post(url, headers: headers, body: jsonEncode(data.toJson()));

    _checkResponse(response, 'Failed to update head menu: ${response.statusCode}');
  }

  Future<void> createHeadMenu(HeadMenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/create-head-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    final response = await http.post(url, headers: headers, body: jsonEncode(data.toJson()));

    _checkResponse(response, 'Failed to save head menu: ${response.statusCode}');
  }

  Future<void> deleteHeadMenu(int id) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({
      "deleteType": "MENU_HEAD",
      "hMenuCd": id
    }));

    _checkResponse(response, 'Failed to delete head menu: ${response.statusCode}');
  }

  Future<void> updateMenu(MenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/edit-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    final response = await http.post(url, headers: headers, body: jsonEncode(data.toJson()));

    _checkResponse(response, 'Failed to update menu: ${response.statusCode}');
  }

  Future<void> createMenu(MenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/create-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    final response = await http.post(url, headers: headers, body: jsonEncode(data.toJson()));

    _checkResponse(response, 'Failed to create menu: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> getNestedMenus(int accessCd) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/getMenusByAccessCode');
    final headers = await _getHeaders();
    final currentUser = await _authService.getUser();
    
    try {
      final res = await http.post(
        url, 
        headers: headers,
        body: jsonEncode({
          'accessCd': accessCd,
          'orgCode': currentUser?.orgCode
        })
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          final transformed = _transformKeys(body);
          return {'headMenus': transformed};
        } else if (body is Map<String, dynamic>) {
          final dataMap = body['data'] != null ? body['data'] : body;
          final transformed = _transformKeys(dataMap);
          if (transformed is Map<String, dynamic>) {
            return Map<String, dynamic>.from(transformed);
          }
          return {'headMenus': transformed};
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  dynamic _transformKeys(dynamic data) {
    if (data is List) {
      return data.map((e) => _transformKeys(e)).toList();
    } else if (data is Map<String, dynamic>) {
      final newMap = <String, dynamic>{};
      data.forEach((key, value) {
        String newKey = key;
        
        if (newKey == 'hmenuCd') newKey = 'headMenuCode';
        else if (newKey == 'hmenuDesc') newKey = 'headMenuDescription';
        else if (newKey == 'hpgmId') newKey = 'headProgramId';
        else if (newKey == 'menuCd') newKey = 'menuCode';
        else if (newKey == 'menuDescn') newKey = 'menuDescription';
        else if (newKey == 'subMenuReq') newKey = 'subMenuRequired';
        else if (newKey == 'parentPgmId') newKey = 'parentProgramId';
        else if (newKey == 'subMenuCd') newKey = 'subMenuCode';
        else if (newKey == 'subMenuPgmId') newKey = 'subMenuProgramId';
        else if (newKey == 'pgmId') newKey = 'programId';
        
        newMap[newKey] = _transformKeys(value);
      });
      return newMap;
    }
    return data;
  }

  Future<void> deleteMenu(int hId, int mId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({
      "deleteType": "MENU",
      "hMenuCd": hId,
      "menuCd": mId
    }));

    _checkResponse(response, 'Failed to delete menu: ${response.statusCode}');
  }

  Future<List<SubMenuModel>> getSubMenus() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-all-sub-menus');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch sub menus: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse is List) {
      return jsonResponse.map((json) => SubMenuModel.fromJson(json)).toList();
    }
    throw Exception('Unexpected sub menus response format');
  }

  Future<SubMenuModel> getSubMenu(int hMenuCd, int menuCd, int subMenuCd) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-sub-menu');
    final headers = await _getHeaders();
    
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'hmenuCd': hMenuCd, 'menuCd': menuCd, 'subMenuCd': subMenuCd})
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch sub menu details: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse != null) {
      return SubMenuModel.fromJson(jsonResponse);
    }
    throw Exception('Sub menu details not found');
  }

  Future<void> updateSubMenu(SubMenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/edit-sub-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    
    final bodyData = data.toJson();
    final response = await http.post(url, headers: headers, body: jsonEncode(bodyData));

    _checkResponse(response, 'Failed to update sub menu: ${response.statusCode}');
  }

  Future<void> createSubMenu(SubMenuModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/create-sub-menu');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';

    final bodyData = data.toJson();
    final response = await http.post(url, headers: headers, body: jsonEncode(bodyData));

    _checkResponse(response, 'Failed to create sub menu: ${response.statusCode}');
  }

  Future<void> deleteSubMenu(int hId, int mId, int sId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({
      "deleteType": "SUB_MENU",
      "hMenuCd": hId,
      "menuCd": mId,
      "subMenuCd": sId
    }));

    _checkResponse(response, 'Failed to delete sub menu: ${response.statusCode}');
  }

  Future<List<MenuProgramModel>> getAllMenuPrograms() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-all-menu-programs');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch menu programs: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse is List) {
      return jsonResponse.map((json) => MenuProgramModel.fromJson(json)).toList();
    }
    throw Exception('Unexpected menu programs response format');
  }

  Future<MenuProgramModel> getMenuProgram(int hMenuCd, int menuCd, int subMenuCd, String pgmId) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/get-menu-program');
    final headers = await _getHeaders();
    
    final response = await http.post(
      url, 
      headers: headers, 
      body: jsonEncode({'hmenuCd': hMenuCd, 'menuCd': menuCd, 'subMenuCd': subMenuCd, 'pgmId': pgmId})
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch menu program details: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse != null) {
      return MenuProgramModel.fromJson(jsonResponse);
    }
    throw Exception('Menu program details not found');
  }

  Future<void> updateMenuProgram(MenuProgramModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/edit-menu-program');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';
    
    final bodyData = data.toJson();
    final response = await http.post(url, headers: headers, body: jsonEncode(bodyData));

    _checkResponse(response, 'Failed to update menu program: ${response.statusCode}');
  }

  Future<void> createMenuProgram(MenuProgramModel data) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/head-menu/create-menu-program');
    final headers = await _getHeaders();
    final user = await _authService.getUser();
    data.userName = user?.userName ?? user?.name ?? '';

    final bodyData = data.toJson();
    final response = await http.post(url, headers: headers, body: jsonEncode(bodyData));

    _checkResponse(response, 'Failed to create menu program: ${response.statusCode}');
  }

  Future<void> deleteMenuProgram(int hId, int mId, int sId, String pgm) async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/delete');
    final headers = await _getHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode({
      "deleteType": "MENU_PROGRAM",
      "hMenuCd": hId,
      "menuCd": mId,
      "subMenuCd": sId,
      "pgmId": pgm
    }));

    _checkResponse(response, 'Failed to delete menu program: ${response.statusCode}');
  }

  Future<List<ProgramModel>> getAllPrograms() async {
    final url = Uri.parse('${AppConfig.instance.baseUrl}/program');
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch programs: ${response.statusCode}');
    }

    final jsonResponse = jsonDecode(response.body);
    if (jsonResponse is List) {
      return (jsonResponse).map((json) => ProgramModel.fromJson(json)).toList();
    } else if (jsonResponse is Map<String, dynamic> && jsonResponse['data'] is List) {
      return (jsonResponse['data'] as List).map((json) => ProgramModel.fromJson(json)).toList();
    }
    throw Exception('Unexpected programs response format');
  }

  void _checkResponse(http.Response response, String defaultMessage) {
    if (response.statusCode != 200) {
      String msg = defaultMessage;
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json.containsKey('message')) {
          msg = json['message'];
        }
      } catch (_) {}
      throw msg;
    }
  }

  Future<AccessPrivileges?> getAccessPrivileges(int accessCd) async {
    try {
      final user = await _authService.getUser();
      final url = Uri.parse('${AppConfig.instance.baseUrl}/access-code/getAccessByAccessCode');
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'accesscd': accessCd,
          'orgcode': user?.orgCode,
        }),
      );

      if (response.statusCode == 200) {
        return AccessPrivileges.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Error fetching access privileges: $e');
    }
    return null;
  }
}


