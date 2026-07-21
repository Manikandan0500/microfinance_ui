import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_calendar.dart';
import '../../am_masters/config/app_config.dart';
import '../../am_masters/services/auth_service.dart';

class HolidayCalendarApiService {
  static String get _baseUrl => '${AppConfig.instance.baseUrl}/api/master';
  static final _authService = AuthService();

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer ${token.replaceAll('"', '')}',
    };
  }

  static Future<List<HolidayCalendar>> getHolidays(String orgCode) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$_baseUrl/getHolidayCalendarData/$orgCode'), headers: headers);
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded.containsKey('data')) {
        data = decoded['data'] as List<dynamic>? ?? [];
      }
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load holidays: ${response.statusCode}');
  }

  static Future<HolidayCalendar> createHoliday(HolidayCalendar holiday) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$_baseUrl/createHolidayCalendar'),
      headers: headers,
      body: jsonEncode(_toJson(holiday)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to create holiday: ${response.statusCode}');
  }

  static Future<HolidayCalendar> updateHoliday(HolidayCalendar holiday) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$_baseUrl/updateHolidayCalendar'),
      headers: headers,
      body: jsonEncode(_toJson(holiday)),
    );
    if (response.statusCode == 200) {
      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> data = (decoded is Map && decoded.containsKey('data')) 
          ? (decoded['data'] as Map<String, dynamic>) 
          : (decoded as Map<String, dynamic>);
      return _fromJson(data);
    }
    throw Exception('Failed to update holiday: ${response.statusCode}');
  }

  static Future<void> deleteHoliday(String branchCode, String holidayDateStr) async {
    throw Exception('Delete operation is not supported by the current backend API.');
  }

  static HolidayCalendar _fromJson(Map<String, dynamic> json) {
    return HolidayCalendar(
      orgCode: (json['orgCode'] ?? json['orgcode'] ?? 'ORG01').toString(),
      branchCode: (json['branchCode'] ?? json['branch_code'] ?? '') as String,
      holidayDate: json['holidayDate'] != null ? DateTime.parse(json['holidayDate']) : (json['holiday_date'] != null ? DateTime.parse(json['holiday_date']) : DateTime.now()),
      holidayName: (json['holidayName'] ?? json['holiday_name'] ?? '') as String,
      holidayType: (json['holidayType'] ?? json['holiday_type'] ?? 'National') as String,
      dueDateShiftRule: (json['dueDateShiftRule'] ?? json['due_date_shift_rule'] ?? 'Shift Next') as String,
      calendarStatus: _parseBool(json['calendarStatus'] ?? json['calendar_status']),
    );
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return true;
    if (val is bool) return val;
    final strVal = val.toString().toLowerCase();
    if (strVal == 'active' || strVal == 'a' || strVal == 'true' || strVal == '1') return true;
    return false;
  }

  static Map<String, dynamic> _toJson(HolidayCalendar holiday) {
    return {
      'orgcode': int.tryParse(holiday.orgCode) ?? 1,
      'branch_code': holiday.branchCode,
      'holiday_date': holiday.holidayDate.toIso8601String().substring(0, 10),
      'holiday_name': holiday.holidayName,
      'holiday_type': holiday.holidayType,
      'due_date_shift_rule': holiday.dueDateShiftRule,
      'calendar_status': holiday.calendarStatus ? '1' : '0',
    };
  }
}
