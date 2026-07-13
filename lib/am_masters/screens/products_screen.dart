import '../models/access_privileges.dart';
import '../services/program_service.dart';
import '../widgets/audit_details_dialog.dart';
import '../services/operational_log_service.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/product_model.dart';
import '../services/ProductLogoService.dart';
import '../services/organization_service.dart';
import '../services/product_service.dart';

// ── Brand colours ──────────────────────────────────────────────────────────────
const _kP = Color(0xFF3D6EBE);
const _kPL = Color(0xFFEEF3FB);
const _kPB = Color(0xFFC5D3E8);
const _kR = Color(0xFFDC2626);
const _kRL = Color(0xFFFEF2F2);
const _kRB = Color(0xFFFECACA);
const _kG = Color(0xFF16A34A);
const _kGL = Color(0xFFDCFCE7);
const _kGB = Color(0xFFBBF7D0);
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
const _kRowAlt = Color(0xFFF0F5FD);

const _kAllowedExts = ['png', 'jpg', 'jpeg'];
const _kMaxLogoBytes = 5 * 1024 * 1024;

enum _V { list, create, view, edit, delete }

class _Product {
  String orgCode, productCode, productName, homeUrl, status;
  bool active;
  Uint8List? logoBytes;
  String? logoName;
  String? logoPath;
  String? userscd;
  int? accesscd;
  String? cuser, cdate, euser, edate, auser, adate;
  String? cdateRaw, edateRaw, adateRaw;

  _Product({
    required this.orgCode,
    required this.productCode,
    required this.productName,
    required this.homeUrl,
    required this.status,
    this.active = false,
    this.logoBytes,
    this.logoName,
    this.logoPath,
    this.userscd,
    this.accesscd,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
    this.cdateRaw,
    this.edateRaw,
    this.adateRaw,
  });

  _Product cp({
    String? orgCode,
    String? productCode,
    String? productName,
    String? homeUrl,
    String? status,
    bool? active,
    Uint8List? logoBytes,
    String? logoName,
    String? logoPath,
    bool clearLogo = false,
    String? cuser,
    String? cdate,
    String? euser,
    String? edate,
    String? auser,
    String? adate,
    String? cdateRaw,
    String? edateRaw,
    String? adateRaw,
  }) => _Product(
    orgCode: orgCode ?? this.orgCode,
    productCode: productCode ?? this.productCode,
    productName: productName ?? this.productName,
    homeUrl: homeUrl ?? this.homeUrl,
    status: status ?? this.status,
    active: active ?? this.active,
    logoBytes: logoBytes ?? this.logoBytes,
    logoName: logoName ?? this.logoName,
    logoPath: clearLogo ? null : (logoPath ?? this.logoPath),
    cuser: cuser ?? this.cuser,
    cdate: cdate ?? this.cdate,
    euser: euser ?? this.euser,
    edate: edate ?? this.edate,
    auser: auser ?? this.auser,
    adate: adate ?? this.adate,
    cdateRaw: cdateRaw ?? this.cdateRaw,
    edateRaw: edateRaw ?? this.edateRaw,
    adateRaw: adateRaw ?? this.adateRaw,
    userscd: this.userscd,
    accesscd: this.accesscd,
  );

  factory _Product.fromModel(ProductModel model) => _Product(
    orgCode: model.orgCode.toString(),
    productCode: model.productCode.toString(),
    productName: model.productName,
    homeUrl: model.homeUrl,
    status: model.status ? 'Active' : 'Inactive',
    active: model.status,
    logoPath: model.logo,
    userscd: model.userscd,
    accesscd: model.accesscd,
    cuser: model.cuser,
    euser: model.euser,
    auser: model.auser,
    // Store raw ISO for sending back to backend
    cdateRaw: model.cdate,
    edateRaw: model.edate,
    adateRaw: model.adate,
    // Format for display
    cdate: _formatAuditDateStatic(model.cdate),
    edate: _formatAuditDateStatic(model.edate),
    adate: _formatAuditDateStatic(model.adate),
  );

  // ✅ Send raw ISO dates — backend can parse LocalDateTime from ISO format
  ProductModel toModel() => ProductModel(
    orgCode: int.tryParse(orgCode) ?? 1,
    productCode: int.tryParse(productCode) ?? 0,
    productName: productName,
    homeUrl: homeUrl,
    status: active,
    logo: logoPath,
    userscd: userscd,
    accesscd: accesscd,
    cuser: cuser,
    euser: euser,
    auser: auser,
    cdate: cdateRaw, // raw ISO e.g. "2026-04-10T11:38:00"
    edate: edateRaw,
    adate: adateRaw,
  );

  // Static version for use inside factory constructor
  static String? _formatAuditDateStatic(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
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
      return '${d.day.toString().padLeft(2, '0')} ${ms[d.month - 1]} ${d.year}, '
          '${h.toString().padLeft(2, '0')}:$m $p';
    } catch (_) {
      return dateStr;
    }
  }
}

// ── Toast ──────────────────────────────────────────────────────────────────────
class _ProdToast {
  static OverlayEntry? _current;
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _current?.remove();
    _current = null;
    final Color bg = isError ? _kRL : _kGL;
    final Color fg = isError ? _kR : _kG;
    final Color border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final IconData icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        bg: bg,
        fg: fg,
        border: border,
        icon: icon,
        onDismiss: () {
          _current?.remove();
          _current = null;
        },
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
    required this.message,
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
    required this.onDismiss,
  });
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide, _fade;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<double>(
      begin: -80,
      end: 0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    top: 24,
    left: 0,
    right: 0,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _slide.value),
        child: Opacity(opacity: _fade.value, child: child),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: widget.bg,
            border: Border.all(color: widget.border, width: 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: widget.fg),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.fg,
                    decoration: TextDecoration.none,
                    decorationColor: Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(Icons.close_rounded, size: 16, color: widget.fg),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Products extends StatefulWidget {
  final AccessPrivileges? accessPrivileges;
  const Products({super.key, this.accessPrivileges});
  @override
  State<Products> createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  _V _view = _V.list;
  _Product? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _orgs = [];
  final List<_Product> _data = [];

  int _page = 0;
  int _totalElements = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  String? _loadError;
  Timer? _debounce;
  bool _isLoadingProducts = false;
  int? _pgmId;

  List<_Product> get _filtered => _data;

  void _go(_V v, [_Product? r]) {
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
      _loadProducts();
    }
  }

  void _toast(String msg, {bool isError = false}) =>
      _ProdToast.show(context, msg, isError: isError);

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadOrganizations();
    _fetchPgmId();
  }

  Future<void> _fetchPgmId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final pgm = programs.firstWhere(
        (p) =>
            p.descn.toLowerCase() == 'product' ||
            p.descn.toLowerCase() == 'products',
      );
      _pgmId = pgm.pgmId;
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
      _loadError = null;
    });
    try {
      final limit = _page == 0 ? 10 : 20;
      final offset = _page == 0 ? 0 : 10 + (_page - 1) * 20;

      final result = await ProductService().getProductsPaginated(
        offset: offset,
        limit: limit,
        search: _search,
      );

      if (mounted) {
        final List<dynamic> content = result['content'] ?? [];
        setState(() {
          _data
            ..clear()
            ..addAll(
              content.map((pJson) {
                final p = ProductModel.fromJson(
                  Map<String, dynamic>.from(pJson),
                );
                return _Product(
                  orgCode: p.orgCode.toString(),
                  productCode: p.productCode.toString(),
                  productName: p.productName,
                  homeUrl: p.homeUrl,
                  status: p.status ? 'Active' : 'Inactive',
                  active: p.status,
                  logoPath: p.logo,
                  cuser: p.cuser,
                  euser: p.euser,
                  auser: p.auser,
                  cdateRaw: p.cdate,
                  edateRaw: p.edate,
                  adateRaw: p.adate,
                  cdate: _formatAuditDate(p.cdate),
                  edate: _formatAuditDate(p.edate),
                  adate: _formatAuditDate(p.adate),
                );
              }),
            );
          _totalElements = result['totalElements'] as int? ?? 0;
          _activeCount = result['activeCount'] as int? ?? 0;
          _inactiveCount = result['inactiveCount'] as int? ?? 0;
          _isLoading = false;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingProducts = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      final raw = await OrganizationService().getAllOrganizations();
      if (mounted)
        setState(() {
          _orgs = raw;
        });
    } catch (_) {
      _toast('Failed to load organizations', isError: true);
    }
  }

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
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

  // ── _openWithLogo — fetch using storedPath from DB ────────────────────────
  Future<void> _openWithLogo(_V view, _Product product) async {
    _go(view, product);
    if (product.logoBytes != null) return; // already loaded

    // Need storedPath (S3 URL from DB) to fetch
    final storedPath = product.logoPath ?? '';
    if (storedPath.isEmpty) return; // no logo stored

    try {
      final bytes = await ProductService().fetchProductLogo(
        orgId: int.tryParse(product.orgCode) ?? 1,
        filePath: storedPath,
      );
      if (!mounted) return;
      if (bytes != null) {
        setState(() {
          final idx = _data.indexWhere(
            (x) => x.productCode == product.productCode,
          );
          if (idx != -1) {
            _data[idx] = _data[idx].cp(logoBytes: bytes);
          }
          if (_sel?.productCode == product.productCode) {
            _sel = _sel!.cp(logoBytes: bytes);
          }
        });
      }
    } catch (_) {
      // Non-critical
    }
  }

  String _buildOrgDisplay(String code) {
    if (code.isEmpty) return '';
    final o = _orgs.firstWhere(
      (e) => e['orgCode']?.toString() == code,
      orElse: () => <String, dynamic>{},
    );
    if (o.isEmpty) return code;
    final name = (o['orgName'] ?? o['name'] ?? '').toString();
    return name.isEmpty ? code : '$code - $name';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: switch (_view) {
      _V.list => _list(),
      _V.create => _form(isEdit: false),
      _V.view => _detail(),
      _V.edit => _form(isEdit: true),
      _V.delete => _delete(),
    },
  );

  // ── Common helpers ─────────────────────────────────────────────────────────
  Widget _page_({required Widget child}) =>
      SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);

  Widget _pageHeader({
    required String title,
    List<Widget> actions = const [],
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _kText,
              letterSpacing: -0.3,
            ),
          ),
        ),
        ...actions,
      ],
    ),
  );

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

  Widget _statCard(
    String num,
    String lbl,
    Color numC,
    Color bg,
    Color border,
    IconData icon,
    Color iconC,
  ) => Container(
    width: 180,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: iconC),
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
                color: numC,
                height: 1.1,
              ),
            ),
            Text(lbl, style: const TextStyle(fontSize: 10, color: _kMuted)),
          ],
        ),
      ],
    ),
  );

  Widget _hBtn(
    String label, {
    Color bg = Colors.white,
    Color fg = _kMuted,
    Color border = _kBorder,
    IconData? icon,
    VoidCallback? onTap,
  }) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
            ],
            Text(
              label,
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

  Widget _fBtn(
    String label,
    IconData icon,
    Color bg,
    Color fg,
    Color border, {
    VoidCallback? onTap,
  }) => MouseRegion(
    cursor: onTap == null
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
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

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    ),
  );

  Widget _statusBadge(bool active) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? _kGL : _kRL,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? _kG : _kR,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
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
    ),
  );

  Widget _pageBtn(
    String label, {
    required bool enabled,
    required VoidCallback onTap,
  }) => MouseRegion(
    cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: enabled ? _kMuted : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    ),
  );

  // ── SCREEN 1: LIST ─────────────────────────────────────────────────────────
  int _getPageOffset(int p) {
    if (p == 0) return 0;
    return 10 + (p - 1) * 20;
  }

  bool _hasNextPage() {
    final nextOffset = _getPageOffset(_page + 1);
    return nextOffset < _totalElements;
  }

  Widget _list() {
    final active = _activeCount;
    final inactive = _inactiveCount;
    final filtered = _filtered;

    return StatefulBuilder(
      builder: (ctx, ls) {
        final pageItems = filtered;
        final start = filtered.isEmpty ? 0 : _getPageOffset(_page) + 1;
        final end = _getPageOffset(_page) + pageItems.length;

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(title: 'Products'),
              Row(
                children: [
                  _statCard(
                    '$_totalElements',
                    'Total Products',
                    _kP,
                    _kPL,
                    _kPB,
                    Icons.inventory_2_rounded,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SearchBox(
                    width: 220,
                    onChanged: (v) {
                      if (_debounce?.isActive ?? false) _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        ls(() {
                          _search = v;
                          _page = 0;
                        });
                        _loadProducts();
                      });
                    },
                  ),
                  if (widget.accessPrivileges?.canCreate ?? true) ...[
                    const SizedBox(width: 10),
                    _hBtn(
                      'New Product',
                      bg: _kP,
                      fg: Colors.white,
                      border: _kP,
                      icon: Icons.add_rounded,
                      onTap: () => _go(_V.create),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoadingProducts)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading products...'),
                      ],
                    ),
                  ),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Failed to load products: $_loadError',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                )
              else
                _card(
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.maxWidth;
                      final cols = [
                        w * 0.15,
                        w * 0.30,
                        w * 0.30,
                        w * 0.12,
                        w * 0.13,
                      ];

                      Widget rowWidget(
                        List<Widget> cells,
                        List<double> widths, {
                        bool isHeader = false,
                        bool isEven = false,
                        bool isHovered = false,
                      }) {
                        Color rowBg;
                        if (isHeader)
                          rowBg = _kP;
                        else if (isHovered)
                          rowBg = _kPL;
                        else if (isEven)
                          rowBg = _kRowAlt;
                        else
                          rowBg = Colors.white;
                        return Container(
                          decoration: BoxDecoration(
                            color: rowBg,
                            border: Border(
                              bottom: BorderSide(
                                color: isHeader
                                    ? Colors.transparent
                                    : const Color(0xFFF1F5F9),
                              ),
                            ),
                          ),
                          child: Row(
                            children: List.generate(
                              widths.length,
                              (i) =>
                                  SizedBox(width: widths[i], child: cells[i]),
                            ),
                          ),
                        );
                      }

                      headerCell(String t) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
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
                          rowWidget(
                            [
                              headerCell('PRODUCT CODE'),
                              headerCell('PRODUCT NAME'),
                              headerCell('HOME URL'),
                              headerCell('STATUS'),
                              headerCell('ACTIONS'),
                            ],
                            cols,
                            isHeader: true,
                          ),

                          ...pageItems.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final r = entry.value;
                            final isEven = idx % 2 == 1;
                            return StatefulBuilder(
                              builder: (_, rowSS) {
                                bool hovered = false;
                                return MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (_) => rowSS(() => hovered = true),
                                  onExit: (_) => rowSS(() => hovered = false),
                                  child: rowWidget(
                                    [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            r.productCode,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: _kP,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            r.productName,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: _kText,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            r.homeUrl,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kMuted,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: _statusBadge(r.active),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                    ],
                                    cols,
                                    isEven: isEven,
                                    isHovered: hovered,
                                  ),
                                );
                              },
                            );
                          }),

                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  pageItems.isEmpty
                                      ? 'No records found'
                                      : 'Showing $start–$end of $_totalElements records',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                Row(
                                  children: [
                                    _pageBtn(
                                      '‹ Prev',
                                      enabled: _page > 0,
                                      onTap: () {
                                        ls(() => _page--);
                                        _loadProducts();
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _pageBtn(
                                      'Next ›',
                                      enabled: _hasNextPage(),
                                      onTap: () {
                                        ls(() => _page++);
                                        _loadProducts();
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

  // ── SCREEN 2 / 4: CREATE / EDIT ────────────────────────────────────────────
  Widget _form({required bool isEdit}) {
    final r = isEdit ? _sel : null;

    final cPCode = TextEditingController(text: r?.productCode ?? '');
    final cPName = TextEditingController(text: r?.productName ?? '');
    final cUrl = TextEditingController(text: r?.homeUrl ?? '');

    bool statusActive = r?.active ?? false;
    bool statusTouched = r != null;

    // ── CHANGE 4: track if logo was explicitly removed by user ─────────────
    // logoBytes: current bytes to show in UI (could be pre-loaded from server)
    // logoRemoved: user pressed "Remove" — tells save to call deleteLogo()
    Uint8List? logoBytes = r?.logoBytes;
    String? logoName = r?.logoName;
    String? logoError;
    bool logoRemoved = false; // NEW

    final errors = <String, String?>{};

    return StatefulBuilder(
      builder: (ctx, ls) {
        void clearError(String key) {
          if (errors.containsKey(key)) ls(() => errors.remove(key));
        }

        bool validate() {
          final e = <String, String?>{};
          if (cPCode.text.trim().isEmpty) {
            e['pcode'] = 'Product Code is required';
          } else if (cPCode.text.trim().length > 5) {
            e['pcode'] = 'Enter Product Code ';
          }
          if (cPName.text.trim().isEmpty) {
            e['pname'] = 'Product Name is required';
          } else if (cPName.text.trim().length > 30) {
            e['pname'] = 'Enter Product Name ';
          }
          if (cUrl.text.trim().isEmpty) e['url'] = 'Home URL is required';
          if (!statusTouched) e['status'] = 'Status is required';
          ls(
            () => errors
              ..clear()
              ..addAll(e),
          );
          return e.isEmpty;
        }

        void save() {
          if (!validate()) {
            _ProdToast.show(
              context,
              'Please fill all required fields.',
              isError: true,
            );
            return;
          }
          if (isEdit) {
            _saveEdit(
              cPName.text,
              cUrl.text,
              statusActive ? 'Active' : 'Inactive',
              logoBytes,
              logoName,
              logoRemoved, // ← pass logoRemoved
            );
          } else {
            _saveCreate(
              '1',
              cPCode.text,
              cPName.text,
              cUrl.text,
              statusActive ? 'Active' : 'Inactive',
              logoBytes,
              logoName,
            );
          }
        }

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeader(
                title: isEdit ? 'Edit Product' : 'Add New Product',
                actions: [
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

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      ? 'Edit Product Details'
                                      : 'Product Details',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Locked fields cannot be changed'
                                      : 'Fill all required fields marked with *',
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
                            Icon(Icons.lock_outline, size: 15, color: _kWarnT),
                            SizedBox(width: 8),
                            Text(
                              'Locked fields cannot be modified',
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
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 4,
                        mainAxisSpacing: 28,
                        crossAxisSpacing: 18,
                        childAspectRatio: 3.2,
                        children: [
                          _NumericOnlyField(
                            label: 'Product Code',
                            ctrl: cPCode,
                            icon: Icons.qr_code_rounded,
                            hint: 'Enter product code',
                            readOnly: isEdit,
                            showLock: isEdit,
                            required: true,
                            maxLength: 5,
                            errorText: errors['pcode'],
                            onChanged: (_) => clearError('pcode'),
                          ),
                          _FloatingLabelField(
                            label: 'Product Name',
                            ctrl: cPName,
                            icon: Icons.inventory_2_rounded,
                            hint: 'Enter product name',
                            required: true,
                            maxLength: 30,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(30),
                            ],
                            errorText: errors['pname'],
                            onChanged: (_) => clearError('pname'),
                          ),
                          _FloatingLabelField(
                            label: 'Home URL',
                            ctrl: cUrl,
                            icon: Icons.link_rounded,
                            hint: 'Enter landing page URL',
                            required: true,
                            maxLength: 100,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(100),
                            ],
                            errorText: errors['url'],
                          ),
                          _StatusToggleField(
                            label: 'Status',
                            isActive: statusActive,
                            isRequired: true,
                            errorText: errors['status'],
                            onChanged: (val) => ls(() {
                              statusActive = val;
                              statusTouched = true;
                              errors.remove('status');
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Logo upload section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: _kBorder, height: 1),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _kPL,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                  Icons.image_rounded,
                                  size: 18,
                                  color: _kP,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Product Logo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _kText,
                                    ),
                                  ),
                                  Text(
                                    'PNG, JPG only — max 5 MB',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _ProductLogoUpload(
                            logoBytes: logoBytes,
                            logoName: logoName,
                            logoError: logoError,
                            onPicked: (bytes, name, error) => ls(() {
                              logoError = error;
                              logoRemoved = false; // picked new → not removed
                              if (error == null) {
                                logoBytes = bytes;
                                logoName = name;
                              } else {
                                logoBytes = null;
                                logoName = null;
                              }
                            }),
                            // ── CHANGE 5: mark logo as removed ────────────────────────
                            onRemove: () => ls(() {
                              logoBytes = null;
                              logoName = null;
                              logoError = null;
                              logoRemoved =
                                  true; // NEW — triggers deleteLogo on save
                            }),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
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
                            isEdit ? 'Update' : 'Create',
                            Icons.check_rounded,
                            _kP,
                            Colors.white,
                            _kP,
                            onTap: save,
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
      },
    );
  }

  // ── SCREEN 3: VIEW DETAIL ──────────────────────────────────────────────────
  Widget _detail() {
    final r = _sel!;
    ro(String label, String val, IconData icon, {String? sub}) =>
        _FloatingLabelField(
          label: label,
          ctrl: TextEditingController(text: val),
          icon: icon,
          readOnly: true,
          subtext: sub,
        );
    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Product Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _hBtn(
                  'Audit Details',
                  bg: Colors.white,
                  fg: _kP,
                  border: _kP,
                  icon: Icons.history_rounded,
                  onTap: () => AuditDetailsDialog.show(
                    context,
                    cuser: r.euser,
                    cdate: r.edate,
                    euser: r.cuser,
                    edate: r.cdate,
                    auser: r.auser,
                    adate: r.adate,
                    subtitle: 'Product audit trail for ${r.productName}',
                  ),
                ),
                const SizedBox(width: 10),
                _hBtn(
                  'Back',
                  bg: _kP,
                  fg: Colors.white,
                  border: _kP,
                  icon: Icons.arrow_back_rounded,
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
                      colors: [Color(0xFFEEF3FB), Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      r.logoBytes != null
                          ? Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(
                                r.logoBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _kP,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.productName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kP,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Org: ${r.orgCode} • Code: ${r.productCode}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: r.active ? _kGL : _kRL,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: r.active ? _kGB : _kRB),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: r.active ? _kG : _kR,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              r.active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: r.active ? _kG : _kR,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 18,
                    childAspectRatio: 3.5,
                    children: [
                      ro('Org Code', r.orgCode, Icons.tag_rounded),
                      ro('Product Code', r.productCode, Icons.qr_code_rounded),
                      ro(
                        'Product Name',
                        r.productName,
                        Icons.inventory_2_rounded,
                      ),
                      ro('Home URL', r.homeUrl, Icons.link_rounded),
                      _StatusToggleField(
                        label: 'Status',
                        isActive: r.active,
                        onChanged: (_) {},
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: _kBorder, height: 1),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _kPL,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(
                              Icons.image_rounded,
                              size: 18,
                              color: _kP,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Logo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kText,
                                ),
                              ),
                              Text(
                                'PNG, JPG only — max 5 MB',
                                style: TextStyle(fontSize: 11, color: _kMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      r.logoBytes != null
                          ? Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.memory(
                                r.logoBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: _kSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    size: 40,
                                    color: _kP,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'No Logo',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
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

  // ── SCREEN 5: DELETE ───────────────────────────────────────────────────────
  Widget _delete() {
    final r = _sel!;
    return StatefulBuilder(
      builder: (ctx, ls) => _page_(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _pageHeader(title: 'Delete Product'),
            _card(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: _kRL,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: _kR,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Confirmation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kR,
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
                          'Are you sure you want to delete this record? This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _kMuted),
                        ),
                        const SizedBox(height: 16),
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
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _delRow('Org Code:', r.orgCode, isRed: true),
                              const SizedBox(height: 6),
                              _delRow(
                                'Product Code:',
                                r.productCode,
                                isRed: true,
                              ),
                              const SizedBox(height: 6),
                              _delRow('Product Name:', r.productName),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => ls(
                            () =>
                                setState(() => _delConfirmed = !_delConfirmed),
                          ),
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
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _delConfirmed ? _kR : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: _kR, width: 1.5),
                                  ),
                                  child: _delConfirmed
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'I understand this will permanently delete this record and all related data.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kR,
                                      fontWeight: FontWeight.w500,
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
                          _delConfirmed ? _kR : Colors.white,
                          _delConfirmed
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                          _delConfirmed ? _kR : _kBorder,
                          onTap: _delConfirmed ? _deleteProduct : null,
                        ),
                      ],
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

  Widget _delRow(String key, String val, {bool isRed = false}) => Row(
    children: [
      SizedBox(
        width: 150,
        child: Text(key, style: const TextStyle(fontSize: 12, color: _kMuted)),
      ),
      Text(
        val,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isRed ? _kR : _kText,
        ),
      ),
    ],
  );

  // ── CRUD ────────────────────────────────────────────────────────────────────

  // // ── _saveCreate — upload logo, get S3 URL, pass to product ───────────────
  // Future<void> _saveCreate(String orgCode, String productCode,
  //     String productName, String homeUrl, String status,
  //     Uint8List? logoBytes, String? logoName) async {
  //   try {
  //     final model = ProductModel(
  //       orgCode: 101,
  //       productCode: int.parse(productCode),
  //       productName: productName,
  //       homeUrl: homeUrl,
  //       status: status.toUpperCase().startsWith('A'),
  //     );
  //     await ProductService().createProduct(model);

  //     String? logoPath;

  //     if (logoBytes != null && logoName != null) {
  //       try {
  //         // Upload → get S3 URL back
  //         logoPath = await _logoService.uploadLogo(
  //           orgCode: 101,
  //           productCode: int.parse(productCode),
  //           logoBytes: logoBytes,
  //           fileName: logoName,
  //         );
  //         // TODO: Save logoPath to DB via your product update API
  //         // e.g. await ProductService().updateLogoPath(int.parse(productCode), logoPath);
  //       } catch (_) {
  //         _toast('Product created, but logo upload failed.', isError: true);
  //       }
  //     }

  //     if (!mounted) return;
  //     setState(() {
  //       final prod = _Product.fromModel(model);
  //       _data.insert(0, prod.cp(
  //         logoBytes: logoBytes,
  //         logoName: logoName,
  //         logoPath: logoPath,   // ← store S3 URL
  //       ));
  //     });
  //     _go(_V.list);
  //     _toast('Product created successfully!');
  //   } catch (_) {
  //     _toast('Failed to create product', isError: true);
  //   }
  // }
  Future<void> _saveCreate(
    String orgCode,
    String productCode,
    String productName,
    String homeUrl,
    String status,
    Uint8List? logoBytes,
    String? logoName,
  ) async {
    try {
      String? logoPath;

      // ── Step 1: Upload logo FIRST to get S3 URL ──────────────────────────
      if (logoBytes != null && logoName != null) {
        try {
          // logoPath = await _logoService.uploadLogo(
          //   orgCode: 101,
          //   productCode: int.parse(productCode),
          //   logoBytes: logoBytes,
          //   fileName: logoName,
          // );
          logoPath = await ProductService().uploadProductLogo(
            orgId: int.tryParse(orgCode) ?? 1,
            fileBytes: logoBytes,
            fileName: logoName,
          );
        } catch (_) {
          _toast(
            'Logo upload failed. Product will be created without logo.',
            isError: true,
          );
        }
      }

      // ── Step 2: Create product WITH logo URL in payload ──────────────────
      final model = ProductModel(
        orgCode: int.tryParse(orgCode) ?? 1,
        productCode: int.parse(productCode),
        productName: productName,
        homeUrl: homeUrl,
        status: status.toUpperCase().startsWith('A'),
        logo: logoPath, // ← S3 URL included in create payload
        pgmId: _pgmId,
      );
      await ProductService().createProduct(model);
      OperationalLogService().logAction(programId: 'PRODUCTS', action: 'I');
      await _loadProducts(); // Reload to ensure UI is in sync with DB

      if (!mounted) return;
      _go(_V.list);
      _toast('Product created successfully!');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _toast(msg.isNotEmpty ? msg : 'Failed to create product', isError: true);
    }
  }
  //   // ── _saveEdit — upload new logo OR delete removed logo using storedPath ───
  // Future<void> _saveEdit(String productName, String homeUrl, String status,
  //     Uint8List? logoBytes, String? logoName, bool logoRemoved) async {
  //   try {
  //     final prod = _sel!;
  //     final oCode = int.tryParse(prod.orgCode) ?? 1;
  //     final pCode = int.parse(prod.productCode);

  //     String? newLogoPath = prod.logoPath; // Keep existing path unless changed

  //     if (logoBytes != null && logoName != null) {
  //       // New logo picked — upload and get new S3 URL
  //       try {
  //         newLogoPath = await _logoService.uploadLogo(
  //           orgCode: oCode,
  //           productCode: pCode,
  //           logoBytes: logoBytes,
  //           fileName: logoName,
  //         );
  //         // TODO: Save newLogoPath to DB
  //       } catch (_) {
  //         _toast('Product updated, but logo upload failed.', isError: true);
  //       }
  //     } else if (logoRemoved && prod.logoPath != null) {
  //       // User removed logo — delete from S3
  //       try {
  //         await _logoService.deleteLogo(
  //           orgCode: oCode,
  //           storedPath: prod.logoPath!,
  //         );
  //         newLogoPath = null;
  //         // TODO: Clear logoPath in DB
  //       } catch (_) {
  //         // Non-critical
  //       }
  //     }

  //     final updated = prod.cp(
  //       productName: productName, homeUrl: homeUrl, status: status,
  //       active: status.toUpperCase().startsWith('A'),
  //       logoBytes: logoBytes,
  //       logoName: logoName,
  //       logoPath: newLogoPath,
  //     );

  //     await ProductService().updateProduct(pCode, updated.toModel());

  //     if (!mounted) return;
  //     setState(() {
  //       final idx = _data.indexWhere((x) => x.productCode == prod.productCode);
  //       if (idx != -1) _data[idx] = updated;
  //     });
  //     _go(_V.list);
  //     _toast('Product updated successfully!');
  //   } catch (_) {
  //     _toast('Failed to update product', isError: true);
  //   }
  // }

  Future<void> _saveEdit(
    String productName,
    String homeUrl,
    String status,
    Uint8List? logoBytes,
    String? logoName,
    bool logoRemoved,
  ) async {
    try {
      final prod = _sel!;
      final oCode = int.tryParse(prod.orgCode) ?? 1;
      final pCode = int.parse(prod.productCode);

      String? newLogoPath = prod.logoPath;

      if (logoBytes != null && logoName != null) {
        try {
          newLogoPath = await ProductService().uploadProductLogo(
            orgId: oCode,
            fileBytes: logoBytes,
            fileName: logoName,
          );
        } catch (_) {
          _toast('Product updated, but logo upload failed.', isError: true);
        }
      } else if (logoRemoved && prod.logoPath != null) {
        try {
          await ProductService().deleteProductLogo(
            orgId: oCode,
            filePath: prod.logoPath!,
          );

          newLogoPath = null;
        } catch (_) {}
      }

      // // ── Pass newLogoPath in update payload ─────────────────────────────
      // final updated = prod.cp(
      //   productName: productName, homeUrl: homeUrl, status: status,
      //   active: status.toUpperCase().startsWith('A'),
      //   logoBytes: logoBytes,
      //   logoName: logoName,
      //   logoPath: newLogoPath,
      //   clearLogo: logoRemoved,
      // );

      // await ProductService().updateProduct(pCode, updated.toModel()); // toModel() sends logo field
      // ── Pass newLogoPath in update payload ─────────────────────────────
      final updated = prod.cp(
        productName: productName,
        homeUrl: homeUrl,
        status: status,
        active: status.toUpperCase().startsWith('A'),
        logoBytes: logoBytes,
        logoName: logoName,
        logoPath: newLogoPath,
        clearLogo: logoRemoved,
      );

      // When logo was removed, explicitly force logo=null in the PUT payload
      final modelToSend = updated.toModel();
      if (logoRemoved) modelToSend.logo = null;

      // Pass pgmId for update
      final finalModel = ProductModel(
        orgCode: modelToSend.orgCode,
        productCode: modelToSend.productCode,
        productName: modelToSend.productName,
        homeUrl: modelToSend.homeUrl,
        status: modelToSend.status,
        logo: modelToSend.logo,
        userscd: modelToSend.userscd,
        accesscd: modelToSend.accesscd,
        userName: modelToSend.userName,
        cuser: modelToSend.cuser,
        cdate: modelToSend.cdate,
        euser: modelToSend.euser,
        edate: modelToSend.edate,
        auser: modelToSend.auser,
        adate: modelToSend.adate,
        pgmId: _pgmId,
      );

      await ProductService().updateProduct(pCode, finalModel);
      OperationalLogService().logAction(programId: 'PRODUCTS', action: 'U');
      await _loadProducts(); // Reload to ensure UI is in sync with DB

      if (!mounted) return;
      _go(_V.list);
      _toast('Product updated successfully!');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _toast(msg.isNotEmpty ? msg : 'Failed to update product', isError: true);
    }
  }

  // ── _deleteProduct — delete logo using storedPath ─────────────────────────
  Future<void> _deleteProduct() async {
    try {
      final prod = _sel!;
      await ProductService().deleteProduct(int.parse(prod.productCode));
      OperationalLogService().logAction(programId: 'PRODUCTS', action: 'D');

      // Best-effort logo cleanup
      if (prod.logoPath != null && prod.logoPath!.isNotEmpty) {
        try {
          await ProductService().deleteProductLogo(
            orgId: int.tryParse(prod.orgCode) ?? 1,
            filePath: prod.logoPath!,
          );
        } catch (_) {}
      }

      if (!mounted) return;
      setState(
        () => _data.removeWhere((x) => x.productCode == prod.productCode),
      );
      _go(_V.list);
      _toast('Product deleted successfully!');
    } catch (_) {
      _toast('Failed to delete product', isError: true);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Product Logo Upload
// ─────────────────────────────────────────────────────────────────────────────
class _ProductLogoUpload extends StatefulWidget {
  final Uint8List? logoBytes;
  final String? logoName;
  final String? logoError;
  final void Function(Uint8List? bytes, String? name, String? error) onPicked;
  final VoidCallback onRemove;

  const _ProductLogoUpload({
    this.logoBytes,
    this.logoName,
    this.logoError,
    required this.onPicked,
    required this.onRemove,
  });

  @override
  State<_ProductLogoUpload> createState() => _ProductLogoUploadState();
}

class _ProductLogoUploadState extends State<_ProductLogoUpload> {
  bool _hovering = false;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    final name = file.name;
    if (bytes == null) return;

    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!_kAllowedExts.contains(ext)) {
      widget.onPicked(
        null,
        null,
        'Invalid format. Only PNG and JPG are allowed.',
      );
      return;
    }
    if (bytes.lengthInBytes > _kMaxLogoBytes) {
      widget.onPicked(
        null,
        null,
        'File too large. Maximum allowed size is 5 MB.',
      );
      return;
    }
    widget.onPicked(bytes, name, null);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.logoBytes != null;
    final hasError = widget.logoError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Product Logo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kMuted,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(widget.logoBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: _pick,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: _kP),
                            SizedBox(width: 6),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                color: _kP,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
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
                      onTap: widget.onRemove,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _kR,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kR),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.logoName != null) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(
                    widget.logoName!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kMuted,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ] else ...[
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: _pick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: hasError ? _kRL : (_hovering ? _kPL : _kSurface),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _DottedBorderBox(
                  isHovered: _hovering,
                  hasError: hasError,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
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
                              : (_hovering ? _kP : const Color(0xFF93A8C9)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasError ? 'Try again' : 'Click to upload',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: hasError ? _kR : (_hovering ? _kP : _kMuted),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'PNG, JPG',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const Text(
                        '(max 5 MB)',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: _kR),
                  const SizedBox(width: 5),
                  Text(
                    widget.logoError!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _kR,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _DottedBorderBox extends StatelessWidget {
  final Widget child;
  final bool isHovered;
  final bool hasError;
  const _DottedBorderBox({
    required this.child,
    required this.isHovered,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(
      color: hasError ? _kR : (isHovered ? _kP : _kBorder),
    ),
    child: SizedBox(width: 160, height: 160, child: Center(child: child)),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0, dashSpace = 4.0, radius = 16.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(radius),
        ),
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
        d += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
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
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(
        color: _focused ? _kP : _kBorder,
        width: _focused ? 2.0 : 1.5,
      ),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _focused
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
      focusNode: _focus,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(
          fontSize: 12,
          color: _focused ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 16,
          color: _focused ? _kP : const Color(0xFF94A3B8),
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

// ── Floating Label Field ──────────────────────────────────────────────────────
class _FloatingLabelField extends StatefulWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final String hint;
  final bool readOnly, required, showLock;
  final String? errorText, subtext;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  const _FloatingLabelField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.hint = '',
    this.readOnly = false,
    this.required = false,
    this.showLock = false,
    this.errorText,
    this.subtext,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
  });
  @override
  State<_FloatingLabelField> createState() => _FloatingLabelFieldState();
}

class _FloatingLabelFieldState extends State<_FloatingLabelField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  bool _focused = false;
  late AnimationController _anim;
  late Animation<double> _labelTop, _labelSize;
  bool get _hasValue => widget.ctrl.text.isNotEmpty;
  bool get _floated => _focused || _hasValue || widget.errorText != null;
  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _labelTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _labelSize = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      _floated ? _anim.forward() : _anim.reverse();
    });
    widget.ctrl.addListener(() {
      if (_floated && _anim.value < 1) _anim.forward();
      if (!_floated && _anim.value > 0) _anim.reverse();
      setState(() {});
    });
  }

  void _requestFocus() {
    if (!widget.readOnly) _focus.requestFocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_FloatingLabelField old) {
    super.didUpdateWidget(old);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final Color borderC = hasError ? _kR : _kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: widget.readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderC, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: TextField(
                  controller: widget.ctrl,
                  focusNode: _focus,
                  readOnly: widget.readOnly,
                  inputFormatters: widget.inputFormatters,
                  maxLength: widget.maxLength,
                  buildCounter:
                      (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kText,
                  ),
                  decoration: InputDecoration(
                    hintText: _floated ? widget.hint : '',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(36, 14, 12, 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: (widget.showLock && widget.readOnly)
                  ? const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: Color(0x8064748B),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(widget.icon, size: 14, color: hasError ? _kR : _kP),
              ),
            ),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, _2) => Positioned(
                top: _labelTop.value,
                left: 28,
                child: GestureDetector(
                  onTap: _requestFocus,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        text: widget.label,
                        children: [
                          if (widget.required)
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: _labelSize.value,
                        fontWeight: FontWeight.w600,
                        color: hasError ? _kR : _kP,
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
        if (widget.subtext != null && widget.subtext!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              widget.subtext!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kP,
                height: 1.2,
              ),
            ),
          ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              widget.errorText!,
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

// ── Numeric-Only Field ────────────────────────────────────────────────────────
class _NumericOnlyField extends StatefulWidget {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  final String hint;
  final bool readOnly, required, showLock;
  final int maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  const _NumericOnlyField({
    required this.label,
    required this.ctrl,
    required this.icon,
    this.hint = '',
    this.readOnly = false,
    this.required = false,
    this.showLock = false,
    this.maxLength = 5,
    this.errorText,
    this.onChanged,
  });
  @override
  State<_NumericOnlyField> createState() => _NumericOnlyFieldState();
}

class _NumericOnlyFieldState extends State<_NumericOnlyField>
    with SingleTickerProviderStateMixin {
  late FocusNode _focus;
  bool _focused = false;
  late AnimationController _anim;
  late Animation<double> _labelTop, _labelSize;
  String? _inlineError;
  bool get _hasValue => widget.ctrl.text.isNotEmpty;
  bool get _floated =>
      _focused || _hasValue || widget.errorText != null || _inlineError != null;
  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _labelTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _labelSize = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _focus.addListener(() {
      setState(() => _focused = _focus.hasFocus);
      _floated ? _anim.forward() : _anim.reverse();
    });
    widget.ctrl.addListener(() {
      if (_floated && _anim.value < 1) _anim.forward();
      if (!_floated && _anim.value > 0) _anim.reverse();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_NumericOnlyField old) {
    super.didUpdateWidget(old);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final displayError = widget.errorText ?? _inlineError;
    final hasError = displayError != null;
    final Color borderC = hasError ? _kR : _kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: widget.readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderC, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: TextField(
                  controller: widget.ctrl,
                  focusNode: _focus,
                  readOnly: widget.readOnly,
                  inputFormatters: [
                    _NumericInputFormatter(
                      onRejected: () => setState(
                        () => _inlineError = 'Only numbers are allowed',
                      ),
                      onAccepted: () => setState(() => _inlineError = null),
                    ),
                    LengthLimitingTextInputFormatter(widget.maxLength),
                  ],
                  keyboardType: TextInputType.number,
                  onChanged: widget.onChanged,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kText,
                  ),
                  decoration: InputDecoration(
                    hintText: _floated ? widget.hint : '',
                    hintStyle: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFCBD5E1),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(36, 14, 12, 14),
                    isDense: true,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: (widget.showLock && widget.readOnly)
                  ? const Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: Color(0x8064748B),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(widget.icon, size: 14, color: hasError ? _kR : _kP),
              ),
            ),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, _2) => Positioned(
                top: _labelTop.value,
                left: 28,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text.rich(
                    TextSpan(
                      text: widget.label,
                      children: [
                        if (widget.required)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: _labelSize.value,
                      fontWeight: FontWeight.w600,
                      color: hasError ? _kR : _kP,
                      letterSpacing: 0.2,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (displayError != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              displayError,
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

class _NumericInputFormatter extends TextInputFormatter {
  final VoidCallback onRejected;
  final VoidCallback onAccepted;
  static final _allowed = RegExp(r'[0-9]');
  _NumericInputFormatter({required this.onRejected, required this.onAccepted});
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final filtered = newValue.text
        .split('')
        .where((c) => _allowed.hasMatch(c))
        .join();
    if (filtered != newValue.text) {
      onRejected();
      return TextEditingValue(
        text: filtered,
        selection: TextSelection.collapsed(offset: filtered.length),
      );
    }
    onAccepted();
    return newValue;
  }
}

class _StatusToggleField extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isRequired, readOnly;
  final String? errorText;
  final ValueChanged<bool> onChanged;
  const _StatusToggleField({
    required this.label,
    required this.isActive,
    required this.onChanged,
    this.isRequired = false,
    this.readOnly = false,
    this.errorText,
  });
  @override
  State<_StatusToggleField> createState() => _StatusToggleFieldState();
}

class _StatusToggleFieldState extends State<_StatusToggleField> {
  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hasError = widget.errorText != null;
    final Color bc = hasError ? _kR : _kP;
    final Color labelC = hasError ? _kR : _kP;

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
                color: widget.readOnly ? _kSurface : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.signal_cellular_alt_rounded, size: 14, color: bc),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      active ? 'Active' : 'Inactive',
                      key: ValueKey(active),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? _kG : _kMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: widget.readOnly
                          ? null
                          : () => widget.onChanged(!active),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: active ? _kG : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: active
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

            // Fixed top label — same as _BranchToggle
            Positioned(
              top: -8,
              left: 28,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.isRequired)
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: labelC,
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
              widget.errorText!,
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
