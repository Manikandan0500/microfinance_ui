import '../models/access_privileges.dart';
import '../services/program_service.dart';
import '../services/address_service.dart';
import '../validation/Validation.dart';
import '../services/profile_service.dart';
import '../services/operational_log_service.dart';
import '../widgets/audit_details_dialog.dart';
import 'package:flutter/material.dart';
import '../Datas/countries.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/organization_service.dart';
import '../widgets/custom_calendar_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
const _kP = Color(0xFF3D6EBE);
const _kPL = Color(0xFFEEF3FB);
const _kPB = Color(0xFFC5D3E8);
const _kR = Color(0xFFDC2626);
const _kRL = Color(0xFFFEF2F2);
const _kRB = Color(0xFFFECACA);
const _kG = Color(0xFF16A34A);
const _kGL = Color(0xFFDCFCE7);
const _kGB = Color(0xFFBBF7D0);
const _kO = Color(0xFFF97316);
const _kOB = Color(0xFFFED7AA);
const _kOBG = Color(0xFFFFF7ED);
const _kOT = Color(0xFFC2410C);
const _kWarnBG = Color(0xFFFFFBEB);
const _kWarnB = Color(0xFFFDE68A);
const _kWarnT = Color(0xFFB45309);
const _kText = Color(0xFF1E293B);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);
// Very light blue for alternating table rows ONLY
const _kRowAlt = Color(0xFFF0F5FD);

class _CountryInfo {
  final String code;
  final String name;
  final String flag;
  final String dialCode;
  final int mobileLength;
  const _CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    required this.dialCode,
    this.mobileLength = 10,
  });
}

_CountryInfo _mapDbToCountryInfo(Map<String, dynamic> c) {
  final code = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toUpperCase();
  final name = (c['countryname'] ?? c['name'] ?? '').toString().trim();
  final dialCode = (c['callcode'] ?? c['dialCode'] ?? '').toString().replaceAll('+', '').trim();
  
  String flag = '';
  if (code.length == 2) {
    try {
      final int first = code.codeUnitAt(0) - 65 + 127462;
      final int second = code.codeUnitAt(1) - 65 + 127462;
      flag = String.fromCharCode(first) + String.fromCharCode(second);
    } catch (_) {}
  }
  
  return _CountryInfo(
    code: code,
    name: name,
    flag: flag,
    dialCode: dialCode,
    mobileLength: 10,
  );
}

enum _V { list, create, view, edit, delete }

class _Org {
  String code, name, openDate, country, division;
  String pincode, telephone, email, status, indiv;
  String a1, a2, a3, a4, a5;
  bool active;
  Uint8List? logoBytes;
  String? logoName;
  String? logoPath;
  String? cuser, cdate, euser, edate, auser, adate;

  _Org({
    required this.code,
    required this.name,
    required this.openDate,
    required this.country,
    required this.division,
    required this.pincode,
    required this.telephone,
    required this.email,
    required this.status,
    required this.indiv,
    this.a1 = '',
    this.a2 = '',
    this.a3 = '',
    this.a4 = '',
    this.a5 = '',
    this.active = true,
    this.logoBytes,
    this.logoName,
    this.logoPath,
    this.cuser, this.cdate, this.euser, this.edate, this.auser, this.adate,
  });

  _Org cp({
    String? code, String? name, String? openDate, String? country, String? division,
    String? pincode, String? telephone, String? email, String? status, String? indiv,
    String? a1, String? a2, String? a3, String? a4, String? a5, bool? active,
    Uint8List? logoBytes, String? logoName, String? logoPath, bool clearLogo = false,
  }) => _Org(
    code: code ?? this.code, name: name ?? this.name, openDate: openDate ?? this.openDate,
    country: country ?? this.country, division: division ?? this.division,
    pincode: pincode ?? this.pincode, telephone: telephone ?? this.telephone,
    email: email ?? this.email, status: status ?? this.status, indiv: indiv ?? this.indiv,
    a1: a1 ?? this.a1, a2: a2 ?? this.a2, a3: a3 ?? this.a3,
    a4: a4 ?? this.a4, a5: a5 ?? this.a5, active: active ?? this.active,
    logoBytes: logoBytes ?? this.logoBytes,
    logoName: logoName ?? this.logoName,
    logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
  );

  factory _Org.fromJson(Map<String, dynamic> json) {
    String formatDate(dynamic value, {bool includeTime = false}) {
      if (value == null || value.toString().isEmpty) return includeTime ? '—' : '';
      try {
        final d = DateTime.parse(value.toString()).toLocal();
        const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        if (includeTime) {
          final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
          final m = d.minute.toString().padLeft(2, '0');
          final p = d.hour >= 12 ? 'PM' : 'AM';
          return '${d.day.toString().padLeft(2,'0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2,'0')}:$m $p';
        }
        return '${d.day.toString().padLeft(2,'0')}-${ms[d.month - 1]}-${d.year}';
      } catch (_) {
        return value.toString();
      }
    }
    return _Org(
      code: json['orgcode']?.toString() ?? '',
      name: json['name'] ?? '',
      openDate: formatDate(json['opendate']),
      country: CountryData.countryNameFromCode(json['country']?.toString() ?? ''),
      division: json['divisionname'] ?? '',
      pincode: json['pincode'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] == 1 ? 'Active' : 'Inactive',
      indiv: json['indiv']?.toString() ?? '',
      a1: json['addrline1'] ?? '',
      a2: json['addrline2'] ?? '',
      a3: json['addrline3'] ?? '',
      a4: json['addrline4'] ?? '',
      a5: json['addrline5'] ?? '',
      active: json['status'] == 1,
      cuser: json['cuser'],
      cdate: formatDate(json['cdate'], includeTime: true),
      euser: json['euser'],
      edate: formatDate(json['edate'], includeTime: true),
      auser: json['auser'],
      adate: formatDate(json['adate'], includeTime: true),
      logoPath: json['logo'],
    );
  }
}

// ── Toast ─────────────────────────────────────────────────────────────────────
class AppToast {
  static OverlayEntry? _current;
  static void show(BuildContext context, String message, {bool isError = false}) {
    _current?.remove();
    _current = null;
    final Color bg = isError ? _kRL : _kGL;
    final Color fg = isError ? _kR : _kG;
    final Color border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final IconData icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message, bg: bg, fg: fg, border: border, icon: icon,
        onDismiss: () { _current?.remove(); _current = null; },
      ),
    );
    _current = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      if (_current == entry) _current = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color bg, fg, border;
  final IconData icon;
  final VoidCallback onDismiss;
  const _ToastWidget({
    required this.message, required this.bg, required this.fg,
    required this.border, required this.icon, required this.onDismiss,
  });
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide, _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<double>(begin: -80, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Positioned(
    top: 24, left: 0, right: 0,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(offset: Offset(0, _slide.value), child: Opacity(opacity: _fade.value, child: child)),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.bg,
            border: Border.all(color: widget.border, width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 18, color: widget.fg),
            const SizedBox(width: 10),
            Flexible(child: Text(widget.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.fg, decoration: TextDecoration.none))),
            const SizedBox(width: 10),
            GestureDetector(onTap: widget.onDismiss, child: Icon(Icons.close_rounded, size: 16, color: widget.fg)),
          ]),
        ),
      ),
    ),
  );
}

class Organizations extends StatefulWidget {
  final AccessPrivileges? accessPrivileges;
  const Organizations({super.key, this.accessPrivileges});
  @override
  State<Organizations> createState() => _OrganizationsState();
}

class _OrganizationsState extends State<Organizations> {
  _V _view = _V.list;
  _Org? _sel;
  bool _delConfirmed = false;
  String _search = '';
  int _page = 0;
  int _totalElements = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  Timer? _debounce;
  List<_Org> _data = [];
  bool _isLoading = true;
  String? _loadError;
  // Countries loaded once at screen level so they're ready before the form opens
  List<Map<String, dynamic>> _apiCountries = [];
  List<Map<String, dynamic>> _apiIndustries = [];
  int? _orgPgmId;

  List<_Org> get _filtered => _data;

  @override
  void initState() {
    super.initState();
    _fetchOrganizations();
    _prefetchCountries();
    _prefetchIndustries();
    _fetchOrgProgramId();
  }

  Future<void> _fetchOrgProgramId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final orgPgm = programs.firstWhere(
        (p) => p.descn.toLowerCase().trim() == 'organizations' || p.descn.toLowerCase().trim() == 'organization',
      );
      _orgPgmId = orgPgm.pgmId;
      debugPrint('Fetched org program ID: $_orgPgmId');
    } catch (e) {
      debugPrint('Error fetching org program ID: $e');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _prefetchCountries() async {
    try {
      final data = await AddressService().getCountries();
      if (mounted) setState(() => _apiCountries = data);
    } catch (_) {}
  }

  Future<void> _prefetchIndustries() async {
    try {
      final data = await OrganizationService().getIndustries();
      if (mounted) {
        setState(() {
          _apiIndustries = data.map((e) {
            final cd = e['industrycd'] ?? '';
            final name = e['industryname'] ?? e['name'] ?? '';
            e['displayName'] = cd.toString().isNotEmpty ? '$cd - $name' : name;
            return e;
          }).toList();
        });
      }
    } catch (_) {}
  }

  _CountryInfo? _findCountryFromApi(String countryNameOrCode) {
    if (countryNameOrCode.isEmpty) return null;
    final term = countryNameOrCode.trim().toLowerCase();
    try {
      final match = _apiCountries.firstWhere((c) {
        final code = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toLowerCase();
        final name = (c['countryname'] ?? c['name'] ?? '').toString().trim().toLowerCase();
        return code == term || name == term;
      });
      return _mapDbToCountryInfo(match);
    } catch (_) {
      final code = countryNameOrCode.length == 2 ? countryNameOrCode.toUpperCase() : '';
      String flag = '';
      if (code.length == 2) {
        try {
          final int first = code.codeUnitAt(0) - 65 + 127462;
          final int second = code.codeUnitAt(1) - 65 + 127462;
          flag = String.fromCharCode(first) + String.fromCharCode(second);
        } catch (_) {}
      }
      return _CountryInfo(
        code: code,
        name: countryNameOrCode,
        flag: flag,
        dialCode: '',
        mobileLength: 10,
      );
    }
  }

  void _go(_V v, [_Org? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _delConfirmed = false;
      if (v == _V.list) {
        _search = '';
        _page = 0;
      }
    });
    if (v == _V.list) {
      _fetchOrganizations();
    }
  }

  Future<void> _fetchOrganizations() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final limit = 10;
      final offset = _page * limit;
      final result = await OrganizationService().getOrganizationsPaginated(
        offset: offset,
        limit: limit,
        search: _search,
      );
      if (mounted) {
        setState(() {
          _data = (result['content'] as List).map((json) => _Org.fromJson(json)).toList();
          _totalElements = result['totalElements'] as int? ?? 0;
          _activeCount = result['activeCount'] as int? ?? 0;
          _inactiveCount = result['inactiveCount'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loadError = e.toString(); _isLoading = false; });
      }
    }
  }

  void _toast(String msg, {bool isError = false}) => AppToast.show(context, msg, isError: isError);

  Future<void> _openWithLogo(_V view, _Org org) async {
    _go(view, org);
    if (org.logoBytes != null) return; 

    final storedPath = org.logoPath ?? '';
    if (storedPath.isEmpty) return;

    try {
      final bytes = await ProfileService().fetchProfilePicture(
        orgId: int.tryParse(org.code) ?? 1,
        filePath: storedPath,
      );
      if (!mounted) return;
      if (bytes != null) {
        setState(() {
          final idx = _data.indexWhere((x) => x.code == org.code);
          if (idx != -1) {
            _data[idx] = _data[idx].cp(logoBytes: bytes);
          }
          if (_sel?.code == org.code) {
            _sel = _sel!.cp(logoBytes: bytes);
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: switch (_view) {
      _V.list   => _list(),
      _V.create => _form(isEdit: false),
      _V.view   => _detail(),
      _V.edit   => _form(isEdit: true),
      _V.delete => _delete(),
    },
  );

  Widget _page_({required Widget child}) =>
      SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);

  Widget _pageHeader({required String title, List<Widget> actions = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kText, letterSpacing: -0.3))),
          ...actions,
        ]),
      );

  Widget _card({required Widget child, EdgeInsets? padding}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
    clipBehavior: Clip.antiAlias,
    padding: padding,
    child: child,
  );

  Widget _statCard(String num, String lbl, Color numC, Color bg, Color border, IconData icon, Color iconC) =>
      Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 18, color: iconC)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: numC, height: 1.1)),
            Text(lbl, style: const TextStyle(fontSize: 10, color: _kMuted)),
          ]),
        ]),
      );

  Widget _hBtn(String label, {Color bg = Colors.white, Color fg = _kMuted, Color border = _kBorder, IconData? icon, VoidCallback? onTap}) =>
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
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorder)),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      );

  Widget _floatField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    String hint = '',
    bool readOnly = false,
    bool required = false,
    String? errorText,
    bool isDatePicker = false,
    DateTime? maxDate,
    FocusNode? focusNode,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool showLock = false,
  }) => _FloatingLabelField(
    label: label, controller: ctrl, icon: icon, hint: hint,
    readOnly: readOnly, isRequired: required, errorText: errorText,
    isDatePicker: isDatePicker, maxDate: maxDate, focusNode: focusNode,
    inputFormatters: inputFormatters, maxLength: maxLength, showLock: showLock,
  );

  Widget _secHdr(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 1)),
    ]),
  );

  // ── LIST ───────────────────────────────────────────────────────────────────
  int _getPageOffset(int p) {
    return p * 10;
  }

  bool _hasNextPage() {
    final nextOffset = (_page + 1) * 10;
    return nextOffset < _totalElements;
  }

  Widget _list() {
    final filtered = _filtered;

    return StatefulBuilder(builder: (ctx, ls) {
      final pageItems = filtered;
      final start = filtered.isEmpty ? 0 : _getPageOffset(_page) + 1;
      final end = _getPageOffset(_page) + pageItems.length;

      return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Organizations'),
        Row(children: [
          _statCard('$_totalElements', 'Total Organizations', _kP, _kPL, _kPB, Icons.apartment_rounded, _kP),
          const SizedBox(width: 10),
          _statCard('$_activeCount', 'Active', _kG, _kGL, _kGB, Icons.check_circle_outline_rounded, _kG),
          const SizedBox(width: 10),
          _statCard('$_inactiveCount', 'Inactive', _kR, _kRL, _kRB, Icons.block_rounded, _kR),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          _SearchBox(
            width: 220,
            onChanged: (v) {
              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                ls(() {
                  _search = v;
                  _page = 0;
                });
                _fetchOrganizations();
              });
            },
          ),
          if (widget.accessPrivileges?.canCreate ?? true) ...[
            const SizedBox(width: 10),
            _hBtn('New Organization', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.add_rounded, onTap: () => _go(_V.create)),
          ],
        ]),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading organizations...')])),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Failed to load organizations: $_loadError', style: const TextStyle(color: Colors.red))),
          )
        else
          _card(child: LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final cols = [w * 0.16, w * 0.35, w * 0.19, w * 0.15, w * 0.15];

            Widget rowWidget(List<Widget> cells, List<double> widths, {bool isHeader = false, bool isEven = false, bool isHovered = false}) {
              Color rowBg;
              if (isHeader) rowBg = const Color(0xFF3D6EBE);
              else if (isHovered) rowBg = const Color(0xFFEEF3FB);
              else if (isEven) rowBg = _kRowAlt; // very light blue for even rows
              else rowBg = Colors.white;
              return Container(
                decoration: BoxDecoration(
                  color: rowBg,
                  border: Border(bottom: BorderSide(color: isHeader ? Colors.transparent : const Color(0xFFF1F5F9))),
                ),
                child: Row(children: List.generate(widths.length, (i) => SizedBox(width: widths[i], child: cells[i]))),
              );
            }

            headerCell(String t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Center(child: Text(t, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
            );

            return Column(children: [
              rowWidget([
                headerCell('ORGANIZATION CODE'),
                headerCell('ORGANIZATION NAME'),
                headerCell('COUNTRY'),
                headerCell('STATUS'),
                headerCell('ACTIONS'),
              ], cols, isHeader: true),
              ...pageItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final r = entry.value;
                final isEven = idx % 2 == 1;
                return StatefulBuilder(builder: (_, rss) {
                  bool hovered = false;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => rss(() => hovered = true),
                    onExit: (_) => rss(() => hovered = false),
                    child: rowWidget([
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Center(child: Text(r.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kP)))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Center(child: Text(r.name, style: const TextStyle(fontSize: 12.5, color: _kText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Center(child: Text(r.country, style: const TextStyle(fontSize: 12.5, color: _kText)))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), child: Center(child: _statusBadge(r.active))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...[
                                if (widget.accessPrivileges?.canView ?? true)
                                  _rowBtn(Icons.visibility_outlined, const Color(0xFF475569), () => _openWithLogo(_V.view, r)),
                                if (widget.accessPrivileges?.canEdit ?? true)
                                  _rowBtn(Icons.edit_outlined, _kP, () => _openWithLogo(_V.edit, r)),
                                if (widget.accessPrivileges?.canDelete ?? true)
                                  _rowBtn(Icons.delete_outline_rounded, _kR, () => _go(_V.delete, r)),
                              ].map((btn) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                                    child: btn,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ], cols, isEven: isEven, isHovered: hovered),
                  );
                });
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    filtered.isEmpty ? 'No records found' : 'Showing $start–$end of $_totalElements records',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                  Row(children: [
                    _pageBtn('‹ Prev', enabled: _page > 0, onTap: () {
                      ls(() => _page--);
                      _fetchOrganizations();
                    }),
                    const SizedBox(width: 6),
                    _pageBtn('Next ›', enabled: _hasNextPage(), onTap: () {
                      ls(() => _page++);
                      _fetchOrganizations();
                    }),
                  ]),
                ]),
              ),
            ]);
          })),
      ]));
    });
  }

  Widget _pageBtn(String label, {required bool enabled, required VoidCallback onTap}) =>
      MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorder)),
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: enabled ? _kMuted : const Color(0xFFCBD5E1))),
          ),
        ),
      );

  Widget _statusBadge(bool active) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: active ? _kGL : _kRL, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: active ? _kG : _kR, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? _kG : _kR)),
      ]),
    ),
  );

  // ── CREATE / EDIT ──────────────────────────────────────────────────────────
  Widget _form({required bool isEdit}) {
    final r = isEdit ? _sel : null;
    final cCode  = TextEditingController(text: r?.code ?? '');
    final cName  = TextEditingController(text: r?.name ?? '');
    final cDate  = TextEditingController(text: r?.openDate ?? '');
    final cDiv   = TextEditingController(text: r?.division ?? '');
    final cPin   = TextEditingController(text: r?.pincode ?? '');

    _CountryInfo? selectedCountry;
    if (r != null) {
      selectedCountry = _findCountryFromApi(r.country);
    } else {
      final dbIndia = _apiCountries.firstWhere(
        (c) {
          final name = (c['countryname'] ?? c['name'] ?? '').toString().trim().toLowerCase();
          final code = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toLowerCase();
          return name == 'india' || code == 'in';
        },
        orElse: () => <String, dynamic>{},
      );
      if (dbIndia.isNotEmpty) {
        selectedCountry = _mapDbToCountryInfo(dbIndia);
      } else {
        selectedCountry = const _CountryInfo(
          code: 'IN',
          name: 'India',
          flag: '🇮🇳',
          dialCode: '91',
          mobileLength: 10,
        );
      }
    }

    String initialTel = r?.telephone ?? '';
    if (initialTel.isNotEmpty) {
      if (initialTel.startsWith('+')) {
        initialTel = initialTel.substring(1);
      }
      if (selectedCountry != null) {
        final dc = selectedCountry.dialCode.replaceAll('+', '').trim();
        if (dc.isNotEmpty && initialTel.startsWith(dc)) {
          initialTel = initialTel.substring(dc.length);
        }
      }
    }

    final cTel   = TextEditingController(text: initialTel);
    final cEmail = TextEditingController(text: r?.email ?? '');

    final cStat  = TextEditingController(text: r?.status ?? '');
    final cIndiv = TextEditingController(text: r?.indiv ?? '');
    final cA3    = TextEditingController(text: r?.a3 ?? '');
    final cA4    = TextEditingController(text: r?.a4 ?? '');

    Map<String, dynamic>? selIndustry;
    if (r?.indiv != null && r!.indiv.isNotEmpty) {
      try {
        selIndustry = _apiIndustries.firstWhere((i) {
          final cd = (i['industrycd'] ?? i['id'] ?? '').toString();
          return cd == r.indiv;
        });
      } catch (_) {}
    }


    final emailFocusNode = FocusNode();
    final mobileFocusNode = FocusNode();
    final errors = <String, String?>{};

    Uint8List? logoBytes  = r?.logoBytes;
    String?    logoName   = r?.logoName;
    String?    logoError;
    bool       logoRemoved = false;

    final today = DateTime.now();
    final maxOpenDate = DateTime(today.year, today.month, today.day);

    // ── Cascade address state (captured by StatefulBuilder closure) ──────────
    bool cLoaded = false;
    List<Map<String, dynamic>> apiStates   = [];
    Map<String, dynamic>? selState;
    bool loadingStates = false;
    List<Map<String, dynamic>> apiCities   = [];
    Map<String, dynamic>? selCity;
    bool loadingCities = false;
    List<Map<String, dynamic>> apiPincodes = [];
    Map<String, dynamic>? selPincode;
    bool loadingPincodes = false;

    // Pre-existing values for edit mode
    final preStateName = r?.a1 ?? '';
    final preCityName  = r?.a2 ?? '';
    final prePincode   = r?.a5 ?? '';

    // Helper: get string from map trying multiple keys
    String gStr(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) { final v = m[k]; if (v != null && v.toString().isNotEmpty) return v.toString(); }
      return '';
    }
    int? gId(Map<String, dynamic> m, List<String> keys) {
      for (final k in keys) { final v = m[k]; if (v != null) return int.tryParse(v.toString()); }
      return null;
    }
    final stateKeys   = ['stateName','name','state_name','statename','statecode'];
    final stateIdKeys = ['stateId','stateid','id','state_id'];
    final cityKeys    = ['cityName','name','city_name','cityname','cityname'];
    final cityIdKeys  = ['cityId','cityid','id','city_id'];
    final pinKeys     = ['pincode','name','pincodeValue','zipcode','pin','areaname'];
    final codeKeys    = ['code','countryCode','isoCode','countrycode','country_code'];
    final cIdKeys     = ['id','countryId','country_id','countryid'];

    return StatefulBuilder(builder: (ctx, ls) {
      void clearError(String key) { if (errors.containsKey(key)) ls(() => errors.remove(key)); }
      final mobileLen = selectedCountry?.mobileLength ?? 10;

      // ── Helper: fetch states — uses class-level _apiCountries ──────────────
      void fetchStatesForCode(String countryCode) {
        if (_apiCountries.isEmpty) {
          AddressService().getCountries().then((data) {
            if (!mounted) return;
            ls(() {
              _apiCountries = data;
            });
            fetchStatesForCode(countryCode);
          }).catchError((_) {});
          return;
        }

        Map<String, dynamic>? ac;
        for (final c in _apiCountries) {
          final v = gStr(c, codeKeys).toLowerCase();
          final n = gStr(c, ['name','countryName','country_name','countryname']).toLowerCase();
          if (v == countryCode.toLowerCase() || n == countryCode.toLowerCase()) {
            ac = c; break;
          }
        }
        if (ac == null) return;
        final cid = gId(ac, cIdKeys);
        if (cid != null) {
          ls(() { loadingStates = true; apiStates = []; });
          AddressService().getStates(cid).then((st) {
            if (!mounted) return;
            ls(() { apiStates = st; loadingStates = false; });
          }).catchError((_) { if (mounted) ls(() => loadingStates = false); });
        }
      }

      // Pre-load full cascade or preloaded country states list
      if (!cLoaded) {
        cLoaded = true;
        if (selectedCountry != null) {
          void loadCascade() async {
            try {
              if (_apiCountries.isEmpty) {
                _apiCountries = await AddressService().getCountries();
                if (!mounted) return;
              }
              
              Map<String, dynamic>? ac;
              for (final c in _apiCountries) {
                final v = gStr(c, codeKeys).toLowerCase();
                final n = gStr(c, ['name','countryName','country_name','countryname']).toLowerCase();
                if (v == selectedCountry!.code.toLowerCase() || n == selectedCountry!.code.toLowerCase()) {
                  ac = c; break;
                }
              }
              if (ac == null) return;
              final cid = gId(ac, cIdKeys);
              if (cid == null) return;

              ls(() => loadingStates = true);
              final st = await AddressService().getStates(cid);
              if (!mounted) return;
              ls(() {
                apiStates = st;
                loadingStates = false;
              });

              if (!isEdit || preStateName.isEmpty || apiStates.isEmpty) return;

              try {
                selState = apiStates.firstWhere(
                  (s) => gStr(s, stateKeys).toLowerCase() == preStateName.toLowerCase(),
                );
              } catch (_) { return; }

              final sid = gId(selState!, stateIdKeys);
              if (sid == null || preCityName.isEmpty) return;

              ls(() => loadingCities = true);
              apiCities = await AddressService().getCities(sid);
              ls(() => loadingCities = false);
              if (!mounted || apiCities.isEmpty) return;

              try {
                selCity = apiCities.firstWhere(
                  (c) => gStr(c, cityKeys).toLowerCase() == preCityName.toLowerCase(),
                );
              } catch (_) { return; }

              final cyid = gId(selCity!, cityIdKeys);
              if (cyid == null || prePincode.isEmpty) return;

              ls(() => loadingPincodes = true);
              apiPincodes = await AddressService().getPincodes(cyid);
              ls(() => loadingPincodes = false);
              if (!mounted || apiPincodes.isEmpty) return;

              try {
                selPincode = apiPincodes.firstWhere(
                  (p) => gStr(p, pinKeys).toLowerCase() == prePincode.toLowerCase(),
                );
              } catch (_) {}

              ls(() {});
            } catch (_) {
              ls(() {
                loadingStates = false;
                loadingCities = false;
                loadingPincodes = false;
              });
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) => loadCascade());
        }
      }

      cCode.addListener(() {
        final text = cCode.text;
        if (text.isEmpty) clearError('code');
        else { final e = orgncodevalid(text); e != null ? ls(() => errors['code'] = e) : clearError('code'); }
      });
      cName.addListener(() {
        final text = cName.text;
        if (text.isEmpty) clearError('name');
        else { final e = orgnamevalid(text); e != null ? ls(() => errors['name'] = e) : clearError('name'); }
      });
      cDate.addListener(() { if (cDate.text.isNotEmpty) clearError('date'); });
      cPin.addListener(() {
        final text = cPin.text;
        if (text.isEmpty) clearError('pincode');
        else { final e = pincodevalid(text); e != null ? ls(() => errors['pincode'] = e) : clearError('pincode'); }
      });

      mobileFocusNode.addListener(() {
        if (!mobileFocusNode.hasFocus) {
          final text = cTel.text.trim();
          if (text.isEmpty) {
            ls(() => errors['telephone'] = 'Telephone is required');
          } else if (text.length != mobileLen) {
            ls(() => errors['telephone'] = 'Must be exactly $mobileLen digits');
          } else {
            final err = mobilenumbervalid(text);
            err != null ? ls(() => errors['telephone'] = err) : clearError('telephone');
          }
        } else {
          clearError('telephone');
        }
      });

      emailFocusNode.addListener(() {
        if (!emailFocusNode.hasFocus && cEmail.text.isNotEmpty) {
          final e = emailvalid(cEmail.text);
          e != null ? ls(() => errors['email'] = e) : clearError('email');
        } else if (emailFocusNode.hasFocus || cEmail.text.isEmpty) {
          clearError('email');
        }
      });

      cDiv.addListener(()   { if (cDiv.text.isNotEmpty) clearError('division'); });
      cIndiv.addListener(() { if (cIndiv.text.isNotEmpty) clearError('indiv'); });

      String formatDateForBackend(String dateStr) {
        if (dateStr.isEmpty) return '';
        try {
          final parts = dateStr.split('-');
          if (parts.length != 3) return dateStr;
          const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
          final monthIndex = months.indexOf(parts[1]);
          if (monthIndex == -1) return dateStr;
          final month = (monthIndex + 1).toString().padLeft(2, '0');
          return '${parts[2]}-$month-${parts[0]}';
        } catch (_) { return dateStr; }
      }

      bool validate() {
        final e = <String, String?>{};
        // Org Code: required even in create mode
        if (cCode.text.trim().isEmpty) {
          e['code'] = 'Organization Code is required';
        } else {
          final err = orgncodevalid(cCode.text.trim());
          if (err != null) e['code'] = err;
        }
        if (cName.text.trim().isEmpty) e['name'] = 'Organization Name is required';
        else { final err = orgnamevalid(cName.text.trim()); if (err != null) e['name'] = err; }
        if (cDate.text.trim().isEmpty) e['date'] = 'Open Date is required';
        if (selState   == null) e['addrState'] = 'State is required';
        if (selCity    == null) e['addrCity']  = 'City is required';
        if (selPincode == null) e['addrPin']   = 'Pincode is required';
        if (cTel.text.trim().isEmpty) e['telephone'] = 'Telephone is required';
        else if (cTel.text.trim().length != mobileLen) e['telephone'] = 'Must be exactly $mobileLen digits';
        else { final err = mobilenumbervalid(cTel.text.trim()); if (err != null) e['telephone'] = err; }
        if (cEmail.text.trim().isEmpty) e['email'] = 'Email is required';
        else if (!cEmail.text.trim().contains('@')) e['email'] = 'Enter a valid email with @';
        else { final err = emailvalid(cEmail.text); if (err != null) e['email'] = err; }
        if (cIndiv.text.trim().isEmpty) e['indiv'] = 'Industry Division is required';
        if (selectedCountry == null) e['country'] = 'Country is required';
        if (cStat.text.trim().isEmpty) e['status'] = 'Status is required';
        ls(() => errors..clear()..addAll(e));
        return e.isEmpty;
      }

      void save() async {
        if (!validate()) { AppToast.show(context, 'Please fill all required fields.', isError: true); return; }
        
        final parsedCode = int.tryParse(cCode.text.trim()) ?? 0;
        if (parsedCode == 0) { AppToast.show(context, 'Invalid org code', isError: true); return; }

        final stateName  = selState   != null ? gStr(selState!,   stateKeys) : '';
        final cityName   = selCity    != null ? gStr(selCity!,    cityKeys)  : '';
        final pinValue   = selPincode != null ? gStr(selPincode!, pinKeys)   : cPin.text.trim();

        String? finalLogoPath = _sel?.logoPath;

        if (logoRemoved && _sel?.logoPath != null && _sel!.logoPath!.isNotEmpty) {
          try {
            await ProfileService().deleteProfilePicture(orgId: parsedCode, filePath: _sel!.logoPath!);
            finalLogoPath = null;
          } catch (_) {}
        }
        
        if (logoBytes != null && logoName != null && logoBytes != _sel?.logoBytes) {
          try {
            final uploadedPath = await ProfileService().uploadProfilePicture(
              orgId: parsedCode,
              fileBytes: logoBytes!,
              fileName: logoName!,
              pathName: 'organization_logo',
            );
            if (uploadedPath != null) {
              finalLogoPath = uploadedPath;
            } else {
              AppToast.show(context, 'Failed to upload logo', isError: true);
              return;
            }
          } catch (e) {
            AppToast.show(context, 'Error uploading logo: $e', isError: true);
            return;
          }
        }

        final orgData = {
          'orgcode': parsedCode,
          'name': cName.text.trim(),
          'opendate': formatDateForBackend(cDate.text.trim()),
          'country': selectedCountry?.code ?? '',
          'divisionname': cDiv.text.trim(),
          'pincode': pinValue,
          'addrline1': stateName,
          'addrline2': cityName,
          'addrline3': cA3.text.trim(),
          'addrline4': cA4.text.trim(),
          'addrline5': pinValue,
          'telephone': cTel.text.trim(),
          'email': cEmail.text.trim(),
          'status': cStat.text == 'Active' ? 1 : 0,
          'indiv': int.tryParse(cIndiv.text.trim()) ?? 1,
          'logo': finalLogoPath,
          if (!isEdit && _orgPgmId != null) 'pgmId': _orgPgmId,
        };
        try {
          if (isEdit) {
            await OrganizationService().updateOrganization(int.parse(_sel!.code), orgData);
            OperationalLogService().logAction(programId: 'ORGANIZATIONS', action: 'U');
            _toast('Organization updated successfully!');
          } else {
            await OrganizationService().createOrganization(orgData);
            OperationalLogService().logAction(programId: 'ORGANIZATIONS', action: 'I');
            _toast('Organization created successfully!');
          }
          await _fetchOrganizations();
          _go(_V.list);
        } catch (e) {
          AppToast.show(context, 'Failed to save organization: $e', isError: true);
        }
      }

      return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEdit ? 'Edit Organization' : 'Add New Organization',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kText, letterSpacing: -0.3),
                ),
              ),
              _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
            ],
          ),
        ),

        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'Edit Organization Details' : 'Organization Details',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                const SizedBox(height: 2),
                Text(isEdit ? 'Locked fields cannot be changed' : 'Fill all required fields marked with *',
                  style: const TextStyle(fontSize: 11, color: _kMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isEdit ? _kOBG : _kPL,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isEdit ? _kOB : _kPB),
                ),
                child: Text(isEdit ? 'EDIT MODE' : 'NEW RECORD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isEdit ? _kOT : _kP)),
              ),
            ]),
          ),

          if (isEdit)
            Container(
              margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: _kWarnBG, border: Border.all(color: _kWarnB), borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.lock_outline, size: 15, color: _kWarnT),
                SizedBox(width: 8),
                Text('Locked fields cannot be modified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kWarnT)),
              ]),
            ),

          // Main fields
          Padding(
            padding: const EdgeInsets.all(22),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 28,
              crossAxisSpacing: 18,
              childAspectRatio: 3.4,
              children: [
                _floatField(label: 'Organization Code', ctrl: cCode, icon: Icons.tag_rounded,
                  hint: 'Enter Organization code', readOnly: isEdit, showLock: isEdit, required: true, errorText: errors['code'],
                  maxLength: 5, inputFormatters: [_RejectingInputFormatter(RegExp(r'^\d*$'), () => ls(() => errors['code'] = 'Only numbers allowed'))]),
                _floatField(label: 'Organization Name', ctrl: cName, icon: Icons.apartment_rounded,
                  hint: 'Enter organization name', required: true, errorText: errors['name'],
                  maxLength: 30),
                _floatField(label: 'Open Date', ctrl: cDate, icon: Icons.calendar_today_rounded,
                  hint: 'Choose date', required: true, errorText: errors['date'],
                  isDatePicker: true, readOnly: false, maxDate: maxOpenDate),
                _OrgCountryPickerField(
                  label: 'Country',
                  selectedCountry: selectedCountry,
                  apiCountries: _apiCountries,
                  isRequired: true,
                  errorText: errors['country'],
                  onChanged: (ci) {
                     if (ci != null) {
                      ls(() {
                        selectedCountry = ci;
                        errors.remove('country');
                        if (ci != null) cTel.text = '';
                        // Reset cascading address on country change
                        selState = null; apiStates = [];
                        selCity  = null; apiCities = [];
                        selPincode = null; apiPincodes = [];
                        errors.remove('addrState'); errors.remove('addrCity'); errors.remove('addrPin');
                      });
                      // Fetch states — works whether apiCountries is loaded or not
                      fetchStatesForCode(ci.code);
                    } else {
                      ls(() {
                        selectedCountry = null;
                        selState = null; apiStates = [];
                        selCity  = null; apiCities = [];
                        selPincode = null; apiPincodes = [];
                      });
                    }
                  },
                ),
                _OrgMobileField(
                  controller: cTel,
                  dialCode: selectedCountry?.dialCode,
                  mobileLength: mobileLen,
                  errorText: errors['telephone'],
                  focusNode: mobileFocusNode,
                  onInvalidInput: () => ls(() => errors['telephone'] = 'Only numbers allowed'),
                ),
                _floatField(label: 'Email', ctrl: cEmail, icon: Icons.email_outlined,
                  hint: 'Enter email address', required: true, errorText: errors['email'], focusNode: emailFocusNode,
                  inputFormatters: [_RejectingInputFormatter(RegExp(r'^[^\s]*$'), () => ls(() => errors['email'] = 'Spaces not allowed'))]),
                // _floatField(label: 'Pincode', ctrl: cPin, icon: Icons.location_on_outlined,
                //   hint: 'Enter pincode', required: true, errorText: errors['pincode'],
                //   maxLength: 6, inputFormatters: [_RejectingInputFormatter(RegExp(r'^\d*$'), () => ls(() => errors['pincode'] = 'Only numbers allowed'))]),
                // _floatField(label: 'Division Name', ctrl: cDiv, icon: Icons.account_tree_rounded,
                //   hint: 'Enter division name', required: true, errorText: errors['division']),
                _OrgApiDropdownField(
                  label: 'Industry Division',
                  icon: Icons.business_center_outlined,
                  selectedItem: selIndustry,
                  items: _apiIndustries,
                  displayKeys: const ['displayName', 'industryname', 'name'],
                  isRequired: true,
                  errorText: errors['indiv'],
                  onChanged: (item) {
                    ls(() {
                      selIndustry = item;
                      if (item != null) {
                        cIndiv.text = (item['industrycd'] ?? item['id'] ?? '').toString();
                      } else {
                        cIndiv.text = '';
                      }
                      errors.remove('indiv');
                    });
                  },
                ),
                 _OrgStatusToggle(
  isActive: cStat.text == 'Active',
  onChanged: (v) {
    ls(() {
      cStat.text = v ? 'Active' : 'Inactive';
      errors.remove('status');
    });
  },
),               
              ],
            ),
          ),

          Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _secHdr('ADDRESS')),

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 28,
              crossAxisSpacing: 18,
              childAspectRatio: 4.2,
              children: [
                // Address Line 1 → State dropdown
                _OrgApiDropdownField(
                  label: 'State',
                  icon: Icons.map_outlined,
                  selectedItem: selState,
                  items: apiStates,
                  displayKeys: stateKeys,
                  isRequired: true,
                  errorText: errors['addrState'],
                  isLoading: loadingStates,
                  enabled: selectedCountry != null && !loadingStates,
                  disabledHint: selectedCountry == null ? 'Select country first' : 'Loading…',
                  onChanged: (item) {
                    ls(() {
                      selState = item;
                      selCity = null; apiCities = [];
                      selPincode = null; apiPincodes = [];
                      errors.remove('addrState');
                    });
                    if (item != null) {
                      final sid = gId(item, stateIdKeys);
                      if (sid != null) {
                        ls(() => loadingCities = true);
                        AddressService().getCities(sid).then((ct) {
                          if (!mounted) return;
                          ls(() { apiCities = ct; loadingCities = false; });
                        }).catchError((_) { if (mounted) ls(() => loadingCities = false); });
                      }
                    }
                  },
                ),
                // Address Line 2 → City dropdown
                _OrgApiDropdownField(
                  label: 'City',
                  icon: Icons.location_city_outlined,
                  selectedItem: selCity,
                  items: apiCities,
                  displayKeys: cityKeys,
                  isRequired: true,
                  errorText: errors['addrCity'],
                  isLoading: loadingCities,
                  enabled: selState != null && !loadingCities,
                  disabledHint: selState == null ? 'Select state first' : 'Loading…',
                  onChanged: (item) {
                    ls(() {
                      selCity = item;
                      selPincode = null; apiPincodes = [];
                      errors.remove('addrCity');
                    });
                    if (item != null) {
                      final cyid = gId(item, cityIdKeys);
                      if (cyid != null) {
                        ls(() => loadingPincodes = true);
                        AddressService().getPincodes(cyid).then((pc) {
                          if (!mounted) return;
                          ls(() { apiPincodes = pc; loadingPincodes = false; });
                        }).catchError((_) { if (mounted) ls(() => loadingPincodes = false); });
                      }
                    }
                  },
                ),
                // Address Line 3 — free text
                _floatField(label: 'Address Line 3', ctrl: cA3, icon: Icons.format_list_bulleted_rounded, hint: 'Street / Area', maxLength: 20),
                // Address Line 4 — free text
                _floatField(label: 'Address Line 4', ctrl: cA4, icon: Icons.format_list_bulleted_rounded, hint: 'Landmark', maxLength: 20),
                // Address Line 5 → Pincode dropdown
                _OrgApiDropdownField(
                  label: 'Pincode',
                  icon: Icons.pin_drop_outlined,
                  selectedItem: selPincode,
                  items: apiPincodes,
                  displayKeys: pinKeys,
                  isRequired: true,
                  errorText: errors['addrPin'],
                  isLoading: loadingPincodes,
                  enabled: selCity != null && !loadingPincodes,
                  disabledHint: selCity == null ? 'Select city first' : 'Loading…',
                  onChanged: (item) {
                    ls(() {
                      selPincode = item;
                      errors.remove('addrPin');
                      // Auto-fill top-level pincode field
                      if (item != null) cPin.text = gStr(item, pinKeys);
                    });
                  },
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(color: _kBorder, height: 1),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _kPL, borderRadius: BorderRadius.circular(9)),
                  child: const Icon(Icons.image_rounded, size: 18, color: _kP),
                ),
                const SizedBox(width: 10),
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Organization Logo', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: _kText)),
                  Text('PNG, JPG only — max 5 MB',
                    style: TextStyle(fontSize: 11, color: _kMuted)),
                ]),
              ]),
              const SizedBox(height: 16),
              _OrgLogoUpload(
                logoBytes: logoBytes,
                logoName:  logoName,
                logoError: logoError,
                onPicked: (bytes, name, error) => ls(() {
                  logoError   = error;
                  logoRemoved = false; 
                  if (error == null) {
                    logoBytes = bytes;
                    logoName  = name;
                  } else {
                    logoBytes = null;
                    logoName  = null;
                  }
                }),
                onRemove: () => ls(() {
                  logoBytes   = null;
                  logoName    = null;
                  logoError   = null;
                  logoRemoved = true; 
                }),
              ),
            ]),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _fBtn('Cancel', Icons.close_rounded, Colors.white, _kP, _kP, onTap: () => _go(_V.list)),
              const SizedBox(width: 10),
              if (isEdit && !(_sel?.active ?? true))
                _fBtn('Activate', Icons.check_circle_outline_rounded, _kG, Colors.white, _kG, onTap: () {
                  final i = _data.indexWhere((x) => x.code == _sel!.code);
                  if (i != -1) setState(() => _data[i] = _data[i].cp(active: true, status: 'Active'));
                  _go(_V.list);
                  _toast('Organization activated.');
                }),
              const SizedBox(width: 10),
              _fBtn(isEdit ? 'Update' : 'Create', Icons.check_rounded, _kP, Colors.white, _kP, onTap: save),
            ]),
          ),
        ])),
      ]));
    });
  }

  String _getIndustryName(String id) {
    if (id.isEmpty) return '';
    try {
      final match = _apiIndustries.firstWhere((i) => (i['industrycd'] ?? i['id'] ?? '').toString() == id);
      return (match['industryname'] ?? match['name'] ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  // ── VIEW DETAIL ────────────────────────────────────────────────────────────
  Widget _detail() {
    final r = _sel!;
    ro(String label, String val, IconData icon, {String? sub}) => _FloatingLabelField(
      label: label, controller: TextEditingController(text: val), icon: icon, readOnly: true, isRequired: false, subtext: sub,
    );

    return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(children: [
          const Expanded(child: Text('Organization Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kText, letterSpacing: -0.3))),
          _hBtn('Audit Details', bg: Colors.white, fg: _kP, border: _kP, icon: Icons.history_rounded, onTap: () => AuditDetailsDialog.show(
            context,
            cuser: r.euser,
            cdate: r.edate,
            euser: r.cuser,
            edate: r.cdate,
            auser: r.auser,
            adate: r.adate,
            subtitle: 'Organization audit trail for ${r.name}',
          )),
          const SizedBox(width: 10),
          _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
        ]),
      ),
      _card(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFEEF3FB), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(children: [
            r.logoBytes != null
                ? Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder)),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(r.logoBytes!, fit: BoxFit.cover))
                : Container(width: 44, height: 44,
                    decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.apartment_rounded, size: 22, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kP)),
              const SizedBox(height: 2),
              Text('Record ID: ${r.code} • Created: ${r.openDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: r.active ? _kGL : _kRL, borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: r.active ? _kG : _kR, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(r.active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: r.active ? _kG : _kR)),
              ]),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 80,
              mainAxisSpacing: 16,
              crossAxisSpacing: 18,
            ),
            children: [
              ro('Organization Code', r.code, Icons.tag_rounded),
              ro('Organization Name', r.name, Icons.apartment_rounded),
              ro('Open Date', r.openDate, Icons.calendar_today_rounded),
              ro('Country', r.country, Icons.language_rounded),
              Builder(builder: (context) {
                String displayTelephone = r.telephone;
                final ci = _findCountryFromApi(r.country);
                if (ci != null && ci.dialCode.isNotEmpty) {
                  String rawTel = r.telephone.trim();
                  if (rawTel.startsWith('+')) {
                    rawTel = rawTel.substring(1);
                  }
                  final dc = ci.dialCode.replaceAll('+', '').trim();
                  if (dc.isNotEmpty && rawTel.startsWith(dc)) {
                    rawTel = rawTel.substring(dc.length);
                  }
                  displayTelephone = '+$dc $rawTel';
                }
                return ro('Mobile', displayTelephone, Icons.phone_outlined);
              }),
              ro('Email', r.email, Icons.email_outlined),
              // ro('Pincode', r.pincode, Icons.location_on_outlined),
              ro('Industry Division', r.indiv, Icons.business_center_outlined, sub: _getIndustryName(r.indiv)),   
              _OrgStatusToggle(
                isActive: r.active,
                onChanged: (_) {},
                readOnly: true,
              ),
            ],
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _secHdr('ADDRESS')),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
          child: GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 52,
              mainAxisSpacing: 28,
              crossAxisSpacing: 18,
            ),
            children: [
              ro('State',          r.a1.isEmpty ? '—' : r.a1, Icons.map_outlined),
              ro('City',           r.a2.isEmpty ? '—' : r.a2, Icons.location_city_outlined),
              ro('Address Line 3', r.a3.isEmpty ? '—' : r.a3, Icons.format_list_bulleted_rounded),
              ro('Address Line 4', r.a4.isEmpty ? '—' : r.a4, Icons.format_list_bulleted_rounded),
              ro('Pincode',        r.a5.isEmpty ? '—' : r.a5, Icons.pin_drop_outlined),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _fBtn('Back', Icons.arrow_back_rounded, _kP, Colors.white, _kP, onTap: () => _go(_V.list)),
          ]),
        ),
      ])),
    ]));
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  Widget _delete() {
    final r = _sel!;
    return StatefulBuilder(builder: (ctx, ls) => _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _pageHeader(title: 'Delete Organization'),
      _card(child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: _kRL,
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delete_outline_rounded, size: 20, color: _kR),
            SizedBox(width: 8),
            Text('Delete Confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kR)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(children: [
            const Text('Are you sure you want to delete this record? This action cannot be undone.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _kMuted)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('RECORD TO BE DELETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
                const SizedBox(height: 10),
                _delRow('Org Code:', r.code, isRed: true),
                const SizedBox(height: 6),
                _delRow('Organization Name:', r.name),
              ]),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => ls(() => setState(() => _delConfirmed = !_delConfirmed)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(color: _kRL, border: Border.all(color: _kRB), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 18, height: 18,
                    decoration: BoxDecoration(color: _delConfirmed ? _kR : Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: _kR, width: 1.5)),
                    child: _delConfirmed ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('I understand this will permanently delete this record and all related data.',
                    style: TextStyle(fontSize: 12, color: _kR, fontWeight: FontWeight.w500))),
                ]),
              ),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _fBtn('Cancel', Icons.close_rounded, Colors.white, _kP, _kP, onTap: () => _go(_V.list)),
            const SizedBox(width: 10),
            _fBtn('Confirm Delete', Icons.delete_outline_rounded,
              _delConfirmed ? _kR : Colors.white,
              _delConfirmed ? Colors.white : const Color(0xFFCBD5E1),
              _delConfirmed ? _kR : _kBorder,
              onTap: _delConfirmed ? () async {
                try {
                  await OrganizationService().deleteOrganization(int.parse(r.code));
                  OperationalLogService().logAction(programId: 'ORGANIZATIONS', action: 'D');
                  await _fetchOrganizations();
                  _go(_V.list);
                  _toast('Organization deleted successfully!');
                } catch (e) {
                  AppToast.show(context, 'Failed to delete organization: $e', isError: true);
                }
              } : null,
            ),
          ]),
        ),
      ])),
    ])));
  }

  Widget _delRow(String key, String val, {bool isRed = false}) => Row(children: [
    SizedBox(width: 150, child: Text(key, style: const TextStyle(fontSize: 12, color: _kMuted))),
    Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isRed ? _kR : _kText)),
  ]);
}

// ── Generic API Dropdown Field (floating label, matches existing field style) ──
class _OrgApiDropdownField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Map<String, dynamic>? selectedItem;
  final List<Map<String, dynamic>> items;
  final List<String> displayKeys;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final bool isRequired;
  final String? errorText;
  final bool isLoading;
  final bool enabled;
  final String disabledHint;

  const _OrgApiDropdownField({
    required this.label,
    required this.icon,
    required this.items,
    required this.displayKeys,
    required this.onChanged,
    this.selectedItem,
    this.isRequired = false,
    this.errorText,
    this.isLoading = false,
    this.enabled = true,
    this.disabledHint = '',
  });

  @override
  State<_OrgApiDropdownField> createState() => _OrgApiDropdownFieldState();
}

class _OrgApiDropdownFieldState extends State<_OrgApiDropdownField>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac;
  late Animation<double> _top, _sz;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();

  String _display(Map<String, dynamic> m) {
    for (final k in widget.displayKeys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  // Float label when item selected, dropdown is open, or there is an error — identical to Country field
  bool get _floated => widget.selectedItem != null || _isOpen || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_OrgApiDropdownField o) {
    super.didUpdateWidget(o);
    _floated ? _ac.forward() : _ac.reverse();
  }

  @override
  void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }

  void _rm() {
    _ov?.remove(); _ov = null;
    if (mounted) setState(() => _isOpen = false);
    _floated ? _ac.forward() : _ac.reverse();
  }

  void _open() {
    if (!widget.enabled || widget.isLoading) return;
    _rm(); _sc.clear();
    setState(() => _isOpen = true); _ac.forward();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final sz = rb.size;
    final pos = rb.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - (pos.dy + sz.height);
    final showAbove = spaceBelow < 300 && pos.dy > spaceBelow;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(
          width: sz.width < 240 ? 240 : sz.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: showAbove ? const Offset(0, -6) : Offset(0, sz.height + 6),
            child: StatefulBuilder(builder: (c2, ss) {
              final q = _sc.text.toLowerCase();
              final filtered = widget.items.where((m) {
                final d = _display(m).toLowerCase();
                return q.isEmpty || d.contains(q);
              }).toList();

              return Material(
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      decoration: const BoxDecoration(
                        color: _kPL,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                      ),
                      child: Row(children: [
                        Icon(widget.icon, size: 15, color: _kP),
                        const SizedBox(width: 6),
                        Text('Select ${widget.label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
                        const Spacer(),
                        Text('${filtered.length} found', style: const TextStyle(fontSize: 10, color: _kMuted)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextField(
                        controller: _sc, autofocus: true, onChanged: (_) => ss(() {}),
                        style: const TextStyle(fontSize: 13, color: _kText),
                        decoration: InputDecoration(
                          hintText: 'Search ${widget.label.toLowerCase()}...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kP),
                          suffixIcon: _sc.text.isNotEmpty
                            ? GestureDetector(onTap: () { _sc.clear(); ss(() {}); }, child: const Icon(Icons.close_rounded, size: 15, color: _kMuted))
                            : null,
                          filled: true, fillColor: _kSurface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kP, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 9), isDense: true,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: _kBorder),
                    Flexible(child: filtered.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20),
                          child: Text('No results found', style: TextStyle(fontSize: 13, color: _kMuted))))
                      : ListView.builder(
                          padding: EdgeInsets.zero, shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            final isSel = widget.selectedItem != null && _display(widget.selectedItem!) == _display(item);
                            final rowBg = isSel ? _kPL : (idx % 2 == 0 ? Colors.white : _kRowAlt);
                            return InkWell(
                              onTap: () { widget.onChanged(item); _rm(); },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                color: rowBg,
                                child: Row(children: [
                                  Expanded(child: Text(_display(item),
                                    style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500))),
                                  if (isSel) const Icon(Icons.check_circle_rounded, size: 16, color: _kP),
                                ]),
                              ),
                            );
                          },
                        ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }

  @override
  Widget build(BuildContext ctx) {
    final sel = widget.selectedItem;
    final err = widget.errorText != null;
    final bc = err ? _kR : _kP;
    final disabled = !widget.enabled || widget.isLoading;
    // Mirror Country field: body text is empty when label is at center (not floated);
    // shows placeholder/hint only when label has floated up, shows selected value when picked.
    final placeholderText = sel != null
        ? _display(sel)
        : (_floated ? (disabled ? widget.disabledHint : 'Select ${widget.label.toLowerCase()}') : '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: disabled ? null : _open,
            child: MouseRegion(
              cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
              child: Container(
                key: _key, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: bc, width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.5),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 12, 0),
                    child: Row(children: [
                      if (widget.isLoading) ...[
                        const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _kP)),
                        const SizedBox(width: 8),
                      ],
                      Expanded(child: Text(
                        placeholderText,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: sel != null ? _kText : _kMuted),
                        overflow: TextOverflow.ellipsis,
                      )),
                      Icon(Icons.unfold_more_rounded, size: 16, color: disabled ? _kBorder : bc),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 10, top: 0, bottom: 0,
          child: Align(alignment: Alignment.centerLeft,
            child: Icon(widget.icon, size: 14, color: err ? _kR : _kP))),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: disabled ? null : _open,
              child: Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600,
                    color: err ? _kR : _kP, letterSpacing: 0.2, decoration: TextDecoration.none),
                ),
              ),
            ),
          ),
        ),
      ]),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}

// ── Search Box ────────────────────────────────────────────────────────────────
class _SearchBox extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.width, required this.onChanged});
  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  @override
  void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override
  void dispose() { _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width, height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _focused ? _kP : _kBorder, width: _focused ? 2.0 : 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _focused ? [BoxShadow(color: _kP.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : [],
    ),
    child: TextField(
      focusNode: _focus,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search organizations',
        hintStyle: TextStyle(fontSize: 12, color: _focused ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1)),
        prefixIcon: Icon(Icons.search_rounded, size: 16, color: _focused ? _kP : const Color(0xFF94A3B8)),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true,
      ),
    ),
  );
}

// ── Country Picker (no dial code shown, dynamic API list, flag-free) ─────────
class _OrgCountryPickerField extends StatefulWidget {
  final String label;
  final _CountryInfo? selectedCountry;
  final List<Map<String, dynamic>> apiCountries;
  final ValueChanged<_CountryInfo?> onChanged;
  final bool isRequired;
  final String? errorText;
  const _OrgCountryPickerField({
    required this.label,
    this.selectedCountry,
    required this.apiCountries,
    required this.onChanged,
    this.isRequired = false,
    this.errorText,
  });
  @override
  State<_OrgCountryPickerField> createState() => _OrgCountryPickerFieldState();
}

class _OrgCountryPickerFieldState extends State<_OrgCountryPickerField> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac;
  late Animation<double> _top, _sz;
  bool _isOpen = false;
  final LayerLink _layerLink = LayerLink();

  bool get _floated => (widget.selectedCountry != null) || _isOpen || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }
  @override
  void didUpdateWidget(_OrgCountryPickerField o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override
  void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }

  void _rm() {
    _ov?.remove(); _ov = null;
    if (mounted) setState(() => _isOpen = false);
    _floated ? _ac.forward() : _ac.reverse();
  }

  void _open() {
    _rm(); _sc.clear();
    setState(() => _isOpen = true); _ac.forward();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
    final sz = rb.size;
    final pos = rb.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final spaceBelow = screenHeight - (pos.dy + sz.height);
    final showAbove = spaceBelow < 340 && pos.dy > spaceBelow;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(
          width: sz.width < 240 ? 240 : sz.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: showAbove ? Alignment.bottomLeft : Alignment.topLeft,
            offset: showAbove ? const Offset(0, -6) : Offset(0, sz.height + 6),
            child: StatefulBuilder(builder: (c2, ss) {
              final dbCountries = widget.apiCountries.map(_mapDbToCountryInfo).toList();
              final filtered = dbCountries.where((c) {
                final q = _sc.text.toLowerCase();
                return q.isEmpty || c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q);
              }).toList();

              return Material(
                elevation: 12,
                shadowColor: Colors.black.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 320),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder),
                  ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: const BoxDecoration(
                      color: _kPL,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.public_rounded, size: 15, color: _kP),
                      const SizedBox(width: 6),
                      const Text('Select Country', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 0.5)),
                      const Spacer(),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _sc, autofocus: true, onChanged: (_) => ss(() {}),
                      style: const TextStyle(fontSize: 13, color: _kText),
                      decoration: InputDecoration(
                        hintText: 'Search by name or code...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kP),
                        suffixIcon: _sc.text.isNotEmpty
                          ? GestureDetector(onTap: () { _sc.clear(); ss(() {}); }, child: const Icon(Icons.close_rounded, size: 15, color: _kMuted))
                          : null,
                        filled: true, fillColor: _kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kP, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 9), isDense: true,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: _kBorder),
                  Flexible(child: filtered.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(20),
                        child: Text('No countries found', style: TextStyle(fontSize: 13, color: _kMuted))))
                    : ListView.builder(
                        padding: EdgeInsets.zero, shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final c = filtered[idx];
                          final isSel = widget.selectedCountry?.code == c.code;
                          final rowBg = isSel ? _kPL : (idx % 2 == 0 ? Colors.white : _kRowAlt);
                          return InkWell(
                            onTap: () { widget.onChanged(c); _rm(); setState(() {}); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: rowBg,
                              child: Row(children: [
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c.name, style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500)),
                                  Text(c.code, style: const TextStyle(fontSize: 10, color: _kMuted)),
                                ])),
                                if (isSel) const Icon(Icons.check_circle_rounded, size: 16, color: _kP),
                              ]),
                            ),
                          );
                        },
                      ),
                  ),
                ]),
              ),
              );
            }),
          ),
        ),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }

  @override
  Widget build(BuildContext ctx) {
    final sel = widget.selectedCountry;
    final err = widget.errorText != null;
    final bc = err ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            onTap: _open,
            child: Container(
              key: _key, height: 44,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: 1.5)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 12, 0),
                  child: Row(children: [
                    Expanded(child: Text(
                      sel != null ? sel.name : (_floated ? 'Select country' : ''),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: sel != null ? _kText : _kMuted),
                      overflow: TextOverflow.ellipsis,
                    )),
                    Icon(Icons.unfold_more_rounded, size: 16, color: bc),
                  ]),
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.language_rounded, size: 14, color: bc))),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: _open,
              child: Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none),
                ),
              ),
            ),
          ),
        ),
      ]),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}


// ── Mobile Field (country-based validation, shows +dialCode badge) ─────────────
class _OrgMobileField extends StatefulWidget {
  final TextEditingController controller;
  final String? dialCode;
  final int mobileLength;
  final String? errorText;
  final FocusNode? focusNode;
  final VoidCallback? onInvalidInput;
  const _OrgMobileField({
    required this.controller, this.dialCode, required this.mobileLength,
    this.errorText, this.focusNode, this.onInvalidInput,
  });
  @override
  State<_OrgMobileField> createState() => _OrgMobileFieldState();
}

class _OrgMobileFieldState extends State<_OrgMobileField> with SingleTickerProviderStateMixin {
  late FocusNode _fn;
  bool _focused = false;
  late AnimationController _ac;
  late Animation<double> _top, _sz;

  bool get _hasCC   => widget.dialCode != null && widget.dialCode!.isNotEmpty;
  bool get _hasVal  => widget.controller.text.isNotEmpty;
  bool get _floated => _focused || _hasVal || _hasCC || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _fn = widget.focusNode ?? FocusNode();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _fn.addListener(() { setState(() => _focused = _fn.hasFocus); _floated ? _ac.forward() : _ac.reverse(); });
    widget.controller.addListener(() { setState(() {}); _floated ? _ac.forward() : _ac.reverse(); });
  }
  @override
  void didUpdateWidget(_OrgMobileField o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override
  void dispose() {
    if (widget.focusNode == null) _fn.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    final err = widget.errorText != null;
    final bc = err ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 44,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: 1.5)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.5),
            child: Row(children: [
              Padding(padding: const EdgeInsets.only(left: 10), child: Icon(Icons.phone_rounded, size: 14, color: bc)),
              if (_hasCC) ...[
                const SizedBox(width: 6),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 7),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: _kPL, borderRadius: BorderRadius.circular(6), border: Border.all(color: _kPB)),
                  child: Text('+${widget.dialCode}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kP)),
                ),
              ],
              Expanded(child: TextField(
                controller: widget.controller,
                focusNode: _fn,
                keyboardType: TextInputType.phone,
                maxLength: widget.mobileLength,
                inputFormatters: [
                  _RejectingInputFormatter(RegExp(r'^\d*$'), () {
                    if (widget.onInvalidInput != null) widget.onInvalidInput!();
                  })
                ],
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kText),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: _floated ? (_hasCC ? '${widget.mobileLength} digit number' : 'Select country first') : '',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                  border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(_hasCC ? 8 : 6, 14, 12, 14), isDense: true,
                ),
              )),
            ]),
          ),
        ),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: () => _fn.requestFocus(),
              child: Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  const TextSpan(
                    text: 'Mobile',
                    children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none),
                ),
              ),
            ),
          ),
        ),
      ]),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}

class _OrgStatusToggle extends StatelessWidget {
  final bool isActive, readOnly;
  final ValueChanged<bool> onChanged;
  final bool hasError;

  const _OrgStatusToggle({
    required this.isActive,
    required this.onChanged,
    this.hasError = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bc = hasError ? _kR : _kP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt_rounded,
                    size: 14,
                    color: bc,
                  ),

                  const SizedBox(width: 6),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      key: ValueKey(isActive),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? _kG : _kMuted,
                      ),
                    ),
                  ),

                  const Spacer(),

                  /// Toggle Button with Cursor Pointer
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: readOnly ? null : () => onChanged(!isActive),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _kG
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration:
                                  const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: isActive
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: -8,
              left: 28,
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  const TextSpan(
                    text: 'Status',
                    children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
                  ),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: bc,
                    letterSpacing: 0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),

        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              'Status is required',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kR,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}
// ── Floating Label Field ──────────────────────────────────────────────────────
class _FloatingLabelField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool readOnly, isRequired, isDatePicker, showLock;
  final String? errorText, subtext;
  final DateTime? maxDate;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const _FloatingLabelField({
    required this.label, required this.controller, required this.icon,
    this.hint = '', this.readOnly = false, this.isRequired = false, this.errorText, this.subtext,
    this.isDatePicker = false, this.maxDate, this.focusNode,
    this.inputFormatters, this.maxLength, this.showLock = false,
  });
  @override
  State<_FloatingLabelField> createState() => _FloatingLabelFieldState();
}

class _FloatingLabelFieldState extends State<_FloatingLabelField> with SingleTickerProviderStateMixin {
  late final FocusNode _focus;
  bool _focused = false;
  late AnimationController _anim;
  late Animation<double> _labelTop, _labelSize;

  bool get _hasValue => widget.controller.text.isNotEmpty;
  bool get _floated  => _focused || _hasValue || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1.0 : 0.0);
    _labelTop  = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _labelSize = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _focus.addListener(() { setState(() => _focused = _focus.hasFocus); _floated ? _anim.forward() : _anim.reverse(); });
    widget.controller.addListener(() { if (_floated && _anim.value < 1) _anim.forward(); if (!_floated && _anim.value > 0) _anim.reverse(); setState(() {}); });
  }

  void _requestFocus() {
    if (!widget.readOnly && !widget.isDatePicker) {
      _focus.requestFocus();
    } else if (widget.isDatePicker) {
      _pickDate(context);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    if (widget.readOnly) return;
    final maxD = widget.maxDate ?? DateTime(2100);
    final firstDate = DateTime(1900);
    DateTime initial = DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(maxD)) initial = maxD;
    try {
      final text = widget.controller.text.trim();
      if (text.isNotEmpty) {
        DateTime? parsed;
        // Try ISO format: YYYY-MM-DD
        final isoReg = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
        final isoMatch = isoReg.firstMatch(text);
        if (isoMatch != null) {
          parsed = DateTime(
            int.parse(isoMatch.group(1)!),
            int.parse(isoMatch.group(2)!),
            int.parse(isoMatch.group(3)!),
          );
        } else {
          // Try custom format: dd-MMM-yyyy or dd-MMM-yy
          final parts = text.split('-');
          if (parts.length == 3) {
            const months = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,
                            'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
            final d = int.parse(parts[0]);
            final m = months[parts[1]] ?? 1;
            var y = int.parse(parts[2]);
            if (y < 100) y += 2000;
            parsed = DateTime(y, m, d);
          }
        }
        if (parsed != null && !parsed.isAfter(maxD) && !parsed.isBefore(firstDate)) {
          initial = parsed;
        }
      }
    } catch (_) {}

    final picked = await showDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: CustomCalendarDialog(
          initialDate: initial,
          firstDate: firstDate,
          lastDate: maxD,
          title: 'Select ${widget.label}',
        ),
      ),
    );

    if (picked != null) {
      if (picked == DateTime(1900, 1, 1)) {
        widget.controller.clear();
      } else {
        const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        widget.controller.text = '${picked.day.toString().padLeft(2,'0')}-${ms[picked.month - 1]}-${picked.year}';
      }
    }
  }

  @override
  void dispose() { if (widget.focusNode == null) _focus.dispose(); _anim.dispose(); super.dispose(); }
  @override
  void didUpdateWidget(_FloatingLabelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final Color borderColor = hasError ? _kR : _kP;

    Widget textField = TextField(
      controller: widget.controller,
      focusNode: _focus,
      readOnly: widget.isDatePicker || widget.readOnly,
      showCursor: widget.isDatePicker ? false : null,
      enableInteractiveSelection: !widget.isDatePicker,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kText),
      decoration: InputDecoration(
        hintText: _floated ? widget.hint : '',
        hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(36, 14, 12, 14), isDense: true,
        suffixIcon: (widget.showLock && widget.readOnly) ? Icon(Icons.lock_outline_rounded, size: 16, color: _kMuted.withOpacity(0.5)) : null,
      ),
    );

    Widget field = Container(
      height: 44,
      decoration: BoxDecoration(
        color: widget.readOnly ? _kSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.5),
        child: widget.isDatePicker && !widget.readOnly ? AbsorbPointer(child: textField) : textField,
      ),
    );

    if (widget.isDatePicker && !widget.readOnly) {
      field = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _pickDate(context),
          behavior: HitTestBehavior.opaque,
          child: field,
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        field,
        Positioned(left: 10, top: 0, bottom: 0,
          child: Align(alignment: Alignment.centerLeft,
            child: Icon(
              widget.isDatePicker && _floated ? Icons.calendar_month_rounded : widget.icon,
              size: 14, color: hasError ? _kR : _kP,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, _2) => Positioned(top: _labelTop.value, left: 28,
            child: GestureDetector(
              onTap: _requestFocus,
              child: Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: _labelSize.value, fontWeight: FontWeight.w600,
                    color: hasError ? _kR : _kP, letterSpacing: 0.2, decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
      if (widget.subtext != null && widget.subtext!.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.subtext!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2))),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}

class _RejectingInputFormatter extends TextInputFormatter {
  final RegExp pattern;
  final VoidCallback onReject;

  _RejectingInputFormatter(this.pattern, this.onReject);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (pattern.hasMatch(newValue.text)) return newValue;
    onReject();
    return oldValue;
  }
}

const _kAllowedExts  = ['png', 'jpg', 'jpeg'];
const _kMaxLogoBytes = 5 * 1024 * 1024;

class _OrgLogoUpload extends StatefulWidget {
  final Uint8List? logoBytes;
  final String?    logoName;
  final String?    logoError;
  final void Function(Uint8List? bytes, String? name, String? error) onPicked;
  final VoidCallback onRemove;

  const _OrgLogoUpload({
    required this.logoBytes, required this.logoName, required this.logoError,
    required this.onPicked, required this.onRemove,
  });

  @override State<_OrgLogoUpload> createState() => _OrgLogoUploadState();
}

class _OrgLogoUploadState extends State<_OrgLogoUpload> {
  bool _hovering = false;

  Future<void> _pick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: _kAllowedExts, withData: true);
    if (res == null || res.files.isEmpty) return;

    final file = res.files.first;
    final bytes = file.bytes;
    final name  = file.name;

    if (bytes == null) return;

    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!_kAllowedExts.contains(ext)) {
      widget.onPicked(null, null, 'Invalid format. Only PNG and JPG are allowed.');
      return;
    }
    if (bytes.lengthInBytes > _kMaxLogoBytes) {
      widget.onPicked(null, null, 'File too large. Maximum allowed size is 5 MB.');
      return;
    }
    widget.onPicked(bytes, name, null);
  }

  @override Widget build(BuildContext context) {
    final hasImage = widget.logoBytes != null;
    final hasError = widget.logoError != null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasImage) ...[
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Organization Logo', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted,
            decoration: TextDecoration.none)),
          const SizedBox(height: 10),
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder)),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(widget.logoBytes!, fit: BoxFit.cover),
          ),
          const SizedBox(height: 12),
          Row(children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _pick,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kBorder)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_outlined, size: 14, color: _kP),
                    SizedBox(width: 6),
                    Text('Edit', style: TextStyle(
                      fontSize: 12, color: _kP, fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none)),
                  ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onRemove,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _kR,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _kR)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                    SizedBox(width: 6),
                    Text('Remove', style: TextStyle(
                      fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none)),
                  ]),
                ),
              ),
            ),
          ]),
          if (widget.logoName != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: Text(widget.logoName!, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: _kMuted,
                  decoration: TextDecoration.none)),
            ),
          ],
        ]),
      ] else ...[
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovering = true),
          onExit:  (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: _pick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 160, height: 160,
              decoration: BoxDecoration(
                color: hasError ? _kRL : (_hovering ? _kPL : _kSurface),
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: _DottedBorderBox(
                isHovered: _hovering,
                hasError:  hasError,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: hasError
                            ? _kR.withOpacity(0.10)
                            : (_hovering ? _kP.withOpacity(0.12) : _kPL),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasError
                            ? Icons.error_outline_rounded
                            : Icons.cloud_upload_rounded,
                        size: 24,
                        color: hasError
                            ? _kR
                            : (_hovering ? _kP : const Color(0xFF93A8C9))),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasError ? 'Try again' : 'Click to upload',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: hasError ? _kR : (_hovering ? _kP : _kMuted),
                        decoration: TextDecoration.none)),
                    const SizedBox(height: 4),
                    const Text('PNG, JPG', style: TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8),
                      decoration: TextDecoration.none)),
                    const Text('(max 5 MB)', style: TextStyle(
                      fontSize: 10, color: Color(0xFF94A3B8),
                      decoration: TextDecoration.none)),
                  ]),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 2),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: _kR),
              const SizedBox(width: 5),
              Text(widget.logoError!, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: _kR, height: 1.2)),
            ]),
          ),
      ],
    ]);
  }
}

class _DottedBorderBox extends StatelessWidget {
  final Widget child;
  final bool isHovered;
  final bool hasError;
  const _DottedBorderBox({
    required this.child, required this.isHovered, this.hasError = false});

  @override Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(
      color: hasError ? _kR : (isHovered ? _kP : _kBorder)),
    child: SizedBox(width: 160, height: 160, child: Center(child: child)),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ..strokeWidth = 1.5 ..style = PaintingStyle.stroke;
    const dashWidth = 6.0, dashSpace = 4.0, radius = 16.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
        d += dashWidth + dashSpace;
      }
    }
  }
  @override bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
