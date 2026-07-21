import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/holiday_calendar_api_service.dart';
import 'models/holiday_calendar.dart';
import 'mf_shared_widgets.dart'; // Using the newly extracted components
import '../am_masters/services/auth_service.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  MFView _view = MFView.list;
  HolidayCalendar? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<HolidayCalendar> _data = [];
  String _currentOrgCode = '1';

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _branchCodeCtrl = TextEditingController();
  final _holidayDateCtrl = TextEditingController();
  final _holidayNameCtrl = TextEditingController();
  final _holidayTypeCtrl = TextEditingController();
  final _dueDateShiftRuleCtrl = TextEditingController();
  
  DateTime? _selectedHolidayDate;
  bool _calendarStatus = true;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadHolidays();
  }

  Future<void> _initUserAndLoadHolidays() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    await _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final holidays = await HolidayCalendarApiService.getHolidays(_currentOrgCode);
      if (mounted) {
        setState(() {
          _data = holidays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  List<HolidayCalendar> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((h) {
      return h.branchCode.toLowerCase().contains(q) || 
             h.holidayName.toLowerCase().contains(q) || 
             h.holidayType.toLowerCase().contains(q);
    }).toList();
  }

  void _go(MFView v, [HolidayCalendar? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _delConfirmed = false;
      if (v == MFView.list) {
        _search = '';
        _currentPage = 1;
      }
    });
    if (v == MFView.list) {
      _loadHolidays();
    } else if (v == MFView.create) {
      _resetForm();
    } else if (v == MFView.edit || v == MFView.view || v == MFView.delete) {
      if (r != null) _loadRecord(r);
    }
  }

  void _toast(String msg, {bool isError = false}) => MFToast.show(context, msg, isError: isError);

  void _resetForm() {
    _orgCodeCtrl.text = _currentOrgCode;
    _branchCodeCtrl.text = 'ALL';
    _selectedHolidayDate = DateTime.now();
    _updateDateField(_selectedHolidayDate);
    _holidayNameCtrl.clear();
    _holidayTypeCtrl.text = 'National';
    _dueDateShiftRuleCtrl.text = 'Shift Next';
    _calendarStatus = true;
  }

  void _updateDateField(DateTime? d) {
    if (d == null) {
      _holidayDateCtrl.clear();
    } else {
      const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      _holidayDateCtrl.text = '${d.day.toString().padLeft(2,'0')}-${ms[d.month - 1]}-${d.year}';
    }
  }

  void _loadRecord(HolidayCalendar r) {
    _orgCodeCtrl.text = r.orgCode;
    _branchCodeCtrl.text = r.branchCode;
    _selectedHolidayDate = r.holidayDate;
    _updateDateField(_selectedHolidayDate);
    _holidayNameCtrl.text = r.holidayName;
    _holidayTypeCtrl.text = r.holidayType;
    _dueDateShiftRuleCtrl.text = r.dueDateShiftRule;
    _calendarStatus = r.calendarStatus;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedHolidayDate == null) {
        _toast('Holiday Date is required', isError: true);
        return;
      }
      
      setState(() => _isLoading = true);
      try {
        final record = HolidayCalendar(
          orgCode: _orgCodeCtrl.text,
          branchCode: _branchCodeCtrl.text,
          holidayDate: _selectedHolidayDate!,
          holidayName: _holidayNameCtrl.text,
          holidayType: _holidayTypeCtrl.text,
          dueDateShiftRule: _dueDateShiftRuleCtrl.text,
          calendarStatus: _calendarStatus,
        );

        if (isEdit) {
          await HolidayCalendarApiService.updateHoliday(record);
          showSuccessDialog(context, 'Holiday updated successfully!', onConfirm: () => _go(MFView.list));
        } else {
          await HolidayCalendarApiService.createHoliday(record);
          showSuccessDialog(context, 'Holiday created successfully!', onConfirm: () => _go(MFView.list));
        }
      } catch (e) {
        _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _confirmDelete() {
    if (_sel != null) {
      _toast('Delete not supported by API', isError: true);
      _go(MFView.list);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _orgCodeCtrl.dispose();
    _branchCodeCtrl.dispose();
    _holidayDateCtrl.dispose();
    _holidayNameCtrl.dispose();
    _holidayTypeCtrl.dispose();
    _dueDateShiftRuleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9), // Background matching am_masters layout
    body: switch (_view) {
      MFView.list   => _list(),
      MFView.create => _form(isEdit: false),
      MFView.view   => _form(isView: true),
      MFView.edit   => _form(isEdit: true),
      MFView.delete => _delete(),
    },
  );

  // ── List View ──────────────────────────────────────────────────────────────
  Widget _list() {
    final list = _filtered;
    final int totalPages = (list.length / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage > list.length) ? list.length : startIndex + _itemsPerPage;
    final pagedList = list.isEmpty ? <HolidayCalendar>[] : list.sublist(startIndex, endIndex);

    final int activeCount = _data.where((e) => e.calendarStatus).length;
    final int inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Holiday Calendar'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: inactiveCount),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
            width: 280, height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Search holidays...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12), isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _fBtn('Add Holiday', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
        ]),
        const SizedBox(height: 16),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3050),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(flex: 2, child: _colHdr('BRANCH')),
              Expanded(flex: 2, child: _colHdr('HOLIDAY DATE')),
              Expanded(flex: 3, child: _colHdr('HOLIDAY NAME')),
              Expanded(flex: 2, child: _colHdr('TYPE')),
              Expanded(flex: 2, child: _colHdr('SHIFT RULE')),
              Expanded(flex: 2, child: _colHdr('STATUS')),
              const SizedBox(width: 110, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
            ]),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
          else if (_loadError != null)
            Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
              const Text('Failed to load data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))), const SizedBox(height: 8),
              Text(_loadError!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ])))
          else if (pagedList.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFCBD5E1)), const SizedBox(height: 16),
              Text('No records found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
            ])))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: pagedList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) {
                final r = pagedList[i];
                final dateStr = '${r.holidayDate.day.toString().padLeft(2, '0')}-${r.holidayDate.month.toString().padLeft(2, '0')}-${r.holidayDate.year}';
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text(r.branchCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    Expanded(flex: 3, child: Text(r.holidayName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.holidayType, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.dueDateShiftRule, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: _statusBadge(r.calendarStatus))),
                    SizedBox(width: 110, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _go(MFView.view, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.edit_rounded, const Color(0xFF1E3050), () => _go(MFView.edit, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.delete_rounded, const Color(0xFFDC2626), () => _go(MFView.delete, r)),
                    ])),
                  ]),
                );
              },
            ),
        ])),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MFPaginationControls(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPrev: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              onNext: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ]),
    );
  }

  Widget _form({bool isEdit = false, bool isView = false}) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(
              title: isView ? 'View Holiday' : (isEdit ? 'Edit Holiday' : 'Create Holiday'),
              actions: [
                _fBtn('Back', Icons.arrow_back_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.list)),
              ],
            ),
            if (isEdit)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFB45309)), const SizedBox(width: 10),
                  Expanded(child: Text('Editing an existing holiday may affect operations on this date.', style: TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
                ]),
              ),
            _card(child: Form(key: _formKey, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('BASIC DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Branch Code', ctrl: _branchCodeCtrl, icon: Icons.store, required: !isView,
                    readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Holiday Date', ctrl: _holidayDateCtrl, icon: Icons.calendar_today, required: !isView,
                    isDatePicker: true, readOnly: isEdit || isView, showLock: isEdit || isView,
                    onDatePickerTap: () async {
                      if (isEdit || isView) return;
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedHolidayDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedHolidayDate = picked;
                          _updateDateField(picked);
                        });
                      }
                    },
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Holiday Name', ctrl: _holidayNameCtrl, icon: Icons.event, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Holiday Type', icon: Icons.category, required: !isView,
                    items: const [{'id':'National'}, {'id':'Public'}, {'id':'Regional'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _holidayTypeCtrl.text},
                    onChanged: (v) { if (v != null) setState(() => _holidayTypeCtrl.text = v['id']); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Due Date Shift Rule', icon: Icons.next_plan, required: !isView,
                    items: const [{'id':'Shift Next'}, {'id':'Shift Prev'}, {'id':'No Shift'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _dueDateShiftRuleCtrl.text},
                    onChanged: (v) { if (v != null) setState(() => _dueDateShiftRuleCtrl.text = v['id']); },
                    enabled: !isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('SETTINGS'),
                const SizedBox(height: 16),
                Container(
                  width: 300, height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    Switch(
                      value: _calendarStatus,
                      onChanged: !isView ? ((v) => setState(() => _calendarStatus = v)) : null,
                      activeColor: const Color(0xFF1E3050),
                      activeTrackColor: const Color(0xFFE3F2FD),
                    ),
                  ]),
                ),
              ]),
            ))),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          const Spacer(),
          if (!isView) ...[
            const SizedBox(width: 12),
            _fBtn(isEdit ? 'Save Changes' : 'Create Record', isEdit ? Icons.save_rounded : Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
          ]
        ]),
      ),
    ]);
  }

  // ── Detail View ────────────────────────────────────────────────────────────
  Widget _detail() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    final dateStr = '${r.holidayDate.day.toString().padLeft(2, '0')}-${r.holidayDate.month.toString().padLeft(2, '0')}-${r.holidayDate.year}';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Holiday Details', actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          const SizedBox(width: 10),
          _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, r)),
        ]),
        _card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.event, color: Color(0xFF1E3050))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.holidayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  _statusBadge(r.calendarStatus),
                  const SizedBox(width: 12),
                  const Icon(Icons.store, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                  Text('Branch: ${r.branchCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ]),
              ])),
            ]),
            const SizedBox(height: 32),
            _secHdr('DETAILS'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Date', dateStr),
              _info('Type', r.holidayType),
              _info('Shift Rule', r.dueDateShiftRule),
            ]),
          ]),
        )),
      ]),
    );
  }

  // ── Delete View ────────────────────────────────────────────────────────────
  Widget _delete() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    final dateStr = '${r.holidayDate.day.toString().padLeft(2, '0')}-${r.holidayDate.month.toString().padLeft(2, '0')}-${r.holidayDate.year}';
    
    return Center(child: Container(
      width: 500, margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626))),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delete Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
            ])),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(children: [
              _delRow('Branch', r.branchCode),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Date', dateStr),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Name', r.holidayName),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: _delConfirmed,
                onChanged: (v) => setState(() => _delConfirmed = v ?? false),
                activeColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('I understand that deleting this record is permanent.', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            
            const SizedBox(width: 12),
            _fBtn('Confirm Delete', Icons.delete_rounded, const Color(0xFFDC2626), Colors.white, const Color(0xFFDC2626), onTap: _delConfirmed ? _confirmDelete : null),
          ]),
        ),
      ]),
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _pageHeader({required String title, List<Widget> actions = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3))),
          ...actions,
        ]),
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _statCard(String num, String lbl, Color numC, Color bg, Color border, IconData icon, Color iconC) =>
      Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconC)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: numC, height: 1.1)),
            Text(lbl, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ]),
        ]),
      );

  Widget _hBtn(String label, {Color bg = Colors.white, Color fg = const Color(0xFF64748B), Color border = const Color(0xFFE2E8F0), IconData? icon, VoidCallback? onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: onTap == null ? bg.withOpacity(0.5) : bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: onTap == null ? border.withOpacity(0.5) : border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      );

  Widget _secHdr(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E3050), letterSpacing: 1)),
    ]),
  );

  Widget _statusBadge(bool active) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? const Color(0xFF16A34A).withOpacity(0.3) : const Color(0xFFDC2626).withOpacity(0.3))),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
      ]),
    ),
  );

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _info(String lbl, String val) => SizedBox(
    width: 200,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      const SizedBox(height: 4),
      Text(val.isEmpty ? '—' : val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
    ]),
  );

  Widget _delRow(String lbl, String val) => Row(children: [
    SizedBox(width: 100, child: Text(lbl, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
    Expanded(child: Text(val.isEmpty ? '—' : val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
  ]);
}
