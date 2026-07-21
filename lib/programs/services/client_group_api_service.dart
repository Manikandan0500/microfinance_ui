import 'dart:convert';
import '../models/client_group_master.dart';
import '../mock_database.dart';

class ClientGroupApiService {
  static final MockDatabase _db = MockDatabase();

  static Future<List<ClientGroupMaster>> getClientGroups() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _db.clientGroups;
  }

  static Future<void> createClientGroup(ClientGroupMaster record) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.addClientGroup(record);
  }

  static Future<void> updateClientGroup(ClientGroupMaster record) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.updateClientGroup(record);
  }

  static Future<void> deleteClientGroup(String groupCode) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.deleteClientGroup(groupCode);
  }

  // --- Client Group Member Map ---
  static Future<List<ClientGroupMemberMap>> getClientGroupMemberMaps() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _db.clientGroupMemberMaps;
  }

  static Future<void> createClientGroupMemberMap(ClientGroupMemberMap record) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.addClientGroupMemberMap(record);
  }

  static Future<void> updateClientGroupMemberMap(ClientGroupMemberMap record) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _db.updateClientGroupMemberMap(record);
  }

  static Future<void> deleteClientGroupMemberMap(String groupCode, String clientId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _db.deleteClientGroupMemberMap(groupCode, clientId);
  }
}
