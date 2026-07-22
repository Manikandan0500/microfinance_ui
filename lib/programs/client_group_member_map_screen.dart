import 'package:flutter/material.dart';
import 'dart:async';
import 'services/client_group_api_service.dart';
import 'models/client_group_master.dart';
import 'models/cif_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class ClientGroupMemberMapScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAuthQueue;
  const ClientGroupMemberMapScreen({super.key, this.onNavigateToAuthQueue});

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
  List<ClientGroupMaster> _groupMasters = [];
  List<CifMaster> _cifMasters = [];
  String _currentOrgCode = '101'; // Default

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _groupCodeCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _memberRoleCtrl = TextEditingController(text: 'Member');
  bool _memberStatus = true;
  DateTime _joinDate = DateTime.now();
  String? _formErr;

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
      final futures = await Future.wait([
        ClientGroupApiService.getClientGroupMemberMaps(),
        ClientGroupApiService.getClientGroups(),
        ClientGroupApiService.getCifMasters(),
      ]);
      _data = futures[0] as List<ClientGroupMemberMap>;
      _groupMasters = futures[1] as List<ClientGroupMaster>;
      _cifMasters = futures[2] as List<CifMaster>;

      // Filter by org
      _data = _data.where((e) => e.orgCode == _currentOrgCode).toList();
      _groupMasters = _groupMasters.where((e) => e.orgCode == _currentOrgCode).toList();
      _cifMasters = _cifMasters.where((e) => e.orgCode == _currentOrgCode).toList();
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
      _formErr = null;
      if (v == MFView.create) {
        _groupCodeCtrl.clear();
        _clientIdCtrl.clear();
        _memberRoleCtrl.text = 'Member';
        _joinDate = DateTime.now();
        _memberStatus = true;
        _memberStatus = true;
      } else if (r != null && (v == MFView.edit || v == MFView.view || v == MFView.delete)) {
        _groupCodeCtrl.text = r.groupCode;
        _clientIdCtrl.text = r.clientId;
        _memberRoleCtrl.text = r.memberRole;
        _joinDate = r.joinDate;
        _memberStatus = r.memberStatus == 'A';
      }
    });
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
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

      String? message;
      if (isEdit) {
        message = await ClientGroupApiService.updateClientGroupMemberMap(record);
      } else {
        // Check duplicates if create
        if (_data.any((e) => e.groupCode == record.groupCode && e.clientId == record.clientId)) {
          throw Exception('This client is already mapped to this group.');
        }
        message = await ClientGroupApiService.createClientGroupMemberMap(record);
      }

      if (message == 'Sent for authorization') {
        showAuthPendingDialog(context, onGoToQueue: () {
          if (widget.onNavigateToAuthQueue != null) {
            widget.onNavigateToAuthQueue!();
          }
        });
        _loadData();
        _go(MFView.list);
      } else {
        showSuccessDialog(context, 'Member mapped successfully', onConfirm: () {
          _loadData();
          _go(MFView.list);
        });
      }
    } catch (e) {
      setState(() { _formErr = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
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

  Widget _rowBtn(IconData icon, Color c, VoidCallback onTap) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
            child: Icon(icon, size: 15, color: c),
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
    final pagedList = filtered.isEmpty ? <ClientGroupMemberMap>[] : filtered.sublist(start, end);
    final activeCount = _data.where((e) => e.memberStatus == 'A').length;
    final inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Client Group Member Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: inactiveCount),
        ]),
        const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        SizedBox(
          width: 300, height: 40,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search group or client...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            onChanged: (v) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
            },
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _go(MFView.create),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            minimumSize: const Size(0, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: const Text('CREATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
      const SizedBox(height: 16),
      _card(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3050),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(flex: 2, child: _colHdr('GROUP CODE')),
              Expanded(flex: 2, child: _colHdr('CLIENT ID')),
              Expanded(flex: 2, child: _colHdr('ROLE')),
              Expanded(flex: 2, child: _colHdr('JOIN DATE')),
              Expanded(flex: 2, child: _colHdr('STATUS')),
              const SizedBox(width: 110, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
            ]),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
          else if (_loadError != null)
            Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
              Text(_loadError!, style: const TextStyle(color: Color(0xFFDC2626))), const SizedBox(height: 16),
              _hBtn('Retry', icon: Icons.refresh_rounded, onTap: _loadData),
            ])))
          else if (pagedList.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFCBD5E1)), const SizedBox(height: 16),
              Text('No mapping records found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
            ])))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: pagedList.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) {
                final r = pagedList[i];
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text(r.groupCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.clientId, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.memberRole, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.joinDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: r.memberStatus == 'A' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                      child: Text(r.memberStatus == 'A' ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.memberStatus == 'A' ? const Color(0xFF166534) : const Color(0xFF991B1B))),
                    )),
                    SizedBox(width: 110, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _go(MFView.view, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.edit_rounded, const Color(0xFF1E3050), () => _go(MFView.edit, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.delete_rounded, const Color(0xFFDC2626), () => _go(MFView.delete, r)),
                    ])),
                  ]),
                );
              },
            ),
        ]),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MFPaginationControls(
            currentPage: _currentPage,
            totalPages: pages,
            onPrev: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            onNext: _currentPage < pages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    ]));
  }

  Widget _fieldBox(Widget child, BoxConstraints c) => SizedBox(width: (c.maxWidth - (24 * 3)) / 4, child: child);

  // Form View (Create, Edit & View)
  Widget _form() {
    final isEdit = _view == MFView.edit;
    final isView = _view == MFView.view;
    final isDelete = _view == MFView.delete;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => _go(MFView.list)),
            Text(isView ? 'View Mapping' : (isEdit ? 'Edit Mapping' : (isDelete ? 'Delete Mapping' : 'Map Client to Group')),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 24),
          if (_formErr != null)
            Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))), child: Text(_formErr!, style: const TextStyle(color: Color(0xFF991B1B)))),
          _card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('MAPPING DETAILS'),
                const SizedBox(height: 32),
                Wrap(spacing: 24, runSpacing: 40, children: [
                  _fieldBox(MFApiDropdownField(
                    label: 'Group Code',
                    icon: Icons.group,
                    required: true,
                    items: _groupMasters.map((g) => {'id': g.groupCode, 'display': '${g.groupCode} - ${g.groupName}'}).toList(),
                    displayKeys: const ['display'],
                    selectedItem: _groupCodeCtrl.text.isNotEmpty ? {'display': '${_groupCodeCtrl.text} - ${_groupMasters.where((g) => g.groupCode == _groupCodeCtrl.text).map((g) => g.groupName).join('')}'} : null,
                    onChanged: (v) => setState(() => _groupCodeCtrl.text = v?['id'] ?? ''),
                    enabled: !isView && !isEdit && !isDelete,
                  ), constraints),
                  _fieldBox(MFApiDropdownField(
                    label: 'Client ID',
                    icon: Icons.person_outline,
                    required: true,
                    items: _cifMasters.map((c) => {'id': c.cifId, 'display': '${c.cifId} - ${c.fullName}'}).toList(),
                    displayKeys: const ['display'],
                    selectedItem: _clientIdCtrl.text.isNotEmpty ? {'display': '${_clientIdCtrl.text} - ${_cifMasters.where((c) => c.cifId == _clientIdCtrl.text).map((c) => c.fullName).join('')}'} : null,
                    onChanged: (v) => setState(() => _clientIdCtrl.text = v?['id'] ?? ''),
                    enabled: !isView && !isEdit && !isDelete,
                  ), constraints),
                  _fieldBox(MFApiDropdownField(
                    label: 'Role', icon: Icons.star_border, required: !isView && !isDelete,
                    items: const [{'id': 'Leader'}, {'id': 'Member'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _memberRoleCtrl.text},
                    onChanged: (v) => setState(() => _memberRoleCtrl.text = v?['id'] ?? 'Member'),
                    enabled: !isView && !isDelete,
                  ), constraints),
                ]),
                const SizedBox(height: 32),
                _secHdr('STATUS'),
                const SizedBox(height: 32),
                Switch(
                  value: _memberStatus,
                  onChanged: (isView || isDelete) ? null : (v) => setState(() => _memberStatus = v),
                ),
              ]);
            }),
          )),
          if (isDelete) ...[
            const SizedBox(height: 24),
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('DANGER ZONE'),
                const SizedBox(height: 32),
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
          ],
          if (!isView && !isDelete)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                _hBtn('Cancel', icon: Icons.close_rounded, onTap: () => _go(MFView.list)),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _saveRecord(isEdit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                  ),
                  child: Text(isEdit ? 'SAVE CHANGES' : 'CREATE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_view == MFView.list) return _list();
    return _form();
  }
}
