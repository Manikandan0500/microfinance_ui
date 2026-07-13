import 'package:flutter/material.dart';

class CustomCalendarDialog extends StatefulWidget {
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const CustomCalendarDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select Date',
  });

  @override
  State<CustomCalendarDialog> createState() => _CustomCalendarDialogState();
}

class _CustomCalendarDialogState extends State<CustomCalendarDialog> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  bool _showYearSelector = false;
  int? _selectedMonthForSelector;
  int? _selectedYearForSelector;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const List<String> _weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    final today = DateTime.now();
    DateTime initialFocus = _selectedDate ?? today;
    if (initialFocus.isBefore(widget.firstDate)) {
      initialFocus = widget.firstDate;
    } else if (initialFocus.isAfter(widget.lastDate)) {
      initialFocus = widget.lastDate;
    }
    _focusedMonth = DateTime(initialFocus.year, initialFocus.month, 1);
  }

  void _checkAndConfirmMonthYear() {
    if (_selectedMonthForSelector != null && _selectedYearForSelector != null) {
      setState(() {
        _focusedMonth = DateTime(_selectedYearForSelector!, _selectedMonthForSelector!, 1);
        _showYearSelector = false;
      });
    }
  }

  int _daysInMonth(int year, int month) {
    var firstDayNextMonth = (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);
    return firstDayNextMonth.difference(DateTime(year, month, 1)).inDays;
  }

  void _prevMonth() {
    if (_showYearSelector) return;
    setState(() {
      int prevMonth = _focusedMonth.month - 1;
      int prevYear = _focusedMonth.year;
      if (prevMonth == 0) {
        prevMonth = 12;
        prevYear -= 1;
      }
      final target = DateTime(prevYear, prevMonth, 1);
      final lastDayOfPrevMonth = DateTime(prevYear, prevMonth, _daysInMonth(prevYear, prevMonth));
      if (lastDayOfPrevMonth.isAfter(widget.firstDate) || lastDayOfPrevMonth.isAtSameMomentAs(widget.firstDate)) {
        _focusedMonth = target;
      }
    });
  }

  void _nextMonth() {
    if (_showYearSelector) return;
    setState(() {
      int nextMonth = _focusedMonth.month + 1;
      int nextYear = _focusedMonth.year;
      if (nextMonth == 13) {
        nextMonth = 1;
        nextYear += 1;
      }
      final target = DateTime(nextYear, nextMonth, 1);
      if (target.isBefore(widget.lastDate) || target.isAtSameMomentAs(widget.lastDate) || target.month == widget.lastDate.month && target.year == widget.lastDate.year) {
        _focusedMonth = target;
      }
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isValidDate(DateTime date) {
    final check = DateTime(date.year, date.month, date.day);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    return (check.isAfter(first) || check.isAtSameMomentAs(first)) &&
           (check.isBefore(last) || check.isAtSameMomentAs(last));
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return 'No Date Selected';
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdays[date.weekday - 1];
    final monthName = _months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    
    // SUN-start logic
    final firstDayWeekday = DateTime(year, month, 1).weekday; // 1 = Monday, ..., 7 = Sunday
    final paddingDays = firstDayWeekday == 7 ? 0 : firstDayWeekday; // Sunday is 0 padding, Monday is 1, ..., Saturday is 6
    
    final daysCount = _daysInMonth(year, month);
    final totalCells = paddingDays + daysCount;
    final rowsCount = (totalCells / 7.0).ceil();
    final gridCellsCount = rowsCount * 7; // complete the rows fully

    // Prev Month Calculation
    int prevMonth = month - 1;
    int prevYear = year;
    if (prevMonth == 0) {
      prevMonth = 12;
      prevYear -= 1;
    }
    final prevDaysCount = _daysInMonth(prevYear, prevMonth);

    // Next Month Calculation
    int nextMonth = month + 1;
    int nextYear = year;
    if (nextMonth == 13) {
      nextMonth = 1;
      nextYear += 1;
    }

    final today = DateTime.now();

    return Center(
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Title and Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () {
                      Navigator.of(context).pop(null); // Close without change
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Navigation: Left arrow, centered Month Year, right arrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: _prevMonth,
                    disabled: _showYearSelector,
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showYearSelector = !_showYearSelector;
                          if (_showYearSelector) {
                            _selectedMonthForSelector = _focusedMonth.month;
                            _selectedYearForSelector = _focusedMonth.year;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _showYearSelector ? const Color(0xFFE8F3FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showYearSelector && (_selectedMonthForSelector == null || _selectedYearForSelector == null)
                                  ? 'Select Month & Year'
                                  : '${_months[month - 1]} $year',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _showYearSelector ? const Color(0xFF2B63C6) : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _showYearSelector ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: _showYearSelector ? const Color(0xFF2B63C6) : const Color(0xFF1E293B),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _navButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _nextMonth,
                    disabled: _showYearSelector,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Year selector view or Calendar day selector view
            if (_showYearSelector) ...[
              // GORGEOUS DUAL MONTH & YEAR SELECTOR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: 200,
                  child: Row(
                    children: [
                      // Month Selector (Left Column)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Month',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: 12,
                                itemBuilder: (context, index) {
                                  final isSel = (index + 1) == _selectedMonthForSelector;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedMonthForSelector = index + 1;
                                        _checkAndConfirmMonthYear();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? const Color(0xFF2B63C6) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _months[index],
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Year Selector (Right Column)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Year',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: ListView.builder(
                                shrinkWrap: true,
                                controller: ScrollController(
                                  // Pre-scroll to the currently focused year
                                  initialScrollOffset: (((_selectedYearForSelector ?? year) - widget.firstDate.year - 2) * 38.0).clamp(0.0, 9999.0),
                                ),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: (widget.lastDate.year - widget.firstDate.year + 1),
                                itemBuilder: (context, index) {
                                  final yr = widget.firstDate.year + index;
                                  final isSel = yr == _selectedYearForSelector;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedYearForSelector = yr;
                                        _checkAndConfirmMonthYear();
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 6),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSel ? const Color(0xFF2B63C6) : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$yr',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(height: 8),
            ] else ...[
              // STANDARD CALENDAR VIEW
              // Weekday Headings (SUN MON ...)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdays.map((day) {
                    return SizedBox(
                      width: 38,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 6),

              // Grid of Dates
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                    childAspectRatio: 1.15, // Highly compact to prevent bottom layout overflow
                  ),
                  itemCount: gridCellsCount,
                  itemBuilder: (context, index) {
                    DateTime cellDate;
                    bool isCurrentMonth = true;

                    if (index < paddingDays) {
                      final dayNumber = prevDaysCount - paddingDays + 1 + index;
                      cellDate = DateTime(prevYear, prevMonth, dayNumber);
                      isCurrentMonth = false;
                    } else if (index >= totalCells) {
                      final dayNumber = index - totalCells + 1;
                      cellDate = DateTime(nextYear, nextMonth, dayNumber);
                      isCurrentMonth = false;
                    } else {
                      final dayNumber = index - paddingDays + 1;
                      cellDate = DateTime(year, month, dayNumber);
                    }

                    final isValid = _isValidDate(cellDate);
                    final isSelected = _isSameDay(_selectedDate, cellDate);
                    final isToday = _isSameDay(today, cellDate);

                    return _dayCell(
                      date: cellDate,
                      isCurrentMonth: isCurrentMonth,
                      isSelected: isSelected,
                      isToday: isToday,
                      isValid: isValid,
                      onTap: () {
                        if (isValid) {
                          setState(() {
                            _selectedDate = cellDate;
                            if (cellDate.month != _focusedMonth.month || cellDate.year != _focusedMonth.year) {
                              _focusedMonth = DateTime(cellDate.year, cellDate.month, 1);
                            }
                          });
                          Navigator.of(context).pop(cellDate);
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Actions: Today and Clear
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _textActionButton(
                      label: 'Today',
                      color: const Color(0xFF2B63C6),
                      onTap: () {
                        final now = DateTime.now();
                        if (_isValidDate(now)) {
                          setState(() {
                            _selectedDate = now;
                            _focusedMonth = DateTime(now.year, now.month, 1);
                          });
                        }
                      },
                    ),
                    _textActionButton(
                      label: 'Clear',
                      color: const Color(0xFFDC2626),
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                          _selectedMonthForSelector = null;
                          _selectedYearForSelector = null;
                          _showYearSelector = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Horizontal Divider
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Footer: Selected Date info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: Color(0xFF2B63C6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedDate == null ? 'No Date' : _formatFullDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap, bool disabled = false}) {
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: disabled ? const Color(0xFFCBD5E1) : const Color(0xFF2B63C6),
          ),
        ),
      ),
    );
  }

  Widget _dayCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool isToday,
    required bool isValid,
    required VoidCallback onTap,
  }) {
    Color textColor;
    BoxDecoration? decoration;

    if (isSelected) {
      textColor = Colors.white;
      decoration = const BoxDecoration(
        color: Color(0xFF2B63C6),
        shape: BoxShape.circle,
      );
    } else if (isCurrentMonth) {
      if (isToday) {
        textColor = const Color(0xFF2B63C6);
        decoration = BoxDecoration(
          color: const Color(0xFFE8F3FF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2B63C6), width: 1),
        );
      } else if (isValid) {
        textColor = const Color(0xFF1E293B);
      } else {
        textColor = const Color(0xFFCBD5E1);
      }
    } else {
      textColor = const Color(0xFFCBD5E1);
    }

    return MouseRegion(
      cursor: isValid ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: isValid ? onTap : null,
        child: Container(
          alignment: Alignment.center,
          decoration: decoration,
          child: Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: (isValid && isCurrentMonth) ? FontWeight.w700 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _textActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
