import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/access_privileges.dart';
import '../../models/menu_models.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../widgets/audit_details_dialog.dart';
import 'menu_master_widgets.dart';

enum _V { list, form, delete }

class MenuProgramTab extends StatefulWidget {
  final ValueChanged<bool>? onFormChanged;
  final ValueChanged<int>? onTotalChanged;
  final void Function(int active, int inactive)? onStatusChanged;
  final VoidCallback? onMenuModified;
  final bool isActive;
  final AccessPrivileges? accessPrivileges;

  const MenuProgramTab({super.key, this.onFormChanged, this.onTotalChanged, this.onStatusChanged, this.onMenuModified, this.isActive = false, this.accessPrivileges});
  @override
  State<MenuProgramTab> createState() => _MenuProgramTabState();
}

class _MenuProgramTabState extends State<MenuProgramTab> {
  final MenuMasterService _service = MenuMasterService();
  bool _isLoading = true;
  bool _hasLoaded = false;
  List<MenuProgramModel> _data = [];
  List<HeadMenuModel> _headMenus = [];
  List<MenuModel> _menus = [];
  List<SubMenuModel> _subMenus = [];
  List<ProgramModel> _programs = [];
  
  _V _view = _V.list;
  bool _isEdit = false;
  bool _isView = false;
  MenuProgramModel? _sel;
  MenuProgramModel? _programToDelete;
  

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  
  String? _filterHMenuCd;
  String? _filterMenuCd;
  String? _filterSubMenuCd;
  
  final _hMenuCdCtrl = TextEditingController();
  final _menuCdCtrl = TextEditingController();
  final _subMenuCdCtrl = TextEditingController();
  final _pgmIdCtrl = TextEditingController();
  final _menuOrderCtrl = TextEditingController();
  final FocusNode _menuOrderFocus = FocusNode();
  final _programPathCtrl = TextEditingController();
  final _menuLogoCtrl = TextEditingController();
  bool _status = true;
  
  String? _hMenuCdError;
  String? _menuCdError;
  String? _subMenuCdError;
  String? _pgmIdError;
  String? _descriptionError;
  String? _menuOrderError;
  String? _programPathError;

  Uint8List? _logoBytes;
  String? _logoName;
  String? _logoError;

  @override
  void initState() {
    super.initState();
    _hMenuCdCtrl.addListener(() { if (_hMenuCdError != null) setState(() => _hMenuCdError = null); });
    _menuCdCtrl.addListener(() { if (_menuCdError != null) setState(() => _menuCdError = null); });
    _subMenuCdCtrl.addListener(() { if (_subMenuCdError != null) setState(() => _subMenuCdError = null); });
    _pgmIdCtrl.addListener(() { if (_pgmIdError != null) setState(() => _pgmIdError = null); });
    _menuOrderCtrl.addListener(() { if (_menuOrderError != null) setState(() => _menuOrderError = null); });
    _programPathCtrl.addListener(() { if (_programPathError != null) setState(() => _programPathError = null); });
    _menuLogoCtrl.addListener(() { if (_logoError != null) setState(() => _logoError = null); });
    _menuOrderFocus.addListener(_onMenuOrderFocusChange);
    if (widget.isActive) {
      _hasLoaded = true;
      _loadData();
    }
  }

  @override
  void didUpdateWidget(MenuProgramTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        _loadData();
      }
      if (_view != _V.list) {
        _go(_V.list);
      }
      if (_search.isNotEmpty || _currentPage != 0 || _searchCtrl.text.isNotEmpty || _filterHMenuCd != null || _filterMenuCd != null || _filterSubMenuCd != null) {
        setState(() {
          _search = '';
          _searchCtrl.clear();
          _currentPage = 0;
          _filterHMenuCd = null;
          _filterMenuCd = null;
          _filterSubMenuCd = null;
        });
      }
      widget.onTotalChanged?.call(_data.length);
      int active = _data.where((d) => d.status).length;
      widget.onStatusChanged?.call(active, _data.length - active);
    }
  }

  void _onMenuOrderFocusChange() {
    if (!_menuOrderFocus.hasFocus) {
      _validateMenuOrder();
    }
  }

  void _validateMenuOrder() {
    if (_menuOrderCtrl.text.trim().isEmpty) return;
    int? enteredOrder = int.tryParse(_menuOrderCtrl.text.trim());
    if (enteredOrder == null) return;

    final hMenuCdStr = _hMenuCdCtrl.text.split(' - ').first;
    final hMenuCd = int.tryParse(hMenuCdStr);
    final menuCdStr = _menuCdCtrl.text.split(' - ').first;
    final menuCd = int.tryParse(menuCdStr);
    final subMenuCdStr = _subMenuCdCtrl.text.split(' - ').first;
    final subMenuCd = int.tryParse(subMenuCdStr);
    if (hMenuCd == null || menuCd == null || subMenuCd == null) return;

    final currentPgmId = _isEdit ? _sel?.pgmId : null;

    bool isDuplicate = _data.any((item) =>
        item.hMenuCd == hMenuCd &&
        item.menuCd == menuCd &&
        item.subMenuCd == subMenuCd &&
        item.menuOrder == enteredOrder &&
        (currentPgmId == null || item.pgmId != currentPgmId));

    setState(() {
      if (isDuplicate) {
        _menuOrderError = 'Menu order $enteredOrder is already in use.';
      } else {
        _menuOrderError = null;
      }
    });
  }

  @override
  void dispose() {
    _menuOrderFocus.removeListener(_onMenuOrderFocusChange);
    _menuOrderFocus.dispose();
    _searchCtrl.dispose();
    _hMenuCdCtrl.dispose();
    _menuCdCtrl.dispose();
    _subMenuCdCtrl.dispose();
    _pgmIdCtrl.dispose();
    _menuOrderCtrl.dispose();
    _programPathCtrl.dispose();
    _menuLogoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    List<MenuProgramModel> newProgData = [];
    List<HeadMenuModel> newHead = [];
    List<MenuModel> newMenu = [];
    List<SubMenuModel> newSub = [];
    List<ProgramModel> newProgList = [];

    try { newProgData = await _service.getAllMenuPrograms(); } catch(e) { print('Error loading menu programs: $e'); }
    try { newHead = await _service.getHeadMenus(); } catch(e) { print('Error loading head menus: $e'); }
    try { newMenu = await _service.getMenus(); } catch(e) { print('Error loading menus: $e'); }
    try { newSub = await _service.getSubMenus(); } catch(e) { print('Error loading submenus: $e'); }
    try { newProgList = await _service.getAllPrograms(); } catch(e) { print('Error loading programs: $e'); }

    if (mounted) {
      setState(() { 
        _data = newProgData;
        _headMenus = newHead;
        _menus = newMenu;
        _subMenus = newSub;
        _programs = newProgList;
        _isLoading = false; 
        _currentPage = 0;
        _filterHMenuCd = null;
        _filterMenuCd = null;
        _filterSubMenuCd = null;
      });
      if (_headMenus.isEmpty) {
        MNToast.show(context, 'Failed to load Head Menus. Check console.', isError: true);
      }
      if (widget.isActive) {
        widget.onTotalChanged?.call(_data.length);
        int active = _data.where((d) => d.status).length;
        widget.onStatusChanged?.call(active, _data.length - active);
      }
    }
  }

  void _go(_V view) {
    setState(() => _view = view);
    widget.onFormChanged?.call(view != _V.list);
  }

  Future<void> _fetchAndOpenForm(MenuProgramModel r, {bool isView = false}) async {
    _go(_V.form);
    setState(() => _isLoading = true);
    try {
      final fetchedProgram = await _service.getMenuProgram(r.hMenuCd, r.menuCd, r.subMenuCd, r.pgmId ?? '');
      if (mounted) {
        setState(() => _isLoading = false);
        _openForm(fetchedProgram, isView);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MNToast.show(context, e.toString(), isError: true);
        _go(_V.list);
      }
    }
  }

  void _openForm([MenuProgramModel? r, bool isView = false]) {
    _sel = r;
    _isEdit = r != null;
    _isView = isView;
    _hMenuCdError = _menuCdError = _subMenuCdError = _pgmIdError = _menuOrderError = _programPathError = _logoError = null;
    
    if (r != null) {
      _isEdit = true;
      String currentHMenuText = r.hMenuCd.toString();
      final hMatch = _headMenus.where((h) => h.hMenuCd == r.hMenuCd).firstOrNull;
      if (hMatch != null) currentHMenuText = '${hMatch.hMenuCd} - ${hMatch.hMenuDesc}';

      String currentMenuText = r.menuCd.toString();
      final mMatch = _menus.where((m) => m.hMenuCd == r.hMenuCd && m.menuCd == r.menuCd).firstOrNull;
      if (mMatch != null) currentMenuText = '${mMatch.menuCd} - ${mMatch.menuDescn}';

      String currentSubMenuText = r.subMenuCd.toString();
      final sMatch = _subMenus.where((s) => s.hMenuCd == r.hMenuCd && s.menuCd == r.menuCd && s.subMenuCd == r.subMenuCd).firstOrNull;
      if (sMatch != null) currentSubMenuText = '${sMatch.subMenuCd} - ${sMatch.menuDescn}';

      String currentPgmText = r.pgmId ?? '';
      final pMatch = _programs.where((p) => p.id.toString() == r.pgmId).firstOrNull;
      if (pMatch != null) currentPgmText = '${pMatch.id} - ${pMatch.programName}';

      _hMenuCdCtrl.text = currentHMenuText;
      _menuCdCtrl.text = currentMenuText;
      _subMenuCdCtrl.text = currentSubMenuText;
      _pgmIdCtrl.text = currentPgmText;
      _menuOrderCtrl.text = r.menuOrder?.toString() ?? '';
      _programPathCtrl.text = r.programPath ?? '';
      _status = r.status;
      _menuLogoCtrl.text = r.menuLogo;
    } else {
      _isEdit = false;
      _hMenuCdCtrl.clear();
      _menuCdCtrl.clear();
      _subMenuCdCtrl.clear();
      _pgmIdCtrl.clear();
      _menuOrderCtrl.clear();
      _programPathCtrl.clear();
      _status = false;
      _menuLogoCtrl.clear();
    }
    _go(_V.form);
  }

  void _closeForm() {
    _go(_V.list);
  }

  Future<void> _save() async {
    _hMenuCdError = _hMenuCdCtrl.text.trim().isEmpty ? 'Head Menu Code is required' : null;
    _menuCdError = _menuCdCtrl.text.trim().isEmpty ? 'Menu Code is required' : null;
    _subMenuCdError = _subMenuCdCtrl.text.trim().isEmpty ? 'Sub Menu Code is required' : null;
    _pgmIdError = _pgmIdCtrl.text.trim().isEmpty ? 'Program ID is required' : null;
    
    if (_menuOrderCtrl.text.trim().isEmpty) {
      _menuOrderError = 'Menu Order is required';
    } else {
      _validateMenuOrder(); // this will set _menuOrderError if duplicate, else null
    }
    
    _programPathError = _programPathCtrl.text.trim().isEmpty ? 'Program Path is required' : null;
    _logoError = _menuLogoCtrl.text.trim().isEmpty ? 'Menu Icon is required' : null;
    
    if (_hMenuCdError != null || _menuCdError != null || _subMenuCdError != null || _pgmIdError != null || _menuOrderError != null || _programPathError != null || _logoError != null) {
      setState(() {});
      return;
    }
    
    final pgmIdParts = _pgmIdCtrl.text.split(' - ');
    final pgmIdValue = pgmIdParts.first;
    final pgmDescValue = pgmIdParts.length > 1 ? pgmIdParts.sublist(1).join(' - ') : '';

    final model = MenuProgramModel(
      hMenuCd: int.parse(_hMenuCdCtrl.text.split(' - ').first),
      menuCd: int.parse(_menuCdCtrl.text.split(' - ').first),
      subMenuCd: int.parse(_subMenuCdCtrl.text.split(' - ').first),
      pgmId: pgmIdValue,
      description: pgmDescValue,
      menuOrder: int.tryParse(_menuOrderCtrl.text.trim()),
      programPath: _programPathCtrl.text.trim(),
      menuLogo: _menuLogoCtrl.text.trim(),
      status: _status,
      userName: AuthService().currentUser?.userName ?? AuthService().currentUser?.name,
      auser: _sel?.auser,
      adate: _sel?.adate,
      euser: _sel?.euser,
      edate: _sel?.edate,
      cuser: _sel?.cuser,
      cdate: _sel?.cdate,
    );


    
    try {
      if (_isEdit) {
        await _service.updateMenuProgram(model);
      } else {
        await _service.createMenuProgram(model);
      }
      MNToast.show(context, 'Saved successfully');
      widget.onMenuModified?.call();
      _closeForm();
      _loadData();
    } catch (e) {
      MNToast.show(context, e.toString(), isError: true);
    }
  }
  
  void _confirmDelete(MenuProgramModel r) {
    _programToDelete = r;
    _go(_V.delete);
  }

  Future<void> _delete() async {
    if (_programToDelete == null) return;
    try {
      await _service.deleteMenuProgram(
        _programToDelete!.hMenuCd, 
        _programToDelete!.menuCd, 
        _programToDelete!.subMenuCd, 
        _programToDelete!.pgmId ?? ''
      );
      MNToast.show(context, 'Deleted successfully');
      widget.onMenuModified?.call();
      _go(_V.list);
      _loadData();
    } catch (e) {
      MNToast.show(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Padding(padding: EdgeInsets.symmetric(vertical: 48), child: Center(child: CircularProgressIndicator()));
    if (_view == _V.form) return _buildForm();
    if (_view == _V.delete) return _buildDelete();
    
    final filteredData = _data.where((e) {
      if (_filterHMenuCd != null && e.hMenuCd.toString() != _filterHMenuCd) return false;
      if (_filterMenuCd != null && e.menuCd.toString() != _filterMenuCd) return false;
      if (_filterSubMenuCd != null && e.subMenuCd.toString() != _filterSubMenuCd) return false;
      if (_search.isNotEmpty && !(e.description.toLowerCase().contains(_search) || 
          (e.pgmId?.toLowerCase().contains(_search) ?? false) ||
          e.subMenuCd.toString().contains(_search) ||
          e.menuCd.toString().contains(_search) ||
          e.hMenuCd.toString().contains(_search))) return false;
      return true;
    }).toList();
    final int totalPages = (filteredData.isEmpty ? 1 : (filteredData.length / _itemsPerPage).ceil());
    final currentData = filteredData.skip(_currentPage * _itemsPerPage).take(_itemsPerPage).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          SearchBox(
            controller: _searchCtrl,
            width: 220,
            hintText: 'Search programs',
            onChanged: (v) => setState(() { _search = v.toLowerCase(); _currentPage = 0; }),
          ),
          const SizedBox(width: 8),
          FilterDropdown(
            label: 'Head Menu',
            value: _filterHMenuCd,
            items: _headMenus.map((e) => FilterDropdownItem(id: e.hMenuCd.toString(), label: e.hMenuDesc)).toList(),
            onChanged: (v) => setState(() { _filterHMenuCd = v; _filterMenuCd = null; _filterSubMenuCd = null; _currentPage = 0; }),
            allText: 'All Head Menus',
            hintText: 'Search head menu...',
          ),
          const SizedBox(width: 8),
          FilterDropdown(
            label: 'Menu',
            value: _filterMenuCd,
            items: _menus
                .where((e) => _filterHMenuCd == null || e.hMenuCd.toString() == _filterHMenuCd)
                .map((e) => FilterDropdownItem(id: e.menuCd.toString(), label: e.menuDescn))
                .fold<Map<String, FilterDropdownItem>>({}, (map, item) => map..putIfAbsent(item.id, () => item))
                .values.toList(),
            onChanged: (v) => setState(() { _filterMenuCd = v; _filterSubMenuCd = null; _currentPage = 0; }),
            allText: 'All Menus',
            hintText: 'Search menu...',
          ),
          const SizedBox(width: 8),
          FilterDropdown(
            label: 'Sub Menu',
            value: _filterSubMenuCd,
            items: _subMenus
                .where((e) => (_filterHMenuCd == null || e.hMenuCd.toString() == _filterHMenuCd) && (_filterMenuCd == null || e.menuCd.toString() == _filterMenuCd))
                .map((e) => FilterDropdownItem(id: e.subMenuCd.toString(), label: e.menuDescn))
                .fold<Map<String, FilterDropdownItem>>({}, (map, item) => map..putIfAbsent(item.id, () => item))
                .values.toList(),
            onChanged: (v) => setState(() { _filterSubMenuCd = v; _currentPage = 0; }),
            allText: 'All Sub Menus',
            hintText: 'Search sub menu...',
          ),
          const SizedBox(width: 16),
          if (widget.accessPrivileges?.canCreate ?? true)
            ActionButton('New Program Mapping', bg: kP, fg: Colors.white, border: kP, icon: Icons.add_rounded, onTap: () => _openForm()),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
          clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth < 1100 ? 1100.0 : constraints.maxWidth;
              final cols = [w * 0.15, w * 0.15, w * 0.15, w * 0.15, w * 0.10, w * 0.15, w * 0.15];
              
              Widget rowWidget(List<Widget> cells, List<double> widths, {bool isHeader = false, bool isEven = false, bool isHovered = false}) {
                Color rowBg;
                if (isHeader) rowBg = kP;
                else if (isHovered) rowBg = kPL;
                else if (isEven) rowBg = const Color(0xFFF0F5FD);
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
              
              Widget _statusBadge(bool active) => IntrinsicWidth(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: active ? kGL : kRL, borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? kG : kR, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? kG : kR)),
                  ]),
                ),
              );

              Widget _rowBtn(IconData icon, Color color, VoidCallback onTap) => MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: kBorder)),
                    child: Icon(icon, size: 14, color: color),
                  ),
                ),
              );

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: w,
                  child: Column(children: [
                rowWidget([
                  headerCell('HEAD MENU'), headerCell('MENU'), headerCell('SUBMENU'), headerCell('PROGRAM'),
                  headerCell('ORDER'), headerCell('STATUS'), headerCell('ACTIONS'),
                ], cols, isHeader: true),
                Column(
                  children: currentData.asMap().entries.map((e) {
                    final idx = e.key;
                    final r = e.value;
                    final isEven = idx % 2 == 1;
                    
                    final hMatch = _headMenus.where((h) => h.hMenuCd == r.hMenuCd).firstOrNull;
                    final mMatch = _menus.where((m) => m.hMenuCd == r.hMenuCd && m.menuCd == r.menuCd).firstOrNull;
                    final sMatch = _subMenus.where((s) => s.hMenuCd == r.hMenuCd && s.menuCd == r.menuCd && s.subMenuCd == r.subMenuCd).firstOrNull;
                    
                    final hText = hMatch != null ? '${r.hMenuCd} - ${hMatch.hMenuDesc}' : '${r.hMenuCd}';
                    final mText = mMatch != null ? '${r.menuCd} - ${mMatch.menuDescn}' : '${r.menuCd}';
                    final sText = sMatch != null ? '${r.subMenuCd} - ${sMatch.menuDescn}' : '${r.subMenuCd} - Not Applicable';
                    final pText = (r.pgmId != null && r.pgmId!.isNotEmpty) ? '${r.pgmId} - ${r.description}' : r.description;
                    
                    return StatefulBuilder(builder: (_, rss) {
                      bool hovered = false;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => rss(() => hovered = true),
                        onExit: (_) => rss(() => hovered = false),
                        child: rowWidget([
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(hText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(mText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(sText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(pText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: kP), textAlign: TextAlign.center))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(r.menuOrder?.toString() ?? '-', style: const TextStyle(fontSize: 12.5, color: kText)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: _statusBadge(r.status))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (widget.accessPrivileges?.canView ?? true) ...[
                                _rowBtn(Icons.visibility_outlined, const Color(0xFF475569), () => _fetchAndOpenForm(r, isView: true)),
                                const SizedBox(width: 4),
                              ],
                              if (widget.accessPrivileges?.canEdit ?? true) ...[
                                _rowBtn(Icons.edit_outlined, kP, () => _fetchAndOpenForm(r)),
                                const SizedBox(width: 4),
                              ],
                              if (widget.accessPrivileges?.canDelete ?? true)
                                _rowBtn(Icons.delete_outline_rounded, kR, () => _confirmDelete(r)),
                            ]))),
                        ], cols, isEven: isEven, isHovered: hovered),
                      );
                    });
                  }).toList(),
                ),
                if (filteredData.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${_currentPage * _itemsPerPage + 1}-${(_currentPage + 1) * _itemsPerPage > filteredData.length ? filteredData.length : (_currentPage + 1) * _itemsPerPage} of ${filteredData.length} records',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        Row(
                          children: [
                            MouseRegion(
                              cursor: _currentPage > 0 ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                              child: GestureDetector(
                                onTap: _currentPage > 0 ? () { setState(() => _currentPage--); Scrollable.maybeOf(context)?.position.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); } : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Text('‹ Prev', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _currentPage > 0 ? const Color(0xFF64748B) : const Color(0xFFCBD5E1))),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            MouseRegion(
                              cursor: _currentPage < totalPages - 1 ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                              child: GestureDetector(
                                onTap: _currentPage < totalPages - 1 ? () { setState(() => _currentPage++); Scrollable.maybeOf(context)?.position.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); } : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: kBorder),
                                  ),
                                  child: Text('Next ›', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _currentPage < totalPages - 1 ? const Color(0xFF64748B) : const Color(0xFFCBD5E1))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ]),
                ),
              );
            }),
          ),
      ],
    ),
  );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: const Text(
                    'Program Mapping',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.3),
                  ),
                ),
                if (_isEdit || _isView) ...[
                  ActionButton(
                    'Audit Details',
                    bg: Colors.white,
                    fg: kP,
                    border: kP,
                    icon: Icons.history_rounded,
                    onTap: () => AuditDetailsDialog.show(
                      context,
                      euser: _sel?.euser,
                      edate: _sel?.edate,
                      cuser: _sel?.cuser,
                      cdate: _sel?.cdate,
                      auser: _sel?.auser,
                      adate: _sel?.adate,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ActionButton('Back', bg: kP, fg: Colors.white, border: kP, icon: Icons.arrow_back_rounded, onTap: _closeForm),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: kBorder))),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_isView ? (_sel?.description ?? 'Mapping Details') : 'Mapping Details', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                      const SizedBox(height: 2),
                      if (!_isView) Text('Fill all required fields marked with *', style: const TextStyle(fontSize: 11, color: kMuted)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: _isView ? const Color(0xFFF1F5F9) : (_isEdit ? const Color(0xFFFFF7ED) : kPL), borderRadius: BorderRadius.circular(20), border: Border.all(color: _isView ? const Color(0xFFCBD5E1) : (_isEdit ? const Color(0xFFFED7AA) : kPB))),
                      child: Text(_isView ? 'VIEW MODE' : (_isEdit ? 'EDIT MODE' : 'NEW RECORD'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _isView ? const Color(0xFF475569) : (_isEdit ? const Color(0xFFEA580C) : kP))),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 28,
                    crossAxisSpacing: 18,
                    childAspectRatio: 2.6,
                    children: [
                      DropdownField(
                        label: 'Head Menu', 
                        value: _hMenuCdCtrl.text.isEmpty ? null : _hMenuCdCtrl.text,
                        icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, 
                        isRequired: true, 
                        readOnly: _isEdit || _isView, 
                        splitCodeDesc: true,
                        errorText: _hMenuCdError,
                        items: _headMenus.map((h) => '${h.hMenuCd} - ${h.hMenuDesc}').toList(),
                        onChanged: (v) {
                          _hMenuCdCtrl.text = v ?? '';
                          _menuCdCtrl.clear();
                          _subMenuCdCtrl.clear();
                          _pgmIdCtrl.clear();
                          setState(() {});
                        },
                      ),
                      DropdownField(
                        label: 'Menu', 
                        value: _menuCdCtrl.text.isEmpty ? null : _menuCdCtrl.text,
                        icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, 
                        isRequired: true, 
                        readOnly: _isEdit || _isView, 
                        isLocked: _hMenuCdCtrl.text.isEmpty,
                        splitCodeDesc: true,
                        errorText: _menuCdError,
                        items: _hMenuCdCtrl.text.isEmpty ? [] : _menus
                          .where((m) => m.hMenuCd.toString() == _hMenuCdCtrl.text.split(' - ').first && m.subMenuReq == true)
                          .map((m) => '${m.menuCd} - ${m.menuDescn}')
                          .toList(),
                        onChanged: (v) {
                          _menuCdCtrl.text = v ?? '';
                          _subMenuCdCtrl.clear();
                          _pgmIdCtrl.clear();
                          setState(() {});
                        },
                      ),
                      Builder(
                        builder: (context) {
                          final subItems = (_hMenuCdCtrl.text.isEmpty || _menuCdCtrl.text.isEmpty) ? <String>[] : _subMenus
                            .where((s) => s.hMenuCd.toString() == _hMenuCdCtrl.text.split(' - ').first && s.menuCd.toString() == _menuCdCtrl.text.split(' - ').first)
                            .map((s) => '${s.subMenuCd} - ${s.menuDescn}')
                            .toList();
                            
                          if (subItems.isEmpty && _menuCdCtrl.text.isNotEmpty) {
                            subItems.add('0 - Not Applicable');
                            if (_subMenuCdCtrl.text != '0 - Not Applicable') {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && _subMenuCdCtrl.text.isEmpty) {
                                  setState(() => _subMenuCdCtrl.text = '0 - Not Applicable');
                                }
                              });
                            }
                          }

                          return DropdownField(
                            label: 'Submenu', 
                            value: _subMenuCdCtrl.text.isEmpty ? null : _subMenuCdCtrl.text,
                            icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, 
                            isRequired: true, 
                            readOnly: _isEdit || _isView, 
                            isLocked: _menuCdCtrl.text.isEmpty,
                            splitCodeDesc: true,
                            errorText: _subMenuCdError,
                            items: subItems,
                            onChanged: (v) {
                              _subMenuCdCtrl.text = v ?? '';
                              _pgmIdCtrl.clear();
                              setState(() {});
                            },
                          );
                        }
                      ),
                      DropdownField(
                        label: 'Program', 
                        value: _pgmIdCtrl.text.isEmpty ? null : _pgmIdCtrl.text,
                        icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.integration_instructions, 
                        isRequired: true, 
                        readOnly: _isEdit || _isView, 
                        isLocked: _subMenuCdCtrl.text.isEmpty,
                        showSearch: true,
                        splitCodeDesc: true,
                        errorText: _pgmIdError,
                        items: _programs.map((p) => '${p.id} - ${p.programName}').toList(),
                        onChanged: (v) {
                          _pgmIdCtrl.text = v ?? '';
                          setState(() {});
                        },
                      ),
                      FloatingLabelField(label: 'Menu Order', controller: _menuOrderCtrl, icon: Icons.sort, isNumber: true, isRequired: true, readOnly: _isView, errorText: _menuOrderError, focusNode: _menuOrderFocus),
                      FloatingLabelField(label: 'Program Path', controller: _programPathCtrl, icon: Icons.link, isRequired: true, readOnly: _isView, errorText: _programPathError),
                      ToggleField(label: 'Status', isActive: _status, isRequired: true, readOnly: _isView, onChanged: (v) => _isView ? null : setState(() => _status = v)),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 22), child: Divider(height: 1, color: kBorder)),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Menu Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kP)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 300,
                          child: FloatingLabelField(
                            label: 'Remarks', 
                            controller: _menuLogoCtrl, 
                            icon: Icons.image_rounded, 
                            isRequired: true, 
                            errorText: _logoError, 
                            readOnly: _isView,
                            hintText: 'e.g., Icons.home or fas fa-user',
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ActionButton(_isView ? 'Back' : 'Cancel', bg: _isView ? kP : Colors.white, fg: _isView ? Colors.white : kP, border: kP, icon: _isView ? Icons.arrow_back_rounded : Icons.close_rounded, onTap: _closeForm),
                      if (!_isView) ...[
                        const SizedBox(width: 12),
                        ActionButton(_isEdit ? 'Save Changes' : 'Create', bg: kP, fg: Colors.white, border: kP, onTap: _save),
                      ],
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDelete() {
    if (_programToDelete == null) return const SizedBox();
    final r = _programToDelete!;
    return DeleteConfirmationWidget(
      title: 'Delete Program Mapping',
      recordDetails: {
        'Sub Menu Code:': r.subMenuCd.toString(),
        'Program ID:': r.pgmId ?? '-',
        'Description:': r.description,
      },
      impactDetails: const [
        'Only this specific Program Mapping will be deleted. No other menus or submenus will be affected.',
      ],
      onCancel: () => _go(_V.list),
      onConfirm: _delete,
    );
  }
}
