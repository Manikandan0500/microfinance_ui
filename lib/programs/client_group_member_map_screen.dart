import 'package:flutter/material.dart';
import 'dart:async';
import 'services/client_group_api_service.dart';
import 'models/client_group_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class ClientGroupMemberMapScreen extends StatefulWidget {
  const ClientGroupMemberMapScreen({super.key});

  @override
  State<ClientGroupMemberMapScreen> createState() => _ClientGroupMemberMapScreenState();
}

class _ClientGroupMemberMapScreenState extends State<ClientGroupMemberMapScreen> {
  MFView _view = MFView.list;
  ClientGroupMemberMap? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<ClientGroupMemberMap> _data = [];
  String _currentOrgCode = '101'; // Default

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _groupCodeCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _memberRoleCtrl = TextEditingController(text: 'Member');
  bool _memberStatus = true;
  DateTime _joinDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrgCode();
    _loadData();
  }

  Future<void> _loadOrgCode() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    _orgCodeCtrl.text = _currentOrgCode;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      _data = await ClientGroupApiService.getClientGroupMemberMaps();
      // Filter by org
      _data = _data.where((e) => e.orgCode == _currentOrgCode).toList();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go(MFView v, [ClientGroupMemberMap? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _delConfirmed = false;
      if (v == MFView.create) {
        _groupCodeCtrl.clear();
        _clientIdCtrl.clear();
        _memberRoleCtrl.text = 'Member';
        _joinDate = DateTime.now();
        _memberStatus = true;
      } else if (r != null && (v == MFView.edit || v == MFView.view)) {
        _groupCodeCtrl.text = r.groupCode;
        _clientIdCtrl.text = r.clientId;
        _memberRoleCtrl.text = r.memberRole;
        _joinDate = r.joinDate;
        _memberStatus = r.memberStatus == 'A';
      }
    });
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final record = ClientGroupMemberMap(
        orgCode: _orgCodeCtrl.text,
        groupCode: _groupCodeCtrl.text.trim().toUpperCase(),
        clientId: _clientIdCtrl.text.trim().toUpperCase(),
        memberRole: _memberRoleCtrl.text,
        joinDate: _joinDate,
        memberStatus: _memberStatus ? 'A' : 'C',
      );

      if (isEdit) {
        await ClientGroupApiService.updateClientGroupMemberMap(record);
        showSuccessDialog(context, 'Member mapped successfully', onConfirm: () {
          _loadData();
          _go(MFView.list);
        });
      } else {
        // Check duplicates if create
        if (_data.any((e) => e.groupCode == record.groupCode && e.clientId == record.clientId)) {
          throw Exception('This client is already mapped to this group.');
        }
        await ClientGroupApiService.createClientGroupMemberMap(record);
        showSuccessDialog(context, 'Member mapped successfully', onConfirm: () {
          _loadData();
          _go(MFView.list);
        });
      }
    } catch (e) {
      MFToast.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (!_delConfirmed) {
      setState(() => _delConfirmed = true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ClientGroupApiService.deleteClientGroupMemberMap(_sel!.groupCode, _sel!.clientId);
      showSuccessDialog(context, 'Member unmapped successfully', onConfirm: () {
        _loadData();
        _go(MFView.list);
      });
    } catch (e) {
      MFToast.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isLoading = false);
    }
  }

  // UI Helpers
  Widget _pageHeader({required String title, required List<Widget> actions}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(color: Colors.white),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      const Spacer(),
      ...actions,
    ]),
  );

  Widget _secHdr(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2));
  
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: onTap == null ? bg.withValues(alpha: 0.5) : bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: onTap == null ? border.withValues(alpha: 0.5) : border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: onTap == null ? fg.withValues(alpha: 0.5) : fg),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onTap == null ? fg.withValues(alpha: 0.5) : fg)),
            ]),
          ),
        ),
      );

  Widget _hBtn(String label, {IconData? icon, VoidCallback? onTap, Color? fg, Color? border}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: border ?? const Color(0xFFE2E8F0))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg ?? const Color(0xFF64748B)), const SizedBox(width: 8)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg ?? const Color(0xFF475569))),
            ]),
          ),
        ),
      );

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  // List View
  Widget _list() {
    final filtered = _data.where((r) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return r.groupCode.toLowerCase().contains(q) || r.clientId.toLowerCase().contains(q);
    }).toList();
    
    final pages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > filtered.length) ? filtered.length : start + _itemsPerPage;
    final items = filtered.sublist(start, end);

    return Column(children: [
      _pageHeader(
        title: 'Client Group Member Map',
        actions: [
          Container(
            width: 300,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(children: [
              const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Search group or client...', border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                  onChanged: (v) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
                  },
                ),
              ),
            ]),
          ),
          const SizedBox(width: 16),
          _fBtn('Map Client', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
        ],
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _card(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(color: Color(0xFF1E3050)),
                child: Row(children: [
                  Expanded(flex: 2, child: _colHdr('GROUP CODE')),
                  Expanded(flex: 2, child: _colHdr('CLIENT ID')),
                  Expanded(flex: 2, child: _colHdr('ROLE')),
                  Expanded(flex: 2, child: _colHdr('JOIN DATE')),
                  Expanded(flex: 2, child: _colHdr('STATUS')),
                  const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
                ]),
              ),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
              else if (_loadError != null)
                Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
                  Text(_loadError!, style: const TextStyle(color: Color(0xFFDC2626))), const SizedBox(height: 16),
                  _hBtn('Retry', icon: Icons.refresh_rounded, onTap: _loadData),
                ])))
              else if (items.isEmpty)
                const Expanded(child: Center(child: Text('No mapping records found', style: TextStyle(color: Color(0xFF64748B)))))
              else
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (_, i) {
                      final r = items[i];
                      return InkWell(
                        onTap: () => _go(MFView.view, r),
                        hoverColor: const Color(0xFFF8FAFC),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(children: [
                            Expanded(flex: 2, child: Text(r.groupCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                            Expanded(flex: 2, child: Text(r.clientId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                            Expanded(flex: 2, child: Text(r.memberRole, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                            Expanded(flex: 2, child: Text(r.joinDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                            Expanded(flex: 2, child: Row(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: r.memberStatus == 'A' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                child: Text(r.memberStatus == 'A' ? 'Active' : 'Exited', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.memberStatus == 'A' ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
                              ),
                            ])),
                            SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _go(MFView.view, r),
                                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF1E3050))),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _go(MFView.edit, r),
                                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF1E3050))),
                                ),
                              ),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              if (pages > 1)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Showing $start to $end of ${filtered.length} entries', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Row(children: [
                      _hBtn('Prev', icon: Icons.chevron_left_rounded, onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : () {}),
                      const SizedBox(width: 8),
                      Text('Page $_currentPage of $pages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      _hBtn('Next', icon: Icons.chevron_right_rounded, onTap: _currentPage < pages ? () => setState(() => _currentPage++) : () {}),
                    ]),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }

  // Form View (Create, Edit & View)
  Widget _form() {
    final isEdit = _view == MFView.edit;
    final isView = _view == MFView.view;
    return Column(children: [
      _pageHeader(
        title: isView ? 'View Mapping' : (isEdit ? 'Edit Mapping' : 'Map Client to Group'),
        actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          if (isView) ...[
            const SizedBox(width: 10),
            _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, _sel)),
          ]
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            _card(child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _secHdr('MAPPING DETAILS'),
                  const SizedBox(height: 16),
                  Wrap(spacing: 24, runSpacing: 24, children: [
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Group Code', ctrl: _groupCodeCtrl, icon: Icons.group_work_rounded, required: !isView,
                      readOnly: isEdit || isView, showLock: isEdit || isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Client ID', ctrl: _clientIdCtrl, icon: Icons.person_outline, required: !isView,
                      readOnly: isEdit || isView, showLock: isEdit || isView,
                    )),
                    SizedBox(width: 300, child: MFApiDropdownField(
                      label: 'Role', icon: Icons.star_border, required: !isView,
                      items: const [{'id': 'Leader'}, {'id': 'Member'}],
                      displayKeys: const ['id'],
                      selectedItem: {'id': _memberRoleCtrl.text},
                      onChanged: (v) => _memberRoleCtrl.text = v?['id'] ?? 'Member',
                      enabled: !isView,
                    )),
                  ]),
                  const SizedBox(height: 32),
                  _secHdr('STATUS'),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Text('Active Mapping', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    const SizedBox(width: 12),
                    Switch(
                      value: _memberStatus,
                      onChanged: isView ? null : (v) => setState(() => _memberStatus = v),
                      activeColor: const Color(0xFF1E3050),
                      activeTrackColor: const Color(0xFFCBD5E1),
                    ),
                  ]),
                ]),
              ),
            )),
            if (isView) ...[
              const SizedBox(height: 24),
              _card(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _secHdr('DANGER ZONE'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
                    child: Row(children: [
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Remove Mapping', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                        SizedBox(height: 4),
                        Text('This will unmap the client from the group.', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                      ])),
                      _hBtn(_delConfirmed ? 'Confirm Unmap' : 'Unmap Client', icon: Icons.person_remove_rounded, fg: const Color(0xFFDC2626), border: const Color(0xFFFCA5A5), onTap: _isLoading ? () {} : _deleteRecord),
                    ]),
                  ),
                ]),
              )),
            ] else ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _fBtn(isEdit ? 'Save Changes' : 'Map Client', isEdit ? Icons.save_rounded : Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
                ],
              ),
            ],
          ]),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_view == MFView.list) return _list();
    return _form();
  }
}
