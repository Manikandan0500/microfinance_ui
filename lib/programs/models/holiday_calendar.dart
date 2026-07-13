class HolidayCalendar {
  String orgCode;
  String branchCode;
  DateTime holidayDate;
  String holidayName;
  String holidayType; // National, Regional, Public
  String dueDateShiftRule; // Shift Next, Shift Prev, No Shift
  bool calendarStatus;

  HolidayCalendar({
    required this.orgCode,
    required this.branchCode,
    required this.holidayDate,
    required this.holidayName,
    required this.holidayType,
    required this.dueDateShiftRule,
    this.calendarStatus = true,
  });

  HolidayCalendar copyWith({
    String? orgCode,
    String? branchCode,
    DateTime? holidayDate,
    String? holidayName,
    String? holidayType,
    String? dueDateShiftRule,
    bool? calendarStatus,
  }) {
    return HolidayCalendar(
      orgCode: orgCode ?? this.orgCode,
      branchCode: branchCode ?? this.branchCode,
      holidayDate: holidayDate ?? this.holidayDate,
      holidayName: holidayName ?? this.holidayName,
      holidayType: holidayType ?? this.holidayType,
      dueDateShiftRule: dueDateShiftRule ?? this.dueDateShiftRule,
      calendarStatus: calendarStatus ?? this.calendarStatus,
    );
  }
}
