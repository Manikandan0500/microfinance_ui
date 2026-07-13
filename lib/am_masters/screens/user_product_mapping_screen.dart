import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/user_access_mapping.dart';
import '../models/user_account_model.dart';
import '../models/product_model.dart';
import '../services/user_access_service.dart';
import '../services/user_account_service.dart';
import '../services/organization_service.dart';
import '../services/product_service.dart';
import '../services/product_mapping_service.dart';
import '../widgets/bulk_upload_dialog.dart';
import '../services/operational_log_service.dart';
import '../services/program_service.dart';
import '../widgets/audit_details_dialog.dart';
import '../models/access_privileges.dart';
import '../services/auth_service.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

// ── Brand colours ──────────────────────────────────────────────────────────────
const _kP = Color(0xFF3D6EBE);
const _kPD = Color(0xFF2D56A0);
const _kPL = Color(0xFFEEF3FB);
const _kPB = Color(0xFFC5D3E8);
const _kR = Color(0xFFDC2626);
const _kRL = Color(0xFFFEF2F2);
const _kRB = Color(0xFFFECACA);
const _kG = Color(0xFF16A34A);
const _kGL = Color(0xFFDCFCE7);
const _kGB = Color(0xFFBBF7D0);
const _kText = Color(0xFF1E293B);
const _kMuted = Color(0xFF64748B);
const _kHint = Color(0xFF94A3B8);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);
const _kBg = Color(0xFFF1F5F9);
const _kOBG = Color(0xFFFFF7ED);
const _kOB = Color(0xFFFED7AA);
const _kOT = Color(0xFFC2410C);
const _kWarnBG = Color(0xFFFFFBEB);
const _kWarnB = Color(0xFFFDE68A);
const _kWarnT = Color(0xFFB45309);

enum _V { list, create, view, edit, delete, bulkUpload }

List<String> _orgOptions = [];
final Map<String, String> _orgNamesByCode = {};

const Map<String, int> _roleToAccessCd = {'Sysadmin': 1, 'Admin': 2, 'User': 3};

String _defaultRoleForProduct(String productName) {
  return productName.toLowerCase() == 'accessmanager' ? 'Admin' : 'User';
}

String _orgCode(String opt) => opt.split(' - ').first.trim();
String _orgName(String code) => _orgNamesByCode[code] ?? '';

class _UserDef {
  final String code;
  final String name;
  final String initials;
  final String dept;
  final bool active;
  final String orgCode;
  final String? email;
  final String? country;
  final String? mobile;

  const _UserDef(
    this.code,
    this.name,
    this.initials,
    this.dept,
    this.active,
    this.orgCode,
    this.email,
    this.country,
    this.mobile,
  );

  String get display => name.isNotEmpty ? '$code - $name' : code;
}

List<_UserDef> _allUsers = [];

_UserDef _userByCodeAndOrg(String userCode, String orgCode) =>
    _allUsers.firstWhere(
      (u) => u.code == userCode && u.orgCode == orgCode,
      orElse: () =>
          _UserDef(userCode, '', '', '', true, orgCode, null, null, null),
    );

// ── Products per org ──────────────────────────────────────────────────────────
Map<String, List<String>> _orgProductsFromApi = {};
List<String> _prodsForOrg(String code) => _orgProductsFromApi[code] ?? [];

// REPLACE the existing _prodIcon() function:
IconData _prodIcon(String p) => switch (p.toLowerCase()) {
  'access manager' => Icons.admin_panel_settings_rounded,
  'connect' => Icons.link_rounded,
  'hrm' => Icons.people_rounded,
  'crm' => Icons.handshake_rounded,
  'payroll' => Icons.account_balance_wallet_rounded,
  'fixed asset' => Icons.warehouse_rounded,
  'finance' => Icons.account_balance_rounded,
  'payments' => Icons.payment_rounded,
  'tickets' => Icons.confirmation_number_rounded,
  'projects' => Icons.folder_special_rounded,
  'test' => Icons.bug_report_rounded,
  _ => Icons.apps_rounded,
};

// ── Data model ────────────────────────────────────────────────────────────────
class _AccessRow {
  int id;
  String orgCode;
  String userCode;
  List<String> productCodes;
  String status;
  int? accessCd;
  String? euser;
  DateTime? edate;
  String? auser;
  DateTime? adate;
  String? cuser;
  DateTime? cdate;

  _AccessRow({
    required this.id,
    required this.orgCode,
    required this.userCode,
    required this.productCodes,
    this.status = 'Active',
    this.accessCd,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.cuser,
    this.cdate,
  });
  bool get active => status == 'Active';
}

class _ProductAssignment {
  final String productName;
  final String role;
  String status;

  _ProductAssignment({
    required this.productName,
    required this.role,
    required this.status,
  });

  int get accessCd => _roleToAccessCd[role] ?? 3;
  bool get isActive => status == 'Active';
}

// ── Toast ──────────────────────────────────────────────────────────────────────
class _Toast {
  static OverlayEntry? _cur;
  static void show(BuildContext ctx, String msg, {bool isError = false}) {
    _cur?.remove();
    final bg = isError ? _kRL : _kGL;
    final fg = isError ? _kR : _kG;
    final bd = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final ic = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _ToastW(
        msg: msg,
        bg: bg,
        fg: fg,
        border: bd,
        icon: ic,
        onDismiss: () {
          e.remove();
          if (_cur == e) _cur = null;
        },
      ),
    );
    _cur = e;
    Overlay.of(ctx).insert(e);
    Future.delayed(const Duration(seconds: 3), () {
      if (_cur == e) {
        e.remove();
        _cur = null;
      }
    });
  }
}

class _ToastW extends StatefulWidget {
  final String msg;
  final Color bg, fg, border;
  final IconData icon;
  final VoidCallback onDismiss;
  const _ToastW({
    required this.msg,
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
    required this.onDismiss,
  });
  @override
  State<_ToastW> createState() => _ToastWState();
}

class _ToastWState extends State<_ToastW> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s, _f;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _s = Tween<double>(
      begin: -50,
      end: 0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _f = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    top: 18,
    left: 0,
    right: 0,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, ch) => Transform.translate(
        offset: Offset(0, _s.value),
        child: Opacity(opacity: _f.value, child: ch),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.bg,
            border: Border.all(color: widget.border),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.msg,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.fg,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(Icons.close_rounded, size: 13, color: widget.fg),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  Main Widget
// ══════════════════════════════════════════════════════════════════════════════
class UserAccess extends StatefulWidget {
  final String roleType;
  final String? adminOrgCode;
  final String? adminOrgName;

  final AccessPrivileges? accessPrivileges;

  const UserAccess({
    super.key,
    this.roleType = '',
    this.adminOrgCode,
    this.adminOrgName,
    this.accessPrivileges,
  });

  @override
  State<UserAccess> createState() => _UserAccessState();
}

class _UserAccessState extends State<UserAccess> {
  _V _view = _V.list;
  _AccessRow? _sel;
  bool _delOk = false;
  String _search = '';
  // CHANGE 1: org filter for the list screen
  String _orgFilter = '';
  int _nextId = 10;
  bool _loading = true;

  int _pageIndex = 0;
  int _totalElements = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  Timer? _debounce;

  final UserAccessService _service = UserAccessService();
  final OrganizationService _orgService = OrganizationService();
  final ProductService _productService = ProductService();
  final ProductMappingService _productMappingService = ProductMappingService();
  final UserAccountService _userAccountService = UserAccountService();

  List<UserAccessMapping> _mappings = [];
  List<_AccessRow> _data = [];
  List<ProductModel> _products = [];
  Map<int, String> _prodCodeToName = {};
  int? _accessPgmId;

  String get _adminOrgLabel {
    final code = widget.adminOrgCode ?? '';
    final name = widget.adminOrgName ?? '';
    if (code.isEmpty) return '';
    return name.isNotEmpty ? '$code - $name' : code;
  }

  bool get _isAdmin => widget.roleType.toUpperCase() == 'ADMIN';

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchAccessPgmId();
  }

  Future<void> _fetchAccessPgmId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final pgm = programs.firstWhere(
        (p) =>
            p.descn.toLowerCase() == 'user product mapping' ||
            p.descn.toLowerCase() == 'user product map' ||
            p.descn.toLowerCase() == 'user access',
      );
      _accessPgmId = pgm.pgmId;
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchMappings() async {
    setState(() => _loading = true);
    try {
      final limit = 10;
      final offset = _pageIndex * limit;
      final orgCodeParam = _isAdmin
          ? widget.adminOrgCode?.toString()
          : (_orgFilter.isNotEmpty ? _orgFilter : null);
      final result = await _service.getMappingsPaginated(
        offset: offset,
        limit: limit,
        search: _search,
        orgCode: orgCodeParam,
      );
      if (mounted) {
        setState(() {
          final content = result['content'] as List<UserAccessMapping>? ?? [];
          _data = _groupMappingsToRows(content);
          _totalElements = result['totalElements'] as int? ?? 0;
          _activeCount = result['activeCount'] as int? ?? 0;
          _inactiveCount = result['inactiveCount'] as int? ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _toast('Failed to load user access mappings: $e', err: true);
      }
    }
  }

  Map<String, List<_UserDef>> _usersByOrg = {};

  Future<void> _loadData() async {
    try {
      final orgResponse = await _orgService.getAllOrganizations();
      _orgOptions = orgResponse
          .map((org) {
            final code =
                org['orgCode']?.toString() ??
                org['orgcode']?.toString() ??
                org['id']?.toString() ??
                '';
            final name =
                org['orgName']?.toString() ??
                org['name']?.toString() ??
                org['org_name']?.toString() ??
                '';
            if (code.isNotEmpty) {
              _orgNamesByCode[code] = name;
              return name.isNotEmpty ? '$code - $name' : code;
            }
            return '';
          })
          .where((e) => e.isNotEmpty)
          .toList();

      _products = await _productService.getAllProducts();
      for (final p in _products) {
        _prodCodeToName[p.productCode] = p.productName;
      }

      final productMappings = await _productMappingService.getAllMappings();
      _orgProductsFromApi.clear();
      for (final mapping in productMappings) {
        final orgCode =
            mapping['orgCode']?.toString() ??
            mapping['orgcode']?.toString() ??
            '';
        if (orgCode.isNotEmpty) {
          _orgProductsFromApi.putIfAbsent(orgCode, () => []);
          final prodCodes = mapping['prodCodes'];
          if (prodCodes is List) {
            for (final rawCode in prodCodes) {
              final prodCode = int.tryParse(rawCode.toString());
              if (prodCode != null && _prodCodeToName.containsKey(prodCode)) {
                final prodName = _prodCodeToName[prodCode]!;
                if (!_orgProductsFromApi[orgCode]!.contains(prodName)) {
                  _orgProductsFromApi[orgCode]!.add(prodName);
                }
              }
            }
          }
        }
      }

      final users = await _userAccountService.getAllUsers();

      // ✅ FIX: Reset and group users by their orgCode
      _usersByOrg.clear();
      _allUsers = users.map((user) {
        final code = user.userCode.toString();
        final fullName = [
          user.fName,
          user.mName,
          user.lName,
        ].where((v) => v != null && v.isNotEmpty).join(' ').trim();
        final initials = _buildInitials(user.fName, user.lName);
        final orgCode = user.orgCode.toString();

        final userDef = _UserDef(
          code,
          fullName,
          initials,
          '',
          user.isActive,
          orgCode,
          user.emailId,
          user.country,
          user.mobile,
        );

        // ✅ Group into _usersByOrg map
        _usersByOrg.putIfAbsent(orgCode, () => []);
        _usersByOrg[orgCode]!.add(userDef);

        return userDef;
      }).toList();

      await _fetchMappings();
    } catch (e) {
      _toast('Failed to load data: $e', err: true);
      setState(() => _loading = false);
    }
  }

  // ✅ Helper to fetch users for a specific org
  List<_UserDef> _getUsersForOrg(String orgCode) {
    return _usersByOrg[orgCode] ?? [];
  }

  List<_AccessRow> _groupMappingsToRows(List<UserAccessMapping> mappings) {
    final Map<String, _AccessRow> grouped = {};
    for (final mapping in mappings) {
      final rawUserCode = mapping.userscd.toString();
      final key = '${mapping.orgcode}_$rawUserCode';
      if (grouped.containsKey(key)) {
        final prodName = _prodNameFromCode(mapping.prodcode);
        if (!grouped[key]!.productCodes.contains(prodName)) {
          grouped[key]!.productCodes.add(prodName);
        }
        if (grouped[key]!.cdate == null) {
          grouped[key]!.cuser = mapping.cuser;
          grouped[key]!.cdate = mapping.cdate;
        }
        if (grouped[key]!.edate == null) {
          grouped[key]!.euser = mapping.euser;
          grouped[key]!.edate = mapping.edate;
        }
        if (grouped[key]!.adate == null) {
          grouped[key]!.auser = mapping.auser;
          grouped[key]!.adate = mapping.adate;
        }
      } else {
        grouped[key] = _AccessRow(
          id: mapping.accesscd ?? 0,
          orgCode: mapping.orgcode.toString(),
          userCode: rawUserCode,
          productCodes: [_prodNameFromCode(mapping.prodcode)],
          status: mapping.status ? 'Active' : 'Inactive',
          accessCd: mapping.accesscd,
          cuser: mapping.cuser,
          cdate: mapping.cdate,
          euser: mapping.euser,
          edate: mapping.edate,
          auser: mapping.auser,
          adate: mapping.adate,
        );
      }
    }
    return grouped.values.toList();
  }

  String _prodNameFromCode(int prodcode) =>
      _prodCodeToName[prodcode] ?? 'Product $prodcode';

  static String _buildInitials(String? first, String? last) {
    final f = (first ?? '').trim();
    final l = (last ?? '').trim();
    if (f.isNotEmpty && l.isNotEmpty) return '${f[0]}${l[0]}'.toUpperCase();
    if (f.isNotEmpty) return f[0].toUpperCase();
    if (l.isNotEmpty) return l[0].toUpperCase();
    return '?';
  }

  void _go(_V v, [_AccessRow? r]) async {
    setState(() {
      _view = v;
      _sel = r;
      _delOk = false;
      if (v == _V.list) {
        _search = '';
        _pageIndex = 0;
      }
    });
    if (v == _V.list) {
      _fetchMappings();
    } else if (v == _V.edit || v == _V.create) {
      try {
        final mappings = await _service.getAllMappings();
        if (mounted) {
          setState(() {
            _mappings = mappings;
          });
        }
      } catch (e) {
        _toast('Failed to load mappings: $e', err: true);
      }
    }
  }

  void _toast(String m, {bool err = false}) =>
      _Toast.show(context, m, isError: err);

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      const ms = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2, '0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2, '0')}:$m $p';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _page({required Widget child}) =>
      SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _fBtn(
    String lbl,
    IconData ic,
    Color bg,
    Color fg,
    Color bd, {
    VoidCallback? onTap,
  }) => MouseRegion(
    cursor: onTap == null
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bd, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 14, color: fg),
            const SizedBox(width: 6),
            Text(
              lbl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _rBtn(IconData ic, Color col, VoidCallback tap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: tap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(ic, size: 14, color: col),
      ),
    ),
  );

  Widget _statusBadge(bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: active ? _kGL : _kRL,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: active ? _kG : _kR,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          active ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? _kG : _kR,
          ),
        ),
      ],
    ),
  );

  Widget _statCard(
    String num,
    String lbl,
    Color nc,
    Color bg,
    Color bd,
    IconData icon,
    Color ic,
  ) => Container(
    width: 180,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bd),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: ic),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              num,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: nc,
                height: 1.1,
              ),
            ),
            Text(lbl, style: const TextStyle(fontSize: 10, color: _kMuted)),
          ],
        ),
      ],
    ),
  );

  Widget _pageBtn(String l, {required bool en, required VoidCallback onTap}) =>
      MouseRegion(
        cursor: en ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: en ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Text(
              l,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: en ? _kMuted : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      );

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _kP,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(height: 1, color: _kBorder),
        const SizedBox(height: 2),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  LIST SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _listScreen() {
    final active = _activeCount;
    final inactive = _inactiveCount;
    const ps = 10;

    return StatefulBuilder(
      builder: (_, ls) {
        int pg = _pageIndex;
        final tp = (_totalElements / ps).ceil().clamp(1, 9999);
        final items = _data;
        final st = _totalElements == 0 ? 0 : pg * ps + 1;
        final en = pg * ps + items.length;

        return _page(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'User Product Mapping',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              Row(
                children: [
                  _statCard(
                    '$_totalElements',
                    'Total',
                    _kP,
                    _kPL,
                    _kPB,
                    Icons.lock_outline_rounded,
                    _kP,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    '$active',
                    'Active',
                    _kG,
                    _kGL,
                    _kGB,
                    Icons.check_circle_outline_rounded,
                    _kG,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    '$inactive',
                    'Inactive',
                    _kR,
                    _kRL,
                    _kRB,
                    Icons.block_rounded,
                    _kR,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CHANGE 1: Added org filter button alongside search box
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SearchBox(
                    width: 220,
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        setState(() {
                          _search = v;
                          _pageIndex = 0;
                        });
                        _fetchMappings();
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  if (!_isAdmin) ...[
                    // ── Org Filter Button ─────────────────────────────────────────
                    _OrgFilterButton(
                      selectedOrgCode: _orgFilter.isEmpty ? null : _orgFilter,
                      orgOptions: _orgOptions,
                      onChanged: (code) {
                        setState(() {
                          _orgFilter = code ?? '';
                          _pageIndex = 0;
                        });
                        _fetchMappings();
                      },
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (widget.accessPrivileges?.canCreate ?? true) ...[
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                                       onTap: () => setState(() => _view = _V.bulkUpload),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _kP,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kP, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.upload_file_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Upload Product',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _go(_V.create),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: _kP,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kP, width: 1.5),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'New Mapping',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading user access...'),
                      ],
                    ),
                  ),
                )
              else
                _card(
                  child: LayoutBuilder(
                    builder: (_, con) {
                      final w = con.maxWidth;
                      final cols = [
                        w * .22,
                        w * .18,
                        w * .35,
                        w * .10,
                        w * .15,
                      ];
                      final hdrs = [
                        'ORGANIZATION',
                        'USER',
                        'PRODUCTS',
                        'STATUS',
                        'ACTIONS',
                      ];

                      Widget hC(String t) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 13,
                        ),
                        child: Center(
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );

                      return Column(
                        children: [
                          Container(
                            decoration: const BoxDecoration(color: _kP),
                            child: Row(
                              children: List.generate(
                                cols.length,
                                (i) => SizedBox(
                                  width: cols[i],
                                  child: hC(hdrs[i]),
                                ),
                              ),
                            ),
                          ),

                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(28),
                              child: Center(
                                child: Text(
                                  'No records found',
                                  style: TextStyle(fontSize: 13, color: _kHint),
                                ),
                              ),
                            ),

                          ...items.asMap().entries.map((e) {
                            final i = e.key;
                            final r = e.value;
                            final orgDisplay = _orgOptions.firstWhere(
                              (o) => _orgCode(o) == r.orgCode,
                              orElse: () => r.orgCode,
                            );
                            // final u = _userByCode(r.userCode); Aasai
                            final u = _userByCodeAndOrg(r.userCode, r.orgCode);

                            return _ListRow(
                              record: r,
                              orgDisplay: orgDisplay,
                              userDisplay: u.display,
                              products: r.productCodes,
                              cols: cols,
                              isEven: i % 2 == 1,
                              // CHANGE 4: row tap removed — only icon buttons trigger actions
                              onView: () => _go(_V.view, r),
                              onEdit: () => _go(_V.edit, r),
                              onDelete: () => _go(_V.delete, r),
                              statusBadge: _statusBadge,
                              rBtn: _rBtn,
                              accessPrivileges: widget.accessPrivileges,
                            );
                          }),

                          Container(
                            decoration: const BoxDecoration(
                              border: Border(top: BorderSide(color: _kBorder)),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _totalElements == 0
                                      ? 'No records found'
                                      : 'Showing $st–$en of $_totalElements records',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _kHint,
                                  ),
                                ),
                                Row(
                                  children: [
                                    _pageBtn(
                                      '‹ Prev',
                                      en: pg > 0,
                                      onTap: () {
                                        setState(() => _pageIndex = pg - 1);
                                        _fetchMappings();
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _pageBtn(
                                      'Next ›',
                                      en: pg < tp - 1,
                                      onTap: () {
                                        setState(() => _pageIndex = pg + 1);
                                        _fetchMappings();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FORM SCREEN (Create / Edit)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _formScreen({required bool isEdit}) {
    return _FormView(
      isEdit: isEdit,
      existing: isEdit ? _sel : null,
      isAdmin: _isAdmin,
      adminOrgLabel: _adminOrgLabel,
      adminOrgCode: widget.adminOrgCode ?? '',
      takenUserCodesForOrg: (orgCode, excludeId) {
        final orgCodeInt = int.tryParse(orgCode);
        if (orgCodeInt == null) return [];

        String? excludedUserCode;
        if (excludeId != null && excludeId != -1) {
          final excludedMapping = _mappings.firstWhere(
            (m) => m.accesscd == excludeId,
            orElse: () => UserAccessMapping(
              orgcode: 0,
              userscd: '',
              syscode: 0,
              prodcode: 0,
              status: false,
            ),
          );
          if (excludedMapping.userscd.isNotEmpty) {
            excludedUserCode = excludedMapping.userscd;
          }
        }

        return _mappings
            .where((m) => m.orgcode == orgCodeInt && m.userscd != excludedUserCode)
            .map((m) => m.userscd)
            .toSet()
            .toList();
      },
      getMappedProducts: (orgCode, userCode) {
        final orgCodeInt = int.tryParse(orgCode);
        if (orgCodeInt == null) return [];
        return _mappings
            .where((m) => m.orgcode == orgCodeInt && m.userscd == userCode)
            .map((m) => _prodCodeToName[m.prodcode] ?? 'Product ${m.prodcode}')
            .toList();
      },
      getMappedStatus: (orgCode, userCode) {
        final orgCodeInt = int.tryParse(orgCode);
        if (orgCodeInt == null) return 'Active';
        final match = _mappings.where(
          (m) => m.orgcode == orgCodeInt && m.userscd == userCode,
        );
        return match.isNotEmpty
            ? (match.first.status ? 'Active' : 'Inactive')
            : 'Active';
      },
      onSave: (orgCode, userCode, assignments) async {
        try {
          final orgCodeInt = int.tryParse(orgCode) ?? 0;
          final mappings = assignments
              .map((assignment) {
                final prodCode = _prodCodeToName.entries
                    .firstWhere(
                      (e) => e.value == assignment.productName,
                      orElse: () => const MapEntry(0, ''),
                    )
                    .key;

                return UserAccessMapping(
                  accesscd: assignment.accessCd,
                  orgcode: orgCodeInt,
                  userscd: userCode,
                  syscode: 0,
                  prodcode: prodCode,
                  status: assignment.isActive,
                );
              })
              .where((mapping) => mapping.prodcode != 0)
              .toList();

          if (mappings.isEmpty) {
            throw Exception('No valid products were selected.');
          }

          final hasExistingMappings = _mappings.any(
            (m) => m.orgcode == orgCodeInt && m.userscd == userCode,
          );

          if (isEdit || hasExistingMappings) {
            // Find all original mapping objects for this orgCode and userCode
            final originalMappings = _mappings
                .where((m) => m.orgcode == orgCodeInt && m.userscd == userCode)
                .toList();

            // Find the new product codes
            final newProductCodes = mappings.map((m) => m.prodcode).toSet();

            // Find the mappings that are no longer in the new product codes
            final removedMappings = originalMappings
                .where((m) => !newProductCodes.contains(m.prodcode))
                .toList();

            // Delete only the removed products individually by their accesscd and prodcode
            for (final rm in removedMappings) {
              if (rm.accesscd != null) {
                await _service.deleteMapping(
                  rm.accesscd!,
                  rm.prodcode,
                  rm.userscd,
                );
              }
            }

            // Upsert the new/modified mappings
            await _service.updateMappings(mappings, pgmId: _accessPgmId);
            OperationalLogService().logAction(programId: 'User Product Mapping', action: 'U');
          } else {
            await _service.createMappings(mappings, pgmId: _accessPgmId);
            OperationalLogService().logAction(programId: 'User Product Mapping', action: 'I');
          }
          await _loadData();
          _go(_V.list);
          _toast(
            isEdit
                ? 'Product mapping updated successfully!'
                : 'Product mapping created successfully!',
          );
        } catch (e) {
          _toast('Failed to save Product Mapping: $e', err: true);
        }
      },
      onCancel: () => _go(_V.list),
      onToast: _toast,
      page: _page,
      card: _card,
      fBtn: _fBtn,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  VIEW SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _viewScreen() {
    final r = _sel!;
    final u = _userByCodeAndOrg(r.userCode, r.orgCode);
    final orgDisplay = _orgOptions.firstWhere(
      (o) => _orgCode(o) == r.orgCode,
      orElse: () => r.orgCode,
    );
    final assignments = r.productCodes
        .map(
          (product) => _ProductAssignment(
            productName: product,
            role: _defaultRoleForProduct(product),
            status: r.status,
          ),
        )
        .toList();

    return _page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Product Mapping Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _fBtn(
                  'Audit Details',
                  Icons.history_rounded,
                  Colors.white,
                  _kP,
                  _kP,
                  onTap: () => AuditDetailsDialog.show(
                    context,
                    title: 'Audit Details',
                    subtitle: 'Product mapping audit trail for ${r.userCode}',
                    cuser: r.euser,
                    cdate:
                        (r.euser == null ||
                            r.euser!.trim() == '-' ||
                            r.edate == null)
                        ? '-'
                        : _formatAuditDate(r.edate!.toIso8601String()),
                    euser: r.cuser,
                    edate: r.cdate == null
                        ? '-'
                        : _formatAuditDate(r.cdate!.toIso8601String()),
                    auser: r.auser,
                    adate: r.adate == null
                        ? '-'
                        : _formatAuditDate(r.adate!.toIso8601String()),
                  ),
                ),
                const SizedBox(width: 10),
                _fBtn(
                  'Back',
                  Icons.arrow_back_rounded,
                  _kP,
                  Colors.white,
                  _kP,
                  onTap: () => _go(_V.list),
                ),
              ],
            ),
          ),

          _card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_kPL, Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.display,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kP,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              orgDisplay,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(r.active),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ORGANIZATION & USER'),
                      Row(
                        children: [
                          Expanded(
                            child: _LockedField(
                              label: 'Organization',
                              value: orgDisplay,
                              icon: Icons.business_rounded,
                              showLock: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _LockedField(
                              label: 'User',
                              value: u.display,
                              icon: Icons.person_outline_rounded,
                              showLock: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(child: SizedBox()),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _sectionLabel('PRODUCT ACCESS'),
                      _ProdGrid(
                        all: _prodsForOrg(r.orgCode),
                        selected: r.productCodes,
                        onToggle: null,
                        readOnlyProducts: _prodsForOrg(r.orgCode),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _fBtn(
                        'Back',
                        Icons.arrow_back_rounded,
                        _kP,
                        Colors.white,
                        _kP,
                        onTap: () => _go(_V.list),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DELETE SCREEN
  // ══════════════════════════════════════════════════════════════════════════
  Widget _deleteScreen() {
    final r = _sel!;
    //  final u          = _userByCode(r.userCode); Aasai
    final u = _userByCodeAndOrg(r.userCode, r.orgCode);

    final orgDisplay = _orgOptions.firstWhere(
      (o) => _orgCode(o) == r.orgCode,
      orElse: () => r.orgCode,
    );

    return StatefulBuilder(
      builder: (_, ls) => _page(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Delete Product Mapping',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _card(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: _kRL,
                        child: Column(
                          children: [
                            const Icon(
                              Icons.delete_outline_rounded,
                              size: 24,
                              color: _kR,
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Delete Confirmation',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kR,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'This action cannot be undone',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kR.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            const Text(
                              'You are about to delete this user product mapping.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: _kMuted),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _kBorder),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'RECORD TO BE DELETED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _kHint,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _delRow(
                                    'Organization',
                                    orgDisplay,
                                    red: true,
                                  ),
                                  const SizedBox(height: 6),
                                  _delRow('User', u.display, red: true),
                                  const SizedBox(height: 6),
                                  _delRow(
                                    'Products',
                                    r.productCodes.isEmpty
                                        ? 'None'
                                        : r.productCodes.join(', '),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () =>
                                  ls(() => setState(() => _delOk = !_delOk)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _kRL,
                                  border: Border.all(color: _kRB),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'I understand this will permanently remove the user\'s access to all mapped products.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _kR,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: _delOk ? _kR : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: _kR,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _delOk
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: _kBorder)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _fBtn(
                              'Cancel',
                              Icons.close_rounded,
                              Colors.white,
                              _kP,
                              _kP,
                              onTap: () => _go(_V.list),
                            ),
                            const SizedBox(width: 10),
                            _fBtn(
                              'Confirm Delete',
                              Icons.delete_outline_rounded,
                              _delOk ? _kR : Colors.white,
                              _delOk ? Colors.white : _kHint,
                              _delOk ? _kR : _kBorder,
                              onTap: _delOk
                                  ? () async {
                                      try {
                                        final orgCodeInt =
                                            int.tryParse(r.orgCode) ?? 0;
                                        await _service.deleteMappingsForUser(
                                          orgCodeInt,
                                          r.userCode,
                                        );
                                        OperationalLogService().logAction(programId: 'User Product Mapping', action: 'D');
                                        setState(
                                          () => _data.removeWhere(
                                            (d) => d.id == r.id,
                                          ),
                                        );
                                        _go(_V.list);
                                        _toast('Product mapping deleted!');
                                      } catch (e) {
                                        _toast(
                                          'Error deleting mapping: $e',
                                          err: true,
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
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
    );
  }

  Widget _delRow(String k, String v, {bool red = false}) => Row(
    children: [
      SizedBox(
        width: 130,
        child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted)),
      ),
      Expanded(
        child: Text(
          v,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: red ? _kR : _kText,
          ),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _kBg,
    body: switch (_view) {
      _V.list => _listScreen(),
      _V.create => _formScreen(isEdit: false),
      _V.view => _viewScreen(),
      _V.edit => _formScreen(isEdit: true),
      _V.delete => _deleteScreen(),
     _V.bulkUpload => _buildBulkUpload(),
    },
  );

  
  Widget _buildBulkUpload() {
    return BulkUploadDialog(
      title: 'Bulk Upload Products',
      entityName: 'Products',
      validateEndpoint: '/user-access-mappings/bulk-upload',
      uploadEndpoint: '/user-access-mappings/bulk-process',
      templateAssetPath: 'assets/User_Product_Mapping_Bulk_Upload_Template.xlsx',
      templateFileName: 'User_Product_Mapping_Bulk_Upload_Template.xlsx',
      templateSheetName: 'User Product Mapping Upload',
      programName: 'User_Product_Mapping',
      onComplete: () {
        _loadData();
        setState(() => _view = _V.list);
      },
      onCancel: () {
        setState(() => _view = _V.list);
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHANGE 1: Org Filter Button for list screen
// ══════════════════════════════════════════════════════════════════════════════
class _OrgFilterButton extends StatefulWidget {
  final String? selectedOrgCode;
  final List<String> orgOptions;
  final ValueChanged<String?> onChanged;

  const _OrgFilterButton({
    this.selectedOrgCode,
    required this.orgOptions,
    required this.onChanged,
  });

  @override
  State<_OrgFilterButton> createState() => _OrgFilterButtonState();
}

class _OrgFilterButtonState extends State<_OrgFilterButton> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _rm();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _rm() {
    _ov?.remove();
    _ov = null;
  }

  void _open() {
    _rm();
    _searchCtrl.clear();
    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final ovBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ovBox);
    final sz = rb.size;

    const dropW = 300.0;
    final left = (pos.dx + sz.width - dropW).clamp(8.0, double.infinity);

    _ov = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _rm,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: pos.dy + sz.height + 4,
                width: dropW,
                child: StatefulBuilder(
                  builder: (c2, ss) {
                    final q = _searchCtrl.text.toLowerCase();
                    final filtered = widget.orgOptions
                        .where((o) => o.toLowerCase().contains(q))
                        .toList();

                    return Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 280),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _kBorder),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Search box inside dropdown
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: TextField(
                                controller: _searchCtrl,
                                autofocus: true,
                                onChanged: (_) => ss(() {}),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _kText,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search organization...',
                                  hintStyle: const TextStyle(
                                    fontSize: 12,
                                    color: _kHint,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                    color: _kHint,
                                  ),
                                  filled: true,
                                  fillColor: _kSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: _kBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: _kBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: _kBorder),
                            Flexible(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                shrinkWrap: true,
                                children: [
                                  // "All Organizations" option
                                  _filterItem(
                                    c2,
                                    null,
                                    'All Organizations',
                                    '',
                                  ),
                                  ...filtered.map((opt) {
                                    final code = _orgCode(opt);
                                    final name = opt.contains(' - ')
                                        ? opt.substring(opt.indexOf(' - ') + 3)
                                        : opt;
                                    return _filterItem(c2, code, name, code);
                                  }),
                                  if (filtered.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No organizations found',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _kHint,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  Widget _filterItem(
    BuildContext ctx,
    String? code,
    String name,
    String dispCode,
  ) {
    final isSel = (widget.selectedOrgCode ?? '') == (code ?? '');
    return InkWell(
      onTap: () {
        widget.onChanged(code);
        _rm();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        color: isSel ? _kPL : Colors.transparent,
        child: Row(
          children: [
            if (dispCode.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _kPL,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  dispCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kP,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: _kText,
                  fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSel) const Icon(Icons.check_rounded, size: 14, color: _kP),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        widget.selectedOrgCode != null && widget.selectedOrgCode!.isNotEmpty;

    // Find the display name of selected org
    String selectedLabel = '';
    if (hasFilter) {
      final match = widget.orgOptions.firstWhere(
        (o) => _orgCode(o) == widget.selectedOrgCode,
        orElse: () => widget.selectedOrgCode!,
      );
      selectedLabel = match.contains(' - ')
          ? match.substring(match.indexOf(' - ') + 3)
          : match;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          key: _key,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: hasFilter ? const Color(0xFF2A55A5) : _kP,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              if (hasFilter) ...[
                Text(
                  selectedLabel.length > 12
                      ? '${selectedLabel.substring(0, 12)}…'
                      : selectedLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => widget.onChanged(null),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHANGE 4: List Row — row click removed, only icons trigger actions
// ══════════════════════════════════════════════════════════════════════════════
class _ListRow extends StatefulWidget {
  final _AccessRow record;
  final String orgDisplay;
  final String userDisplay;
  final List<String> products;
  final List<double> cols;
  final bool isEven;
  final VoidCallback onView, onEdit, onDelete;
  final Widget Function(bool) statusBadge;
  final Widget Function(IconData, Color, VoidCallback) rBtn;

  final AccessPrivileges? accessPrivileges;

  const _ListRow({
    required this.record,
    required this.orgDisplay,
    required this.userDisplay,
    required this.products,
    required this.cols,
    required this.isEven,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    required this.statusBadge,
    required this.rBtn,
    this.accessPrivileges,
  });

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _hov = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    // CHANGE 4: hover still works for visual feedback but no row-level tap
    final bg = widget.isEven ? _kSurface : Colors.white;

    Widget cell(double w, Widget child) => SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Center(child: child),
      ),
    );

    return MouseRegion(
      // CHANGE 4: cursor is now 'basic' since row is not clickable
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: Container(
        // CHANGE 4: No GestureDetector wrapping the whole row — only icon buttons are clickable
        decoration: BoxDecoration(
          color: bg,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            cell(
              widget.cols[0],
              Text(
                widget.orgDisplay,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _kP,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            cell(
              widget.cols[1],
              Text(
                widget.userDisplay,
                style: const TextStyle(fontSize: 12.5, color: _kText),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            cell(
              widget.cols[2],
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: widget.products.isEmpty
                    ? [
                        const Text(
                          '—',
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                      ]
                    : widget.products
                          .map(
                            (p) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kPL,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _kPB, width: 0.8),
                              ),
                              child: Text(
                                p.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: _kP,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
              ),
            ),
            cell(widget.cols[3], widget.statusBadge(r.active)),
            cell(
              widget.cols[4],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...[
                    if (widget.accessPrivileges?.canView ?? true)
                      widget.rBtn(Icons.visibility_outlined, _kMuted, widget.onView),
                    if (widget.accessPrivileges?.canEdit ?? true)
                      widget.rBtn(Icons.edit_outlined, _kP, widget.onEdit),
                    if (widget.accessPrivileges?.canDelete ?? true)
                      widget.rBtn(Icons.delete_outline_rounded, _kR, widget.onDelete),
                  ].map((btn) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.5),
                    child: btn,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Form View
// ══════════════════════════════════════════════════════════════════════════════
class _FormView extends StatefulWidget {
  final bool isEdit;
  final _AccessRow? existing;
  final bool isAdmin;
  final String adminOrgLabel;
  final String adminOrgCode;
  final List<String> Function(String orgCode, int excludeId)
  takenUserCodesForOrg;
  final List<String> Function(String orgCode, String userCode)
  getMappedProducts;
  final String Function(String orgCode, String userCode) getMappedStatus;
  final Future<void> Function(String, String, List<_ProductAssignment>) onSave;
  final VoidCallback onCancel;
  final void Function(String, {bool err}) onToast;
  final Widget Function({required Widget child}) page;
  final Widget Function({required Widget child}) card;
  final Widget Function(
    String,
    IconData,
    Color,
    Color,
    Color, {
    VoidCallback? onTap,
  })
  fBtn;

  const _FormView({
    required this.isEdit,
    required this.existing,
    required this.isAdmin,
    required this.adminOrgLabel,
    required this.adminOrgCode,
    required this.takenUserCodesForOrg,
    required this.getMappedProducts,
    required this.getMappedStatus,
    required this.onSave,
    required this.onCancel,
    required this.onToast,
    required this.page,
    required this.card,
    required this.fBtn,
  });

  @override
  State<_FormView> createState() => _FormViewState();
}

class _FormViewState extends State<_FormView> {
  String? _selOrg;
  String? _selUserDisplay;
  String? _selStatus;
  List<_ProductAssignment> _selAssignments = [];
  bool _submitted = false;
  // CHANGE 3: track if user tried clicking the user field without selecting an org
  bool _userClickedWithoutOrg = false;

  String get _orgCodeVal => _selOrg != null ? _orgCode(_selOrg!) : '';

  List<String> get _availableProds =>
      _orgCodeVal.isNotEmpty ? _prodsForOrg(_orgCodeVal) : [];

  List<_UserDef> get _availableUsers {
    final list = _allUsers
        .where((u) => _orgCodeVal.isEmpty || u.orgCode == _orgCodeVal)
        .toList();
    final seen = <String>{};
    final uniqueList = list.where((u) => seen.add(u.code)).toList();

    // If it's a new mapping (widget.existing == null), only users not mapped to any product or mapped only to Access Manager are allowed
    if (widget.existing == null && _orgCodeVal.isNotEmpty) {
      return uniqueList.where((u) {
        final mappedProds = widget.getMappedProducts(_orgCodeVal, u.code);
        if (mappedProds.isEmpty) return true;
        if (mappedProds.length == 1 &&
            mappedProds.first.toLowerCase() == 'access manager')
          return true;
        return false;
      }).toList();
    }
    return uniqueList;
  }

  List<String> get _userDisplayItems =>
      _availableUsers.map((u) => u.display).toList();

  String get _selectedUserCode {
    if (_selUserDisplay == null || _selUserDisplay!.isEmpty) return '';
    return _selUserDisplay!.split(' - ').first.trim();
  }

  bool get _isUserAlreadyMapped {
    if (_orgCodeVal.isEmpty || _selectedUserCode.isEmpty) return false;
    if (widget.isEdit) return true;
    return widget
        .takenUserCodesForOrg(_orgCodeVal, -1)
        .contains(_selectedUserCode);
  }

  bool get _orgErr => _submitted && _selOrg == null;
  bool get _userErr => _submitted && _selUserDisplay == null;
  bool get _prodErr => _submitted && _selAssignments.isEmpty;
  List<String> get _selProds =>
      _selAssignments.map((item) => item.productName).toList();

  void _ensureAccessManager(String status) {
    final hasAccessManager = _selAssignments.any(
      (a) => a.productName.toLowerCase() == 'access manager',
    );
    if (!hasAccessManager) {
      final accMgrName = _availableProds.firstWhere(
        (p) => p.toLowerCase() == 'access manager',
        orElse: () => 'Access Manager',
      );
      _selAssignments.add(
        _ProductAssignment(
          productName: accMgrName,
          role: _defaultRoleForProduct(accMgrName),
          status: status,
        ),
      );
    }
  }

  void _onUserChanged(String? val) {
    setState(() {
      _selUserDisplay = val;
      _userClickedWithoutOrg = false;
      if (val != null && val.isNotEmpty) {
        final uCode = val.split(' - ').first.trim();
        final mappedProds = widget.getMappedProducts(_orgCodeVal, uCode);
        final status = widget.getMappedStatus(_orgCodeVal, uCode);

        _selAssignments = mappedProds
            .map(
              (product) => _ProductAssignment(
                productName: product,
                role: _defaultRoleForProduct(product),
                status: status,
              ),
            )
            .toList();

        final isAlreadyMapped = widget
            .takenUserCodesForOrg(_orgCodeVal, -1)
            .contains(uCode);
        if (isAlreadyMapped) {
          _ensureAccessManager(status);
        }
      } else {
        _selAssignments = [];
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _selOrg = _orgOptions.firstWhere(
        (o) => _orgCode(o) == ex.orgCode,
        orElse: () => '',
      );
      if (_selOrg!.isEmpty) _selOrg = null;
      final u = _userByCodeAndOrg(ex.userCode, ex.orgCode);

      _selUserDisplay = u.display.isNotEmpty ? u.display : null;
      _selAssignments = ex.productCodes
          .map(
            (product) => _ProductAssignment(
              productName: product,
              role: _defaultRoleForProduct(product),
              status: ex.status,
            ),
          )
          .toList();
      _ensureAccessManager(ex.status);
    } else if (widget.isAdmin && widget.adminOrgLabel.isNotEmpty) {
      _selOrg = widget.adminOrgLabel;
    }
  }

  void _onOrgChanged(String? val) {
    setState(() {
      _selOrg = val;
      _selUserDisplay = null;
      _selAssignments = [];
      _userClickedWithoutOrg = false;
    });
  }

  Widget _sectionLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _kP,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        const Divider(height: 1, color: _kBorder),
        const SizedBox(height: 2),
      ],
    ),
  );

  // void _toggleProduct(String productName) {
  //   final existingIndex = _selAssignments.indexWhere(
  //     (item) => item.productName == productName,
  //   );

  //   if (existingIndex >= 0) {
  //     setState(() => _selAssignments.removeAt(existingIndex));
  //     return;
  //   }

  //   if ((_selStatus ?? '').isEmpty) {
  //     widget.onToast(
  //       'Select status before adding a product.',
  //       err: true,
  //     );
  //     return;
  //   }

  //   setState(() {
  //     _selAssignments.add(
  //       _ProductAssignment(
  //         productName: productName,
  //         role: _defaultRoleForProduct(productName),
  //         status: _selStatus!,
  //       ),
  //     );
  //     _selStatus = null;
  //   });
  // }
  void _toggleProduct(String productName) {
    final existingIndex = _selAssignments.indexWhere(
      (item) => item.productName == productName,
    );

    if (existingIndex >= 0) {
      setState(() => _selAssignments.removeAt(existingIndex));
      return;
    }

    // ✅ Status check removed — products can be added freely
    setState(() {
      _selAssignments.add(
        _ProductAssignment(
          productName: productName,
          role: _defaultRoleForProduct(productName),
          status: 'Active', // default status
        ),
      );
    });
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (_orgErr || _userErr || _prodErr) {
      widget.onToast('Please fill all required fields.', err: true);
      return;
    }
    await widget.onSave(
      _orgCodeVal,
      _selectedUserCode,
      List<_ProductAssignment>.from(_selAssignments),
    );
  }

  bool get _orgLocked => widget.isAdmin || widget.isEdit;
  bool get _userLocked => widget.isEdit;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return widget.page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEdit
                        ? 'Edit Product Mapping'
                        : 'Create New Product Mapping',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                widget.fBtn(
                  'Back',
                  Icons.arrow_back_rounded,
                  _kP,
                  Colors.white,
                  _kP,
                  onTap: widget.onCancel,
                ),
              ],
            ),
          ),

          widget.card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'Modify Access Configuration'
                                  : 'Access Configuration',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEdit
                                  ? 'Organization and user details cannot be changed in edit mode. You can update assigned products only.'
                                  : 'Select a user, and assign the required products to configure access.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: _kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isEdit ? _kOBG : _kPL,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isEdit ? _kOB : _kPB),
                        ),
                        child: Text(
                          isEdit ? 'EDIT MODE' : 'NEW RECORD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isEdit ? _kOT : _kP,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isEdit)
                  Container(
                    margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _kWarnBG,
                      border: Border.all(color: _kWarnB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: _kWarnT,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'locked fields cannot be modified',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _kWarnT,
                          ),
                        ),
                      ],
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('ORGANIZATION & USER'),
                      Row(
                        children: [
                          // CHANGE 2: Org dropdown is now searchable (uses _SearchableOrgDrop)
                          Expanded(
                            child: _orgLocked
                                ? _LockedField(
                                    label: 'Organization',
                                    value: _selOrg ?? '',
                                    icon: Icons.business_rounded,
                                  )
                                : _SearchableOrgDrop(
                                    label: 'Organization',
                                    value: _selOrg,
                                    items: _orgOptions,
                                    hasError: _orgErr,
                                    onChanged: _onOrgChanged,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          // CHANGE 3: user field — show error on click when no org, remove placeholder
                          Expanded(
                            child: _orgCodeVal.isNotEmpty
                                ? (_userLocked
                                      ? _LockedField(
                                          label: 'User',
                                          value: _selUserDisplay ?? '',
                                          icon: Icons.person_outline_rounded,
                                        )
                                      : _SearchableUserDrop(
                                          label: 'User',
                                          value: _selUserDisplay,
                                          items: _userDisplayItems,
                                          hasError:
                                              _userErr ||
                                              _userClickedWithoutOrg,
                                          onChanged: _onUserChanged,
                                        ))
                                // CHANGE 3: When no org selected, show a disabled-looking field
                                // that shows an error message when tapped instead of a placeholder
                                : _NoOrgUserField(
                                    hasError: _userClickedWithoutOrg,
                                    onTap: () {
                                      setState(
                                        () => _userClickedWithoutOrg = true,
                                      );
                                      widget.onToast(
                                        'Please select an organization first.',
                                        err: true,
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 14),

                          const Expanded(child: SizedBox()),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      const SizedBox(height: 22),

                      if (_orgCodeVal.isNotEmpty) ...[
                        _sectionLabel('PRODUCT ACCESS'),
                        _ProdGrid(
                          all: _availableProds,
                          selected: _selProds,
                          hasError: _prodErr,
                          onToggle: _toggleProduct,
                          readOnlyProducts: [
                            if (!isEdit && _isUserAlreadyMapped)
                              'Access Manager',
                          ],
                        ),
                        const SizedBox(height: 14),
                        _SelectedProductAssignments(
                          items: _selAssignments,
                          onRemove: (productName) => setState(() {
                            _selAssignments.removeWhere(
                              (item) => item.productName == productName,
                            );
                          }),
                          onToggleStatus: (productName) => setState(() {
                            final item = _selAssignments.firstWhere(
                              (i) => i.productName == productName,
                            );
                            item.status = item.isActive ? 'Inactive' : 'Active';
                          }),
                          readOnlyProducts: [
                            if (!isEdit && _isUserAlreadyMapped)
                              'Access Manager',
                          ],
                        ),
                      ] else ...[
                        _sectionLabel('PRODUCT ACCESS'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kBorder),
                          ),
                          child: const Center(
                            child: Text(
                              'Select an organization to view available products',
                              style: TextStyle(fontSize: 12, color: _kHint),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      widget.fBtn(
                        'Cancel',
                        Icons.close_rounded,
                        Colors.white,
                        _kP,
                        _kP,
                        onTap: widget.onCancel,
                      ),
                      const SizedBox(width: 10),
                      widget.fBtn(
                        isEdit ? 'Save Changes' : 'Create Mapping',
                        Icons.check_rounded,
                        _kP,
                        Colors.white,
                        _kP,
                        onTap: () {
                          _save();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHANGE 3: No-Org User Field — tappable, shows error when clicked without org
// ══════════════════════════════════════════════════════════════════════════════
class _NoOrgUserField extends StatelessWidget {
  final bool hasError;
  final VoidCallback onTap;

  const _NoOrgUserField({required this.hasError, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError ? _kR : _kBorder;
    final iconColor = hasError ? _kR : _kHint;
    final textColor = hasError ? _kR : _kHint;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 6),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ),
              Expanded(
                child: Text(
                  hasError
                      ? 'Select organization first'
                      : 'Select organization first',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CHANGE 2: Searchable Org Dropdown
// ══════════════════════════════════════════════════════════════════════════════
class _SearchableOrgDrop extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool hasError;

  const _SearchableOrgDrop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<_SearchableOrgDrop> createState() => _SearchableOrgDropState();
}

class _SearchableOrgDropState extends State<_SearchableOrgDrop>
    with TickerProviderStateMixin {
  late AnimationController _lA, _dA;
  late Animation<double> _lTop, _lSz, _dF, _dS;
  OverlayEntry? _ov;
  final _link = LayerLink();
  bool _open = false;

  bool get _floated =>
      _open ||
      (widget.value != null && widget.value!.isNotEmpty) ||
      widget.hasError;

  @override
  void initState() {
    super.initState();
    _lA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _lTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _lSz = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _dA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _dF = CurvedAnimation(parent: _dA, curve: Curves.easeOut);
    _dS = Tween<double>(
      begin: -4,
      end: 0,
    ).animate(CurvedAnimation(parent: _dA, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_SearchableOrgDrop o) {
    super.didUpdateWidget(o);
    _floated ? _lA.forward() : _lA.reverse();
    if (_open) _ov?.markNeedsBuild();
  }

  @override
  void dispose() {
    _rmOv();
    _lA.dispose();
    _dA.dispose();
    super.dispose();
  }

  void _rmOv() {
    _ov?.remove();
    _ov = null;
  }

  void _openDrop() {
    if (_open) return;
    setState(() => _open = true);
    _lA.forward();
    _dA.forward(from: 0);
    final box = context.findRenderObject() as RenderBox?;
    final sz = box?.size ?? Size.zero;

    _ov = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDrop,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, sz.height + 3),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _dA,
                  builder: (_, ch) => Transform.translate(
                    offset: Offset(0, _dS.value),
                    child: Opacity(opacity: _dF.value, child: ch),
                  ),
                  child: _OrgSearchPanel(
                    items: widget.items,
                    selected: widget.value,
                    width: sz.width,
                    onSelect: (v) {
                      _closeDrop();
                      widget.onChanged(v);
                    },
                    onCancel: _closeDrop,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  void _closeDrop() {
    _dA.reverse().then((_) => _rmOv());
    setState(() => _open = false);
    if (!_floated) _lA.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError ? _kR : _kP;
    final fullVal = widget.value ?? '';

    return CompositedTransformTarget(
      link: _link,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _openDrop,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      Icons.business_rounded,
                      size: 14,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                  Expanded(
                    child: fullVal.isNotEmpty
                        ? Text(
                            fullVal,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : (_floated
                              ? const Text(
                                  'Select organization',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _lA,
            builder: (_, __) => Positioned(
              top: _lTop.value,
              left: 28,
              child: IgnorePointer(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: _lSz.value,
                      fontWeight: FontWeight.w600,
                      color: widget.hasError ? _kR : _kP,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Org Search Panel ──────────────────────────────────────────────────────────
class _OrgSearchPanel extends StatefulWidget {
  final List<String> items;
  final String? selected;
  final double width;
  final ValueChanged<String> onSelect;
  final VoidCallback? onCancel;

  const _OrgSearchPanel({
    required this.items,
    required this.selected,
    required this.width,
    required this.onSelect,
    this.onCancel,
  });

  @override
  State<_OrgSearchPanel> createState() => _OrgSearchPanelState();
}

class _OrgSearchPanelState extends State<_OrgSearchPanel> {
  String _q = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
    final idx = widget.items.indexOf(widget.selected ?? '');
    if (idx >= 0) {
      _highlightedIndex = idx;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_q.isEmpty) return widget.items;
    return widget.items
        .where((i) => i.toLowerCase().contains(_q.toLowerCase()))
        .toList();
  }

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

  void _selectHighlighted(List<String> filtered) {
    if (filtered.isNotEmpty &&
        _highlightedIndex >= 0 &&
        _highlightedIndex < filtered.length) {
      widget.onSelect(filtered[_highlightedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _highlightedIndex = (_highlightedIndex + 1).clamp(
              0,
              filtered.length - 1,
            );
          });
          _scrollToHighlighted();
        } else if (key == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _highlightedIndex = (_highlightedIndex - 1).clamp(
              0,
              filtered.length - 1,
            );
          });
          _scrollToHighlighted();
        } else if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          _selectHighlighted(filtered);
        } else if (key == LogicalKeyboardKey.escape) {
          if (widget.onCancel != null) widget.onCancel!();
        }
      },
      child: GestureDetector(
        onTap: () {},
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: widget.width,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() {
                      _q = v;
                      _highlightedIndex = 0;
                    }),
                    onSubmitted: (_) => _selectHighlighted(filtered),
                    style: const TextStyle(fontSize: 13, color: _kText),
                    decoration: InputDecoration(
                      hintText: 'Search organization…',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      suffixIcon: _q.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _q = '');
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: _kSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),

                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No organizations found',
                              style: TextStyle(fontSize: 12, color: _kHint),
                            ),
                          ),
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (_, i) {
                              final it = filtered[i];
                              final sel = it == widget.selected;
                              final code = _orgCode(it);
                              final name = it.contains(' - ')
                                  ? it.substring(it.indexOf(' - ') + 3)
                                  : it;
                              return _OrgListTile(
                                display: it,
                                code: code,
                                name: name,
                                isSelected: sel,
                                isHighlighted: i == _highlightedIndex,
                                query: _q,
                                onTap: () => widget.onSelect(it),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Org Tile ──────────────────────────────────────────────────────────────────
class _OrgListTile extends StatefulWidget {
  final String display, code, name, query;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _OrgListTile({
    required this.display,
    required this.code,
    required this.name,
    required this.isSelected,
    this.isHighlighted = false,
    required this.query,
    required this.onTap,
  });

  @override
  State<_OrgListTile> createState() => _OrgListTileState();
}

class _OrgListTileState extends State<_OrgListTile> {
  bool _hov = false;

  InlineSpan _highlight(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);
    final lower = text.toLowerCase();
    final qL = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(qL, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
            color: _kP,
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFFDBEAFE),
          ),
        ),
      );
      start = idx + query.length;
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: widget.isSelected
              ? _kPL
              : (widget.isHighlighted || _hov
                    ? _kPL.withOpacity(0.5)
                    : Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.isSelected ? _kP : _kPL,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: widget.isSelected ? _kPD : _kPB),
                ),
                child: Text(
                  widget.code,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.isSelected ? Colors.white : _kP,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              widget.isSelected || widget.isHighlighted || _hov
                              ? _kP
                              : _kText,
                          fontWeight:
                              widget.isSelected || widget.isHighlighted || _hov
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        children: [_highlight(widget.name, widget.query)],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_rounded, size: 14, color: _kP),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Searchable User Dropdown
// ══════════════════════════════════════════════════════════════════════════════
class _SearchableUserDrop extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final bool hasError;

  const _SearchableUserDrop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  State<_SearchableUserDrop> createState() => _SearchableUserDropState();
}

class _SearchableUserDropState extends State<_SearchableUserDrop>
    with TickerProviderStateMixin {
  late AnimationController _lA, _dA;
  late Animation<double> _lTop, _lSz, _dF, _dS;
  OverlayEntry? _ov;
  final _link = LayerLink();
  bool _open = false;

  bool get _floated =>
      _open ||
      (widget.value != null && widget.value!.isNotEmpty) ||
      widget.hasError;

  @override
  void initState() {
    super.initState();
    _lA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _lTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _lSz = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _dA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _dF = CurvedAnimation(parent: _dA, curve: Curves.easeOut);
    _dS = Tween<double>(
      begin: -4,
      end: 0,
    ).animate(CurvedAnimation(parent: _dA, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_SearchableUserDrop o) {
    super.didUpdateWidget(o);
    _floated ? _lA.forward() : _lA.reverse();
    if (_open) _ov?.markNeedsBuild();
  }

  @override
  void dispose() {
    _rmOv();
    _lA.dispose();
    _dA.dispose();
    super.dispose();
  }

  void _rmOv() {
    _ov?.remove();
    _ov = null;
  }

  void _openDrop() {
    if (_open) return;
    setState(() => _open = true);
    _lA.forward();
    _dA.forward(from: 0);
    final box = context.findRenderObject() as RenderBox?;
    final sz = box?.size ?? Size.zero;
    _ov = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDrop,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, sz.height + 3),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _dA,
                  builder: (_, ch) => Transform.translate(
                    offset: Offset(0, _dS.value),
                    child: Opacity(opacity: _dF.value, child: ch),
                  ),
                  child: _UserSearchPanel(
                    items: widget.items,
                    selected: widget.value,
                    width: sz.width,
                    onSelect: (v) {
                      _closeDrop();
                      widget.onChanged(v);
                    },
                    onCancel: _closeDrop,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  void _closeDrop() {
    _dA.reverse().then((_) => _rmOv());
    setState(() => _open = false);
    if (!_floated) _lA.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError ? _kR : _kP;
    final displayVal = widget.value ?? '';

    return CompositedTransformTarget(
      link: _link,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: _openDrop,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                  Expanded(
                    child: displayVal.isNotEmpty
                        ? Text(
                            displayVal,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : (_floated
                              ? const Text(
                                  'Select a user',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 18,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _lA,
            builder: (_, __) => Positioned(
              top: _lTop.value,
              left: 28,
              child: IgnorePointer(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: _lSz.value,
                      fontWeight: FontWeight.w600,
                      color: widget.hasError ? _kR : _kP,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search panel ──────────────────────────────────────────────────────────────
class _UserSearchPanel extends StatefulWidget {
  final List<String> items;
  final String? selected;
  final double width;
  final ValueChanged<String> onSelect;
  final VoidCallback? onCancel;

  const _UserSearchPanel({
    required this.items,
    required this.selected,
    required this.width,
    required this.onSelect,
    this.onCancel,
  });

  @override
  State<_UserSearchPanel> createState() => _UserSearchPanelState();
}

class _UserSearchPanelState extends State<_UserSearchPanel> {
  String _q = '';
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
    final idx = widget.items.indexOf(widget.selected ?? '');
    if (idx >= 0) {
      _highlightedIndex = idx;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_q.isEmpty) return widget.items;
    return widget.items
        .where((i) => i.toLowerCase().contains(_q.toLowerCase()))
        .toList();
  }

  String _initials(String display) {
    final parts = display.split(' - ');
    if (parts.length > 1) {
      final nameParts = parts.sublist(1).join(' - ').trim().split(' ');
      if (nameParts.length >= 2)
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '?';
    }
    return display.isNotEmpty ? display[0].toUpperCase() : '?';
  }

  void _scrollToHighlighted() {
    const itemH = 50.0;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _highlightedIndex * itemH,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectHighlighted(List<String> filtered) {
    if (filtered.isNotEmpty &&
        _highlightedIndex >= 0 &&
        _highlightedIndex < filtered.length) {
      widget.onSelect(filtered[_highlightedIndex]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowDown) {
          setState(() {
            _highlightedIndex = (_highlightedIndex + 1).clamp(
              0,
              filtered.length - 1,
            );
          });
          _scrollToHighlighted();
        } else if (key == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _highlightedIndex = (_highlightedIndex - 1).clamp(
              0,
              filtered.length - 1,
            );
          });
          _scrollToHighlighted();
        } else if (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) {
          _selectHighlighted(filtered);
        } else if (key == LogicalKeyboardKey.escape) {
          if (widget.onCancel != null) widget.onCancel!();
        }
      },
      child: GestureDetector(
        onTap: () {},
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: widget.width,
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() {
                      _q = v;
                      _highlightedIndex = 0;
                    }),
                    onSubmitted: (_) => _selectHighlighted(filtered),
                    style: const TextStyle(fontSize: 13, color: _kText),
                    decoration: InputDecoration(
                      hintText: 'Search by name or code…',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      suffixIcon: _q.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _q = '');
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: _kSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),

                Flexible(
                  child: filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(fontSize: 12, color: _kHint),
                            ),
                          ),
                        )
                      : Scrollbar(
                          thumbVisibility: true,
                          child: ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (_, i) {
                              final it = filtered[i];
                              final sel = it == widget.selected;
                              return _UserListTile(
                                display: it,
                                initials: _initials(it),
                                isSelected: sel,
                                isHighlighted: i == _highlightedIndex,
                                query: _q,
                                onTap: () => widget.onSelect(it),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── User tile ─────────────────────────────────────────────────────────────────
class _UserListTile extends StatefulWidget {
  final String display, initials, query;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  const _UserListTile({
    required this.display,
    required this.initials,
    required this.isSelected,
    this.isHighlighted = false,
    required this.query,
    required this.onTap,
  });
  @override
  State<_UserListTile> createState() => _UserListTileState();
}

class _UserListTileState extends State<_UserListTile> {
  bool _hov = false;

  InlineSpan _highlight(String text, String query) {
    if (query.isEmpty) return TextSpan(text: text);
    final lower = text.toLowerCase();
    final qL = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = lower.indexOf(qL, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) spans.add(TextSpan(text: text.substring(start, idx)));
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: const TextStyle(
            color: _kP,
            fontWeight: FontWeight.w700,
            backgroundColor: Color(0xFFDBEAFE),
          ),
        ),
      );
      start = idx + query.length;
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final dashIdx = widget.display.indexOf(' - ');
    final code = dashIdx >= 0
        ? widget.display.substring(0, dashIdx)
        : widget.display;
    final name = dashIdx >= 0 ? widget.display.substring(dashIdx + 3) : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          color: widget.isSelected
              ? _kPL
              : (widget.isHighlighted || _hov
                    ? _kPL.withOpacity(0.5)
                    : Colors.transparent),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isSelected ? _kP : _kPL,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isSelected ? _kPD : _kPB,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.initials,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected ? Colors.white : _kP,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (name.isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                widget.isSelected ||
                                    widget.isHighlighted ||
                                    _hov
                                ? _kP
                                : _kText,
                            fontWeight:
                                widget.isSelected ||
                                    widget.isHighlighted ||
                                    _hov
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          children: [_highlight(name, widget.query)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                widget.isSelected ||
                                    widget.isHighlighted ||
                                    _hov
                                ? _kP
                                : _kText,
                            fontWeight:
                                widget.isSelected ||
                                    widget.isHighlighted ||
                                    _hov
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          children: [_highlight(code, widget.query)],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: _kMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            _highlight('User Code: $code', widget.query),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isSelected)
                const Icon(Icons.check_rounded, size: 14, color: _kP),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Product Grid
// ══════════════════════════════════════════════════════════════════════════════
class _ProdGrid extends StatefulWidget {
  final List<String> all, selected;
  final ValueChanged<String>? onToggle;
  final bool hasError;
  final List<String> readOnlyProducts;
  const _ProdGrid({
    required this.all,
    required this.selected,
    this.onToggle,
    this.hasError = false,
    this.readOnlyProducts = const [],
  });
  @override
  State<_ProdGrid> createState() => _ProdGridState();
}

class _ProdGridState extends State<_ProdGrid> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final ro = widget.onToggle == null;
    final borderColor = widget.hasError ? _kR : _kP;
    final filtered = widget.all
        .where((p) => p.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
          child: Row(
            children: [
              if (!ro)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.hasError ? _kRL : _kPL,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: widget.hasError ? _kRB : _kPB),
                  ),
                  child: Text(
                    widget.hasError
                        ? 'Select at least one product'
                        : '${widget.selected.length}/${widget.all.length} selected',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!ro)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProdSearch(
                      width: 190,
                      onChanged: (v) => setState(() => _q = v),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: widget.selected.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'No products selected',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                ),
                              )
                            : Row(
                                children: widget.selected.map((p) {
                                  final isProdReadOnly =
                                      ro ||
                                      widget.readOnlyProducts.any(
                                        (rp) =>
                                            rp.toLowerCase() == p.toLowerCase(),
                                      );
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 5),
                                    child: _SelChip(
                                      label: p,
                                      icon: _prodIcon(p),
                                      readOnly: isProdReadOnly,
                                      onRemove: isProdReadOnly
                                          ? null
                                          : () => widget.onToggle!(p),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ),
                  ],
                ),
              if (!ro) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
              ],
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (_, cons) {
                    final cardW = (cons.maxWidth - 30) / 4;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: filtered.map((p) {
                        final sel = widget.selected.contains(p);
                        final isReadOnlyProduct =
                            ro ||
                            widget.readOnlyProducts.any(
                              (rp) => rp.toLowerCase() == p.toLowerCase(),
                            );
                        return SizedBox(
                          width: cardW,
                          height: 52,
                          child: _ProdCard(
                            label: p,
                            icon: _prodIcon(p),
                            selected: sel,
                            readOnly: isReadOnlyProduct,
                            onYes: isReadOnlyProduct
                                ? null
                                : () {
                                    if (!sel) widget.onToggle!(p);
                                  },
                            onNo: isReadOnlyProduct
                                ? null
                                : () {
                                    if (sel) widget.onToggle!(p);
                                  },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  Product Field — read-only chips for view screen
// ══════════════════════════════════════════════════════════════════════════════
class _ProductField extends StatelessWidget {
  final List<String> products;
  const _ProductField({required this.products});
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: products.isEmpty
        ? [
            const Text(
              'No products assigned',
              style: TextStyle(
                fontSize: 11,
                color: _kMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ]
        : products
              .map(
                (prod) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _kPL,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _kPB, width: 1),
                  ),
                  child: Text(
                    prod.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kP,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              )
              .toList(),
  );
}

class _SelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onRemove;
  const _SelChip({
    required this.label,
    required this.icon,
    required this.readOnly,
    this.onRemove,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
    decoration: BoxDecoration(
      color: _kPL,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kPB, width: 1.2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _kP),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kP,
          ),
        ),
        if (!readOnly && onRemove != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: _kP.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 9, color: _kP),
            ),
          ),
        ],
      ],
    ),
  );
}

class _SelectedProductAssignments extends StatelessWidget {
  final List<_ProductAssignment> items;
  final ValueChanged<String> onRemove;
  final ValueChanged<String>? onToggleStatus;
  final List<String> readOnlyProducts;

  const _SelectedProductAssignments({
    super.key,
    required this.items,
    required this.onRemove,
    this.onToggleStatus,
    this.readOnlyProducts = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Products',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final isReadOnly = readOnlyProducts.any(
              (rp) => rp.toLowerCase() == item.productName.toLowerCase(),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kText,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _kPL,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPB),
                      ),
                      child: Text(
                        item.role,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _kP,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isReadOnly || onToggleStatus == null
                          ? null
                          : () => onToggleStatus!(item.productName),
                      child: MouseRegion(
                        cursor: isReadOnly || onToggleStatus == null
                            ? SystemMouseCursors.basic
                            : SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: item.isActive ? _kGL : _kRL,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: item.isActive ? _kGB : _kRB,
                            ),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: item.isActive ? _kG : _kR,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isReadOnly) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => onRemove(item.productName),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _kRL,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _kRB),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: _kR,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ProdCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected, readOnly;
  final VoidCallback? onYes, onNo;
  const _ProdCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.readOnly,
    this.onYes,
    this.onNo,
  });
  @override
  State<_ProdCard> createState() => _ProdCardState();
}

class _ProdCardState extends State<_ProdCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: widget.readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: sel
              ? _kPL
              : (_hov && !widget.readOnly
                    ? const Color(0xFFF8FAFF)
                    : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? _kP : (_hov && !widget.readOnly ? _kPB : _kBorder),
            width: sel ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: sel ? _kP.withOpacity(0.12) : _kSurface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: sel ? _kPB : _kBorder, width: 1),
              ),
              child: Icon(widget.icon, size: 14, color: sel ? _kP : _kMuted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _kP : _kText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // ✅ Toggle button added back
            GestureDetector(
              onTap: widget.readOnly
                  ? null
                  : () => sel ? widget.onNo?.call() : widget.onYes?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 22,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? _kG : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: sel
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
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
          ],
        ),
      ),
    );
  }
}

// class _RadioBtn extends StatelessWidget {
//   final String label; final bool active, readOnly;
//   final Color activeColor, activeBg, activeBorder;
//   final VoidCallback? onTap;
//   const _RadioBtn({required this.label, required this.active, required this.activeColor, required this.activeBg, required this.activeBorder, required this.readOnly, this.onTap});
//   @override Widget build(BuildContext context) => MouseRegion(
//     cursor: readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
//     child: GestureDetector(onTap: readOnly ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 120),
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: active ? activeBg : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: active ? activeBorder : _kBorder, width: active ? 1.4 : 1.0),
//         ),
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           AnimatedContainer(duration: const Duration(milliseconds: 120),
//             width: 7, height: 7,
//             decoration: BoxDecoration(shape: BoxShape.circle,
//               color: active ? activeColor : Colors.white,
//               border: Border.all(color: active ? activeColor : const Color(0xFFCBD5E1), width: 1.4)),
//             child: active ? Center(child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null),
//           const SizedBox(width: 4),
//           Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? activeColor : _kMuted)),
//         ]),
//       )),
//   );
// }

class _StatusToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool hasError;
  const _StatusToggle({
    required this.isActive,
    required this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasError ? _kR : _kP, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.signal_cellular_alt_rounded,
            size: 16,
            color: hasError ? _kR : _kP,
          ),
          const SizedBox(width: 8),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: _kP,
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              key: ValueKey(isActive),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? _kG : _kMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onChanged(!isActive),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 24,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isActive ? _kG : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: isActive
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 18,
                      height: 18,
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
        ],
      ),
    );
  }
}

class _ProdSearch extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  const _ProdSearch({required this.width, required this.onChanged});
  @override
  State<_ProdSearch> createState() => _ProdSearchState();
}

class _ProdSearchState extends State<_ProdSearch> {
  final _f = FocusNode();
  bool _foc = false;
  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() => _foc = _f.hasFocus));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _foc ? _kP : _kBorder, width: _foc ? 1.5 : 1.0),
      borderRadius: BorderRadius.circular(9),
      boxShadow: _foc
          ? [
              BoxShadow(
                color: _kP.withOpacity(0.10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
    ),
    child: TextField(
      focusNode: _f,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 12.5, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(
          fontSize: 12,
          color: _foc ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 15,
          color: _foc ? _kP : const Color(0xFF94A3B8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 7),
        isDense: true,
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  Floating-label Dropdown
// ══════════════════════════════════════════════════════════════════════════════
class _FloatDrop extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final bool readOnly, hasError;
  const _FloatDrop({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.readOnly = false,
    this.hasError = false,
  });
  @override
  State<_FloatDrop> createState() => _FloatDropState();
}

class _FloatDropState extends State<_FloatDrop> with TickerProviderStateMixin {
  late AnimationController _lA, _dA;
  late Animation<double> _lTop, _lSz, _dF, _dS;
  OverlayEntry? _ov;
  final _link = LayerLink();
  bool _open = false;

  bool get _floated =>
      _open ||
      (widget.value != null && widget.value!.isNotEmpty) ||
      widget.hasError;

  @override
  void initState() {
    super.initState();
    _lA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _lTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _lSz = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _dA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _dF = CurvedAnimation(parent: _dA, curve: Curves.easeOut);
    _dS = Tween<double>(
      begin: -4,
      end: 0,
    ).animate(CurvedAnimation(parent: _dA, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_FloatDrop o) {
    super.didUpdateWidget(o);
    _floated ? _lA.forward() : _lA.reverse();
    if (_open) _ov?.markNeedsBuild();
  }

  @override
  void dispose() {
    _rmOv();
    _lA.dispose();
    _dA.dispose();
    super.dispose();
  }

  void _rmOv() {
    _ov?.remove();
    _ov = null;
  }

  void _openDrop() {
    if (widget.readOnly || _open) return;
    setState(() => _open = true);
    _lA.forward();
    _dA.forward(from: 0);
    final box = context.findRenderObject() as RenderBox?;
    final sz = box?.size ?? Size.zero;
    _ov = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDrop,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, sz.height + 3),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _dA,
                  builder: (_, ch) => Transform.translate(
                    offset: Offset(0, _dS.value),
                    child: Opacity(opacity: _dF.value, child: ch),
                  ),
                  child: _DropList(
                    items: widget.items,
                    selected: widget.value,
                    width: sz.width,
                    onSelect: (v) {
                      _closeDrop();
                      widget.onChanged(v);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  void _closeDrop() {
    _dA.reverse().then((_) => _rmOv());
    setState(() => _open = false);
    if (!_floated) _lA.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError ? _kR : _kP;
    final bg = widget.readOnly ? _kSurface : Colors.white;
    final displayVal = widget.value ?? '';
    return CompositedTransformTarget(
      link: _link,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onTap: widget.readOnly ? null : _openDrop,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      widget.icon,
                      size: 14,
                      color: widget.hasError ? _kR : _kP,
                    ),
                  ),
                  Expanded(
                    child: displayVal.isNotEmpty
                        ? Text(
                            displayVal,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : (_floated
                              ? Text(
                                  'Select ${widget.label}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                )
                              : const SizedBox.shrink()),
                  ),
                  if (!widget.readOnly)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        _open
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: widget.hasError ? _kR : _kP,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _lA,
            builder: (_, __) => Positioned(
              top: _lTop.value,
              left: 28,
              child: IgnorePointer(
                child: Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: _lSz.value,
                      fontWeight: FontWeight.w600,
                      color: widget.hasError ? _kR : _kP,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropList extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final double width;
  final ValueChanged<String> onSelect;
  const _DropList({
    required this.items,
    required this.selected,
    required this.width,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(maxHeight: 220),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kP, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10.5),
      child: Scrollbar(
        thumbVisibility: true,
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
          itemBuilder: (_, i) {
            final it = items[i];
            final sel = it == selected;
            return InkWell(
              onTap: () => onSelect(it),
              hoverColor: _kPL,
              child: Container(
                color: sel ? _kPL : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        it,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                          color: sel ? _kP : _kText,
                        ),
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check_rounded, size: 13, color: _kP),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  Read-only locked field
// ══════════════════════════════════════════════════════════════════════════════
class _LockedField extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final String? placeholder;
  final bool showLock;
  const _LockedField({
    required this.label,
    required this.value,
    required this.icon,
    this.placeholder,
    this.showLock = true,
  });
  @override
  State<_LockedField> createState() => _LockedFieldState();
}

class _LockedFieldState extends State<_LockedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _a;
  late Animation<double> _t, _s;
  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.value.isNotEmpty ? 1.0 : 0.0,
    );
    _t = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _a, curve: Curves.easeOut));
    _s = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _a, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_LockedField o) {
    super.didUpdateWidget(o);
    widget.value.isNotEmpty ? _a.forward() : _a.reverse();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        height: 44,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kP, width: 1.5),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(widget.icon, size: 14, color: _kP),
            ),
            Expanded(
              child: widget.value.isNotEmpty
                  ? Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : Text(
                      widget.placeholder ?? '—',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
            ),
            if (widget.showLock)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 13,
                  color: _kHint,
                ),
              ),
          ],
        ),
      ),
      AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Positioned(
          top: _t.value,
          left: 28,
          child: IgnorePointer(
            child: Container(
              color: _kSurface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: _s.value,
                  fontWeight: FontWeight.w600,
                  color: _kP,
                  letterSpacing: 0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════════
//  Search Box
// ══════════════════════════════════════════════════════════════════════════════
class _SearchBox extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  const _SearchBox({required this.width, required this.onChanged});
  @override
  State<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<_SearchBox> {
  final _f = FocusNode();
  bool _foc = false;
  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() => _foc = _f.hasFocus));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width,
    height: 38,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _foc ? _kP : _kBorder, width: _foc ? 2.0 : 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _foc
          ? [
              BoxShadow(
                color: _kP.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
    ),
    child: TextField(
      focusNode: _f,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search mapping',
        hintStyle: TextStyle(
          fontSize: 12,
          color: _foc ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 16,
          color: _foc ? _kP : const Color(0xFF94A3B8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
    ),
  );
}
