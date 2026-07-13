import '../models/access_privileges.dart';
import '../services/program_service.dart';
import '../services/operational_log_service.dart';
import '../widgets/audit_details_dialog.dart';
import '../services/address_service.dart';
import '../validation/Validation.dart';
import '../services/profile_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/branch_service.dart';
import '../services/organization_service.dart';
import '../models/branch_model.dart';
import '../widgets/custom_calendar_dialog.dart';



// ── Brand colours ─────────────────────────────────────────────────────────────
const _kP      = Color(0xFF3D6EBE);
const _kPL     = Color(0xFFEEF3FB);
const _kPB     = Color(0xFFC5D3E8);
const _kR      = Color(0xFFDC2626);
const _kRL     = Color(0xFFFEF2F2);
const _kRB     = Color(0xFFFECACA);
const _kG      = Color(0xFF16A34A);
const _kGL     = Color(0xFFDCFCE7);
const _kGB     = Color(0xFFBBF7D0);
const _kO      = Color(0xFFF97316);
const _kOB     = Color(0xFFFED7AA);
const _kOBG    = Color(0xFFFFF7ED);
const _kOT     = Color(0xFFC2410C);
const _kWarnBG = Color(0xFFFFFBEB);
const _kWarnB  = Color(0xFFFDE68A);
const _kWarnT  = Color(0xFFB45309);
const _kText   = Color(0xFF1E293B);
const _kMuted  = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface= Color(0xFFF8FAFC);
const _kRowAlt = Color(0xFFF0F5FD);

// ── Country data (full A-Z list with mobileLength) ────────────────────────────
class _CountryInfo {
  final String code, name, flag, dialCode;
  final int mobileLength;
  const _CountryInfo({
    required this.code, required this.name, required this.flag,
    required this.dialCode, this.mobileLength = 10,
  });
}

_CountryInfo _mapDbToCountryInfo(Map<String, dynamic> c) {
  final code = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toUpperCase();
  final name = (c['countryname'] ?? c['name'] ?? '').toString().trim();
  final dialCode = (c['callcode'] ?? c['dialCode'] ?? '').toString().replaceAll('+', '').trim();
  
  return _CountryInfo(
    code: code,
    name: name,
    flag: '',
    dialCode: dialCode,
    mobileLength: 10,
  );
}

// ── View enum ──────────────────────────────────────────────────────────────────
enum _V { list, create, view, edit, delete }

// ── Data model ─────────────────────────────────────────────────────────────────
class _Branch {
  String orgCode, branchCode, branchName, openDate, country, division, pincode;
  String telephone, email, status, headBranch;
  String a1, a2, a3, a4, a5;
  String? cuser, cdate, euser, edate, auser, adate;

  _Branch({
    required this.orgCode, required this.branchCode, required this.branchName,
    required this.openDate, required this.country, required this.division,
    required this.pincode,
    required this.telephone, required this.email, required this.status,
    required this.headBranch,
    this.a1='', this.a2='', this.a3='', this.a4='', this.a5='',
    this.cuser, this.cdate, this.euser, this.edate, this.auser, this.adate,
  });

  bool get active {
    final n = status.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return n == '1' || n == 'active' || n == 'true';
  }

  _Branch cp({
    String? orgCode, String? branchCode, String? branchName, String? openDate,
    String? country, String? division, String? pincode, String? telephone, String? email,
    String? status, String? headBranch,
    String? a1, String? a2, String? a3, String? a4, String? a5,
  }) => _Branch(
    orgCode: orgCode ?? this.orgCode, branchCode: branchCode ?? this.branchCode,
    branchName: branchName ?? this.branchName, openDate: openDate ?? this.openDate,
    country: country ?? this.country, division: division ?? this.division,
    pincode: pincode ?? this.pincode,
    telephone: telephone ?? this.telephone, email: email ?? this.email,
    status: status ?? this.status, headBranch: headBranch ?? this.headBranch,
    a1: a1 ?? this.a1, a2: a2 ?? this.a2, a3: a3 ?? this.a3,
    a4: a4 ?? this.a4, a5: a5 ?? this.a5,
    cuser: this.cuser, cdate: this.cdate, euser: this.euser, edate: this.edate, auser: this.auser, adate: this.adate,
  );
}

// ── Toast ──────────────────────────────────────────────────────────────────────
class _BranchToast {
  static OverlayEntry? _current;
  static void show(BuildContext context, String message, {bool isError = false}) {
    _current?.remove(); _current = null;
    final bg = isError ? _kRL : _kGL;
    final fg = isError ? _kR : _kG;
    final border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
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
  final String message; final Color bg, fg, border; final IconData icon; final VoidCallback onDismiss;
  const _ToastWidget({required this.message, required this.bg, required this.fg,
    required this.border, required this.icon, required this.onDismiss});
  @override State<_ToastWidget> createState() => _ToastWidgetState();
}
class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _slide, _fade;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<double>(begin: -80, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Positioned(
    top: 24, left: 0, right: 0,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(offset: Offset(0, _slide.value), child: Opacity(opacity: _fade.value, child: child)),
      child: Center(child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: widget.bg, border: Border.all(color: widget.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 18, color: widget.fg), const SizedBox(width: 10),
          Flexible(child: Text(widget.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: widget.fg, decoration: TextDecoration.none, decorationColor: Colors.transparent))),
          const SizedBox(width: 10),
          GestureDetector(onTap: widget.onDismiss, child: Icon(Icons.close_rounded, size: 16, color: widget.fg)),
        ]),
      )),
    ),
  );
}

class Branches extends StatefulWidget {
  // ── FIX 1: added isAdmin + adminOrgCode params ────────────────────────────
  final bool isAdmin;
  final String? adminOrgCode; // pass logged-in admin's orgCode string, e.g. "5"
  final AccessPrivileges? accessPrivileges;
  const Branches({super.key, this.isAdmin = false, this.adminOrgCode = '', this.accessPrivileges});
  @override State<Branches> createState() => _BranchesState();
}

class _BranchesState extends State<Branches> {
  _V _view = _V.list;
  _Branch? _sel;
  bool _delConfirmed = false;
  String _search = '';
  String _orgFilter = '';
  bool _isLoading = true;
  List<_Branch> _data = [];
  List<Map<String, dynamic>> _orgs = [];
  List<Map<String, dynamic>> _apiCountries = [];

  int _page = 0;
  int _totalElements = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  String? _loadError;
  Timer? _debounce;
  int? _branchPgmId;

  @override
  void initState() {
    super.initState();
    // ── FIX 2: pre-lock filter to admin's org from the start ─────────────────
    if (widget.isAdmin && widget.adminOrgCode != null && widget.adminOrgCode!.isNotEmpty) {
      _orgFilter = widget.adminOrgCode!;
    }
    _loadBranches();
    _loadOrgs();
    _prefetchCountries();
    _fetchBranchProgramId();
  }

  Future<void> _fetchBranchProgramId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final pgm = programs.firstWhere(
        (p) => p.descn.toLowerCase().trim() == 'branches' || p.descn.toLowerCase().trim() == 'branch',
      );
      _branchPgmId = pgm.pgmId;
      debugPrint('Fetched branch program ID: $_branchPgmId');
    } catch (e) {
      debugPrint('Error fetching branch program ID: $e');
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

  _CountryInfo? _findCountryFromApi(String codeOrName) {
    if (codeOrName.isEmpty) return null;
    final lower = codeOrName.toLowerCase();
    for (final c in _apiCountries) {
      final ccode = (c['countrycode'] ?? c['code'] ?? '').toString().trim().toLowerCase();
      final cname = (c['countryname'] ?? c['name'] ?? '').toString().trim().toLowerCase();
      if (ccode == lower || cname == lower) {
        return _mapDbToCountryInfo(c);
      }
    }
    final code = codeOrName.length == 2 ? codeOrName.toUpperCase() : '';
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
      name: codeOrName,
      flag: flag,
      dialCode: '',
      mobileLength: 10,
    );
  }

  Future<void> _loadOrgs() async {
    try {
      final raw = await OrganizationService().getAllOrganizations();
      if (mounted) setState(() => _orgs = raw);
    } catch (_) {}
  }

   String _getOrgName(String code) {
    final org = _orgs.firstWhere((o) => o['orgcode']?.toString() == code, orElse: () => {});
    return (org['name'] ?? '').toString();
  }

  String _buildOrgDisplay(String code) {
    if (code.isEmpty) return '';
    final o = _orgs.firstWhere((e) => e['orgcode']?.toString() == code, orElse: () => <String, dynamic>{});
    if (o.isEmpty) return code;
    final name = (o['name'] ?? '').toString();
    return name.isEmpty ? code : '$code - $name';
  }

  String _formatDateForFrontend(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      if (RegExp(r'^\d{2}-[a-zA-Z]{3}-\d{4}$').hasMatch(dateStr)) return dateStr;
      DateTime? d;
      if (dateStr.contains('T')) {
        d = DateTime.tryParse(dateStr);
      } else {
        final parts = dateStr.split('-');
        if (parts.length == 3 && parts[0].length == 4) {
          d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      }
      if (d != null) {
        const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        return '${d.day.toString().padLeft(2,'0')}-${ms[d.month - 1]}-${d.year}';
      }
    } catch (_) {}
    return dateStr;
  }

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2,'0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2,'0')}:$m $p';
    } catch (_) { return dateStr; }
  }

  Future<void> _loadBranches() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final limit = 10;
      final offset = _page * 10;
      
      final filterOrgCode = _orgFilter.isNotEmpty ? int.tryParse(_orgFilter) : null;
      
      final result = await BranchService().getBranchesPaginated(
        offset: offset,
        limit: limit,
        search: _search,
        orgCode: filterOrgCode,
      );
      
      if (mounted) {
        final List<dynamic> content = result['content'] ?? [];
        setState(() {
          _data = content.map((bJson) {
            final b = Branch.fromJson(bJson);
            return _Branch(
              orgCode: b.orgCode.toString(),
              branchCode: b.branchCode.toString(),
              branchName: b.branchName,
              openDate: _formatDateForFrontend(b.openDate ?? ''),
              country: b.country ?? '',
              division: b.divisionName ?? '',
              pincode: b.pincode ?? '',
              telephone: b.telephone ?? '',
              email: b.email ?? '',
              status: b.status == true ? 'Active' : 'Inactive',
              headBranch: b.headBranch == true ? '1' : '0',
              a1: b.addressLine1 ?? '', a2: b.addressLine2 ?? '', a3: b.addressLine3 ?? '',
              a4: b.addressLine4 ?? '', a5: b.addressLine5 ?? '',
              cuser: b.cuser, cdate: _formatAuditDate(b.cdate),
              euser: b.euser, edate: _formatAuditDate(b.edate),
              auser: b.auser, adate: _formatAuditDate(b.adate),
            );
          }).toList();
          
          _totalElements = result['totalElements'] as int? ?? 0;
          _activeCount = result['activeCount'] as int? ?? 0;
          _inactiveCount = result['inactiveCount'] as int? ?? 0;
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

  List<_Branch> get _filtered => _data;

  void _go(_V v, [_Branch? r]) {
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
      _loadBranches();
    }
  }

  void _toast(String msg, {bool isError = false}) => _BranchToast.show(context, msg, isError: isError);

  void _showHeadBranchWarningDialog(BuildContext context, String orgLabel) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFFED7AA), width: 1.5),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: Color(0xFFEA580C),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Head Branch Already Exists',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The organization "$orgLabel" already has an active Head Branch.\n\nOnly one Head Branch can be created or set per organization.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: _kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _kP,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _kP.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Understood',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  // ── Common helpers ─────────────────────────────────────────────────────────
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

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
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
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _kBorder)),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      );

  Widget _secHdr(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 1)),
    ]),
  );

  Widget _statusBadge(bool active) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: active ? _kGL : _kRL, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? _kG : _kR, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? _kG : _kR)),
      ]),
    ),
  );

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

  // ── LIST ───────────────────────────────────────────────────────────────────
  int _getPageOffset(int p) {
    return p * 10;
  }

  bool _hasNextPage() {
    final nextOffset = _getPageOffset(_page + 1);
    return nextOffset < _totalElements;
  }

  Widget _list() {
    final active = _activeCount;
    final inactive = _inactiveCount;
    final filtered = _filtered;

    return StatefulBuilder(builder: (ctx, ls) {
      final pageItems = filtered;
      final start = filtered.isEmpty ? 0 : _getPageOffset(_page) + 1;
      final end = _getPageOffset(_page) + pageItems.length;

      return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Branches'),

        Row(children: [
          _statCard('$_totalElements', 'Total Branches', _kP, _kPL, _kPB, Icons.account_tree_rounded, _kP),
          const SizedBox(width: 10),
          _statCard('$active', 'Active', _kG, _kGL, _kGB, Icons.check_circle_outline_rounded, _kG),
          const SizedBox(width: 10),
          _statCard('$inactive', 'Inactive', _kR, _kRL, _kRB, Icons.block_rounded, _kR),
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
                _loadBranches();
              });
            },
          ),
          // Only show org filter for non-admin users
          if (!widget.isAdmin) ...[
            const SizedBox(width: 10),
            _OrgFilterButton(
              selectedOrgCode: _orgFilter.isEmpty ? null : _orgFilter,
              organizations: _orgs,
              onChanged: (v) {
                ls(() {
                  _orgFilter = v ?? '';
                  _page = 0;
                });
                _loadBranches();
              },
            ),
          ],
          if (widget.accessPrivileges?.canCreate ?? true) ...[
            const SizedBox(width: 10),
            _hBtn('New Branch', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.add_rounded, onTap: () => _go(_V.create)),
          ],
        ]),
        const SizedBox(height: 14),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Column(children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading branches...')])),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Failed to load branches: $_loadError', style: const TextStyle(color: Colors.red))),
          )
        else
          _card(child: LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final cols = [w * 0.20, w * 0.12, w * 0.20, w * 0.13, w * 0.10, w * 0.12, w * 0.13];

            Widget rowWidget(List<Widget> cells, List<double> widths, {bool isHeader = false, bool isEven = false, bool isHovered = false}) {
              Color rowBg;
              if (isHeader) rowBg = _kP;
              else if (isHovered) rowBg = _kPL;
              else if (isEven) rowBg = _kRowAlt;
              else rowBg = Colors.white;
              return Container(
                decoration: BoxDecoration(color: rowBg, border: Border(bottom: BorderSide(color: isHeader ? Colors.transparent : const Color(0xFFF1F5F9)))),
                child: Row(children: List.generate(widths.length, (i) => SizedBox(width: widths[i], child: cells[i]))),
              );
            }

            headerCell(String t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Center(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5))),
            );

            return Column(children: [
              rowWidget([
                headerCell('ORGANIZATION'), headerCell('BRANCH CODE'), headerCell('BRANCH NAME'),
                headerCell('COUNTRY'), headerCell('HEAD BRANCH'), headerCell('STATUS'), headerCell('ACTIONS'),
              ], cols, isHeader: true),

              ...pageItems.asMap().entries.map((entry) {
                final idx = entry.key; final r = entry.value; final isEven = idx % 2 == 1;
                return StatefulBuilder(builder: (_, rss) {
                  bool hovered = false;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => rss(() => hovered = true),
                    onExit: (_) => rss(() => hovered = false),
                    child: rowWidget([
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: Text(_buildOrgDisplay(r.orgCode), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kP), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: Text(r.branchCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kP)))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: Text(r.branchName, style: const TextStyle(fontSize: 12.5, color: _kText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: Text(_findCountryFromApi(r.country)?.name ?? r.country, style: const TextStyle(fontSize: 12.5, color: _kText), maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: _yesNoBadge(r.headBranch == '1'))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Center(child: _statusBadge(r.active))),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                          ...[
                            if (widget.accessPrivileges?.canView ?? true)
                              _rowBtn(Icons.visibility_outlined, const Color(0xFF475569), () => _go(_V.view, r)),
                            if (widget.accessPrivileges?.canEdit ?? true)
                              _rowBtn(Icons.edit_outlined, _kP, () => _go(_V.edit, r)),
                            if (widget.accessPrivileges?.canDelete ?? true)
                              _rowBtn(Icons.delete_outline_rounded, _kR, () => _go(_V.delete, r)),
                          ].map((btn) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.5),
                            child: btn,
                          )),
                        ]))),
                    ], cols, isEven: isEven, isHovered: hovered),
                  );
                });
              }),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(filtered.isEmpty ? 'No records found' : 'Showing $start–$end of $_totalElements records',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  Row(children: [
                    _pageBtn('‹ Prev', enabled: _page > 0, onTap: () {
                      ls(() => _page--);
                      _loadBranches();
                    }),
                    const SizedBox(width: 6),
                    _pageBtn('Next ›', enabled: _hasNextPage(), onTap: () {
                      ls(() => _page++);
                      _loadBranches();
                    }),
                  ]),
                ]),
              ),
            ]);
          })),
      ]));
    });
  }

  Widget _yesNoBadge(bool yes) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: yes ? _kPL : _kSurface, borderRadius: BorderRadius.circular(20)),
      child: Text(yes ? 'Yes' : 'No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: yes ? _kP : _kMuted)),
    ),
  );

  // ── CREATE / EDIT ──────────────────────────────────────────────────────────
  Widget _form({required bool isEdit}) {
    final r = isEdit ? _sel : null;
    // For edit: show existing branch org. For create+admin: show admin's org.
    // _orgs may still be loading here; StatefulBuilder inside will re-sync once loaded.
    final String initialOrgText = r != null
        ? r.orgCode
        : (widget.isAdmin && widget.adminOrgCode != null && widget.adminOrgCode!.isNotEmpty
            ? widget.adminOrgCode!
            : '');
    final cOrg = TextEditingController(text: initialOrgText);

    _CountryInfo? _countryForOrgLabel(String label) {
      final code = label.contains(' - ') ? label.split(' - ').first.trim() : label.trim();
      if (code.isEmpty) return null;
      final org = _orgs.firstWhere((e) => e['orgcode']?.toString() == code, orElse: () => <String, dynamic>{});
      if (org.isEmpty) return null;
      final rawCountry = (org['country'] ?? org['countryCode'] ?? org['country_code'])?.toString().trim() ?? '';
      return _findCountryFromApi(rawCountry);
    }

    _CountryInfo? selectedCountry;
    if (r != null) {
      selectedCountry = r.country.isNotEmpty == true ? _findCountryFromApi(r.country) : null;
    } else {
      _CountryInfo? orgCountry;
      if (cOrg.text.isNotEmpty && _orgs.isNotEmpty) {
        orgCountry = _countryForOrgLabel(cOrg.text);
      }
      if (orgCountry != null) {
        selectedCountry = orgCountry;
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

    final cBCode  = TextEditingController(text: r?.branchCode ?? '');
    final cBName  = TextEditingController(text: r?.branchName ?? '');
    final cDate   = TextEditingController(text: r?.openDate ?? '');
    final cTel    = TextEditingController(text: initialTel);
    final cEmail  = TextEditingController(text: r?.email ?? '');
    final cStat   = TextEditingController(text: r?.status.isNotEmpty == true ? r!.status : '');
    final cDiv    = TextEditingController(text: r?.division ?? '');
    final cPin    = TextEditingController(text: r?.pincode ?? '');
    final cHB     = TextEditingController(text: r?.headBranch == '1' ? 'Yes' : (r != null ? 'No' : ''));
    final cA1     = TextEditingController(text: r?.a1 ?? '');
    final cA2     = TextEditingController(text: r?.a2 ?? '');
    final cA3     = TextEditingController(text: r?.a3 ?? '');
    final cA4     = TextEditingController(text: r?.a4 ?? '');
    final cA5     = TextEditingController(text: r?.a5 ?? '');

    final mobileFocusNode = FocusNode();
    final emailFocusNode  = FocusNode();
    final errors = <String, String?>{};

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

    bool orgHasHeadBranch = false;
    bool checkingHeadBranch = false;
    bool initialCheckDone = false;

    Future<void> checkOrgHeadBranch(String orgCodeText, StateSetter ls) async {
      final code = orgCodeText.contains(' - ')
          ? orgCodeText.split(' - ').first.trim()
          : orgCodeText.trim();
      if (code.isEmpty) {
        ls(() {
          orgHasHeadBranch = false;
        });
        return;
      }
      ls(() {
        checkingHeadBranch = true;
      });
      try {
        final orgCodeInt = int.tryParse(code);
        if (orgCodeInt != null) {
          final result = await BranchService().getBranchesPaginated(
            offset: 0,
            limit: 100,
            orgCode: orgCodeInt,
          );
          final List<dynamic> content = result['content'] ?? [];
          final hasHB = content.any((bJson) {
            final b = Branch.fromJson(bJson);
            return b.headBranch == true &&
                (!isEdit || b.branchCode.toString() != (r?.branchCode ?? ''));
          });
          ls(() {
            orgHasHeadBranch = hasHB;
            checkingHeadBranch = false;
            if (hasHB && cHB.text != 'No') {
              cHB.text = 'No';
            }
          });
        } else {
          ls(() {
            orgHasHeadBranch = false;
            checkingHeadBranch = false;
          });
        }
      } catch (e) {
        debugPrint('Error checking head branch: $e');
        ls(() {
          checkingHeadBranch = false;
        });
      }
    }

    return StatefulBuilder(builder: (ctx, ls) {
      // ── FIX 5: re-sync admin org text after async _loadOrgs completes ────────
      // cOrg may have been empty at first build if _orgs wasn't loaded yet.
      if (widget.isAdmin && widget.adminOrgCode != null && widget.adminOrgCode!.isNotEmpty &&
          cOrg.text.isEmpty && _orgs.isNotEmpty) {
        cOrg.text = widget.adminOrgCode!;
      }

      final currentOrgCode = cOrg.text.trim().contains(' - ')
          ? cOrg.text.trim().split(' - ').first.trim()
          : cOrg.text.trim();

      if (!initialCheckDone && currentOrgCode.isNotEmpty) {
        initialCheckDone = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          checkOrgHeadBranch(cOrg.text, ls);
        });
      }

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

      // Live listeners
      cBCode.addListener(() { if (cBCode.text.isEmpty) clearError('bcode'); else { final e = orgncodevalid(cBCode.text); e != null ? ls(() => errors['bcode'] = e) : clearError('bcode'); } });
      cBName.addListener(() { if (cBName.text.isEmpty) clearError('bname'); else { final e = orgnamevalid(cBName.text); e != null ? ls(() => errors['bname'] = e) : clearError('bname'); } });
      cDate.addListener(() { if (cDate.text.isNotEmpty) clearError('date'); });
      cHB.addListener(() { if (cHB.text.isNotEmpty) clearError('hb'); });
      cStat.addListener(() { if (cStat.text.isNotEmpty) clearError('status'); });
      cDiv.addListener(() { if (cDiv.text.isNotEmpty) clearError('division'); });
      // cPin.addListener(() {
      //   final text = cPin.text;
      //   if (text.isEmpty) clearError('pincode');
      //   else { final e = pincodevalid(text); e != null ? ls(() => errors['pincode'] = e) : clearError('pincode'); }
      // });
      cA1.addListener(() { if (cA1.text.isNotEmpty) clearError('a1'); });
      cA4.addListener(() { if (cA4.text.isNotEmpty) clearError('a4'); });
      cA5.addListener(() { if (cA5.text.isNotEmpty) clearError('a5'); });

      mobileFocusNode.addListener(() {
        if (!mobileFocusNode.hasFocus) {
          final text = cTel.text.trim();
          if (text.isEmpty) ls(() => errors['telephone'] = 'Mobile is required');
          else if (text.length != mobileLen) ls(() => errors['telephone'] = 'Must be exactly $mobileLen digits');
          else { final err = mobilenumbervalid(text); err != null ? ls(() => errors['telephone'] = err) : clearError('telephone'); }
        } else { clearError('telephone'); }
      });

      emailFocusNode.addListener(() {
        if (!emailFocusNode.hasFocus && cEmail.text.isNotEmpty) {
          final e = emailvalid(cEmail.text);
          e != null ? ls(() => errors['email'] = e) : clearError('email');
        } else if (emailFocusNode.hasFocus || cEmail.text.isEmpty) {
          clearError('email');
        }
      });

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
        if (cOrg.text.trim().isEmpty) e['org'] = 'Organization is required';
        if (cBCode.text.trim().isEmpty) e['bcode'] = 'Branch Code is required';
        else { final err = orgncodevalid(cBCode.text.trim()); if (err != null) e['bcode'] = err; }
        if (cBName.text.trim().isEmpty) e['bname'] = 'Branch Name is required';
        else { final err = orgnamevalid(cBName.text.trim()); if (err != null) e['bname'] = err; }
        if (cHB.text.trim().isEmpty) e['hb'] = 'Head Branch is required';
        else if (cHB.text.trim() == 'Yes' && orgHasHeadBranch) {
          e['hb'] = 'A Head Branch already exists for this organization';
        }
        if (cStat.text.trim().isEmpty) e['status'] = 'Status is required';
        if (cDiv.text.trim().isEmpty) e['division'] = 'Industry Division is required';
        if (cDate.text.trim().isEmpty) e['date'] = 'Open Date is required';
        if (selectedCountry == null) e['country'] = 'Country is required';
        // if (cPin.text.trim().isEmpty) e['pincode'] = 'Pincode is required';
        // else { final err = pincodevalid(cPin.text); if (err != null) e['pincode'] = err; }
        if (cTel.text.trim().isEmpty) e['telephone'] = 'Mobile is required';
        else if (cTel.text.trim().length != mobileLen) e['telephone'] = 'Must be exactly $mobileLen digits';
        else { final err = mobilenumbervalid(cTel.text.trim()); if (err != null) e['telephone'] = err; }
        if (cEmail.text.trim().isEmpty) e['email'] = 'Email is required';
        else if (!cEmail.text.trim().contains('@')) e['email'] = 'Enter a valid email with @';
        else { final err = emailvalid(cEmail.text); if (err != null) e['email'] = err; }
        if (selState   == null) e['addrState'] = 'State is required';
        if (selCity    == null) e['addrCity']  = 'City is required';
        if (selPincode == null) e['addrPin']   = 'Pincode is required';
        ls(() => errors..clear()..addAll(e));
        return e.isEmpty;
      }

      Future<void> save() async {
        if (!validate()) { _BranchToast.show(context, 'Please fill all required fields.', isError: true); return; }

        final orgCodeRaw = cOrg.text.trim().contains(' - ')
            ? cOrg.text.trim().split(' - ').first.trim()
            : cOrg.text.trim();

        final stateName  = selState   != null ? gStr(selState!,   stateKeys) : '';
        final cityName   = selCity    != null ? gStr(selCity!,    cityKeys)  : '';
        final pinValue   = selPincode != null ? gStr(selPincode!, pinKeys)   : cPin.text.trim();

        final branch = Branch(
          orgCode: int.tryParse(orgCodeRaw) ?? 0,
          branchCode: int.tryParse(cBCode.text.trim()) ?? 0,
          branchName: cBName.text.trim(),
          openDate: formatDateForBackend(cDate.text.trim()),
          country: selectedCountry?.code ?? '',
          divisionName: cDiv.text.trim().isEmpty ? null : cDiv.text.trim(),
          pincode: pinValue.isEmpty ? null : pinValue,
          telephone: cTel.text.trim().isEmpty ? null : cTel.text.trim(),
          email: cEmail.text.trim().isEmpty ? null : cEmail.text.trim(),
          status: cStat.text.trim() == 'Active',
          headBranch: cHB.text.trim() == 'Yes',
          addressLine1: stateName.isEmpty ? null : stateName,
          addressLine2: cityName.isEmpty ? null : cityName,
          addressLine3: cA3.text.trim().isEmpty ? null : cA3.text.trim(),
          addressLine4: cA4.text.trim().isEmpty ? null : cA4.text.trim(),
          addressLine5: pinValue.isEmpty ? null : pinValue,
          pgmId:  _branchPgmId ,
        );

        try {
          if (isEdit) {
            await BranchService().updateBranch(int.parse(_sel!.branchCode), branch);
            OperationalLogService().logAction(programId: 'BRANCHES', action: 'U');
            _toast('Branch updated successfully!');
          } else {
            await BranchService().createBranch(branch);
            OperationalLogService().logAction(programId: 'BRANCHES', action: 'I');
            _toast('Branch created successfully!');
          }
          await _loadBranches();
          _go(_V.list);
        } catch (e) {
          _BranchToast.show(context, 'Failed to save branch: $e', isError: true);
        }
      }

      return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isEdit ? 'Edit Branch' : 'Add New Branch',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kText, letterSpacing: -0.3),
                ),
              ),
              _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
            ],
          ),
        ),

        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEdit ? 'Edit Branch Details' : 'Branch Details',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kText)),
                const SizedBox(height: 2),
                Text(isEdit ? 'Locked fields cannot be changed' : 'Fill all required fields marked with *',
                  style: const TextStyle(fontSize: 11, color: _kMuted)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: isEdit ? _kOBG : _kPL, borderRadius: BorderRadius.circular(20), border: Border.all(color: isEdit ? _kOB : _kPB)),
                child: Text(isEdit ? 'EDIT MODE' : 'NEW RECORD',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isEdit ? _kOT : _kP)),
              ),
            ]),
          ),


          // Main fields grid
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
                // 1. Organization
                // ── FIX 7: readOnly = isEdit OR isAdmin ───────────────────────
                _OrgDropdownField(
                  label: 'Organization',
                  controller: cOrg,
                  organizations: widget.isAdmin
                      ? _orgs.where((o) => o['orgcode']?.toString() == widget.adminOrgCode).toList()
                      : _orgs,
                  readOnly: isEdit || widget.isAdmin,
                  showLock: isEdit || widget.isAdmin,
                  isRequired: true,
                  errorText: errors['org'],
                  onChanged: (v) => ls(() {
                    final newCountry = _countryForOrgLabel(v);
                    if (newCountry?.code != selectedCountry?.code) {
                      cTel.text = '';
                      // Reset cascading address on country change
                      selState = null; apiStates = [];
                      selCity  = null; apiCities = [];
                      selPincode = null; apiPincodes = [];
                      errors.remove('addrState'); errors.remove('addrCity'); errors.remove('addrPin');
                      if (newCountry != null) {
                        fetchStatesForCode(newCountry.code);
                      }
                    }
                    cOrg.text = v;
                    selectedCountry = newCountry;
                    errors.remove('org');
                    if (newCountry != null) errors.remove('country');
                    checkOrgHeadBranch(v, ls);
                  }),
                ),
                // 2. Branch Code (locked in edit)
                _FloatingLabelField(
                  label: 'Branch Code', ctrl: cBCode, icon: Icons.account_tree_rounded,
                  hint: 'Enter branch code', readOnly: isEdit, showLock: isEdit, required: true, errorText: errors['bcode'],
                  maxLength: 5,
                  inputFormatters: [_BranchRejectingFormatter(RegExp(r'^\d*$'), () => ls(() => errors['bcode'] = 'Only numbers allowed'))],
                ),
                // 3. Branch Name
                _FloatingLabelField(
                  label: 'Branch Name', ctrl: cBName, icon: Icons.store_mall_directory_outlined,
                  hint: 'Enter branch name', required: true, errorText: errors['bname'],
                  maxLength: 30,
                ),
                // 4. Head Branch toggle
                _BranchToggle(
                  label: 'Head Branch',
                  icon: Icons.star_outline_rounded,
                  isActive: cHB.text == 'Yes',
                  trueLabel: 'Yes', falseLabel: 'No',
                  activeColor: _kG,
                  readOnly: false,
                  subtext: null,
                  onChanged: (v) {
                    if (orgHasHeadBranch && v) {
                      _showHeadBranchWarningDialog(context, cOrg.text);
                      return;
                    }
                    ls(() {
                      cHB.text = v ? 'Yes' : 'No';
                      errors.remove('hb');
                    });
                  },
                  hasError: errors['hb'] != null,
                ),
                // 5. Open Date (no future dates)
                _FloatingLabelField(
                  label: 'Open Date', ctrl: cDate, icon: Icons.calendar_today_rounded,
                  hint: 'Choose date', required: true, errorText: errors['date'],
                  isDatePicker: true, maxDate: maxOpenDate,
                ),
                // 6. Country
                _BranchCountryPickerField(
                  label: 'Country',
                  selectedCountry: selectedCountry,
                  countries: _apiCountries.map((c) => _mapDbToCountryInfo(c)).toList(),
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
                // 7. Mobile
                _BranchMobileField(
                  controller: cTel,
                  dialCode: selectedCountry?.dialCode,
                  mobileLength: mobileLen,
                  errorText: errors['telephone'],
                  focusNode: mobileFocusNode,
                ),
                // 8. Email
                _FloatingLabelField(
                  label: 'Email', ctrl: cEmail, icon: Icons.email_outlined,
                  hint: 'Enter email address', required: true, errorText: errors['email'],
                  focusNode: emailFocusNode,
                  inputFormatters: [_BranchRejectingFormatter(RegExp(r'^[^\s]*$'), () => ls(() => errors['email'] = 'Spaces not allowed'))],
                ),
                // 9. Pincode
                // _FloatingLabelField(
                //   label: 'Pincode', ctrl: cPin, icon: Icons.location_on_outlined,
                //   hint: 'Enter pincode', required: true, errorText: errors['pincode'],
                //   maxLength: 6,
                //   inputFormatters: [_BranchRejectingFormatter(RegExp(r'^\d*$'), () => ls(() => errors['pincode'] = 'Only numbers allowed'))],
                // ),
                // 10. Industry Division
                _FloatingLabelField(
                  label: 'Industry Division', ctrl: cDiv, icon: Icons.account_balance_outlined,
                  hint: 'Enter industry division', required: true, errorText: errors['division'],
                  maxLength: 5,
                  inputFormatters: [_BranchRejectingFormatter(RegExp(r'^\d*$'), () => ls(() => errors['division'] = 'Only numbers allowed'))],
                ),
                // 11. Status toggle
                _BranchToggle(
                  label: 'Status',
                  icon: Icons.signal_cellular_alt_rounded,
                  isActive: cStat.text == 'Active',
                  trueLabel: 'Active', falseLabel: 'Inactive',
                  activeColor: _kG,
                  onChanged: (v) => ls(() {
                    cStat.text = v ? 'Active' : 'Inactive';
                    errors.remove('status');
                  }),
                  hasError: errors['status'] != null,
                ),
              ],
            ),
          ),

          // Address section
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
                _BranchApiDropdownField(
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
                _BranchApiDropdownField(
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
                _FloatingLabelField(label: 'Address Line 3', ctrl: cA3, icon: Icons.format_list_bulleted_rounded, hint: 'Street / Area', maxLength: 20),
                // Address Line 4 — free text
                _FloatingLabelField(label: 'Address Line 4', ctrl: cA4, icon: Icons.format_list_bulleted_rounded, hint: 'Landmark', maxLength: 20),
                // Address Line 5 → Pincode dropdown
                _BranchApiDropdownField(
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
                      if (item != null) {
                        cPin.text = gStr(item, pinKeys);
                        errors.remove('pincode');
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _kBorder))),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              _fBtn('Cancel', Icons.close_rounded, Colors.white, _kP, _kP, onTap: () => _go(_V.list)),
              const SizedBox(width: 10),
              _fBtn(isEdit ? 'Update' : 'Create', Icons.check_rounded, _kP, Colors.white, _kP, onTap: save),
            ]),
          ),
        ])),
      ]));
    });
  }

  // ── VIEW DETAIL ────────────────────────────────────────────────────────────
  Widget _detail() {
    final r = _sel!;
    final ci = _findCountryFromApi(r.country);

    ro(String label, String val, IconData icon, {String? sub}) => _FloatingLabelField(
      label: label, ctrl: TextEditingController(text: val), icon: icon, readOnly: true, subtext: sub,
    );

    return _page_(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          children: [
            const Expanded(
              child: Text('Branch Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _kText, letterSpacing: -0.3)),
            ),
            _hBtn('Audit Details', bg: Colors.white, fg: _kP, border: _kP, icon: Icons.history_rounded, onTap: () => AuditDetailsDialog.show(
              context,
              cuser: r.euser,
              cdate: r.edate,
              euser: r.cuser,
              edate: r.cdate,
              auser: r.auser,
              adate: r.adate,
              subtitle: 'Branch audit trail for ${r.branchName}',
            )),
            const SizedBox(width: 10),
            _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
          ],
        ),
      ),
      _card(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFEEF3FB), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
            border: Border(bottom: BorderSide(color: _kBorder)),
          ),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_tree_rounded, size: 22, color: Colors.white)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.branchName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kP)),
              const SizedBox(height: 2),
              Text('Org: ${r.orgCode} • Branch: ${r.branchCode} • Created: ${r.openDate}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: r.active ? _kGL : _kRL, borderRadius: BorderRadius.circular(20), border: Border.all(color: r.active ? _kGB : _kRB)),
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
          child: GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4, mainAxisSpacing: 28, crossAxisSpacing: 18,
            childAspectRatio: 2.5,
            children: [
              ro('Organization', r.orgCode, Icons.apartment_rounded, sub: _getOrgName(r.orgCode)),
              ro('Branch Code', r.branchCode, Icons.account_tree_rounded),
              ro('Branch Name', r.branchName, Icons.store_mall_directory_outlined),
              _BranchToggle(
                label: 'Head Branch',
                icon: Icons.star_outline_rounded,
                isActive: r.headBranch == '1',
                trueLabel: 'Yes', falseLabel: 'No',
                activeColor: _kG,
                onChanged: (_) {},
                readOnly: true,
              ),
              ro('Open Date', r.openDate, Icons.calendar_today_rounded),
              ro('Country', ci != null ? ci.name : r.country, Icons.language_rounded),
              Builder(builder: (context) {
                String displayTelephone = r.telephone;
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
              // ro('Pincode', r.pincode.isEmpty ? '—' : r.pincode, Icons.location_on_outlined),
              ro('Industry Division', r.division.isEmpty ? '—' : r.division, Icons.account_balance_outlined),
              _BranchToggle(
                label: 'Status',
                icon: Icons.signal_cellular_alt_rounded,
                isActive: r.active,
                trueLabel: 'Active', falseLabel: 'Inactive',
                activeColor: _kG,
                onChanged: (_) {},
                readOnly: true,
              ),
            ],
          ),
        ),

        Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: _secHdr('ADDRESS')),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
          child: GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4, mainAxisSpacing: 28, crossAxisSpacing: 18,
            childAspectRatio: 2.5,
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
      _pageHeader(title: 'Delete Branch'),
      _card(child: Column(children: [
        Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), color: _kRL,
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.delete_outline_rounded, size: 20, color: _kR), SizedBox(width: 8),
            Text('Delete Confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kR)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(22), child: Column(children: [
          const Text('Are you sure you want to delete this record? This action cannot be undone.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _kBorder), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('RECORD TO BE DELETED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
              const SizedBox(height: 10),
              _delRow('Org Code:', r.orgCode, isRed: true),
              const SizedBox(height: 6),
              _delRow('Branch Code:', r.branchCode, isRed: true),
              const SizedBox(height: 6),
              _delRow('Branch Name:', r.branchName),
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
        ])),
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
                  await BranchService().deleteBranch(int.parse(r.orgCode), int.parse(r.branchCode),pgmId: _branchPgmId);
                  OperationalLogService().logAction(programId: 'BRANCHES', action: 'D');
                  await _loadBranches();
                  _go(_V.list);
                  _toast('Branch deleted successfully!');
                } catch (e) {
                  _BranchToast.show(context, 'Failed to delete branch: $e', isError: true);
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

// ── Search Box ────────────────────────────────────────────────────────────────
class _SearchBox extends StatefulWidget {
  final double width; final ValueChanged<String> onChanged;
  const _SearchBox({required this.width, required this.onChanged});
  @override State<_SearchBox> createState() => _SearchBoxState();
}
class _SearchBoxState extends State<_SearchBox> {
  final FocusNode _focus = FocusNode(); bool _focused = false;
  @override void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override void dispose() { _focus.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width, height: 36,
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: _focused ? _kP : _kBorder, width: _focused ? 2.0 : 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _focused ? [BoxShadow(color: _kP.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : []),
    child: TextField(
      focusNode: _focus, onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search branches...',
        hintStyle: TextStyle(fontSize: 12, color: _focused ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1)),
        prefixIcon: Icon(Icons.search_rounded, size: 16, color: _focused ? _kP : const Color(0xFF94A3B8)),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true,
      ),
    ),
  );
}

// ── Org Filter Button (same as Users screen) ──────────────────────────────────
class _OrgFilterButton extends StatefulWidget {
  final String? selectedOrgCode;
  final List<Map<String, dynamic>> organizations;
  final ValueChanged<String?> onChanged;
  const _OrgFilterButton({this.selectedOrgCode, required this.organizations, required this.onChanged});
  @override State<_OrgFilterButton> createState() => _OrgFilterButtonState();
}
class _OrgFilterButtonState extends State<_OrgFilterButton> {
  final GlobalKey _key = GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController(); String _q = '';
  @override void dispose() { _rm(); _sc.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov = null; }

  // void _open() {
  //   _rm(); _sc.clear(); _q = '';
  //   final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
  //   final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
  //   final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;
  //   const dropW = 290.0;
  //   final left = pos.dx + sz.width - dropW;
  //   _ov = OverlayEntry(builder: (ctx) => GestureDetector(
  //     behavior: HitTestBehavior.translucent, onTap: _rm,
  //     child: Material(color: Colors.transparent, child: Stack(children: [
  //       Positioned(left: left, top: pos.dy + sz.height + 4, width: dropW,
  //         child: StatefulBuilder(builder: (c2, ss) => Material(
  //           elevation: 8, borderRadius: BorderRadius.circular(14),
  //           child: Container(
  //             constraints: const BoxConstraints(maxHeight: 260),
  //             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
  //             child: Column(mainAxisSize: MainAxisSize.min, children: [
  //               Padding(padding: const EdgeInsets.all(8), child: TextField(
  //                 controller: _sc, autofocus: true, onChanged: (v) => ss(() => _q = v),
  //                 style: const TextStyle(fontSize: 13, color: _kText),
  //                 decoration: InputDecoration(
  //                   hintText: 'Search organization...',
  //                   hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
  //                   prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
  //                   filled: true, fillColor: _kSurface,
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
  //                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
  //                   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
  //                   contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
  //                 ),
  //               )),
  //               const Divider(height: 1, color: _kBorder),
  //               Flexible(child: ListView(padding: const EdgeInsets.symmetric(vertical: 4), shrinkWrap: true, children: [
  //                 _item(c2, null, 'All Organizations', '', ss),
  //                 ...widget.organizations.where((o) {
  //                   final code = (o['orgCode']?.toString() ?? '');
  //                   final nm = (o['orgName'] ?? o['name'] ?? '').toString().toLowerCase();
  //                   return _q.isEmpty || code.contains(_q.toLowerCase()) || nm.contains(_q.toLowerCase());
  //                 }).map((o) {
  //                   final code = o['orgCode']?.toString() ?? '';
  //                   final nm = (o['orgName'] ?? o['name'] ?? '').toString();
  //                   return _item(c2, code, nm, code, ss);
  //                 }),
  //               ])),
  //             ]),
  //           ),
  //         ))),
  //     ])),
  //   ));
  //   Overlay.of(context).insert(_ov!);
  // }
int _hlIdx = 0;
  List<Map<String, dynamic>> _filteredOrgs = [];
  final ScrollController _filterScrollCtrl = ScrollController();

  void _scrollToHl() {
    const itemH = 40.0;
    if (_filterScrollCtrl.hasClients) {
      _filterScrollCtrl.animateTo(
        _hlIdx * itemH,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _open() {
    _rm(); _sc.clear(); _q = '';
    _hlIdx = 0;
    _filteredOrgs = List.from(widget.organizations);
    // start highlight on current selection (index 0 = "All", so +1 offset)
    final selIdx = _filteredOrgs.indexWhere((o) => o['orgcode']?.toString() == (widget.selectedOrgCode ?? ''));
    _hlIdx = selIdx >= 0 ? selIdx + 1 : 0; // +1 because row 0 is "All Organizations"

    final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;
    const dropW = 290.0;
    final left = pos.dx + sz.width - dropW;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(left: left, top: pos.dy + sz.height + 4, width: dropW,
          child: StatefulBuilder(builder: (c2, ss) {
            _filteredOrgs = widget.organizations.where((o) {
              final code = (o['orgcode']?.toString() ?? '');
              final nm = (o['name'] ?? '').toString().toLowerCase();
              return _q.isEmpty || code.contains(_q.toLowerCase()) || nm.contains(_q.toLowerCase());
            }).toList();
            // total rows = 1 ("All") + filtered orgs
            final totalRows = 1 + _filteredOrgs.length;
            if (_hlIdx >= totalRows) _hlIdx = totalRows - 1;

            void selectHighlighted() {
              if (_hlIdx == 0) { widget.onChanged(null); _rm(); return; }
              final o = _filteredOrgs[_hlIdx - 1];
              widget.onChanged(o['orgcode']?.toString());
              _rm();
            }

            return KeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => _hlIdx = (_hlIdx + 1).clamp(0, totalRows - 1));
                  _scrollToHl();
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => _hlIdx = (_hlIdx - 1).clamp(0, totalRows - 1));
                  _scrollToHl();
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHighlighted();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(
                elevation: 8, borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.all(8), child: TextField(
                      controller: _sc, autofocus: true,
                      onChanged: (v) => ss(() { _q = v; _hlIdx = 0; }),
                      onSubmitted: (_) => selectHighlighted(),
                      style: const TextStyle(fontSize: 13, color: _kText),
                      decoration: InputDecoration(
                        hintText: 'Search organization...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                        filled: true, fillColor: _kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
                      ),
                    )),
                    const Divider(height: 1, color: _kBorder),
                    Flexible(child: ListView.separated(
                      controller: _filterScrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: 1 + _filteredOrgs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
                      itemBuilder: (_, i) {
                        final isHl = i == _hlIdx;
                        if (i == 0) {
                          // "All Organizations" row
                          final isSel = (widget.selectedOrgCode ?? '').isEmpty;
                          return InkWell(
                            onTap: () { widget.onChanged(null); _rm(); },
                            onHover: (h) { if (h) ss(() => _hlIdx = 0); },
                            hoverColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              color: isSel ? _kPL : isHl ? _kPL.withOpacity(0.5) : Colors.transparent,
                              child: Row(children: [
                                Expanded(child: Text('All Organizations',
                                  style: TextStyle(fontSize: 13, color: isSel || isHl ? _kP : _kText,
                                    fontWeight: isSel || isHl ? FontWeight.w600 : FontWeight.w400))),
                                if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
                              ]),
                            ),
                          );
                        }
                        final o = _filteredOrgs[i - 1];
                        final code = o['orgcode']?.toString() ?? '';
                        final nm = (o['orgName'] ?? o['name'] ?? '').toString();
                        final isSel = (widget.selectedOrgCode ?? '') == code;
                        return InkWell(
                          onTap: () { widget.onChanged(code); _rm(); },
                          onHover: (h) { if (h) ss(() => _hlIdx = i); },
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            color: isSel ? _kPL : isHl ? _kPL.withOpacity(0.5) : Colors.transparent,
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(color: isSel ? _kP : _kPL, borderRadius: BorderRadius.circular(4)),
                                child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSel ? Colors.white : _kP)),
                              ),
                              Expanded(child: Text(nm, style: TextStyle(fontSize: 13, color: isSel || isHl ? _kP : _kText,
                                fontWeight: isSel || isHl ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
                              if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
                            ]),
                          ),
                        );
                      },
                    )),
                  ]),
                ),
              ),
            );
          })),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }
  Widget _item(BuildContext c, String? code, String name, String dispCode, StateSetter ss) {
    final isSel = (widget.selectedOrgCode ?? '') == (code ?? '');
    return InkWell(
      onTap: () { widget.onChanged(code); _rm(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: isSel ? _kPL : Colors.transparent,
        child: Row(children: [
          if (dispCode.isNotEmpty) Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: _kPL, borderRadius: BorderRadius.circular(4)),
            child: Text(dispCode, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
          ),
          Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
          if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
        ]),
      ),
    );
  }

  @override Widget build(BuildContext ctx) {
    final has = widget.selectedOrgCode != null && widget.selectedOrgCode!.isNotEmpty;
    return MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
      onTap: _open,
      child: Container(
        key: _key, height: 36, padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: has ? const Color(0xFF2A55A5) : _kP, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.filter_list_rounded, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          const Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          if (has) ...[
            const SizedBox(width: 4),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            GestureDetector(onTap: () => widget.onChanged(null), child: const Icon(Icons.close_rounded, size: 13, color: Colors.white)),
          ] else ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
          ],
        ]),
      ),
    ));
  }
}

// ── Org Dropdown Field (like Users screen) ────────────────────────────────────
class _OrgDropdownField extends StatefulWidget {
  final String label; final TextEditingController controller;
  final List<Map<String, dynamic>> organizations;
  final bool readOnly, isRequired, showLock; final ValueChanged<String> onChanged; final String? errorText;
  const _OrgDropdownField({
    required this.label, required this.controller, required this.organizations,
    this.readOnly = false, this.isRequired = false, required this.onChanged, this.errorText,
    this.showLock = false,
  });
  @override State<_OrgDropdownField> createState() => _OrgDropdownFieldState();
}
class _OrgDropdownFieldState extends State<_OrgDropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac; late Animation<double> _top, _sz;
  bool _isOpen = false;

  bool get _hasVal => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText != null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    widget.controller.addListener(() { setState(() {}); _floated ? _ac.forward() : _ac.reverse(); });
  }
  @override void didUpdateWidget(_OrgDropdownField o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov = null; setState(() => _isOpen = false); _floated ? _ac.forward() : _ac.reverse(); }

  // void _open() {
  //   if (widget.readOnly) return; _rm(); _sc.clear();
  //   setState(() => _isOpen = true); _ac.forward();
  //   final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
  //   final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
  //   final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;
  //   _ov = OverlayEntry(builder: (ctx) => GestureDetector(
  //     behavior: HitTestBehavior.translucent, onTap: _rm,
  //     child: Material(color: Colors.transparent, child: Stack(children: [
  //       Positioned(left: pos.dx, top: pos.dy + sz.height + 6, width: sz.width.clamp(240.0, 360.0),
  //         child: StatefulBuilder(builder: (c2, ss) => Material(
  //           elevation: 12, borderRadius: BorderRadius.circular(14),
  //           child: Container(
  //             constraints: const BoxConstraints(maxHeight: 260),
  //             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
  //             child: Column(mainAxisSize: MainAxisSize.min, children: [
  //               Padding(padding: const EdgeInsets.all(8), child: TextField(
  //                 controller: _sc, autofocus: true, onChanged: (_) => ss(() {}),
  //                 style: const TextStyle(fontSize: 13, color: _kText),
  //                 decoration: InputDecoration(
  //                   hintText: 'Search organization...',
  //                   hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
  //                   prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
  //                   filled: true, fillColor: _kSurface,
  //                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
  //                   enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
  //                   focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
  //                   contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
  //                 ),
  //               )),
  //               const Divider(height: 1, color: _kBorder),
  //               Flexible(child: ListView(
  //                 padding: const EdgeInsets.symmetric(vertical: 4), shrinkWrap: true,
  //                 children: widget.organizations.where((o) {
  //                   final code = o['orgCode']?.toString() ?? '';
  //                   final nm = (o['orgName'] ?? o['name'] ?? '').toString().toLowerCase();
  //                   final q = _sc.text.toLowerCase();
  //                   return q.isEmpty || code.contains(q) || nm.contains(q);
  //                 }).map((o) {
  //                   final code = o['orgCode']?.toString() ?? '';
  //                   final nm = (o['orgName'] ?? o['name'] ?? '').toString();
  //                   final isSel = widget.controller.text.startsWith(code);
  //                   return InkWell(
  //                     onTap: () { widget.onChanged(code); _rm(); },
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  //                       color: isSel ? _kPL : Colors.transparent,
  //                       child: Row(children: [
  //                         Container(
  //                           padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 8),
  //                           decoration: BoxDecoration(color: _kPL, borderRadius: BorderRadius.circular(4)),
  //                           child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
  //                         ),
  //                         Expanded(child: Text(nm, style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w600 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
  //                         if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
  //                       ]),
  //                     ),
  //                   );
  //                 }).toList(),
  //               )),
  //             ]),
  //           ),
  //         ))),
  //     ])),
  //   ));
  //   Overlay.of(context).insert(_ov!);
  // }
  // ── keyboard nav state ────────────────────────────────────────────────────
  int _highlightedIndex = 0;
  List<Map<String, dynamic>> _filteredOrgs = [];
  final ScrollController _scrollCtrl = ScrollController();

  void _scrollToHighlighted() {
    const itemH = 40.0;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _highlightedIndex * itemH,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _open() {
    if (widget.readOnly) return; _rm(); _sc.clear();
    _highlightedIndex = 0;
    _filteredOrgs = List.from(widget.organizations);
    // jump highlight to already-selected item
    final selIdx = _filteredOrgs.indexWhere((o) => widget.controller.text.startsWith(o['orgcode']?.toString() ?? ''));
    if (selIdx >= 0) _highlightedIndex = selIdx;

    setState(() => _isOpen = true); _ac.forward();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(left: pos.dx, top: pos.dy + sz.height + 6, width: sz.width.clamp(240.0, 360.0),
          child: StatefulBuilder(builder: (c2, ss) {
            final q = _sc.text.toLowerCase();
            _filteredOrgs = widget.organizations.where((o) {
              final code = o['orgcode']?.toString() ?? '';
              final nm = (o['name'] ?? '').toString().toLowerCase();
              return q.isEmpty || code.contains(q) || nm.contains(q);
            }).toList();
            if (_highlightedIndex >= _filteredOrgs.length) {
              _highlightedIndex = _filteredOrgs.isEmpty ? 0 : _filteredOrgs.length - 1;
            }

            void selectHighlighted() {
              if (_filteredOrgs.isEmpty) return;
              final o = _filteredOrgs[_highlightedIndex];
              widget.onChanged(o['orgcode']?.toString() ?? '');
              _rm();
            }

            return KeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowDown) {
                  ss(() => _highlightedIndex = (_highlightedIndex + 1).clamp(0, _filteredOrgs.length - 1));
                  _scrollToHighlighted();
                } else if (key == LogicalKeyboardKey.arrowUp) {
                  ss(() => _highlightedIndex = (_highlightedIndex - 1).clamp(0, _filteredOrgs.length - 1));
                  _scrollToHighlighted();
                } else if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
                  selectHighlighted();
                } else if (key == LogicalKeyboardKey.escape) {
                  _rm();
                }
              },
              child: Material(
                elevation: 12, borderRadius: BorderRadius.circular(14),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: const EdgeInsets.all(8), child: TextField(
                      controller: _sc, autofocus: true,
                      onChanged: (_) => ss(() => _highlightedIndex = 0),
                      onSubmitted: (_) => selectHighlighted(),
                      style: const TextStyle(fontSize: 13, color: _kText),
                      decoration: InputDecoration(
                        hintText: 'Search organization...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                        filled: true, fillColor: _kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kP, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
                      ),
                    )),
                    const Divider(height: 1, color: _kBorder),
                    Flexible(child: _filteredOrgs.isEmpty
                      ? const Padding(padding: EdgeInsets.all(20),
                          child: Text('No results found', style: TextStyle(fontSize: 13, color: _kMuted)))
                      : ListView.separated(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          shrinkWrap: true,
                          itemCount: _filteredOrgs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
                          itemBuilder: (_, i) {
                            final o = _filteredOrgs[i];
                            final code = o['orgcode']?.toString() ?? '';
                            final nm = (o['name'] ?? '').toString();
                            final isSel = widget.controller.text.startsWith(code);
                            final isHl  = i == _highlightedIndex;
                            final rowBg = isSel ? _kPL : isHl ? _kPL.withOpacity(0.5) : Colors.transparent;
                            return InkWell(
                              onTap: () { widget.onChanged(code); _rm(); },
                              onHover: (h) { if (h) ss(() => _highlightedIndex = i); },
                              hoverColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                color: rowBg,
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(color: isSel ? _kP : _kPL, borderRadius: BorderRadius.circular(4)),
                                    child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSel ? Colors.white : _kP)),
                                  ),
                                  Expanded(child: Text(nm, style: TextStyle(fontSize: 13, color: isSel || isHl ? _kP : _kText, fontWeight: isSel || isHl ? FontWeight.w700 : FontWeight.w400), overflow: TextOverflow.ellipsis)),
                                  if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
                                ]),
                              ),
                            );
                          },
                        )),
                  ]),
                ),
              ),
            );
          })),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err = widget.errorText != null; final bc = err ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: _open,
          child: Container(
            key: _key, height: 44,
            decoration: BoxDecoration(
              color: widget.readOnly ? _kSurface : Colors.white,
              borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: 1.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 12, 36, 12),
                child: Row(children: [
                  Expanded(child: Text(
                    widget.controller.text.isEmpty ? (_floated ? 'Search organization...' : '') : widget.controller.text,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: widget.controller.text.isEmpty ? _kMuted : _kText),
                    overflow: TextOverflow.ellipsis,
                  )),
                  (widget.showLock && widget.readOnly)
                      ? const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0x8064748B))
                      : (!widget.readOnly ? const Icon(Icons.arrow_drop_down, size: 20, color: _kP) : const SizedBox.shrink()),
                ]),
              ),
            ),
          ),
        ),
        Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.apartment_rounded, size: 14, color: bc))),
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
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none)),
              ),
            )),
        ),
      ]),
      Builder(
        builder: (context) {
          if (widget.controller.text.isNotEmpty) {
            final code = widget.controller.text.trim();
            final match = widget.organizations.where((o) => ((o['orgcode'] ?? o['orgCode'])?.toString() ?? '') == code).toList();
            if (match.isNotEmpty) {
              final nm = (match.first['orgName'] ?? match.first['name'] ?? '').toString();
              if (nm.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: Text(nm, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2)),
                );
              }
            }
          }
          return const SizedBox.shrink();
        },
      ),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
    ]);
  }
}

// ── Country Picker (full A-Z list, same as Org screen) ────────────────────────
class _BranchCountryPickerField extends StatefulWidget {
  final String label; final _CountryInfo? selectedCountry;
  final List<_CountryInfo> countries;
  final ValueChanged<_CountryInfo?> onChanged; final bool isRequired; final String? errorText;
  const _BranchCountryPickerField({
    required this.label, this.selectedCountry, required this.countries, required this.onChanged,
    this.isRequired = false, this.errorText,
  });
  @override State<_BranchCountryPickerField> createState() => _BranchCountryPickerFieldState();
}
class _BranchCountryPickerFieldState extends State<_BranchCountryPickerField> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(); OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac; late Animation<double> _top, _sz;
  bool _isOpen = false;

  bool get _floated => (widget.selectedCountry != null) || _isOpen || widget.errorText != null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }
  @override void didUpdateWidget(_BranchCountryPickerField o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override void dispose() { _rm(); _sc.dispose(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov = null; if (mounted) setState(() => _isOpen = false); _floated ? _ac.forward() : _ac.reverse(); }

  void _open() {
    _rm(); _sc.clear();
    setState(() => _isOpen = true); _ac.forward();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(left: pos.dx, top: pos.dy + sz.height + 6, width: sz.width,
          child: StatefulBuilder(builder: (c2, ss) {
            final filtered = widget.countries.where((c) {
              final q = _sc.text.toLowerCase();
              return q.isEmpty || c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q);
            }).toList();
            return Material(
              elevation: 12, shadowColor: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: const BoxDecoration(
                      color: _kPL,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.public_rounded, size: 15, color: _kP), SizedBox(width: 6),
                      Text('Select Country', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 0.5)),
                    ]),
                  ),
                  Padding(padding: const EdgeInsets.all(10), child: TextField(
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
                  )),
                  const Divider(height: 1, color: _kBorder),
                  Flexible(child: filtered.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(20),
                          child: Text('No countries found', style: TextStyle(fontSize: 13, color: _kMuted))))
                      : ListView.builder(
                          padding: EdgeInsets.zero, shrinkWrap: true, itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final c = filtered[idx]; final isSel = widget.selectedCountry?.code == c.code;
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
                        )),
                ]),
              ),
            );
          })),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final sel = widget.selectedCountry; final err = widget.errorText != null; final bc = err ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
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
        Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.language_rounded, size: 14, color: bc))),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: _open,
              child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none))),
            )),
        ),
      ]),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
    ]);
  }
}

// ── Mobile Field (country-based validation, +dialCode badge) ──────────────────
class _BranchMobileField extends StatefulWidget {
  final TextEditingController controller; final String? dialCode;
  final int mobileLength; final String? errorText; final FocusNode? focusNode;
  const _BranchMobileField({required this.controller, this.dialCode, required this.mobileLength, this.errorText, this.focusNode});
  @override State<_BranchMobileField> createState() => _BranchMobileFieldState();
}
class _BranchMobileFieldState extends State<_BranchMobileField> with SingleTickerProviderStateMixin {
  late FocusNode _fn; bool _focused = false;
  late AnimationController _ac; late Animation<double> _top, _sz;

  bool get _hasCC   => widget.dialCode != null && widget.dialCode!.isNotEmpty;
  bool get _hasVal  => widget.controller.text.isNotEmpty;
  bool get _floated => _focused || _hasVal || _hasCC || widget.errorText != null;

  @override void initState() {
    super.initState();
    _fn = widget.focusNode ?? FocusNode();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _fn.addListener(() { setState(() => _focused = _fn.hasFocus); _floated ? _ac.forward() : _ac.reverse(); });
    widget.controller.addListener(() { setState(() {}); _floated ? _ac.forward() : _ac.reverse(); });
  }
  @override void didUpdateWidget(_BranchMobileField o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override void dispose() { if (widget.focusNode == null) _fn.dispose(); _ac.dispose(); super.dispose(); }

  @override Widget build(BuildContext ctx) {
    final err = widget.errorText != null; final bc = err ? _kR : _kP;
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
                controller: widget.controller, focusNode: _fn,
                keyboardType: TextInputType.phone, maxLength: widget.mobileLength,
                inputFormatters: [
                  _BranchRejectingFormatter(RegExp(r'^\d*$'), () {})
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
              child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  const TextSpan(
                    text: 'Mobile',
                    children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none))),
            )),
        ),
      ]),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
    ]);
  }
}

// ── Branch Toggle Field (Status / Head Branch) ────────────────────────────────
class _BranchToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final String trueLabel, falseLabel;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool hasError;
  final String? subtext;

  const _BranchToggle({
    required this.label, required this.icon,
    required this.isActive, required this.trueLabel, required this.falseLabel,
    required this.activeColor, required this.onChanged, this.hasError = false, this.readOnly = false,
    this.subtext,
  });
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final bc = hasError ? _kR : _kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        MouseRegion(
          cursor: readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: readOnly ? null : () => onChanged(!isActive),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: Row(children: [
                Icon(icon, size: 14, color: bc),
                const SizedBox(width: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isActive ? trueLabel : falseLabel,
                    key: ValueKey(isActive),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isActive ? activeColor : _kMuted),
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34, height: 18, padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isActive ? activeColor : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 14, height: 14,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          top: -8, left: 28,
          child: Container(
            color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text.rich(
              TextSpan(text: label, children: const [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ]),
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600,
                color: bc, letterSpacing: 0.2, decoration: TextDecoration.none),
            ),
          ),
        ),
      ]),
      if (hasError)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text('$label is required',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        )
      else if (subtext != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(subtext!,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w500, color: _kO, height: 1.2)),
        ),
    ]);
  }
}

// ── Simple Dropdown (Status / Head Branch — white rows) ───────────────────────
class _BranchSimpleDropdown extends StatefulWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final List<String> items; final bool isRequired; final String? errorText;
  const _BranchSimpleDropdown({
    required this.label, required this.controller, required this.icon,
    required this.items, this.isRequired = false, this.errorText,
  });
  @override State<_BranchSimpleDropdown> createState() => _BranchSimpleDropdownState();
}
class _BranchSimpleDropdownState extends State<_BranchSimpleDropdown> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey(); OverlayEntry? _ov;
  late AnimationController _ac; late Animation<double> _top, _sz;
  bool _isOpen = false;

  bool get _hasVal  => widget.controller.text.isNotEmpty;
  bool get _floated => _hasVal || _isOpen || widget.errorText != null;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    widget.controller.addListener(() { setState(() {}); _floated ? _ac.forward() : _ac.reverse(); });
  }
  @override void didUpdateWidget(_BranchSimpleDropdown o) { super.didUpdateWidget(o); _floated ? _ac.forward() : _ac.reverse(); }
  @override void dispose() { _rm(); _ac.dispose(); super.dispose(); }
  void _rm() { _ov?.remove(); _ov = null; setState(() => _isOpen = false); _floated ? _ac.forward() : _ac.reverse(); }

  void _open() {
    _rm(); setState(() => _isOpen = true); _ac.forward();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?; if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov); final sz = rb.size;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent, onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(left: pos.dx, top: pos.dy + sz.height + 6, width: sz.width,
          child: Material(
            elevation: 12, shadowColor: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _kBorder)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: _kPL,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(13), topRight: Radius.circular(13)),
                    border: Border(bottom: BorderSide(color: _kPB)),
                  ),
                  child: Row(children: [
                    Icon(widget.icon, size: 13, color: _kP), const SizedBox(width: 6),
                    Text(widget.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 0.4)),
                  ]),
                ),
                ...widget.items.asMap().entries.map((entry) {
                  final idx = entry.key; final item = entry.value;
                  final isSel = widget.controller.text == item;
                  final isAct = item == 'Active'; final isIna = item == 'Inactive';
                  final isYes = item == 'Yes';
                  final Color? dotColor = isAct ? _kG : (isIna ? _kR : (isYes ? _kP : null));
                  final isLast = idx == widget.items.length - 1;
                  return InkWell(
                    onTap: () { widget.controller.text = item; setState(() {}); _rm(); },
                    borderRadius: isLast
                        ? const BorderRadius.only(bottomLeft: Radius.circular(13), bottomRight: Radius.circular(13))
                        : BorderRadius.zero,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? _kPL : Colors.white,
                        borderRadius: isLast
                            ? const BorderRadius.only(bottomLeft: Radius.circular(13), bottomRight: Radius.circular(13))
                            : null,
                      ),
                      child: Row(children: [
                        if (dotColor != null) Container(
                          width: 10, height: 10, margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(0.15), shape: BoxShape.circle,
                            border: Border.all(color: dotColor, width: 1.5),
                          ),
                        ),
                        Expanded(child: Text(item, style: TextStyle(fontSize: 13,
                          color: dotColor ?? _kText, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500))),
                        if (isSel) Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: _kP, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
                        ),
                      ]),
                    ),
                  );
                }),
              ]),
            ),
          )),
      ])),
    ));
    Overlay.of(context).insert(_ov!);
  }

  @override Widget build(BuildContext ctx) {
    final err = widget.errorText != null; final bc = err ? _kR : _kP;
    final currentVal = widget.controller.text;
    final isAct = currentVal == 'Active'; final isIna = currentVal == 'Inactive';
    final isYes = currentVal == 'Yes';
    final Color? valColor = isAct ? _kG : (isIna ? _kR : (isYes ? _kP : null));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: _open,
          child: Container(
            key: _key, height: 44,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: bc, width: 1.5)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 12, 0),
                child: Row(children: [
                  if (valColor != null) Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: valColor, shape: BoxShape.circle)),
                  Expanded(child: Text(
                    currentVal.isEmpty ? (_floated ? 'Please select' : '') : currentVal,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: currentVal.isEmpty ? _kMuted : (valColor ?? _kText)),
                    overflow: TextOverflow.ellipsis,
                  )),
                  Icon(Icons.unfold_more_rounded, size: 16, color: bc),
                ]),
              ),
            ),
          ),
        ),
        Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft, child: Icon(widget.icon, size: 14, color: bc))),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: _open,
              child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600, color: bc, letterSpacing: 0.2, decoration: TextDecoration.none))),
            )),
        ),
      ]),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
    ]);
  }
}

// ── Blocking Input Formatter (same as org screen) ───────────────────────────
class _BranchRejectingFormatter extends TextInputFormatter {
  final RegExp pattern;
  final VoidCallback onReject;
  _BranchRejectingFormatter(this.pattern, this.onReject);
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (pattern.hasMatch(newValue.text)) return newValue;
    onReject();
    return oldValue;
  }
}

// ── Floating Label Field ──────────────────────────────────────────────────────
class _FloatingLabelField extends StatefulWidget {
  final String label; final TextEditingController ctrl; final IconData icon;
  final String hint; final bool readOnly, required, isDatePicker, showLock;
  final String? errorText, subtext; final DateTime? maxDate; final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  const _FloatingLabelField({
    required this.label, required this.ctrl, required this.icon,
    this.hint = '', this.readOnly = false, this.required = false, this.errorText,
    this.isDatePicker = false, this.maxDate, this.focusNode,
    this.inputFormatters, this.maxLength, this.showLock = false,
    this.subtext,
  });
  @override State<_FloatingLabelField> createState() => _FloatingLabelFieldState();
}
class _FloatingLabelFieldState extends State<_FloatingLabelField> with SingleTickerProviderStateMixin {
  late final FocusNode _focus; bool _focused = false;
  late AnimationController _anim; late Animation<double> _labelTop, _labelSize;

  bool get _hasValue => widget.ctrl.text.isNotEmpty;
  bool get _floated  => _focused || _hasValue || widget.errorText != null;

  @override void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1.0 : 0.0);
    _labelTop  = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _labelSize = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _focus.addListener(() { setState(() => _focused = _focus.hasFocus); _floated ? _anim.forward() : _anim.reverse(); });
    widget.ctrl.addListener(() { if (_floated && _anim.value < 1) _anim.forward(); if (!_floated && _anim.value > 0) _anim.reverse(); setState(() {}); });
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
    final firstDate = DateTime(2000);
    DateTime initial = DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(maxD)) initial = maxD;
    try {
      final parts = widget.ctrl.text.split('-');
      if (parts.length == 3) {
        const months = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
        final d = int.parse(parts[0]);
        final m = months[parts[1]] ?? 1;
        var y = int.parse(parts[2]);
        if (y < 100) y += 2000; // handle two‑digit years
        final parsed = DateTime(y, m, d);
        if (!parsed.isAfter(maxD) && !parsed.isBefore(DateTime(2000))) {
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
        widget.ctrl.clear();
      } else {
        const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        widget.ctrl.text = '${picked.day.toString().padLeft(2,'0')}-${ms[picked.month - 1]}-${picked.year}';
      }
    }
  }

  @override void dispose() { if (widget.focusNode == null) _focus.dispose(); _anim.dispose(); super.dispose(); }
  @override void didUpdateWidget(_FloatingLabelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final Color borderColor = hasError ? _kR : _kP;
    Widget textField = TextField(
      controller: widget.ctrl, focusNode: _focus,
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
        child: GestureDetector(onTap: () => _pickDate(context), behavior: HitTestBehavior.opaque, child: field),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        field,
        Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft,
          child: Icon(widget.isDatePicker && _floated ? Icons.calendar_month_rounded : widget.icon, size: 14, color: hasError ? _kR : _kP))),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, _2) => Positioned(top: _labelTop.value, left: 28,
            child: GestureDetector(
              onTap: _requestFocus,
              child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.required)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _labelSize.value, fontWeight: FontWeight.w600,
                    color: hasError ? _kR : _kP, letterSpacing: 0.2, decoration: TextDecoration.none),
                )),
            )),
        ),
      ]),
      if (widget.subtext != null && widget.subtext!.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.subtext!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2))),
      if (widget.errorText != null)
        Padding(padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
    ]);
  }
}

// ── Generic API Dropdown Field (floating label, matches existing field style) ──
class _BranchApiDropdownField extends StatefulWidget {
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

  const _BranchApiDropdownField({
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
  State<_BranchApiDropdownField> createState() => _BranchApiDropdownFieldState();
}

class _BranchApiDropdownFieldState extends State<_BranchApiDropdownField>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac;
  late Animation<double> _top, _sz;
  bool _isOpen = false;

  String _display(Map<String, dynamic> m) {
    for (final k in widget.displayKeys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  bool get _floated => widget.selectedItem != null || _isOpen || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_BranchApiDropdownField o) {
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
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov);
    final sz = rb.size;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(
          left: pos.dx, bottom: ov.size.height - pos.dy + 6, width: sz.width,
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
    final placeholderText = sel != null
        ? _display(sel)
        : (_floated ? (disabled ? widget.disabledHint : 'Select ${widget.label.toLowerCase()}') : '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
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
