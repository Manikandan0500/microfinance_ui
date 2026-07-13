import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';
import 'program_service.dart';
import '../models/program_model.dart';

class OperationalLogService {
  final _authService = AuthService();
  static final OperationalLogService _instance = OperationalLogService._internal();
  factory OperationalLogService() => _instance;
  OperationalLogService._internal() {
    _initLocation();
  }

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

  double? _latitude;
  double? _longitude;

  List<Program> _programs = [];
  bool _fetchingPrograms = false;

  Future<void> _loadPrograms() async {
    if (_programs.isNotEmpty || _fetchingPrograms) return;
    _fetchingPrograms = true;
    try {
      _programs = await ProgramService().getAllPrograms();
    } catch (_) {}
    _fetchingPrograms = false;
  }

  Future<String> _resolveProgramId(String inputLabel) async {
    if (inputLabel.contains(' - ') || inputLabel == 'Forgot Password') return inputLabel;
    await _loadPrograms();
    final cleanInput = inputLabel.trim().toLowerCase();
    
    final match = _programs.firstWhere(
      (p) => p.descn.trim().toLowerCase() == cleanInput,
      orElse: () => Program(pgmId: 0, descn: inputLabel, moduleId: 0, subModuleId: 0, pgmClass: 0, status: true),
    );

    if (match.pgmId != 0) {
      return '${match.pgmId} - ${match.descn}';
    }
    
    final partialMatch = _programs.firstWhere(
      (p) => p.descn.trim().toLowerCase().contains(cleanInput) || cleanInput.contains(p.descn.trim().toLowerCase()),
      orElse: () => Program(pgmId: 0, descn: inputLabel, moduleId: 0, subModuleId: 0, pgmClass: 0, status: true),
    );

    if (partialMatch.pgmId != 0) {
      return '${partialMatch.pgmId} - ${partialMatch.descn}';
    }

    return inputLabel;
  }

  Future<void> _initLocation() async {
    try {
      final response = await http.get(Uri.parse('https://ipapi.co/json/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          _latitude = (data['latitude'] as num?)?.toDouble();
          _longitude = (data['longitude'] as num?)?.toDouble();
        }
      }
    } catch (_) {}
  }

  Future<void> logAction({
    required String programId,
    required String action, // V, I, U, D, Z, A, R
    int? pgmId,
  }) async {
    if (_latitude == null || _longitude == null) {
      await _initLocation();
    }

    int? orgCode;
    String? userScd;
    // Use authService to get user data (no dart:html needed)


    if (orgCode == null || userScd == null) {
      try {
        final user = await _authService.getUser();
        if (user != null) {
          orgCode = user.orgCode;
          userScd = user.userScd;
        }
      } catch (_) {}
    }

    final resolvedPgmId = await _resolveProgramId(programId);

    final body = {
      'orgCode': orgCode ?? 1,
      'programId': resolvedPgmId,
      'doneBy': userScd ?? 'UNKNOWN',
      'action': action,
      'latitude': _latitude?.toString() ?? '',
      'longitude': _longitude?.toString() ?? '',
      'ipAddress': '127.0.0.1', 
    };

    try {
      final uri = Uri.parse('${AppConfig.instance.baseUrl}/operationalLogs/updateOperationalLog');
      final headers = await _getHeaders();
      await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e) {
      // Fail silently
    }
  }

  Future<Map<String, dynamic>> getOperationalLogsPaginated({
    int? orgCode,
    String? programId,
    String? action,
    String? doneBy,
    String? startDate,
    String? endDate,
    required int offset,
    required int limit,
  }) async {
    final Map<String, dynamic> body = {
      if (orgCode != null) 'orgCode': orgCode,
      if (programId != null && programId.trim().isNotEmpty) 'programId': programId.trim(),
      if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
      if (doneBy != null && doneBy.trim().isNotEmpty) 'doneBy': doneBy.trim(),
      if (startDate != null && startDate.trim().isNotEmpty) 'startDate': startDate.trim(),
      if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate.trim(),
      'offset': offset,
      'limit': limit,
    };

    final uri = Uri.parse('${AppConfig.instance.baseUrl}/operationalLogs/getOperationalLog');
    final headers = await _getHeaders();
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load operational logs: ${response.statusCode}');
    }
  }

  Future<void> logExit(String programId) async {
    int? orgCode;
    String? userScd;
    try {
      final userDataStr = null;
      if (userDataStr != null) {
        final map = jsonDecode(userDataStr);
        orgCode = map['orgCode'] != null ? int.tryParse(map['orgCode'].toString()) : null;
        userScd = map['userScd']?.toString();
      }
    } catch (_) {}

    if (orgCode == null || userScd == null) {
      try {
        final user = await _authService.getUser();
        if (user != null) {
          orgCode = user.orgCode;
          userScd = user.userScd;
        }
      } catch (_) {}
    }

    final resolvedPgmId = await _resolveProgramId(programId);

    final body = {
      'orgCode': orgCode ?? 1,
      'programId': resolvedPgmId,
      'doneBy': userScd ?? 'UNKNOWN',
    };

    try {
      final uri = Uri.parse('${AppConfig.instance.baseUrl}/operationalLogs/updateExitTime');
      final headers = await _getHeaders();
      await http.post(uri, headers: headers, body: jsonEncode(body));
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> logUnauthenticatedEvent({
    required int orgCode,
    required String userScd,
    required String programId,
    required String action,
    required String tableName,
    required String primaryKey,
    required String dataBlock,
  }) async {
    if (_latitude == null || _longitude == null) {
      await _initLocation();
    }

    final resolvedPgmId = await _resolveProgramId(programId);

    final opLogBody = {
      'orgCode': orgCode,
      'programId': resolvedPgmId,
      'doneBy': userScd,
      'action': action,
      'latitude': _latitude?.toString() ?? '',
      'longitude': _longitude?.toString() ?? '',
      'ipAddress': '127.0.0.1', 
    };

    final auditLogBody = {
      'orgCode': orgCode,
      'programId': resolvedPgmId,
      'primaryKey': primaryKey,
      'action': action,
      'tableName': tableName,
      'dataBlock': dataBlock,
      'doneBy': userScd,
    };

    try {
      final opUri = Uri.parse('${AppConfig.instance.baseUrl}/auth/updateOperationalLog');
      await http.post(opUri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(opLogBody));
      
      final auditUri = Uri.parse('${AppConfig.instance.baseUrl}/auth/updateAuditLogs');
      await http.post(auditUri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(auditLogBody));
    } catch (e) {
      // Fail silently
    }
  }
}


