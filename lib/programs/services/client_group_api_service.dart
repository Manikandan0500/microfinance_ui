import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../Login/services/auth_service 4.dart';
import '../models/client_group_master.dart';
import '../models/cif_master.dart';

class ClientGroupApiService {
  static const String _baseUrlGroupMaster = 'http://localhost:8085/api/group-master';
  static const String _baseUrlGroupMember = 'http://localhost:8085/api/group-member-map';
  static const String _baseUrlCif = 'http://localhost:8085/api/cif-master';

  static int get _userOrgCode => AuthService().currentUser?.orgCode ?? 101;

  // --- CIF Master ---
  static Future<List<CifMaster>> getCifMasters() async {
    final response = await http.get(Uri.parse('$_baseUrlCif?orgCode=$_userOrgCode'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CifMaster.fromJson(json)).toList();
    }
    throw Exception('Failed to load CIF records: ${response.statusCode}');
  }

  // --- Client Group Master ---

  static Future<List<ClientGroupMaster>> getClientGroups() async {
    final response = await http.get(Uri.parse('$_baseUrlGroupMaster?orgCode=$_userOrgCode'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapGroupMasterFromJson(json)).toList();
    }
    throw Exception('Failed to load client groups: ${response.statusCode}');
  }

  static Future<String?> createClientGroup(ClientGroupMaster record) async {
    final body = jsonEncode(_mapGroupMasterToJson(record));
    final response = await http.post(
      Uri.parse(_baseUrlGroupMaster),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to create client group: ${response.statusCode}');
  }

  static Future<String?> updateClientGroup(ClientGroupMaster record) async {
    final url = '$_baseUrlGroupMaster/$_userOrgCode/${Uri.encodeComponent(record.groupCode)}';
    final body = jsonEncode(_mapGroupMasterToJson(record));
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to update client group: ${response.statusCode}');
  }

  static Future<void> deleteClientGroup(String groupCode) async {
    // Delete endpoint is not available in backend yet.
    throw UnimplementedError('Delete client group is not supported in backend.');
  }

  // --- Client Group Member Map ---

  static Future<List<ClientGroupMemberMap>> getClientGroupMemberMaps() async {
    final response = await http.get(Uri.parse('$_baseUrlGroupMember?orgCode=$_userOrgCode'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _mapGroupMemberFromJson(json)).toList();
    }
    throw Exception('Failed to load client group members: ${response.statusCode}');
  }

  static Future<String?> createClientGroupMemberMap(ClientGroupMemberMap record) async {
    final body = jsonEncode(_mapGroupMemberToJson(record));
    final response = await http.post(
      Uri.parse(_baseUrlGroupMember),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to create client group member: ${response.statusCode}');
  }

  static Future<String?> updateClientGroupMemberMap(ClientGroupMemberMap record) async {
    final url = '$_baseUrlGroupMember/$_userOrgCode/${Uri.encodeComponent(record.groupCode)}/${Uri.encodeComponent(record.clientId)}';
    final body = jsonEncode(_mapGroupMemberToJson(record));
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final resMap = jsonDecode(response.body);
      return resMap['message']?.toString();
    }
    throw Exception('Failed to update client group member: ${response.statusCode}');
  }

  static Future<void> deleteClientGroupMemberMap(String groupCode, String clientId) async {
    // Delete endpoint is not available in backend yet.
    throw UnimplementedError('Delete client group member map is not supported in backend.');
  }

  // --- Mapping functions ---

  static ClientGroupMaster _mapGroupMasterFromJson(Map<String, dynamic> json) {
    return ClientGroupMaster(
      orgCode: json['id']?['orgcode']?.toString() ?? '101',
      groupCode: json['id']?['group_code']?.toString() ?? json['id']?['groupCode']?.toString() ?? '',
      groupName: json['group_name'] ?? json['groupName'] ?? '',
      branchCode: json['branch_code']?.toString() ?? json['branchCode']?.toString() ?? '',
      regionCode: json['region_code'] ?? json['regionCode'] ?? '',
      regionalOfficerId: json['regional_officer_id'] ?? json['regionalOfficerId'] ?? '',
      sourceSystem: json['source_system'] ?? json['sourceSystem'] ?? '',
      sourceRefNo: json['source_ref_no'] ?? json['sourceRefNo'],
      meetingDay: json['meeting_day'] ?? json['meetingDay'] ?? '',
      meetingFrequency: json['meeting_frequency'] ?? json['meetingFrequency'] ?? '',
      groupStatus: json['group_status'] ?? json['groupStatus'] ?? 'A',
    );
  }

  static Map<String, dynamic> _mapGroupMasterToJson(ClientGroupMaster record) {
    final user = AuthService().currentUser;
    final userName = [user?.fName, user?.mName, user?.lName].where((e) => e != null && e.isNotEmpty).join(' ');

    return {
      'id': {
        'orgcode': int.tryParse(record.orgCode) ?? 101,
        'group_code': record.groupCode,
      },
      'group_name': record.groupName,
      'branch_code': int.tryParse(record.branchCode),
      'region_code': record.regionCode,
      'regional_officer_id': record.regionalOfficerId,
      'source_system': record.sourceSystem,
      'source_ref_no': record.sourceRefNo,
      'meeting_day': record.meetingDay,
      'meeting_frequency': record.meetingFrequency,
      'group_status': record.groupStatus,
      'user_name': userName.isNotEmpty ? userName : (user?.name ?? user?.email ?? 'SYS'),
    };
  }

  static ClientGroupMemberMap _mapGroupMemberFromJson(Map<String, dynamic> json) {
    return ClientGroupMemberMap(
      orgCode: json['id']?['orgcode']?.toString() ?? '101',
      groupCode: json['id']?['group_code']?.toString() ?? json['id']?['groupCode']?.toString() ?? '',
      clientId: json['id']?['client_id']?.toString() ?? json['id']?['clientId']?.toString() ?? '',
      memberRole: json['member_role'] ?? json['memberRole'] ?? '',
      joinDate: json['join_date'] != null ? DateTime.parse(json['join_date']) : (json['joinDate'] != null ? DateTime.parse(json['joinDate']) : DateTime.now()),
      memberStatus: json['member_status'] ?? json['memberStatus'] ?? 'A',
    );
  }

  static Map<String, dynamic> _mapGroupMemberToJson(ClientGroupMemberMap record) {
    final user = AuthService().currentUser;
    final userName = [user?.fName, user?.mName, user?.lName].where((e) => e != null && e.isNotEmpty).join(' ');

    return {
      'id': {
        'orgcode': int.tryParse(record.orgCode) ?? 101,
        'group_code': record.groupCode,
        'client_id': record.clientId,
      },
      'member_role': record.memberRole,
      'join_date': record.joinDate.toIso8601String(),
      'member_status': record.memberStatus,
      'user_name': userName.isNotEmpty ? userName : (user?.name ?? user?.email ?? 'SYS'),
    };
  }
}
