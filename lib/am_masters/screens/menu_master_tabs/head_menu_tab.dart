import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/menu_models.dart';
import '../../models/access_privileges.dart';
import '../../services/menu_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/audit_details_dialog.dart';
import 'menu_master_widgets.dart';

enum _V { list, form, delete }

class HeadMenuTab extends StatefulWidget {
  final ValueChanged<bool>? onFormChanged;
  final ValueChanged<int>? onTotalChanged;
  final void Function(int active, int inactive)? onStatusChanged;
  final VoidCallback? onMenuModified;
  final bool isActive;
  final AccessPrivileges? accessPrivileges;
  const HeadMenuTab({super.key, this.onFormChanged, this.onTotalChanged, this.onStatusChanged, this.onMenuModified, this.isActive = false, this.accessPrivileges});
  @override
  State<HeadMenuTab> createState() => _HeadMenuTabState();
}

class _HeadMenuTabState extends State<HeadMenuTab> {
  final MenuMasterService _service = MenuMasterService();
  bool _isLoading = true;
  bool _hasLoaded = false;
  List<HeadMenuModel> _data = [];
  int _totalRecords = 0;
  
  // Form View State
  _V _view = _V.list;
  bool _isEdit = false;
  bool _isView = false;
  HeadMenuModel? _sel;
  

  int _currentPage = 0;
  final int _itemsPerPage = 10;
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  
  final _hMenuCdCtrl = TextEditingController();
  final FocusNode _hMenuCdFocus = FocusNode();
  final _hMenuDescCtrl = TextEditingController();
  final _hPgmIdCtrl = TextEditingController();
  final _programPathCtrl = TextEditingController();
  final _menuLogoCtrl = TextEditingController();
  final _menuLocationCtrl = TextEditingController();
  bool _menuStatus = true;
  
  String? _hMenuCdError;
  String? _hMenuDescError;
  String? _hPgmIdError;
  String? _programPathError;
  String? _menuLocationError;
  
  String? _logoError;

  String? _filterHMenuCd;

  @override
  void initState() {
    super.initState();
    _hMenuCdCtrl.addListener(() { if (_hMenuCdError != null) setState(() => _hMenuCdError = null); });
    _hMenuDescCtrl.addListener(() { if (_hMenuDescError != null) setState(() => _hMenuDescError = null); });
    _hPgmIdCtrl.addListener(() { if (_hPgmIdError != null) setState(() => _hPgmIdError = null); });
    _programPathCtrl.addListener(() { if (_programPathError != null) setState(() => _programPathError = null); });
    _menuLocationCtrl.addListener(() { if (_menuLocationError != null) setState(() => _menuLocationError = null); });
    _menuLogoCtrl.addListener(() { if (_logoError != null) setState(() => _logoError = null); });
    _hMenuCdFocus.addListener(_onHMenuCdFocusChange);
    if (widget.isActive) {
      _hasLoaded = true;
      _loadData();
    }
  }

  @override
  void didUpdateWidget(HeadMenuTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      if (!_hasLoaded) {
        _hasLoaded = true;
        _loadData();
      }
      if (_view != _V.list) {
        _go(_V.list);
      }
      if (_search.isNotEmpty || _currentPage != 0 || _searchCtrl.text.isNotEmpty || _filterHMenuCd != null) {
        setState(() {
          _search = '';
          _searchCtrl.clear();
          _currentPage = 0;
          _filterHMenuCd = null;
        });
      }
      widget.onTotalChanged?.call(_data.length);
      int active = _data.where((d) => d.menuStatus).length;
      widget.onStatusChanged?.call(active, _data.length - active);
    }
  }

  void _onHMenuCdFocusChange() {
    if (!_hMenuCdFocus.hasFocus) {
      _validateHMenuCd();
    }
  }

  void _validateHMenuCd() {
    if (_hMenuCdCtrl.text.trim().isEmpty) return;
    int? enteredCd = int.tryParse(_hMenuCdCtrl.text.trim());
    if (enteredCd == null) return;

    if (_isEdit) return; // code cannot be modified in edit mode

    bool isDuplicate = _data.any((item) => item.hMenuCd == enteredCd);

    setState(() {
      if (isDuplicate) {
        _hMenuCdError = 'Head Menu Code $enteredCd is already in use.';
      } else {
        _hMenuCdError = null;
      }
    });
  }

  @override
  void dispose() {
    _hMenuCdFocus.removeListener(_onHMenuCdFocusChange);
    _hMenuCdFocus.dispose();
    _searchCtrl.dispose();
    _hMenuCdCtrl.dispose();
    _hMenuDescCtrl.dispose();
    _hPgmIdCtrl.dispose();
    _programPathCtrl.dispose();
    _menuLogoCtrl.dispose();
    _menuLocationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.getHeadMenus();
      if (mounted) {
        setState(() { _data = res; _isLoading = false; _currentPage = 0; _filterHMenuCd = null; });
        if (widget.isActive) {
          widget.onTotalChanged?.call(_data.length);
          int active = _data.where((d) => d.menuStatus).length;
          widget.onStatusChanged?.call(active, _data.length - active);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MNToast.show(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _openForm([HeadMenuModel? r, bool isView = false]) async {
    _sel = r;
    _go(_V.form);
    
    HeadMenuModel? fetchedRecord;
    if (r != null) {
      setState(() => _isLoading = true);
      try {
        fetchedRecord = await _service.getHeadMenu(r.hMenuCd!);
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          MNToast.show(context, e.toString(), isError: true);
          _go(_V.list);
        }
        return;
      }
      setState(() => _isLoading = false);
    }
    
    _isEdit = fetchedRecord != null;
    _isView = isView;
    _hMenuCdError = _hMenuDescError = _hPgmIdError = _programPathError = _menuLocationError = _logoError = null;
    
    if (fetchedRecord != null) {
      _isEdit = true;
      _hMenuCdCtrl.text = fetchedRecord.hMenuCd.toString();
      _hMenuDescCtrl.text = fetchedRecord.hMenuDesc;
      _hPgmIdCtrl.text = fetchedRecord.hPgmId ?? '';
      _programPathCtrl.text = fetchedRecord.programPath ?? '';
      _menuLocationCtrl.text = fetchedRecord.menuLocation ?? '';
      _menuStatus = fetchedRecord.menuStatus;
      _menuLogoCtrl.text = fetchedRecord.menuLogo;
    } else {
      _isEdit = false;
      _hMenuCdCtrl.clear();
      _hMenuDescCtrl.clear();
      _hPgmIdCtrl.clear();
      _programPathCtrl.clear();
      _menuLocationCtrl.clear();
      _menuStatus = false;
      _menuLogoCtrl.clear();
    }
  }

  void _go(_V v) {
    setState(() => _view = v);
    widget.onFormChanged?.call(v != _V.list);
  }

  Future<void> _save() async {
    if (_hMenuCdCtrl.text.trim().isEmpty) {
      _hMenuCdError = 'Head Menu Code is required';
    } else {
      _validateHMenuCd();
    }
    
    _hMenuDescError = _hMenuDescCtrl.text.trim().isEmpty ? 'Description is required' : null;
    _hPgmIdError = _hPgmIdCtrl.text.trim().isEmpty ? 'Program ID is required' : null;
    _programPathError = _programPathCtrl.text.trim().isEmpty ? 'Program Path is required' : null;
    _menuLocationError = _menuLocationCtrl.text.trim().isEmpty ? 'Location is required' : null;
    _logoError = _menuLogoCtrl.text.trim().isEmpty ? 'Remarks are required' : null;
    
    if (_hMenuCdError != null || _hMenuDescError != null || _hPgmIdError != null || _programPathError != null || _menuLocationError != null || _logoError != null) {
      setState(() {});
      return;
    }
    
    final model = HeadMenuModel(
      hMenuCd: int.parse(_hMenuCdCtrl.text.trim()),
      hMenuDesc: _hMenuDescCtrl.text.trim(),
      hPgmId: _hPgmIdCtrl.text.trim(),
      programPath: _programPathCtrl.text.trim(),
      menuLogo: _menuLogoCtrl.text.trim(),
      menuLocation: _menuLocationCtrl.text.trim(),
      menuStatus: _menuStatus,
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
        await _service.updateHeadMenu(model);
      } else {
        await _service.createHeadMenu(model);
      }
      MNToast.show(context, 'Saved successfully');
      widget.onMenuModified?.call();
      _go(_V.list);
      _loadData();
    } catch (e) {
      MNToast.show(context, e.toString(), isError: true);
    }
  }
  
  Future<void> _delete(int cd) async {
    try {
      await _service.deleteHeadMenu(cd);
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
      if (_search.isNotEmpty && !(e.hMenuDesc.toLowerCase().contains(_search) || e.hMenuCd.toString().contains(_search))) return false;
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
            hintText: 'Search head menus',
            onChanged: (v) => setState(() { _search = v.toLowerCase(); _currentPage = 0; }),
          ),
          const SizedBox(width: 16),
          if (widget.accessPrivileges?.canCreate ?? true)
            ActionButton('New Head Menu', bg: kP, fg: Colors.white, border: kP, icon: Icons.add_rounded, onTap: () => _openForm()),
        ]),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
          clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(builder: (ctx, constraints) {
              final w = constraints.maxWidth < 900 ? 900.0 : constraints.maxWidth;
              final cols = [w * 0.15, w * 0.35, w * 0.20, w * 0.15, w * 0.15];
              
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
                  headerCell('HEAD MENU CODE'), headerCell('DESCRIPTION'), headerCell('LOCATION'),
                  headerCell('STATUS'), headerCell('ACTIONS'),
                ], cols, isHeader: true),
                Column(
                  children: currentData.asMap().entries.map((e) {
                    final idx = e.key;
                    final r = e.value;
                    final isEven = idx % 2 == 1;
                    return StatefulBuilder(builder: (_, rss) {
                      bool hovered = false;
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        onEnter: (_) => rss(() => hovered = true),
                        onExit: (_) => rss(() => hovered = false),
                        child: rowWidget([
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(r.hMenuCd.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: kP)))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(r.hMenuDesc, style: const TextStyle(fontSize: 12.5, color: kText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: Text(r.menuLocation ?? '-', style: const TextStyle(fontSize: 12.5, color: kText), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Center(child: _statusBadge(r.menuStatus))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                              if (widget.accessPrivileges?.canView ?? true) ...[
                                _rowBtn(Icons.visibility_outlined, const Color(0xFF475569), () => _openForm(r, true)),
                                const SizedBox(width: 4),
                              ],
                              if (widget.accessPrivileges?.canEdit ?? true) ...[
                                _rowBtn(Icons.edit_outlined, kP, () => _openForm(r)),
                                const SizedBox(width: 4),
                              ],
                              if (widget.accessPrivileges?.canDelete ?? true)
                                _rowBtn(Icons.delete_outline_rounded, kR, () { _sel = r; _go(_V.delete); }),
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
                    'Head Menu',
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
                ActionButton('Back', bg: kP, fg: Colors.white, border: kP, icon: Icons.arrow_back_rounded, onTap: () => _go(_V.list)),
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
                      Row(
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 16, color: kP),
                          const SizedBox(width: 6),
                          Text(_isView ? (_sel?.hMenuDesc ?? 'Head Menu Details') : 'Head Menu Details', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kText)),
                        ],
                      ),
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
                      crossAxisCount: 4,
                      mainAxisSpacing: 22,
                      crossAxisSpacing: 22,
                      childAspectRatio: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        FloatingLabelField(label: 'Head Menu Code', controller: _hMenuCdCtrl, icon: (_isEdit || _isView) ? Icons.lock_outline_rounded : Icons.code, isRequired: true, isNumber: true, readOnly: _isEdit || _isView, errorText: _hMenuCdError, focusNode: _hMenuCdFocus),
                        FloatingLabelField(label: 'Description', controller: _hMenuDescCtrl, icon: Icons.description, isRequired: true, errorText: _hMenuDescError, readOnly: _isView),
                        FloatingLabelField(label: 'Head Menu Program ID', controller: _hPgmIdCtrl, icon: Icons.code, isRequired: true, errorText: _hPgmIdError, readOnly: _isView, hintText: 'Enter landing page program ID'),
                        FloatingLabelField(label: 'Program Path', controller: _programPathCtrl, icon: Icons.link, isRequired: true, errorText: _programPathError, readOnly: _isView, hintText: 'Enter landing page program path'),
                        DropdownField(
                          label: 'Location',
                          value: _menuLocationCtrl.text.isNotEmpty ? _menuLocationCtrl.text : null,
                          items: const ['Left', 'Right', 'Top', 'Bottom'],
                          onChanged: (v) {
                            if (v != null && !_isView) setState(() => _menuLocationCtrl.text = v);
                          },
                          icon: Icons.place,
                          isRequired: true,
                          errorText: _menuLocationError,
                          readOnly: _isView,
                        ),
                        ToggleField(label: 'Status', isActive: _menuStatus, isRequired: true, onChanged: (v) => _isView ? null : setState(() => _menuStatus = v), readOnly: _isView),
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
                        const Text('MENU ICON', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kP)),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 300,
                          child: FloatingLabelField(
                            label: 'Remarks', 
                            controller: _menuLogoCtrl, 
                            icon: Icons.chat_bubble_outline_rounded, 
                            isRequired: true, 
                            errorText: _logoError, 
                            readOnly: _isView,
                            hintText: 'Enter remarks here...',
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
                      ActionButton(_isView ? 'Back' : 'Cancel', bg: _isView ? kP : Colors.white, fg: _isView ? Colors.white : kP, border: kP, icon: _isView ? Icons.arrow_back_rounded : Icons.close_rounded, onTap: () => _go(_V.list)),
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
    final r = _sel!;
    return DeleteConfirmationWidget(
      title: 'Delete Head Menu',
      recordDetails: {
        'Head Menu Code:': r.hMenuCd.toString(),
        'Description:': r.hMenuDesc,
      },
      impactDetails: const [
        'Deleting this Head Menu will automatically delete all of its Menus.',
        'All Submenus associated with those Menus will be deleted.',
        'All Program Mappings inside those Submenus will be deleted.',
      ],
      onCancel: () => _go(_V.list),
      onConfirm: () => _delete(r.hMenuCd!),
    );
  }
}
