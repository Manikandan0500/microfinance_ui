import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../models/access_privileges.dart';
import '../../models/menu_models.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../widgets/audit_details_dialog.dart';
import 'menu_master_widgets.dart';

enum _V { list, form, delete }

class SubMenuTab extends StatefulWidget {
  final ValueChanged<bool>? onFormChanged;
  final ValueChanged<int>? onTotalChanged;
  final void Function(int active, int inactive)? onStatusChanged;
  final VoidCallback? onMenuModified;
  final AccessPrivileges? accessPrivileges;
  final bool isActive;
  const SubMenuTab({super.key, this.onFormChanged, this.onTotalChanged, this.onStatusChanged, this.onMenuModified, this.isActive = false, this.accessPrivileges});
  @override
  State<SubMenuTab> createState() => _SubMenuTabState();
}

class _SubMenuTabState extends State<SubMenuTab> {
  final MenuMasterService _service = MenuMasterService();
  bool _isLoading = true;
  bool _hasLoaded = false;
  List<SubMenuModel> _data = [];
  List<HeadMenuModel> _headMenus = [];
  List<MenuModel> _menus = [];
  
  _V _view = _V.list;
  bool _isEdit = false;
  bool _isView = false;
  SubMenuModel? _sel;
  SubMenuModel? _subMenuToDelete;
  

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  
  String? _filterHMenuCd;
  String? _filterMenuCd;
  
  final _hMenuCdCtrl = TextEditingController();
  final _menuCdCtrl = TextEditingController();
  final _subMenuCdCtrl = TextEditingController();
  final _subMenuPgmIdCtrl = TextEditingController();
  final _menuDescnCtrl = TextEditingController();
  final _menuOrderCtrl = TextEditingController();
  final FocusNode _menuOrderFocus = FocusNode();
  final _programPathCtrl = TextEditingController();
  final _menuLogoCtrl = TextEditingController();
  
  String? _hMenuCdError;
  String? _menuCdError;
  String? _subMenuCdError;
  String? _subMenuPgmIdError;
  String? _menuDescnError;
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
    _subMenuPgmIdCtrl.addListener(() { if (_subMenuPgmIdError != null) setState(() => _subMenuPgmIdError = null); });
    _menuDescnCtrl.addListener(() { if (_menuDescnError != null) setState(() => _menuDescnError = null); });
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
  void didUpdateWidget(SubMenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        _loadData();
      }
      if (_view != _V.list) {
        _go(_V.list);
      }
      if (_search.isNotEmpty || _currentPage != 0 || _searchCtrl.text.isNotEmpty || _filterHMenuCd != null || _filterMenuCd != null) {
        setState(() {
          _search = '';
          _searchCtrl.clear();
          _currentPage = 0;
          _filterHMenuCd = null;
          _filterMenuCd = null;
        });
      }
      widget.onTotalChanged?.call(_data.length);
      int active = _data.length;
      widget.onStatusChanged?.call(active, 0);
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
    if (hMenuCd == null || menuCd == null) return;

    final currentSubMenuCd = _isEdit ? _sel?.subMenuCd : null;

    bool isDuplicate = _data.any((item) =>
        item.hMenuCd == hMenuCd &&
        item.menuCd == menuCd &&
        item.menuOrder == enteredOrder &&
        (currentSubMenuCd == null || item.subMenuCd != currentSubMenuCd));

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
    _subMenuPgmIdCtrl.dispose();
    _menuDescnCtrl.dispose();
    _menuOrderCtrl.dispose();
    _programPathCtrl.dispose();
    _menuLogoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getSubMenus();
      final hmRes = await _service.getHeadMenus();
      final mRes = await _service.getMenus();
      if (mounted) {
        setState(() { 
          _data = res; _headMenus = hmRes; _menus = mRes; _isLoading = false; _currentPage = 0; 
          _filterHMenuCd = null;
          _filterMenuCd = null;
        });
        if (widget.isActive) {
          widget.onTotalChanged?.call(_data.length);
          int active = _data.length;
          widget.onStatusChanged?.call(active, 0);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MNToast.show(context, e.toString(), isError: true);
      }
    }
  }

  void _go(_V view) {
    setState(() => _view = view);
    widget.onFormChanged?.call(view != _V.list);
  }

  Future<void> _fetchAndOpenForm(SubMenuModel r, {bool isView = false}) async {
    _go(_V.form);
    setState(() => _isLoading = true);
    try {
      final fetchedSubMenu = await _service.getSubMenu(r.hMenuCd, r.menuCd, r.subMenuCd);
      if (mounted) {
        setState(() => _isLoading = false);
        _openForm(fetchedSubMenu, isView);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MNToast.show(context, e.toString(), isError: true);
        _go(_V.list);
      }
    }
  }

  void _openForm([SubMenuModel? r, bool isView = false]) {
    _sel = r;
    _isEdit = r != null;
    _isView = isView;
    _hMenuCdError = _menuCdError = _subMenuCdError = _subMenuPgmIdError = _menuDescnError = _menuOrderError = _programPathError = _logoError = null;
    if (r != null) {
      _isEdit = true;
      String currentHMenuText = r.hMenuCd.toString();
      final hMatch = _headMenus.where((h) => h.hMenuCd == r.hMenuCd).firstOrNull;
      if (hMatch != null) {
        currentHMenuText = '${hMatch.hMenuCd} - ${hMatch.hMenuDesc}';
      }
      
      String currentMenuText = r.menuCd.toString();
      final mMatch = _menus.where((m) => m.hMenuCd == r.hMenuCd && m.menuCd == r.menuCd).firstOrNull;
      if (mMatch != null) {
        currentMenuText = '${mMatch.menuCd} - ${mMatch.menuDescn}';
      }

      _hMenuCdCtrl.text = currentHMenuText;
      _menuCdCtrl.text = currentMenuText;
      _subMenuCdCtrl.text = r.subMenuCd.toString();
      _subMenuPgmIdCtrl.text = r.subMenuPgmId ?? '';
      _menuDescnCtrl.text = r.menuDescn;
      _menuOrderCtrl.text = r.menuOrder?.toString() ?? '';
      _programPathCtrl.text = r.programPath ?? '';
      _menuLogoCtrl.text = r.menuLogo;
    } else {
      _isEdit = false;
      _hMenuCdCtrl.clear();
      _menuCdCtrl.clear();
      _subMenuCdCtrl.clear();
      _subMenuPgmIdCtrl.clear();
      _menuDescnCtrl.clear();
      _menuOrderCtrl.clear();
      _programPathCtrl.clear();
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
    _subMenuPgmIdError = _subMenuPgmIdCtrl.text.trim().isEmpty ? 'Program ID is required' : null;
    _menuDescnError = _menuDescnCtrl.text.trim().isEmpty ? 'Description is required' : null;
    
    if (_menuOrderCtrl.text.trim().isEmpty) {
      _menuOrderError = 'Menu Order is required';
    } else {
      _validateMenuOrder(); // this will set _menuOrderError if duplicate, else null
    }
    
    _programPathError = _programPathCtrl.text.trim().isEmpty ? 'Program Path is required' : null;
    _logoError = _menuLogoCtrl.text.trim().isEmpty ? 'Menu Icon is required' : null;
    
    if (_hMenuCdError != null || _menuCdError != null || _subMenuCdError != null || _subMenuPgmIdError != null || _menuDescnError != null || _menuOrderError != null || _programPathError != null || _logoError != null) {
      setState(() {});
      return;
    }
    
    int parsedHMenuCd = 0;
    final hMenuVal = _hMenuCdCtrl.text.trim();
    if (hMenuVal.contains('-')) {
      parsedHMenuCd = int.tryParse(hMenuVal.split('-').first.trim()) ?? 0;
    } else {
      parsedHMenuCd = int.tryParse(hMenuVal) ?? 0;
    }

    int parsedMenuCd = 0;
    final menuVal = _menuCdCtrl.text.trim();
    if (menuVal.contains('-')) {
      parsedMenuCd = int.tryParse(menuVal.split('-').first.trim()) ?? 0;
    } else {
      parsedMenuCd = int.tryParse(menuVal) ?? 0;
    }

    final model = SubMenuModel(
      hMenuCd: parsedHMenuCd,
      menuCd: parsedMenuCd,
      subMenuCd: int.parse(_subMenuCdCtrl.text.trim()),
      menuDescn: _menuDescnCtrl.text.trim(),
      menuOrder: int.tryParse(_menuOrderCtrl.text.trim()),
      subMenuPgmId: _subMenuPgmIdCtrl.text.trim(),
      programPath: _programPathCtrl.text.trim(),
      menuLogo: _menuLogoCtrl.text.trim(),
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
        await _service.updateSubMenu(model);
      } else {
        await _service.createSubMenu(model);
      }
      MNToast.show(context, 'Saved successfully');
      widget.onMenuModified?.call();
      _closeForm();
      _loadData();
    } catch (e) {
      MNToast.show(context, e.toString(), isError: true);
    }
  }
  
  void _confirmDelete(SubMenuModel r) {
    _subMenuToDelete = r;
    _go(_V.delete);
  }

  Future<void> _delete() async {
    if (_subMenuToDelete == null) return;
    try {
      await _service.deleteSubMenu(_subMenuToDelete!.hMenuCd, _subMenuToDelete!.menuCd, _subMenuToDelete!.subMenuCd);
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
      if (_search.isNotEmpty && !(e.menuDescn.toLowerCase().contains(_search) || e.subMenuCd.toString().contains(_search) || e.menuCd.toString().contains(_search) || e.hMenuCd.toString().contains(_search))) return false;
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
            hintText: 'Search sub menus',
            onChanged: (v) => setState(() { _search = v.toLowerCase(); _currentPage = 0; }),
          ),
          const SizedBox(width: 8),
          FilterDropdown(
            label: 'Head Menu',
            value: _filterHMenuCd,
            items: _headMenus.map((e) => FilterDropdownItem(id: e.hMenuCd.toString(), label: e.hMenuDesc)).toList(),
            onChanged: (v) => setState(() { _filterHMenuCd = v; _filterMenuCd = null; _currentPage = 0; }),
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
            onChanged: (v) => setState(() { _filterMenuCd = v; _currentPage = 0; }),
            allText: 'All Menus',
            hintText: 'Search menu...',
          ),
          const SizedBox(width: 16),
          if (widget.accessPrivileges?.canCreate ?? true)
            ActionButton('New Submenu', bg: kP, fg: Colors.white, border: kP, icon: Icons.add_rounded, onTap: () => _openForm()),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
          clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
              final cols = [w * 0.25, w * 0.25, w * 0.25, w * 0.10, w * 0.15];
              
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
                  headerCell('HEAD MENU'), headerCell('MENU'), headerCell('SUBMENU'), headerCell('ORDER'),
                  headerCell('ACTIONS'),
                ], cols, isHeader: true),
                Column(
                  children: currentData.asMap().entries.map((e) {
                    final idx = e.key;
                    final r = e.value;
                    final isEven = idx % 2 == 1;
                    final hMatch = _headMenus.where((h) => h.hMenuCd == r.hMenuCd).firstOrNull;
                    final mMatch = _menus.where((m) => m.hMenuCd == r.hMenuCd && m.menuCd == r.menuCd).firstOrNull;
                    final hText = hMatch != null ? '${r.hMenuCd} - ${hMatch.hMenuDesc}' : '${r.hMenuCd}';
                    final mText = mMatch != null ? '${r.menuCd} - ${mMatch.menuDescn}' : '${r.menuCd}';
                    final sText = '${r.subMenuCd} - ${r.menuDescn}';
                    return StatefulBuilder(builder: (_, rss) {
                      bool hovered = false;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => rss(() => hovered = true),
                        onExit: (_) => rss(() => hovered = false),
                        child: rowWidget([
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(hText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(mText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(sText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(r.menuOrder?.toString() ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText)))),
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
                    'Submenu',
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
                      Text(_isView ? (_sel?.menuDescn ?? 'Submenu Details') : 'Submenu Details', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
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
                    childAspectRatio: 3.4,
                    children: [
                      DropdownField(
                        label: 'Head Menu', 
                        value: _hMenuCdCtrl.text.isEmpty ? null : _hMenuCdCtrl.text,
                        items: _headMenus.map((h) => '${h.hMenuCd} - ${h.hMenuDesc}').toList(),
                        splitCodeDesc: true,
                        onChanged: (v) {
                          if (v != null && !_isView) {
                            setState(() {
                              _hMenuCdCtrl.text = v;
                              _menuCdCtrl.clear(); // Reset menu when head menu changes
                            });
                          }
                        },
                        icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, 
                        isRequired: true, 
                        readOnly: _isEdit || _isView, 
                        errorText: _hMenuCdError
                      ),
                      DropdownField(
                        label: 'Menu', 
                        value: _menuCdCtrl.text.isEmpty ? null : _menuCdCtrl.text,
                        isLocked: _hMenuCdCtrl.text.isEmpty,
                        items: _menus
                            .where((m) => m.subMenuReq == true && m.hMenuCd.toString() == (_hMenuCdCtrl.text.contains('-') ? _hMenuCdCtrl.text.split('-').first.trim() : _hMenuCdCtrl.text.trim()))
                            .map((m) => '${m.menuCd} - ${m.menuDescn}')
                            .toList(),
                        splitCodeDesc: true,
                        onChanged: (v) {
                          if (v != null && !_isView) {
                            setState(() => _menuCdCtrl.text = v);
                          }
                        },
                        icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, 
                        isRequired: true, 
                        readOnly: _isEdit || _isView, 
                        errorText: _menuCdError
                      ),
                      FloatingLabelField(label: 'Submenu Code', controller: _subMenuCdCtrl, icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, isRequired: true, isNumber: true, readOnly: _isEdit || _isView, errorText: _subMenuCdError),
                      FloatingLabelField(label: 'Description', controller: _menuDescnCtrl, icon: Icons.description, isRequired: true, readOnly: _isView, errorText: _menuDescnError),
                      FloatingLabelField(label: 'Menu Order', controller: _menuOrderCtrl, icon: Icons.sort, isNumber: true, isRequired: true, readOnly: _isView, errorText: _menuOrderError, focusNode: _menuOrderFocus),
                      FloatingLabelField(label: 'Submenu Program ID', controller: _subMenuPgmIdCtrl, icon: Icons.fingerprint, isRequired: true, readOnly: _isView, errorText: _subMenuPgmIdError),
                      FloatingLabelField(label: 'Program Path', controller: _programPathCtrl, icon: Icons.link, isRequired: true, readOnly: _isView, errorText: _programPathError),
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
    if (_subMenuToDelete == null) return const SizedBox();
    final r = _subMenuToDelete!;
    return DeleteConfirmationWidget(
      title: 'Delete Sub Menu',
      recordDetails: {
        'Sub Menu Code:': r.subMenuCd.toString(),
        'Description:': r.menuDescn,
      },
      impactDetails: const [
        'Deleting this Submenu will automatically delete all of its Program Mappings.',
      ],
      onCancel: () => _go(_V.list),
      onConfirm: _delete,
    );
  }
}
