import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/holiday_calendar.dart';

class HolidayCalendarApiService {
  static const String _baseUrl = 'http://localhost:8085/api/holidays';

  static Future<List<HolidayCalendar>> getHolidays() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => _fromJson(json)).toList();
    }
    throw Exception('Failed to load holiday calendar: ${response.statusCode}');
  }

  static Future<HolidayCalendar> createHoliday(HolidayCalendar holiday) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(_toJson(holiday)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return _fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to create holiday calendar entry: ${response.statusCode}');
  }

  static Future<void> deleteHoliday(String branchCode, String holidayDateStr) async {
    final url = '$_baseUrl/1/${Uri.encodeComponent(branchCode)}/${Uri.encodeComponent(holidayDateStr)}';
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete holiday: ${response.statusCode}');
    }
  }

  static HolidayCalendar _fromJson(Map<String, dynamic> json) {
    return HolidayCalendar(
      orgCode: (json['orgCode'] ?? 'ORG01').toString(),
      branchCode: (json['branchCode'] ?? '') as String,
      holidayDate: DateTime.parse(json['holidayDate'] as String),
      holidayName: (json['holidayName'] ?? '') as String,
      holidayType: (json['holidayType'] ?? 'National') as String,
      dueDateShiftRule: (json['dueDateShiftRule'] ?? 'Shift Next') as String,
      calendarStatus: (json['calendarStatus'] ?? true) as bool,
    );
  }

  static Map<String, dynamic> _toJson(HolidayCalendar holiday) {
    return {
      'orgCode': 1,
      'branchCode': holiday.branchCode,
      'holidayDate': holiday.holidayDate.toIso8601String().substring(0, 10),
      'holidayName': holiday.holidayName,
      'holidayType': holiday.holidayType,
      'dueDateShiftRule': holiday.dueDateShiftRule,
      'calendarStatus': holiday.calendarStatus,
    };
  }
}
