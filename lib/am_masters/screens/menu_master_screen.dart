import 'package:flutter/material.dart';
import '../services/operational_log_service.dart';
import '../services/menu_service.dart';
import '../services/auth_service.dart';
import '../models/access_privileges.dart';
import '../models/menu_models.dart';
import '../widgets/audit_details_dialog.dart';
import 'menu_master_tabs/head_menu_tab.dart';
import 'menu_master_tabs/menu_tab.dart';
import 'menu_master_tabs/sub_menu_tab.dart';
import 'menu_master_tabs/menu_program_tab.dart';
import 'menu_master_tabs/menu_master_widgets.dart';
import 'menu_master_tabs/coming_soon_screen.dart';

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
const _kInfoL = Color(0xFFE0F2FE);
const _kInfoB = Color(0xFFBAE6FD);
const _kInfo = Color(0xFF0EA5E9);
const _kText = Color(0xFF1E293B);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

const _kEnBG = Color(0xFFDCFCE7);
const _kEnFG = Color(0xFF16A34A);
const _kEnB = Color(0xFFBBF7D0);
const _kDiBG = Color(0xFFFEF2F2);
const _kDiFG = Color(0xFFDC2626);
const _kDiB = Color(0xFFFECACA);

enum _V { list, create, view, edit, delete }

class _Menu {
  final String menuCode;
  String menuDesc, menuOrder, subMenuReq, landingProgram, programPath;
  String menuLogo, menuLocation, menuStatus;
  bool active;
  _Menu({
    required this.menuCode,
    required this.menuDesc,
    required this.menuOrder,
    required this.subMenuReq,
    required this.landingProgram,
    required this.programPath,
    required this.menuLogo,
    required this.menuLocation,
    required this.menuStatus,
    this.active = true,
  });
  bool get isEnabled =>
      menuStatus.startsWith('1') || menuStatus.toLowerCase().contains('enable');
  _Menu cp({
    String? menuDesc,
    String? menuOrder,
    String? subMenuReq,
    String? landingProgram,
    String? programPath,
    String? menuLogo,
    String? menuLocation,
    String? menuStatus,
    bool? active,
  }) => _Menu(
    menuCode: menuCode,
    menuDesc: menuDesc ?? this.menuDesc,
    menuOrder: menuOrder ?? this.menuOrder,
    subMenuReq: subMenuReq ?? this.subMenuReq,
    landingProgram: landingProgram ?? this.landingProgram,
    programPath: programPath ?? this.programPath,
    menuLogo: menuLogo ?? this.menuLogo,
    menuLocation: menuLocation ?? this.menuLocation,
    menuStatus: menuStatus ?? this.menuStatus,
    active: active ?? this.active,
  );
}

class _MNToast {
  static OverlayEntry? _c;
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    _c?.remove();
    _c = null;
    final bg = isError ? _kRL : _kGL;
    final fg = isError ? _kR : _kG;
    final border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    final entry = OverlayEntry(
      builder: (_) => _ToastW(
        message: message,
        bg: bg,
        fg: fg,
        border: border,
        icon: icon,
        onDismiss: () {
          _c?.remove();
          _c = null;
        },
      ),
    );
    _c = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      if (_c == entry) _c = null;
    });
  }
}

class _ToastW extends StatefulWidget {
  final String message;
  final Color bg, fg, border;
  final IconData icon;
  final VoidCallback onDismiss;
  const _ToastW({
    required this.message,
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
            border: Border.all(color: widget.border),
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

class MenuMaster extends StatefulWidget {
  const MenuMaster({super.key});
  @override
  State<MenuMaster> createState() => _MenuMasterState();
}

class _MenuMasterState extends State<MenuMaster> {
  _V _view = _V.list;
  _Menu? _sel;
  bool _delConfirmed = false;
  String _search = '';
  int _page = 0;
  static const int _pageSize = 10;

  final List<_Menu> _data = [
    _Menu(
      menuCode: '10',
      menuDesc: 'CRM Head',
      menuOrder: '1',
      subMenuReq: '1',
      landingProgram: 'CRM_DASH',
      programPath: '/crm/dashboard',
      menuLogo: 'crm-icon.svg',
      menuLocation: 'L - Left',
      menuStatus: '1',
    ),
    _Menu(
      menuCode: '11',
      menuDesc: 'CRM Viewer',
      menuOrder: '2',
      subMenuReq: '1',
      landingProgram: 'CRM_VIEW',
      programPath: '/crm/view',
      menuLogo: 'crm-view.svg',
      menuLocation: 'L - Left',
      menuStatus: '1',
    ),
    _Menu(
      menuCode: '20',
      menuDesc: 'Reports',
      menuOrder: '3',
      subMenuReq: '0',
      landingProgram: 'REPORT_MAIN',
      programPath: '/reports',
      menuLogo: 'reports-icon.svg',
      menuLocation: 'L - Left',
      menuStatus: '0',
      active: false,
    ),
  ];

  List<_Menu> get _filtered => _data
      .where(
        (r) =>
            r.menuCode.toLowerCase().contains(_search.toLowerCase()) ||
            r.menuDesc.toLowerCase().contains(_search.toLowerCase()) ||
            r.menuLocation.toLowerCase().contains(_search.toLowerCase()),
      )
      .toList();

  void _go(_V v, [_Menu? r]) => setState(() {
    _view = v;
    _sel = r;
    _delConfirmed = false;
    if (v == _V.list) {
      _page = 0;
      _search = '';
    }
  });
  void _toast(String msg, {bool isError = false}) =>
      _MNToast.show(context, msg, isError: isError);

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

  Widget _page_({required Widget child}) =>
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
          mainAxisSize: MainAxisSize.min,
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
  Widget _floatField({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    String hint = '',
    bool readOnly = false,
    bool required = false,
    String? errorText,
  }) => _FloatingLabelField(
    label: label,
    controller: ctrl,
    icon: icon,
    hint: hint,
    readOnly: readOnly,
    isRequired: required,
    errorText: errorText,
  );

  Widget _menuStatusBadge(bool enabled) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? _kEnBG : _kDiBG,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: enabled ? _kEnB : _kDiB),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: enabled ? _kEnFG : _kDiFG,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            enabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: enabled ? _kEnFG : _kDiFG,
            ),
          ),
        ],
      ),
    ),
  );
  Widget _numPageBtn(
    String label, {
    required bool enabled,
    required bool active,
    required VoidCallback onTap,
  }) => MouseRegion(
    cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
    child: GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 32),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _kP : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _kP : _kBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.white
                  : (enabled ? _kMuted : const Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _list() {
    final enabled = _data.where((r) => r.active).length;
    final disabled = _data.length - enabled;
    final filtered = _filtered;
    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    return StatefulBuilder(
      builder: (ctx, ls) {
        final pageItems = filtered
            .skip(_page * _pageSize)
            .take(_pageSize)
            .toList();
        final start = filtered.isEmpty ? 0 : _page * _pageSize + 1;
        final end = _page * _pageSize + pageItems.length;
        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Menu Master',
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
                    '${_data.length}',
                    'Total Records',
                    _kP,
                    _kPL,
                    _kPB,
                    Icons.menu_book_rounded,
                    _kP,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    '$enabled',
                    'Active',
                    _kEnFG,
                    _kEnBG,
                    _kEnB,
                    Icons.check_circle_outline_rounded,
                    _kEnFG,
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    '$disabled',
                    'Inactive',
                    _kDiFG,
                    _kDiBG,
                    _kDiB,
                    Icons.block_rounded,
                    _kDiFG,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SearchBox(
                    width: 220,
                    onChanged: (v) => setState(() {
                      _search = v;
                      _page = 0;
                    }),
                  ),
                  const SizedBox(width: 10),
                  _hBtn(
                    'New Menu',
                    bg: _kP,
                    fg: Colors.white,
                    border: _kP,
                    icon: Icons.add_rounded,
                    onTap: () => _go(_V.create),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _card(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final cols = [
                      w * 0.10,
                      w * 0.22,
                      w * 0.10,
                      w * 0.14,
                      w * 0.16,
                      w * 0.14,
                      w * 0.14,
                    ];
                    Widget rowWidget(
                      List<Widget> cells,
                      List<double> widths, {
                      bool isHeader = false,
                      bool isEven = false,
                      bool isHovered = false,
                    }) {
                      Color rowBg;
                      if (isHeader) {
                        rowBg = const Color(0xFF3D6EBE);
                      } else if (isHovered)
                        rowBg = const Color(0xFFEEF3FB);
                      else if (isEven)
                        rowBg = const Color(0xFFF8FAFC);
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
                            (i) => SizedBox(width: widths[i], child: cells[i]),
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
                    dataCell(
                      String t, {
                      Color color = _kText,
                      FontWeight fw = FontWeight.w400,
                    }) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Center(
                        child: Text(
                          t,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: color,
                            fontWeight: fw,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                    return Column(
                      children: [
                        rowWidget(
                          [
                            headerCell('MENU CODE'),
                            headerCell('MENU DESCRIPTION'),
                            headerCell('MENU ORDER'),
                            headerCell('MENU LOCATION'),
                            headerCell('MENU STATUS'),
                            headerCell('ACTIONS'),
                            const SizedBox(),
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
                                    dataCell(
                                      r.menuCode,
                                      color: _kP,
                                      fw: FontWeight.w700,
                                    ),
                                    dataCell(r.menuDesc),
                                    dataCell(r.menuOrder),
                                    dataCell(r.menuLocation),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: _menuStatusBadge(r.isEnabled),
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
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          _rowBtn(
                                            Icons.visibility_outlined,
                                            const Color(0xFF475569),
                                            () => _go(_V.view, r),
                                          ),
                                          const SizedBox(width: 6),
                                          _rowBtn(
                                            Icons.edit_outlined,
                                            _kP,
                                            () => _go(_V.edit, r),
                                          ),
                                          const SizedBox(width: 6),
                                          _rowBtn(
                                            Icons.delete_outline_rounded,
                                            _kR,
                                            () => _go(_V.delete, r),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(),
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
                                filtered.isEmpty
                                    ? 'No records found'
                                    : 'Showing $start–$end of ${filtered.length} records',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Row(
                                children: [
                                  _numPageBtn(
                                    '‹',
                                    enabled: _page > 0,
                                    active: false,
                                    onTap: () => ls(() => _page--),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(
                                    totalPages,
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _numPageBtn(
                                        '${i + 1}',
                                        enabled: true,
                                        active: _page == i,
                                        onTap: () => ls(() => _page = i),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _numPageBtn(
                                    '›',
                                    enabled: _page < totalPages - 1,
                                    active: false,
                                    onTap: () => ls(() => _page++),
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

  Widget _form({required bool isEdit}) {
    final r = isEdit ? _sel : null;
    final cCode = TextEditingController(text: r?.menuCode ?? '');
    final cDesc = TextEditingController(text: r?.menuDesc ?? '');
    final cOrder = TextEditingController(text: r?.menuOrder ?? '');
    final cSub = TextEditingController(text: r?.subMenuReq ?? '');
    final cLanding = TextEditingController(text: r?.landingProgram ?? '');
    final cPath = TextEditingController(text: r?.programPath ?? '');
    final cLogo = TextEditingController(text: r?.menuLogo ?? '');
    final cLoc = TextEditingController(text: r?.menuLocation ?? '');
    final cStatus = TextEditingController(text: r?.menuStatus ?? '');
    final errors = <String, String?>{};
    return StatefulBuilder(
      builder: (ctx, ls) {
        void clearError(String key) {
          if (errors.containsKey(key)) ls(() => errors.remove(key));
        }

        cCode.addListener(() {
          if (cCode.text.isNotEmpty) clearError('code');
        });
        cDesc.addListener(() {
          if (cDesc.text.isNotEmpty) clearError('desc');
        });
        cOrder.addListener(() {
          if (cOrder.text.isNotEmpty) clearError('order');
        });
        cSub.addListener(() {
          if (cSub.text.isNotEmpty) clearError('sub');
        });
        cLoc.addListener(() {
          if (cLoc.text.isNotEmpty) clearError('loc');
        });
        cStatus.addListener(() {
          if (cStatus.text.isNotEmpty) clearError('status');
        });
        bool validate() {
          final e = <String, String?>{};
          if (cCode.text.trim().isEmpty) e['code'] = 'Required';
          if (cDesc.text.trim().isEmpty) e['desc'] = 'Required';
          if (cOrder.text.trim().isEmpty) e['order'] = 'Required';
          if (cSub.text.trim().isEmpty) e['sub'] = 'Required';
          if (cLoc.text.trim().isEmpty) e['loc'] = 'Required';
          if (cStatus.text.trim().isEmpty) e['status'] = 'Required';
          ls(
            () => errors
              ..clear()
              ..addAll(e),
          );
          return e.isEmpty;
        }

        void save() {
          if (!validate()) {
            _MNToast.show(
              context,
              'Please fill all required fields.',
              isError: true,
            );
            return;
          }
          if (isEdit) {
            final i = _data.indexWhere((x) => x.menuCode == _sel!.menuCode);
            if (i != -1) {
              setState(
                () => _data[i] = _data[i].cp(
                  menuDesc: cDesc.text,
                  menuOrder: cOrder.text,
                  subMenuReq: cSub.text,
                  landingProgram: cLanding.text,
                  programPath: cPath.text,
                  menuLogo: cLogo.text,
                  menuLocation: cLoc.text,
                  menuStatus: cStatus.text,
                  active: !cStatus.text.startsWith('0'),
                ),
              );
            }
            _go(_V.list);
            OperationalLogService().logAction(programId: 'Menu Master', action: 'U');
            _toast('Menu updated successfully!');
          } else {
            setState(
              () => _data.add(
                _Menu(
                  menuCode: cCode.text,
                  menuDesc: cDesc.text,
                  menuOrder: cOrder.text,
                  subMenuReq: cSub.text,
                  landingProgram: cLanding.text,
                  programPath: cPath.text,
                  menuLogo: cLogo.text,
                  menuLocation: cLoc.text,
                  menuStatus: cStatus.text,
                  active: !cStatus.text.startsWith('0'),
                ),
              ),
            );
            _go(_V.list);
            OperationalLogService().logAction(programId: 'Menu Master', action: 'I');
            _toast('Menu created successfully!');
          }
        }

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  isEdit ? 'Edit Menu' : 'Add New Menu',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
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
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Menu Details' : 'Menu Details',
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
                              'Edit Menu — Locked fields cannot be changed',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _kWarnT,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!isEdit)
                      Container(
                        margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _kInfoL,
                          border: Border.all(color: _kInfoB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 15,
                              color: _kInfo,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'New Menu — Fill all required fields (*)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _kInfo,
                                ),
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
                        childAspectRatio: 4.5,
                        children: [
                          _floatField(
                            label: 'Menu Code',
                            ctrl: cCode,
                            icon: Icons.tag_rounded,
                            hint: '2-digit unique',
                            readOnly: isEdit,
                            required: true,
                            errorText: errors['code'],
                          ),
                          _floatField(
                            label: 'Menu Description',
                            ctrl: cDesc,
                            icon: Icons.description_outlined,
                            hint: 'Auto from program',
                            required: true,
                            errorText: errors['desc'],
                          ),
                          _floatField(
                            label: 'Menu Order',
                            ctrl: cOrder,
                            icon: Icons.sort_rounded,
                            hint: 'Display order 1,2,3…',
                            required: true,
                            errorText: errors['order'],
                          ),
                          _floatField(
                            label: 'Sub Menu Req',
                            ctrl: cSub,
                            icon: Icons.account_tree_rounded,
                            hint: '1=Yes, 0=No',
                            required: true,
                            errorText: errors['sub'],
                          ),
                          _floatField(
                            label: 'Landing Program',
                            ctrl: cLanding,
                            icon: Icons.rocket_launch_outlined,
                            hint: 'Program ID',
                          ),
                          _floatField(
                            label: 'Program Path',
                            ctrl: cPath,
                            icon: Icons.link_rounded,
                            hint: 'Landing page path',
                          ),
                          _floatField(
                            label: 'Menu Logo',
                            ctrl: cLogo,
                            icon: Icons.image_outlined,
                            hint: 'Icon file path',
                          ),
                          _floatField(
                            label: 'Menu Location',
                            ctrl: cLoc,
                            icon: Icons.location_on_outlined,
                            hint: 'L/R/C/T/B',
                            required: true,
                            errorText: errors['loc'],
                          ),
                          _floatField(
                            label: 'Menu Status',
                            ctrl: cStatus,
                            icon: Icons.toggle_on_rounded,
                            hint: '1=Enabled, 0=Disabled',
                            required: true,
                            errorText: errors['status'],
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
                          if (isEdit && (_sel?.active ?? true))
                            _fBtn(
                              'Deactivate',
                              Icons.block_rounded,
                              Colors.white,
                              _kR,
                              _kRB,
                              onTap: () {
                                final i = _data.indexWhere(
                                  (x) => x.menuCode == _sel!.menuCode,
                                );
                                if (i != -1) {
                                  setState(
                                    () => _data[i] = _data[i].cp(
                                      active: false,
                                      menuStatus: '0',
                                    ),
                                  );
                                }
                                _go(_V.list);
                                _toast('Menu deactivated.');
                              },
                            )
                          else if (isEdit)
                            _fBtn(
                              'Activate',
                              Icons.check_circle_outline_rounded,
                              _kG,
                              Colors.white,
                              _kG,
                              onTap: () {
                                final i = _data.indexWhere(
                                  (x) => x.menuCode == _sel!.menuCode,
                                );
                                if (i != -1) {
                                  setState(
                                    () => _data[i] = _data[i].cp(
                                      active: true,
                                      menuStatus: '1',
                                    ),
                                  );
                                }
                                _go(_V.list);
                                _toast('Menu activated.');
                              },
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

  Widget _detail() {
    final r = _sel!;
    ro(String label, String val, IconData icon) => _FloatingLabelField(
      label: label,
      controller: TextEditingController(text: val),
      icon: icon,
      readOnly: true,
      isRequired: false,
    );
    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Menu Details',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kText,
                letterSpacing: -0.3,
              ),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
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
                              r.menuDesc,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kP,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MENU${r.menuCode.padLeft(3, '0')} • Menu Module • Record Details',
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
                    childAspectRatio: 4.5,
                    children: [
                      ro('Menu Code', r.menuCode, Icons.tag_rounded),
                      ro(
                        'Menu Description',
                        r.menuDesc,
                        Icons.description_outlined,
                      ),
                      ro('Menu Order', r.menuOrder, Icons.sort_rounded),
                      ro(
                        'Sub Menu Req',
                        r.subMenuReq,
                        Icons.account_tree_rounded,
                      ),
                      ro(
                        'Landing Program',
                        r.landingProgram,
                        Icons.rocket_launch_outlined,
                      ),
                      ro('Program Path', r.programPath, Icons.link_rounded),
                      ro('Menu Logo', r.menuLogo, Icons.image_outlined),
                      ro(
                        'Menu Location',
                        r.menuLocation,
                        Icons.location_on_outlined,
                      ),
                      ro('Menu Status', r.menuStatus, Icons.toggle_on_rounded),
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
                      const SizedBox(width: 10),
                      _fBtn(
                        'Edit',
                        Icons.edit_outlined,
                        Colors.white,
                        _kP,
                        _kP,
                        onTap: () => _go(_V.edit, r),
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

  Widget _delete() {
  final r = _sel!;
  return StatefulBuilder(
    builder: (ctx, ls) => _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Delete Menu',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kText,
                letterSpacing: -0.3,
              ),
            ),
          ),

          /// ✅ ADDED CENTER + WIDTH CONTROL
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: _card(
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
                                _delRow('Menu Code:', r.menuCode, isRed: true),
                                const SizedBox(height: 6),
                                _delRow('Menu Description:', r.menuDesc),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          GestureDetector(
                            onTap: () => ls(
                              () => setState(() => _delConfirmed = !_delConfirmed),
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
                            onTap: _delConfirmed
                                ? () {
                                    setState(
                                      () => _data.removeWhere(
                                        (x) => x.menuCode == r.menuCode,
                                      ),
                                    );
                                    _go(_V.list);
                                    OperationalLogService().logAction(programId: 'Menu Master', action: 'D');
                                    _toast('Menu deleted successfully!');
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

  Widget _delRow(String key, String val, {bool isRed = false}) => Row(
    children: [
      SizedBox(
        width: 180,
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
}

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
        hintText: 'Search records...',
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

class _FloatingLabelField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool readOnly, isRequired;
  final String? errorText;
  const _FloatingLabelField({
    required this.label,
    required this.controller,
    required this.icon,
    this.hint = '',
    this.readOnly = false,
    this.isRequired = false,
    this.errorText,
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
  bool get _hasValue => widget.controller.text.isNotEmpty;
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
    widget.controller.addListener(() {
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
  void didUpdateWidget(_FloatingLabelField o) {
    super.didUpdateWidget(o);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final borderC = hasError ? _kR : _kP;
    const labelC = _kP;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderC, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.5),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              readOnly: widget.readOnly,
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
          left: 11,
          top: 15,
          child: Icon(widget.icon, size: 14, color: hasError ? _kR : labelC),
        ),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, _) => Positioned(
            top: _labelTop.value,
            left: 28,
            child: GestureDetector(
              onTap: _requestFocus,
              child: Container(
                color: widget.readOnly ? const Color(0xFFF8FAFC) : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${widget.label}${(widget.isRequired && _floated) ? ' *' : ''}',
                  style: TextStyle(
                    fontSize: _labelSize.value,
                    fontWeight: FontWeight.w600,
                    color: hasError ? _kR : labelC,
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
}
