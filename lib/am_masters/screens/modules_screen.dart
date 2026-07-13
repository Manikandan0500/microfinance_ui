import 'package:flutter/material.dart';
import 'dart:async';
import '../models/module_model.dart';
import '../models/sub_module_model.dart';
import '../models/program_model.dart';
import '../services/module_service.dart';
import '../services/sub_module_service.dart';
import '../services/operational_log_service.dart';
import '../services/program_service.dart';
import '../services/profile_service.dart';
import '../models/access_privileges.dart';
import '../services/auth_service.dart';

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

// Enabled / Disabled badge colours
const _kEnBG = Color(0xFFDCFCE7);
const _kEnFG = Color(0xFF16A34A);
const _kEnB = Color(0xFFBBF7D0);
const _kDiBG = Color(0xFFFEF2F2);
const _kDiFG = Color(0xFFDC2626);
const _kDiB = Color(0xFFFECACA);

enum _V { list, create, createSub, createProgram, view, edit, delete }

enum ModuleSection { modules, subModules, programs }

class _ModToast {
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

class Modules extends StatefulWidget {
  final ModuleSection initialSection;
  final AccessPrivileges? accessPrivileges;
  const Modules({super.key, this.initialSection = ModuleSection.modules, this.accessPrivileges});

  @override
  State<Modules> createState() => _ModulesState();
}

class _ModulesState extends State<Modules> {
  _V _view = _V.list;
  Module? _sel;
  bool _delConfirmed = false;
  String _search = '';
  String _subSearch = '';
  String _programSearch = '';
  int _page = 0;
  int _subModulePage = 0;
  int _programPage = 0;
  int _totalModules = 0;
  int _totalSubModules = 0;
  int _totalPrograms = 0;
  late ModuleSection _section;
  static const int _pageSize = 10;
  final ModuleService _moduleService = ModuleService();
  List<Module> _data = [];
  bool _isLoading = false;

  Timer? _debounce;
  List<Module> _allModules = [];
  List<SubModule> _allSubModules = [];
  List<Program> _allPrograms = [];

  List<Module> get _filtered => _data;

  final SubModuleService _subModuleService = SubModuleService();
  final ProgramService _programService = ProgramService();
  List<SubModule> _subData = [];
  List<Program> _programData = [];
  SubModule? _selSubModule;
  Program? _selProgram;

  void _go(_V v, [Object? item]) => setState(() {
    _view = v;
    _delConfirmed = false;
    _sel = item is Module ? item : null;
    _selSubModule = item is SubModule ? item : null;
    _selProgram = item is Program ? item : null;
    if (v == _V.list) {
      _page = 0;
      _subModulePage = 0;
      _programPage = 0;
      _search = '';
      _subSearch = '';
      _programSearch = '';
      _loadModules();
      _loadSubModules();
      _loadPrograms();
    }
  });

  void _toast(String msg, {bool isError = false}) =>
      _ModToast.show(context, msg, isError: isError);

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _fetchCachedModules().then((_) {
      _fetchCachedSubModules().then((_) {
        _fetchCachedPrograms();
      });
    });
    _loadModules();
    _loadSubModules();
    _loadPrograms();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchCachedModules() async {
    try {
      final list = await _moduleService.getAllModules();
      if (mounted) setState(() => _allModules = list);
    } catch (_) {}
  }

  Future<void> _fetchCachedSubModules() async {
    try {
      final list = await _subModuleService.getAllSubModules();
      if (mounted) setState(() => _allSubModules = list);
    } catch (_) {}
  }

  Future<void> _fetchCachedPrograms() async {
    try {
      final list = await _programService.getAllPrograms();
      if (mounted) setState(() => _allPrograms = list);
    } catch (_) {}
  }

  final Map<String, Future<String?>> _auditUserCache = {};

  String? _normalizeAuditName(String? s) {
    if (s == null || s.trim().isEmpty || s == '—') return null;
    try {
      return s
          .trim()
          .split(' ')
          .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
          .join(' ');
    } catch (_) {
      return s;
    }
  }

  Future<String?> _resolveAuditUser({
    required String? userId,
    String? fallbackUserName,
    required int orgCode,
  }) async {
    if (userId == null || userId.trim().isEmpty) {
      return _normalizeAuditName(fallbackUserName) ?? userId;
    }

    final trimmedId = userId.trim();
    if (_auditUserCache.containsKey(trimmedId)) {
      final cached = await _auditUserCache[trimmedId];
      return cached ?? _normalizeAuditName(fallbackUserName) ?? trimmedId;
    }

    final future = ProfileService()
        .getUserDetails(trimmedId, orgCode)
        .then((profile) => _normalizeAuditName(profile?.name ?? profile?.userName))
        .catchError((_) => null);
    _auditUserCache[trimmedId] = future;
    final resolved = await future;
    return resolved ?? _normalizeAuditName(fallbackUserName) ?? trimmedId;
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    try {
      final res = await _moduleService.getModulesPaginated(
        _page * _pageSize,
        _pageSize,
        search: _search,
      );
      final List<Module> modules = List<Module>.from(res['content']);
      _totalModules = res['totalElements'] as int;

      final authUser = await AuthService().getUser();
      final orgCode = authUser?.orgCode ?? 0;
      final updated = await Future.wait(modules.map((m) async {
        final cuser = await _resolveAuditUser(
          userId: m.cuser,
          fallbackUserName: m.userName,
          orgCode: orgCode,
        );
        final euser = await _resolveAuditUser(
          userId: m.euser,
          fallbackUserName: m.userName,
          orgCode: orgCode,
        );
        final auser = await _resolveAuditUser(
          userId: m.auser,
          fallbackUserName: m.userName,
          orgCode: orgCode,
        );
        return m.copyWith(
          cuser: cuser,
          euser: euser,
          auser: auser,
          cdate: m.cdate,
          edate: m.edate,
          adate: m.adate,
        );
      }));
      setState(() => _data = updated);
      _fetchCachedModules();
    } catch (e) {
      _toast('Failed to load modules', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSubModules() async {
    try {
      final res = await _subModuleService.getSubModulesPaginated(
        _subModulePage * _pageSize,
        _pageSize,
        search: _subSearch,
      );
      final List<SubModule> subModules = List<SubModule>.from(res['content']);
      _totalSubModules = res['totalElements'] as int;

      final authUser = await AuthService().getUser();
      final orgCode = authUser?.orgCode ?? 0;
      final updated = await Future.wait(subModules.map((s) async {
        final cuser = await _resolveAuditUser(
          userId: s.cuser,
          fallbackUserName: s.userName,
          orgCode: orgCode,
        );
        final euser = await _resolveAuditUser(
          userId: s.euser,
          fallbackUserName: s.userName,
          orgCode: orgCode,
        );
        final auser = await _resolveAuditUser(
          userId: s.auser,
          fallbackUserName: s.userName,
          orgCode: orgCode,
        );
        return s.copyWith(
          cuser: cuser,
          euser: euser,
          auser: auser,
          cdate: s.cdate,
          edate: s.edate,
          adate: s.adate,
        );
      }));
      setState(() => _subData = updated);
      _fetchCachedSubModules();
    } catch (e) {
      _toast('Failed to load submodules', isError: true);
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final res = await _programService.getProgramsPaginated(
        _programPage * _pageSize,
        _pageSize,
        search: _programSearch,
      );
      final List<Program> programs = List<Program>.from(res['content']);
      _totalPrograms = res['totalElements'] as int;

      final authUser = await AuthService().getUser();
      final orgCode = authUser?.orgCode ?? 0;
      final updated = await Future.wait(programs.map((p) async {
        final cuser = await _resolveAuditUser(
          userId: p.cuser,
          fallbackUserName: p.userName,
          orgCode: orgCode,
        );
        final euser = await _resolveAuditUser(
          userId: p.euser,
          fallbackUserName: p.userName,
          orgCode: orgCode,
        );
        final auser = await _resolveAuditUser(
          userId: p.auser,
          fallbackUserName: p.userName,
          orgCode: orgCode,
        );
        return p.copyWith(
          cuser: cuser,
          euser: euser,
          auser: auser,
          cdate: p.cdate,
          edate: p.edate,
          adate: p.adate,
        );
      }));
      setState(() => _programData = updated);
      _fetchCachedPrograms();
    } catch (e) {
      _toast('Failed to load programs', isError: true);
    }
  }

  String moduleLabelFor(int moduleId) {
    final item = _allModules.firstWhere(
      (m) => m.moduleId == moduleId,
      orElse: () => Module(
        moduleId: moduleId,
        moduleName: 'Unknown',
        subModule: false,
        status: false,
      ),
    );
    return '${item.moduleId} - ${item.moduleName}';
  }

  String subModuleLabelFor(int subModuleId) {
    final item = _allSubModules.firstWhere(
      (s) => s.subModuleId == subModuleId,
      orElse: () => SubModule(
        subModuleId: subModuleId,
        moduleId: 0,
        subModuleName: 'Unknown',
        status: false,
      ),
    );
    return '${item.subModuleId} - ${item.subModuleName}';
  }

  String subModuleRoleLabelFor(int subModuleId) {
    final item = _allSubModules.firstWhere(
      (s) => s.subModuleId == subModuleId,
      orElse: () => SubModule(
        subModuleId: subModuleId,
        moduleId: 0,
        subModuleName: 'Unknown',
        status: false,
      ),
    );
    final roleName = item.accesscd == 1
        ? 'SYSADMIN'
        : (item.accesscd == 2
            ? 'ADMIN'
            : (item.accesscd == 3 ? 'END USER' : '${item.subModuleId}'));
    final parentModule = _allModules.firstWhere(
      (m) => m.moduleId == item.moduleId,
      orElse: () => Module(
        moduleId: item.moduleId,
        moduleName: 'Unknown',
        subModule: false,
        status: false,
      ),
    );
    return '$roleName - ${parentModule.moduleName} - ${item.subModuleName}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: switch (_view) {
      _V.list => _list(),
      _V.create => _form(isEdit: false),
      _V.createSub => _subForm(isEdit: false),
      _V.createProgram => _programForm(isEdit: false),
      _V.view => _section == ModuleSection.modules
          ? _detail()
          : _section == ModuleSection.subModules
              ? _subDetail()
              : _programDetail(),
      _V.edit => _section == ModuleSection.modules
          ? _form(isEdit: true)
          : _section == ModuleSection.subModules
              ? _subForm(isEdit: true)
              : _programForm(isEdit: true),
      _V.delete => _section == ModuleSection.modules
          ? _delete()
          : _section == ModuleSection.subModules
              ? _subDelete()
              : _programDelete(),
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
    bool center = false,
  }) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: center ? Alignment.center : null,
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

  Widget _sectionButton(String label, ModuleSection page, IconData icon) => _hBtn(
        label,
        bg: _section == page ? _kP : Colors.white,
        fg: _section == page ? Colors.white : _kMuted,
        border: _section == page ? _kP : _kBorder,
        icon: icon,
        onTap: () => setState(() => _section = page),
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

  DateTime? _tryParseAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    // Try standard ISO parse first.
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Fall back to the display format produced by the audit popup.
    final formatted = RegExp(r'^(\d{1,2}) (January|February|March|April|May|June|July|August|September|October|November|December),? (\d{4}),? (\d{1,2}):(\d{2}) (AM|PM)\$');
    final match = formatted.firstMatch(dateStr.trim());
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = [
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
      ].indexOf(match.group(2)!) + 1;
      final year = int.parse(match.group(3)!);
      var hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final period = match.group(6);
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return DateTime(year, month, day, hour, minute);
    }

    return null;
  }

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    final parsed = _tryParseAuditDate(dateStr);
    if (parsed == null) return dateStr;
    final d = parsed.toLocal();
    const ms = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return "${d.day.toString().padLeft(2,'0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2,'0')}:$m $p";
  }

  String? _normalizeAuditDateValue(String? value) {
    if (value == null || value.isEmpty) return null;
    final parsed = _tryParseAuditDate(value);
    return parsed?.toLocal().toIso8601String();
  }

  String _cap(String? s) {
    if (s == null || s.isEmpty || s == '—') return s ?? '—';
    try {
      return s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
    } catch (_) { return s; }
  }

  Widget _auditItem(String label, String value, IconData icon) {
    return Expanded(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kP, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: _kP),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 13, color: _kText, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -9,
            left: 20,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _kP, letterSpacing: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAuditPopupForProgram(Program r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 750,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFEEF3FB), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history_rounded, size: 22, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Audit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kP)),
                  const SizedBox(height: 2),
                  Text('Record identification and audit trail', style: TextStyle(fontSize: 11, color: _kMuted.withOpacity(0.8))),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _kGL, borderRadius: BorderRadius.circular(20)), child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kG, letterSpacing: 0.5))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(children: [
                Row(children: [
                  _auditItem('Created By', _cap(r.euser), Icons.person_add_alt_1_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Created Date', _formatAuditDate(r.edate), Icons.calendar_today_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Modified By', _cap(r.cuser), Icons.person_search_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Modified Date', _formatAuditDate(r.cdate), Icons.edit_calendar_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Approved By', _cap(r.auser), Icons.how_to_reg_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Approved Date', _formatAuditDate(r.adate), Icons.fact_check_rounded),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Center(child: SizedBox(width: 140, height: 44, child: _hBtn('Close', bg: _kP, fg: Colors.white, border: _kP, onTap: () => Navigator.pop(ctx), center: true)))),
          ]),
        ),
      ),
    );
  }

  void _showAuditPopupForSubModule(SubModule r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 750,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFEEF3FB), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history_rounded, size: 22, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Audit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kP)),
                  const SizedBox(height: 2),
                  Text('Record identification and audit trail', style: TextStyle(fontSize: 11, color: _kMuted.withOpacity(0.8))),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _kGL, borderRadius: BorderRadius.circular(20)), child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kG, letterSpacing: 0.5))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(children: [
                Row(children: [
                  _auditItem('Created By', _cap(r.euser), Icons.person_add_alt_1_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Created Date', _formatAuditDate(r.edate), Icons.calendar_today_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Modified By', _cap(r.cuser), Icons.person_search_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Modified Date', _formatAuditDate(r.cdate), Icons.edit_calendar_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Approved By', _cap(r.auser), Icons.how_to_reg_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Approved Date', _formatAuditDate(r.adate), Icons.fact_check_rounded),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Center(child: SizedBox(width: 140, height: 44, child: _hBtn('Close', bg: _kP, fg: Colors.white, border: _kP, onTap: () => Navigator.pop(ctx), center: true)))),
          ]),
        ),
      ),
    );
  }

  void _showAuditPopupForModule(Module r) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 750,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, 15))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFEEF3FB), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: _kP, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.history_rounded, size: 22, color: Colors.white)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Audit Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kP)),
                  const SizedBox(height: 2),
                  Text('Record identification and audit trail', style: TextStyle(fontSize: 11, color: _kMuted.withOpacity(0.8))),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _kGL, borderRadius: BorderRadius.circular(20)), child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _kG, letterSpacing: 0.5))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(children: [
                Row(children: [
                  _auditItem('Created By', _cap(r.euser), Icons.person_add_alt_1_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Created Date', _formatAuditDate(r.edate), Icons.calendar_today_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Modified By', _cap(r.cuser), Icons.person_search_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Modified Date', _formatAuditDate(r.cdate), Icons.edit_calendar_rounded),
                ]),
                const SizedBox(height: 30),
                Row(children: [
                  _auditItem('Approved By', _cap(r.auser), Icons.how_to_reg_rounded),
                  const SizedBox(width: 24),
                  _auditItem('Approved Date', _formatAuditDate(r.adate), Icons.fact_check_rounded),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Center(child: SizedBox(width: 140, height: 44, child: _hBtn('Close', bg: _kP, fg: Colors.white, border: _kP, onTap: () => Navigator.pop(ctx), center: true)))),
          ]),
        ),
      ),
    );
  }
  
  Widget _toggleField({
    required String label,
    required IconData icon,
    required bool value,
    required String trueLabel,
    required String falseLabel,
    required Color activeColor,
    required ValueChanged<bool> onChanged,
    bool isRequired = false,
    bool hasError = false,
    bool readOnly = false,
  }) {
    final borderColor = hasError ? _kR : _kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: borderColor),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      value ? trueLabel : falseLabel,
                      key: ValueKey(value),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: value ? activeColor : _kMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: readOnly ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: readOnly ? null : () => onChanged(!value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: value ? activeColor : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: label,
                    children: isRequired ? const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
                  ),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: borderColor,
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
              '$label is required',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2),
            ),
          ),
      ],
    );
  }

  Widget _enabledBadge(bool enabled) => IntrinsicWidth(
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
            enabled ? 'Active' : 'Inactive',
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
    final enabled = _allModules.where((r) => r.status).length;
    final disabled = _allModules.length - enabled;
    final subEnabled = _allSubModules.where((r) => r.status).length;
    final subDisabled = _allSubModules.length - subEnabled;
    final pgmEnabled = _allPrograms.where((r) => r.status).length;
    final pgmDisabled = _allPrograms.length - pgmEnabled;
    final filtered = _filtered;
    final totalPages = (_totalModules / _pageSize).ceil().clamp(1, 9999);
    final sectionTitle = _section == ModuleSection.modules
        ? 'Modules'
        : _section == ModuleSection.subModules
            ? 'Sub Modules'
            : 'Programs';
    final sectionTotal = _section == ModuleSection.modules
        ? _totalModules
        : _section == ModuleSection.subModules
            ? _totalSubModules
            : _totalPrograms;
    final sectionActive = _section == ModuleSection.modules
        ? enabled
        : _section == ModuleSection.subModules
            ? subEnabled
            : pgmEnabled;
    final sectionInactive = _section == ModuleSection.modules
        ? disabled
        : _section == ModuleSection.subModules
            ? subDisabled
            : pgmDisabled;
    return StatefulBuilder(
      builder: (ctx, ls) {
        final pageItems = filtered;
        final start = filtered.isEmpty ? 0 : _page * _pageSize + 1;
        final end = _page * _pageSize + pageItems.length;
        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  sectionTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _statCard(
                      '$sectionTotal',
                      'Total Records',
                      _kP,
                      _kPL,
                      _kPB,
                      Icons.view_module_rounded,
                      _kP,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      '$sectionActive',
                      'Active',
                      _kEnFG,
                      _kEnBG,
                      _kEnB,
                      Icons.check_circle_outline_rounded,
                      _kEnFG,
                    ),
                    const SizedBox(width: 10),
                    _statCard(
                      '$sectionInactive',
                      'Inactive',
                      _kDiFG,
                      _kDiBG,
                      _kDiB,
                      Icons.block_rounded,
                      _kDiFG,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _sectionButton('Modules', ModuleSection.modules, Icons.view_module_rounded),
                    const SizedBox(width: 10),
                    _sectionButton('Sub Modules', ModuleSection.subModules, Icons.subdirectory_arrow_right_rounded),
                    const SizedBox(width: 10),
                    _sectionButton('Programs', ModuleSection.programs, Icons.play_arrow_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_section == ModuleSection.modules)
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
                            _page = 0;
                          });
                          _loadModules();
                        });
                      },
                    ),
                    if (widget.accessPrivileges?.canCreate ?? true) ...[
                      const SizedBox(width: 10),
                      _hBtn(
                        'New Module',
                        bg: _kP,
                        fg: Colors.white,
                        border: _kP,
                        icon: Icons.add_rounded,
                        onTap: () => _go(_V.create),
                      ),
                    ],
                  ],
                ),
              if (_section == ModuleSection.subModules)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _SearchBox(
                      width: 220,
                      onChanged: (v) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          setState(() {
                            _subSearch = v;
                            _subModulePage = 0;
                          });
                          _loadSubModules();
                        });
                      },
                    ),
                    if (widget.accessPrivileges?.canCreate ?? true) ...[
                      const SizedBox(width: 10),
                      _hBtn(
                        'New Sub Module',
                        bg: _kP,
                        fg: Colors.white,
                        border: _kP,
                        icon: Icons.subdirectory_arrow_right_rounded,
                        onTap: () => _go(_V.createSub),
                      ),
                    ],
                  ],
                ),
              if (_section == ModuleSection.programs)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _SearchBox(
                      width: 220,
                      onChanged: (v) {
                        if (_debounce?.isActive ?? false) _debounce?.cancel();
                        _debounce = Timer(const Duration(milliseconds: 300), () {
                          setState(() {
                            _programSearch = v;
                            _programPage = 0;
                          });
                          _loadPrograms();
                        });
                      },
                    ),
                    if (widget.accessPrivileges?.canCreate ?? true) ...[
                      const SizedBox(width: 10),
                      _hBtn(
                        'New Program',
                        bg: _kP,
                        fg: Colors.white,
                        border: _kP,
                        icon: Icons.playlist_add_rounded,
                        onTap: () => _go(_V.createProgram),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 14),
              if (_section == ModuleSection.modules)
                _card(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final cols = [
                      w * 0.12,
                      w * 0.30,
                      w * 0.20,
                      w * 0.20,
                      w * 0.18,
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
                            headerCell('MODULE ID'),
                            headerCell('MODULE NAME'),
                            headerCell('SUB MODULE'),
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
                                    dataCell(
                                      r.moduleId.toString(),
                                      color: _kP,
                                      fw: FontWeight.w700,
                                    ),
                                    dataCell(r.moduleName),
                                    dataCell(r.subModule ? 'Yes' : 'No'),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Center(
                                        child: _enabledBadge(r.status),
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
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
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
                                filtered.isEmpty
                                    ? 'No records found'
                                    : 'Showing $start–$end of $_totalModules records',
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
                                    onTap: () {
                                      ls(() => _page--);
                                      _loadModules();
                                    },
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
                                        onTap: () {
                                          ls(() => _page = i);
                                          _loadModules();
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _numPageBtn(
                                    '›',
                                    enabled: _page < totalPages - 1,
                                    active: false,
                                    onTap: () {
                                      ls(() => _page++);
                                      _loadModules();
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
              if (_section == ModuleSection.modules) const SizedBox(height: 24),
              if (_section == ModuleSection.subModules) const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Sub Modules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (_section == ModuleSection.subModules)
                _card(
                  child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final cols = [
                      w * 0.12,
                      w * 0.28,
                      w * 0.28,
                      w * 0.10,
                      w * 0.10,
                      w * 0.12,
                    ];
                    String moduleNameFor(int moduleId) {
                      final items = _allModules.where((m) => m.moduleId == moduleId).toList();
                      return items.isNotEmpty ? items.first.moduleName : 'Unknown';
                    }
                    final subPageItems = _subData;
                    final subStart = _subData.isEmpty ? 0 : _subModulePage * _pageSize + 1;
                    final subEnd = _subModulePage * _pageSize + subPageItems.length;
                    final subTotalPages = (_totalSubModules / _pageSize).ceil().clamp(1, 9999);
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
                            headerCell('SUB ID'),
                            headerCell('MODULE'),
                            headerCell('SUB MODULE NAME'),
                            headerCell('ROLE'),
                            headerCell('STATUS'),
                            headerCell('ACTIONS'),
                          ],
                          cols,
                          isHeader: true,
                        ),
                        if (_subData.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 20,
                            ),
                            child: Center(
                              child: Text(
                                'No submodules found',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          ...subPageItems.asMap().entries.map((entry) {
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
                                        r.subModuleId.toString(),
                                        color: _kP,
                                        fw: FontWeight.w700,
                                      ),
                                      dataCell(
                                        '${r.moduleId} - ${moduleNameFor(r.moduleId)}',
                                        color: _kP,
                                        fw: FontWeight.w700,
                                      ),
                                      dataCell(r.subModuleName),
                                      dataCell(
                                        r.accesscd == 1 ? 'SYSADMIN' : (r.accesscd == 2 ? 'ADMIN' : (r.accesscd == 3 ? 'END USER' : '')),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: _enabledBadge(r.status),
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
                                          mainAxisSize: MainAxisSize.min,
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
                                _subData.isEmpty
                                    ? 'No records found'
                                    : 'Showing $subStart–$subEnd of $_totalSubModules records',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Row(
                                children: [
                                  _numPageBtn(
                                    '‹',
                                    enabled: _subModulePage > 0,
                                    active: false,
                                    onTap: () {
                                      ls(() => _subModulePage--);
                                      _loadSubModules();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(
                                    subTotalPages,
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _numPageBtn(
                                        '${i + 1}',
                                        enabled: true,
                                        active: _subModulePage == i,
                                        onTap: () {
                                          ls(() => _subModulePage = i);
                                          _loadSubModules();
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _numPageBtn(
                                    '›',
                                    enabled: _subModulePage < subTotalPages - 1,
                                    active: false,
                                    onTap: () {
                                      ls(() => _subModulePage++);
                                      _loadSubModules();
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
              if (_section == ModuleSection.subModules) const SizedBox(height: 24),
              if (_section == ModuleSection.programs) const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Programs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (_section == ModuleSection.programs)
                _card(
                  child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final cols = [
                      w * 0.10,
                      w * 0.20,
                      w * 0.20,
                      w * 0.16,
                      w * 0.12,
                      w * 0.10,
                      w * 0.12,
                    ];
                    String moduleLabelFor(int moduleId) {
                      final item = _allModules.firstWhere(
                        (m) => m.moduleId == moduleId,
                        orElse: () => Module(
                          moduleId: moduleId,
                          moduleName: 'Unknown',
                          subModule: false,
                          status: false,
                        ),
                      );
                      return item.moduleName;
                    }
                    String subModuleLabelFor(int subModuleId) {
                      final item = _allSubModules.firstWhere(
                        (s) => s.subModuleId == subModuleId,
                        orElse: () => SubModule(
                          subModuleId: subModuleId,
                          moduleId: 0,
                          subModuleName: 'Unknown',
                          status: false,
                        ),
                      );
                      return item.subModuleName;
                    }
                    final pgmPageItems = _programData;
                    final pgmStart =
                        _programData.isEmpty ? 0 : _programPage * _pageSize + 1;
                    final pgmEnd = _programPage * _pageSize + pgmPageItems.length;
                    final pgmTotalPages =
                        (_totalPrograms / _pageSize).ceil().clamp(1, 9999);
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
                            headerCell('PGM ID'),
                            headerCell('MODULE'),
                            headerCell('SUB MODULE'),
                            headerCell('DESCRIPTION'),
                            headerCell('CLASS'),
                            headerCell('STATUS'),
                            headerCell('ACTIONS'),
                          ],
                          cols,
                          isHeader: true,
                        ),
                        if (_programData.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 20,
                            ),
                            child: Center(
                              child: Text(
                                'No programs found',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _kMuted,
                                ),
                              ),
                            ),
                          )
                        else
                          ...pgmPageItems.asMap().entries.map((entry) {
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
                                        r.pgmId.toString(),
                                        color: _kP,
                                        fw: FontWeight.w700,
                                      ),
                                      dataCell(
                                        '${r.moduleId} - ${moduleLabelFor(r.moduleId)}',
                                        color: _kP,
                                        fw: FontWeight.w700,
                                      ),
                                      dataCell(
                                        subModuleRoleLabelFor(r.subModuleId),
                                        color: _kP,
                                        fw: FontWeight.w700,
                                      ),
                                      dataCell(r.descn),
                                      dataCell(r.pgmClass.toString()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: _enabledBadge(r.status),
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
                                          mainAxisSize: MainAxisSize.min,
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
                                _programData.isEmpty
                                    ? 'No records found'
                                    : 'Showing $pgmStart–$pgmEnd of $_totalPrograms records',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              Row(
                                children: [
                                  _numPageBtn(
                                    '‹',
                                    enabled: _programPage > 0,
                                    active: false,
                                    onTap: () {
                                      ls(() => _programPage--);
                                      _loadPrograms();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(
                                    pgmTotalPages,
                                    (i) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: _numPageBtn(
                                        '${i + 1}',
                                        enabled: true,
                                        active: _programPage == i,
                                        onTap: () {
                                          ls(() => _programPage = i);
                                          _loadPrograms();
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  _numPageBtn(
                                    '›',
                                    enabled: _programPage < pgmTotalPages - 1,
                                    active: false,
                                    onTap: () {
                                      ls(() => _programPage++);
                                      _loadPrograms();
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

  Widget _form({required bool isEdit}) {
    final r = isEdit ? _sel : null;
    final cId = TextEditingController(text: r?.moduleId.toString() ?? '');
    final cName = TextEditingController(text: r?.moduleName ?? '');
    bool subModuleValue = r?.subModule ?? false;
    bool statusValue = r?.status ?? true;
    final errors = <String, String?>{};
    return StatefulBuilder(
      builder: (ctx, ls) {
        void clearError(String key) {
          if (errors.containsKey(key)) ls(() => errors.remove(key));
        }

        cId.addListener(() {
          if (cId.text.isNotEmpty) clearError('id');
        });
        cName.addListener(() {
          if (cName.text.isNotEmpty) clearError('name');
        });

        bool validate() {
          final e = <String, String?>{};
          if (cId.text.trim().isEmpty && isEdit) e['id'] = 'Required';
          if (cName.text.trim().isEmpty) e['name'] = 'Required';
          ls(
            () => errors
              ..clear()
              ..addAll(e),
          );
          return e.isEmpty;
        }

        void save() async {
          if (!validate()) {
            _ModToast.show(
              context,
              'Please fill all required fields.',
              isError: true,
            );
            return;
          }
          try {
            final user = await AuthService().getUser();
            final currentUser = user?.userName ?? user?.email ?? user?.name ?? '';
            final nowUtc = DateTime.now().toUtc().toIso8601String();
            final module = Module(
              moduleId: isEdit ? int.parse(cId.text) : 0,
              moduleName: cName.text,
              subModule: subModuleValue,
              status: statusValue,
              euser: isEdit ? r?.euser : currentUser,
              edate: isEdit ? _normalizeAuditDateValue(r?.edate) : nowUtc,
              cuser: isEdit ? currentUser : null,
              cdate: isEdit ? nowUtc : null,
              auser: isEdit ? r?.auser : currentUser,
              adate: isEdit ? _normalizeAuditDateValue(r?.adate) : nowUtc,
            );
            if (isEdit) {
              await _moduleService.updateModule(module.moduleId, module);
              OperationalLogService().logAction(programId: 'Modules', action: 'U');
              _toast('Module updated successfully!');
            } else {
              await _moduleService.createModule(module);
              OperationalLogService().logAction(programId: 'Modules', action: 'I');
              _toast('Module created successfully!');
            }
            _loadModules();
            _go(_V.list);
          } catch (e) {
            _toast('Failed to save module', isError: true);
          }
        }

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
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
                    _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
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
                                      ? 'Edit Module Details'
                                      : 'Module Details',
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
                        childAspectRatio: 3.2,
                        children: [
                          _floatField(
                            label: 'Module ID',
                            ctrl: cId,
                            icon: Icons.tag_rounded,
                            hint: 'Enter the Module ID',
                            readOnly: isEdit,
                            required: isEdit,
                            errorText: errors['id'],
                          ),
                          _floatField(
                            label: 'Module Name',
                            ctrl: cName,
                            icon: Icons.view_module_rounded,
                            hint: 'Enter the Module Name',
                            required: true,
                            errorText: errors['name'],
                          ),
                          _toggleField(
                            label: 'Sub Module',
                            icon: Icons.account_tree_rounded,
                            value: subModuleValue,
                            trueLabel: 'Yes',
                            falseLabel: 'No',
                            activeColor: _kP,
                            onChanged: (v) => ls(() => subModuleValue = v),
                            isRequired: true,
                          ),
                          _toggleField(
                            label: 'Status',
                            icon: Icons.toggle_on_rounded,
                            value: statusValue,
                            trueLabel: 'Active',
                            falseLabel: 'Inactive',
                            activeColor: _kG,
                            onChanged: (v) => ls(() => statusValue = v),
                            isRequired: true,
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
                          if (isEdit && (_sel?.status ?? true))
                            _fBtn(
                              'Deactivate',
                              Icons.block_rounded,
                              Colors.white,
                              _kR,
                              _kRB,
                              onTap: () async {
                                if (_sel == null) return;
                                try {
                                  await _moduleService.updateModule(
                                    _sel!.moduleId,
                                    _sel!.copyWith(status: false),
                                  );
                                  _toast('Module deactivated.');
                                  await _loadModules();
                                  _go(_V.list);
                                } catch (_) {
                                  _toast('Failed to deactivate module.', isError: true);
                                }
                              },
                            )
                          else if (isEdit)
                            _fBtn(
                              'Activate',
                              Icons.check_circle_outline_rounded,
                              _kG,
                              Colors.white,
                              _kG,
                              onTap: () async {
                                if (_sel == null) return;
                                try {
                                  await _moduleService.updateModule(
                                    _sel!.moduleId,
                                    _sel!.copyWith(status: true),
                                  );
                                  _toast('Module activated.');
                                  await _loadModules();
                                  _go(_V.list);
                                } catch (_) {
                                  _toast('Failed to activate module.', isError: true);
                                }
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

  Widget _subForm({bool isEdit = false}) {
    final r = isEdit ? _selSubModule : null;
    final cSubId = TextEditingController(text: r?.subModuleId.toString() ?? '');
    final cModuleId = TextEditingController(text: r?.moduleId.toString() ?? '');
    final cName = TextEditingController(text: r?.subModuleName ?? '');
    bool statusValue = r?.status ?? true;
    Module? selectedModule;
    int? selectedRole = r?.accesscd;
    if (r != null) {
      for (final module in _data) {
        if (module.moduleId == r.moduleId) {
          selectedModule = module;
          break;
        }
      }
    }
    final errors = <String, String?>{};

    return StatefulBuilder(
      builder: (ctx, ls) {
        void clearError(String key) {
          if (errors.containsKey(key)) ls(() => errors.remove(key));
        }

        final moduleItems = _data
            .where((m) => m.subModule)
            .map((m) => '${m.moduleId} - ${m.moduleName}')
            .toList();

        final roleItems = ['SYSADMIN', 'ADMIN', 'END USER'];
        
        String? _getRoleText(int? val) {
          if (val == 1) return 'SYSADMIN';
          if (val == 2) return 'ADMIN';
          if (val == 3) return 'END USER';
          return null;
        }

        int? _getRoleVal(String? text) {
          if (text == 'SYSADMIN') return 1;
          if (text == 'ADMIN') return 2;
          if (text == 'END USER') return 3;
          return null;
        }

        cSubId.addListener(() {
          if (cSubId.text.isNotEmpty) clearError('subId');
        });
        cModuleId.addListener(() {
          if (cModuleId.text.isNotEmpty) clearError('moduleId');
        });
        cName.addListener(() {
          if (cName.text.isNotEmpty) clearError('name');
        });

        bool validate() {
          final e = <String, String?>{};
          if (cSubId.text.trim().isEmpty) e['subId'] = 'Required';
          if (cModuleId.text.trim().isEmpty) e['moduleId'] = 'Required';
          if (cName.text.trim().isEmpty) e['name'] = 'Required';
          if (selectedRole == null) e['role'] = 'Required';
          ls(
            () => errors
              ..clear()
              ..addAll(e),
          );
          return e.isEmpty;
        }

        void save() async {
          if (!validate()) {
            _ModToast.show(
              context,
              'Please fill all required fields.',
              isError: true,
            );
            return;
          }
          try {
            final user = await AuthService().getUser();
            final currentUser = user?.userName ?? user?.email ?? user?.name ?? '';
            final nowUtc = DateTime.now().toUtc().toIso8601String();
            final subModule = SubModule(
              subModuleId: int.parse(cSubId.text),
              moduleId: int.parse(cModuleId.text),
              subModuleName: cName.text,
              status: statusValue,
              accesscd: selectedRole,
              euser: isEdit ? r?.euser : currentUser,
              edate: isEdit ? r?.edate : nowUtc,
              cuser: isEdit ? currentUser : null,
              cdate: isEdit ? nowUtc : null,
              auser: isEdit ? r?.auser : currentUser,
              adate: isEdit ? r?.adate : nowUtc,
            );
            if (isEdit) {
              await _subModuleService.updateSubModule(subModule.subModuleId, subModule);
              OperationalLogService().logAction(programId: 'Sub Modules', action: 'U');
              _toast('Sub module updated successfully!');
            } else {
              await _subModuleService.createSubModule(subModule);
              OperationalLogService().logAction(programId: 'Sub Modules', action: 'I');
              _toast('Sub module created successfully!');
            }
            await _loadSubModules();
            _go(_V.list);
          } catch (e) {
            _toast(isEdit ? 'Failed to update submodule' : 'Failed to create submodule', isError: true);
          }
        }

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Sub Module' : 'Add New Sub Module',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
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
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sub Module Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Fill all required fields marked with *',
                                  style: TextStyle(
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
                              color: _kPL,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kPB),
                            ),
                            child: Text(
                              isEdit ? 'EDIT MODE' : 'NEW RECORD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kP,
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
                        childAspectRatio: 3.2,
                        children: [
                          _floatField(
                            label: 'Sub Module ID',
                            ctrl: cSubId,
                            icon: Icons.category_rounded,
                            hint: 'Enter The Sub Module ID',
                            required: true,
                            errorText: errors['subId'],
                          ),
                          _CustomDropdownField(
                            label: 'Module',
                            icon: Icons.view_module_rounded,
                            value: selectedModule != null ? '${selectedModule!.moduleId} - ${selectedModule!.moduleName}' : '',
                            items: moduleItems,
                            hint: 'Select module',
                            isRequired: true,
                            errorText: errors['moduleId'],
                            onChanged: (value) {
                              final module = _data.firstWhere((m) => '${m.moduleId} - ${m.moduleName}' == value);
                              ls(() {
                                selectedModule = module;
                                cModuleId.text = module.moduleId.toString();
                              });
                            },
                          ),
                          _floatField(
                            label: 'Sub Module Name',
                            ctrl: cName,
                            icon: Icons.account_tree_rounded,
                            hint: 'Enter The Sub Module Name',
                            required: true,
                            errorText: errors['name'],
                          ),
                          _CustomDropdownField(
                            label: 'Role',
                            icon: Icons.admin_panel_settings_rounded,
                            value: _getRoleText(selectedRole) ?? '',
                            items: roleItems,
                            hint: 'Select role',
                            isRequired: true,
                            errorText: errors['role'],
                            onChanged: (value) {
                              ls(() {
                                selectedRole = _getRoleVal(value);
                                if (selectedRole != null) clearError('role');
                              });
                            },
                          ),
                          _toggleField(
                            label: 'Status',
                            icon: Icons.toggle_on_rounded,
                            value: statusValue,
                            trueLabel: 'Active',
                            falseLabel: 'Inactive',
                            activeColor: _kG,
                            onChanged: (v) => ls(() => statusValue = v),
                            isRequired: true,
                            hasError: errors['status'] != null,
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

  Widget _programForm({bool isEdit = false}) {
    final r = isEdit ? _selProgram : null;
    final cPgmId = TextEditingController(text: r?.pgmId.toString() ?? '');
    final cDesc = TextEditingController(text: r?.descn ?? '');
    final cNewPgmName = TextEditingController(text: '');
    final cModuleId = TextEditingController(text: r?.moduleId.toString() ?? '');
    final cSubModuleId = TextEditingController(text: r?.subModuleId.toString() ?? '');
    final cPgmClass = TextEditingController(text: r?.pgmClass.toString() ?? '');
    bool statusValue = r?.status ?? true;
    Module? selectedModule;
    if (r != null) {
      for (final module in _data) {
        if (module.moduleId == r.moduleId) {
          selectedModule = module;
          break;
        }
      }
    }
    SubModule? selectedSubModule;
    if (r != null) {
      for (final sub in _subData) {
        if (sub.subModuleId == r.subModuleId) {
          selectedSubModule = sub;
          break;
        }
      }
    }
    final errors = <String, String?>{};
    return StatefulBuilder(
      builder: (ctx, ls) {
        void clearError(String key) {
          if (errors.containsKey(key)) ls(() => errors.remove(key));
        }

        final moduleItems = _data.map((m) => '${m.moduleId} - ${m.moduleName}').toList();
        final programDescItems = [
          ..._programData.map((p) => (p.descn ?? '').trim()).where((d) => d.isNotEmpty).toSet().toList()..sort(),
          'Add New Program',
        ];
        final subModuleItems = selectedModule != null
            ? _subData
                .where((s) => s.moduleId == selectedModule!.moduleId)
                .map((s) => subModuleRoleLabelFor(s.subModuleId))
                .toList()
            : _subData
                .map((s) => subModuleRoleLabelFor(s.subModuleId))
                .toList();

        cPgmId.addListener(() {
          if (cPgmId.text.isNotEmpty) clearError('pgmId');
        });
        cDesc.addListener(() {
          if (cDesc.text.isNotEmpty) clearError('descn');
        });
        cNewPgmName.addListener(() {
          if (cNewPgmName.text.isNotEmpty) clearError('newPgmName');
        });
        cModuleId.addListener(() {
          if (cModuleId.text.isNotEmpty) clearError('moduleId');
        });
        cSubModuleId.addListener(() {
          if (cSubModuleId.text.isNotEmpty) clearError('subModuleId');
        });
        cPgmClass.addListener(() {
          if (cPgmClass.text.isNotEmpty) clearError('pgmClass');
        });

        bool validate() {
          final e = <String, String?>{};
          if (cPgmId.text.trim().isEmpty) e['pgmId'] = 'Required';
          if (cDesc.text.trim().isEmpty) {
            e['descn'] = 'Required';
          } else if (cDesc.text == 'Add New Program' && cNewPgmName.text.trim().isEmpty) {
            e['newPgmName'] = 'Required';
          }
          if (cModuleId.text.trim().isEmpty) e['moduleId'] = 'Required';
          if (cSubModuleId.text.trim().isEmpty) e['subModuleId'] = 'Required';
          if (cPgmClass.text.trim().isEmpty) e['pgmClass'] = 'Required';
          ls(
            () => errors
              ..clear()
              ..addAll(e),
          );
          return e.isEmpty;
        }

        Future<void> save() async {
          if (!validate()) {
            _ModToast.show(
              context,
              'Please fill all required fields.',
              isError: true,
            );
            return;
          }

          try {
            final user = await AuthService().getUser();
            final currentUser = user?.userName ?? user?.email ?? user?.name ?? '';
            final nowUtc = DateTime.now().toUtc().toIso8601String();
            final program = Program(
              pgmId: int.parse(cPgmId.text),
              descn: cDesc.text == 'Add New Program' ? cNewPgmName.text.trim() : cDesc.text.trim(),
              moduleId: int.parse(cModuleId.text),
              subModuleId: int.parse(cSubModuleId.text),
              pgmClass: int.parse(cPgmClass.text),
              status: statusValue,
              euser: isEdit ? r?.euser : currentUser,
              edate: isEdit ? _normalizeAuditDateValue(r?.edate) : nowUtc,
              cuser: isEdit ? currentUser : null,
              cdate: isEdit ? nowUtc : null,
              auser: isEdit ? r?.auser : currentUser,
              adate: isEdit ? _normalizeAuditDateValue(r?.adate) : nowUtc,
            );
            if (isEdit) {
              await _programService.updateProgram(program.pgmId, program);
              OperationalLogService().logAction(programId: 'Programs', action: 'U');
              _toast('Program updated successfully!');
            } else {
              final created = await _programService.createProgram(program);
              OperationalLogService().logAction(programId: 'Programs', action: 'I');
              setState(() => _programData.add(created));
              _toast('Program created successfully!');
            }
            await _loadPrograms();
            _go(_V.list);
          } catch (e) {
            _toast(isEdit ? 'Failed to update program' : 'Failed to create program', isError: true);
          }
        }

        return _page_(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? 'Edit Program' : 'Add New Program',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _hBtn('Back', bg: _kP, fg: Colors.white, border: _kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
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
                        border: Border(bottom: BorderSide(color: _kBorder)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Program Details',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Fill all required fields marked with *',
                                  style: TextStyle(
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
                              color: _kPL,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _kPB),
                            ),
                            child: Text(
                              isEdit ? 'EDIT MODE' : 'NEW RECORD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _kP,
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
                        childAspectRatio: 3.2,
                        children: [
                          _floatField(
                            label: 'Program ID',
                            ctrl: cPgmId,
                            icon: Icons.code_rounded,
                            hint: 'Enter The Program ID',
                            required: true,
                            errorText: errors['pgmId'],
                          ),
                          _CustomDropdownField(
                            label: 'Description',
                            icon: Icons.description_rounded,
                            value: cDesc.text,
                            items: programDescItems,
                            hint: 'Select Program Description',
                            isRequired: true,
                            errorText: errors['descn'],
                            onChanged: (value) {
                              ls(() {
                                cDesc.text = value;
                                errors.remove('descn');
                              });
                            },
                          ),
                          if (cDesc.text == 'Add New Program')
                            _floatField(
                              label: 'Program Name',
                              ctrl: cNewPgmName,
                              icon: Icons.edit_note_rounded,
                              hint: 'Enter program name',
                              required: true,
                              errorText: errors['newPgmName'],
                            ),
                          _CustomDropdownField(
                            label: 'Module',
                            icon: Icons.view_module_rounded,
                            value: selectedModule != null ? '${selectedModule!.moduleId} - ${selectedModule!.moduleName}' : '',
                            items: moduleItems,
                            hint: 'Select module',
                            isRequired: true,
                            errorText: errors['moduleId'],
                            onChanged: (value) {
                              final module = _data.firstWhere((m) => '${m.moduleId} - ${m.moduleName}' == value);
                              final hasSubModules = _subData.any((s) => s.moduleId == module.moduleId);
                              if (!hasSubModules) {
                                _ModToast.show(
                                  context,
                                  'No sub module found for "${module.moduleName}". Please create a sub module for this module first.',
                                  isError: true,
                                );
                                return;
                              }
                              ls(() {
                                selectedModule = module;
                                selectedSubModule = null;
                                cModuleId.text = module.moduleId.toString();
                                cSubModuleId.clear();
                                errors.remove('moduleId');
                              });
                            },
                          ),
                          _CustomDropdownField(
                            label: 'Sub Module',
                            icon: Icons.subdirectory_arrow_right_rounded,
                            value: selectedSubModule != null ? subModuleRoleLabelFor(selectedSubModule!.subModuleId) : '',
                            items: subModuleItems,
                            hint: 'Select sub module',
                            isRequired: true,
                            errorText: errors['subModuleId'],
                            onChanged: (value) {
                              final subModule = _subData.firstWhere((s) => subModuleRoleLabelFor(s.subModuleId) == value);
                              ls(() {
                                selectedSubModule = subModule;
                                cSubModuleId.text = subModule.subModuleId.toString();
                              });
                            },
                          ),
                          _floatField(
                            label: 'Program Class',
                            ctrl: cPgmClass,
                            icon: Icons.class_rounded,
                            hint: 'Enter The Program Class',
                            required: true,
                            errorText: errors['pgmClass'],
                          ),
                          _toggleField(
                            label: 'Status',
                            icon: Icons.toggle_on_rounded,
                            value: statusValue,
                            trueLabel: 'Active',
                            falseLabel: 'Inactive',
                            activeColor: _kG,
                            onChanged: (v) => ls(() => statusValue = v),
                            isRequired: true,
                            hasError: false,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
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
                _hBtn('Audit Details', bg: Colors.white, fg: _kP, border: _kP, icon: Icons.history_rounded, onTap: () => _showAuditPopupForModule(r)),
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
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.view_module_rounded,
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
                              r.moduleName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kP,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'MODULE${r.moduleId.toString().padLeft(3, '0')} • Menu Module • Record Details',
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
                          color: r.status ? _kGL : _kRL,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: r.status ? _kGB : _kRB),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: r.status ? _kG : _kR,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              r.status ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: r.status ? _kG : _kR,
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
                    childAspectRatio: 3.2,
                    children: [
                      ro('Module ID', r.moduleId.toString(), Icons.tag_rounded),
                      ro(
                        'Module Name',
                        r.moduleName,
                        Icons.view_module_rounded,
                      ),
                      ro('Sub Module', r.subModule ? 'Yes' : 'No', Icons.account_tree_rounded),
                      ro('Status', r.status ? 'Active' : 'Inactive', Icons.toggle_on_rounded),
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
                              _delRow('Module ID:', r.moduleId, isRed: true),
                              const SizedBox(height: 6),
                              _delRow('Module Name:', r.moduleName),
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
                          onTap: _delConfirmed
                              ? () async {
                                  try {
                                    await _moduleService.deleteModule(r.moduleId);
                                    OperationalLogService().logAction(programId: 'Modules', action: 'D');
                                    _toast('Module deleted successfully!');
                                    await _loadModules();
                                    _go(_V.list);
                                  } catch (e) {
                                    _toast(e.toString(), isError: true);
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
          ],
        ),
      ),
    );
  }

  Widget _subDetail() {
    final r = _selSubModule!;
    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Sub Module Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _hBtn('Audit Details', bg: Colors.white, fg: _kP, border: _kP, icon: Icons.history_rounded, onTap: () => _showAuditPopupForSubModule(r)),
              ],
            ),
          ),
          _card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 3.0,
                    children: [
                      _floatField(
                        label: 'Sub Module ID',
                        ctrl: TextEditingController(text: r.subModuleId.toString()),
                        icon: Icons.category_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Module ID',
                        ctrl: TextEditingController(text: moduleLabelFor(r.moduleId)),
                        icon: Icons.view_module_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Sub Module Name',
                        ctrl: TextEditingController(text: r.subModuleName),
                        icon: Icons.account_tree_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Status',
                        ctrl: TextEditingController(text: r.status ? 'Active' : 'Inactive'),
                        icon: Icons.toggle_on_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Role',
                        ctrl: TextEditingController(
                          text: r.accesscd == 1 ? 'SYSADMIN' : (r.accesscd == 2 ? 'ADMIN' : (r.accesscd == 3 ? 'END USER' : '')),
                        ),
                        icon: Icons.admin_panel_settings_rounded,
                        readOnly: true,
                        required: false,
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

  Widget _programDetail() {
    final r = _selProgram!;
    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Expanded(
                  child: Text(
                    'Program Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _hBtn('Audit Details', bg: Colors.white, fg: _kP, border: _kP, icon: Icons.history_rounded, onTap: () => _showAuditPopupForProgram(r)),
              ],
            ),
          ),
          _card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 3.0,
                    children: [
                      _floatField(
                        label: 'Program ID',
                        ctrl: TextEditingController(text: r.pgmId.toString()),
                        icon: Icons.code_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Description',
                        ctrl: TextEditingController(text: r.descn),
                        icon: Icons.description_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Module ID',
                        ctrl: TextEditingController(text: moduleLabelFor(r.moduleId)),
                        icon: Icons.view_module_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Sub Module ID',
                        ctrl: TextEditingController(text: subModuleRoleLabelFor(r.subModuleId)),
                        icon: Icons.subdirectory_arrow_right_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Program Class',
                        ctrl: TextEditingController(text: r.pgmClass.toString()),
                        icon: Icons.class_rounded,
                        readOnly: true,
                        required: false,
                      ),
                      _floatField(
                        label: 'Status',
                        ctrl: TextEditingController(text: r.status ? 'Active' : 'Inactive'),
                        icon: Icons.toggle_on_rounded,
                        readOnly: true,
                        required: false,
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

  Widget _subDelete() {
    final r = _selSubModule!;
    return StatefulBuilder(
      builder: (ctx, ls) => _page_(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Delete Sub Module',
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
                          'Are you sure you want to delete this sub module? This action cannot be undone.',
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
                              _delRow('Sub Module ID:', r.subModuleId, isRed: true),
                              const SizedBox(height: 6),
                              _delRow('Module ID:', r.moduleId),
                              const SizedBox(height: 6),
                              _delRow('Sub Module Name:', r.subModuleName),
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
                          _delConfirmed ? Colors.white : const Color(0xFFCBD5E1),
                          _delConfirmed ? _kR : _kBorder,
                          onTap: _delConfirmed
                              ? () async {
                                  try {
                                    await _subModuleService.deleteSubModule(r.subModuleId);
                                    OperationalLogService().logAction(programId: 'Sub Modules', action: 'D');
                                    _toast('Sub module deleted successfully!');
                                    await _loadSubModules();
                                    _go(_V.list);
                                  } catch (e) {
                                    _toast(e.toString(), isError: true);
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
          ],
        ),
      ),
    );
  }

  Widget _programDelete() {
    final r = _selProgram!;
    return StatefulBuilder(
      builder: (ctx, ls) => _page_(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Delete Program',
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
                          'Are you sure you want to delete this program? This action cannot be undone.',
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
                              _delRow('Program ID:', r.pgmId, isRed: true),
                              const SizedBox(height: 6),
                              _delRow('Module ID:', r.moduleId),
                              const SizedBox(height: 6),
                              _delRow('Sub Module ID:', r.subModuleId),
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
                          _delConfirmed ? Colors.white : const Color(0xFFCBD5E1),
                          _delConfirmed ? _kR : _kBorder,
                          onTap: _delConfirmed
                              ? () async {
                                  try {
                                    await _programService.deleteProgram(r.pgmId);
                                    OperationalLogService().logAction(programId: 'Programs', action: 'D');
                                    _toast('Program deleted successfully!');
                                    await _loadPrograms();
                                    _go(_V.list);
                                  } catch (_) {
                                    _toast('Failed to delete program.', isError: true);
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
          ],
        ),
      ),
    );
  }

  Widget _delRow(String key, Object val, {bool isRed = false}) => Row(
    children: [
      SizedBox(
        width: 150,
        child: Text(key, style: const TextStyle(fontSize: 12, color: _kMuted)),
      ),
      Text(
        val.toString(),
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
          top:15,
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

// ── Custom Dropdown Field (Overlay-based with floating label) ────────────────
class _CustomDropdownField extends StatefulWidget {
  final String label;
  final String value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  final bool isRequired;
  final String hint;
  final String? errorText;

  const _CustomDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.icon,
    required this.onChanged,
    this.isRequired = false,
    this.hint = 'Select an option',
    this.errorText,
  });

  @override
  State<_CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<_CustomDropdownField>
    with SingleTickerProviderStateMixin {
  final _link = LayerLink();
  OverlayEntry? _overlay;
  bool _open = false;
  bool _hovered = false;

  late final AnimationController _ac;
  late final Animation<double> _labelTop, _labelSize;

  bool get _hasValue => widget.value.isNotEmpty;
  bool get _floated => _open || _hasValue || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _labelTop = Tween<double>(begin: 13, end: -8)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _labelSize = Tween<double>(begin: 13, end: 10.5)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant _CustomDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open && (widget.items != oldWidget.items || widget.value != oldWidget.value)) {
      _closeOverlay();
    }
    _floated ? _ac.forward() : _ac.reverse();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _toggleOverlay() {
    if (widget.items.isEmpty) return;
    if (_open) {
      _closeOverlay();
      return;
    }

    _removeOverlay();
    _overlay = OverlayEntry(builder: (_) {
      final renderBox = context.findRenderObject() as RenderBox?;
      final width = renderBox?.size.width ?? 0;
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeOverlay,
        child: Stack(children: [
          Positioned.fill(child: Container(color: Colors.transparent)),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: Offset(0, (renderBox?.size.height ?? 44) + 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kP, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.09), blurRadius: 14, offset: const Offset(0, 4))],
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (_, index) {
                      final item = widget.items[index];
                      final selected = item == widget.value;
                      final isAddNew = item == 'Add New Program';
                      final textCol = selected
                          ? _kP
                          : (isAddNew ? const Color(0xFF3D6EBE) : _kText);
                      final fontW = isAddNew ? FontWeight.w700 : FontWeight.w500;
                      return GestureDetector(
                        onTap: () {
                          widget.onChanged(item);
                          _closeOverlay();
                        },
                        child: Container(
                          color: selected ? _kPL : (isAddNew ? const Color(0xFFF0F5FF) : Colors.white),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(children: [
                            if (isAddNew) ...[
                              const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF3D6EBE)),
                              const SizedBox(width: 8),
                            ],
                            Expanded(child: Text(item, style: TextStyle(fontSize: 13, fontWeight: fontW, color: textCol))),
                            if (selected) Icon(Icons.check, size: 16, color: _kP),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });

    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
    _ac.forward();
  }

  void _closeOverlay() {
    _removeOverlay();
    if (mounted) {
      setState(() => _open = false);
      if (!_hasValue) _ac.reverse();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.errorText != null ? _kR : _kP;
    final displayText = widget.value.isNotEmpty ? widget.value : '';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _toggleOverlay,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 44,
              decoration: BoxDecoration(
                color: _hovered && !_open ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: _open ? 2.0 : 1.5),
                boxShadow: _open
                    ? [BoxShadow(color: _kP.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 36, right: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            displayText.isEmpty ? (_floated ? widget.hint : '') : displayText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: displayText.isEmpty ? const Color(0xFFCBD5E1) : _kText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedRotation(
                          duration: const Duration(milliseconds: 180),
                          turns: _open ? 0.5 : 0.0,
                          child: Icon(Icons.expand_more_rounded, size: 18, color: borderColor),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10, top: 0, bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(widget.icon, size: 14, color: borderColor),
                  ),
                ),
                AnimatedBuilder(
                  animation: _ac,
                  builder: (_, __) => Positioned(
                    top: _labelTop.value,
                    left: 28,
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text.rich(
                        TextSpan(
                          text: widget.label,
                          children: [
                            if (widget.isRequired)
                              const TextSpan(text: ' *', style: TextStyle(color: _kR)),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: _labelSize.value,
                          fontWeight: FontWeight.w600,
                          color: borderColor,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 6),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, color: _kR)),
        ),
    ]);
  }
}
