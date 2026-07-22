import 'package:flutter/material.dart';
import 'dart:async';
import 'services/client_group_api_service.dart';
import 'models/client_group_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class ClientGroupMasterScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAuthQueue;
  const ClientGroupMasterScreen({super.key, this.onNavigateToAuthQueue});

  @override
  State<ClientGroupMasterScreen> createState() => _ClientGroupMasterScreenState();
}

class _ClientGroupMasterScreenState extends State<ClientGroupMasterScreen> {
  MFView _view = MFView.list;
  ClientGroupMaster? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<ClientGroupMaster> _data = [];
  String _currentOrgCode = '101'; // Default

  final _orgCodeCtrl = TextEditingController();
  final _groupCodeCtrl = TextEditingController();
  final _groupNameCtrl = TextEditingController();
  final _branchCodeCtrl = TextEditingController();
  final _regionCodeCtrl = TextEditingController();
  final _regionalOfficerIdCtrl = TextEditingController();
  final _sourceSystemCtrl = TextEditingController(text: 'MANUAL');
  final _sourceRefNoCtrl = TextEditingController();
  final _meetingDayCtrl = TextEditingController();
  final _meetingFrequencyCtrl = TextEditingController();
  
  bool _groupStatus = true;
  String? _formErr;
  
  final _formKey = GlobalKey<FormState>();

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
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final res = await ClientGroupApiService.getClientGroups();
      _data = res;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go(MFView v, [ClientGroupMaster? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _delConfirmed = false;
      _formErr = null;
      if (v == MFView.create) {
        _resetForm();
      } else if (v == MFView.edit || v == MFView.view || v == MFView.delete) {
        _populateForm(r!);
      }
    });
  }

  void _resetForm() {
    _orgCodeCtrl.text = _currentOrgCode;
    _groupCodeCtrl.clear();
    _groupNameCtrl.clear();
    _branchCodeCtrl.clear();
    _regionCodeCtrl.clear();
    _regionalOfficerIdCtrl.clear();
    _sourceSystemCtrl.text = 'MANUAL';
    _sourceRefNoCtrl.clear();
    _meetingDayCtrl.clear();
    _meetingFrequencyCtrl.clear();
    _groupStatus = true;
  }

  void _populateForm(ClientGroupMaster r) {
    _orgCodeCtrl.text = r.orgCode;
    _groupCodeCtrl.text = r.groupCode;
    _groupNameCtrl.text = r.groupName;
    _branchCodeCtrl.text = r.branchCode;
    _regionCodeCtrl.text = r.regionCode;
    _regionalOfficerIdCtrl.text = r.regionalOfficerId;
    _sourceSystemCtrl.text = r.sourceSystem;
    _sourceRefNoCtrl.text = r.sourceRefNo ?? '';
    _meetingDayCtrl.text = r.meetingDay;
    _meetingFrequencyCtrl.text = r.meetingFrequency;
    _groupStatus = r.groupStatus == 'A';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    
    setState(() => _isLoading = true);
    try {
      final record = ClientGroupMaster(
        orgCode: _orgCodeCtrl.text,
        groupCode: _groupCodeCtrl.text.trim().toUpperCase(),
        groupName: _groupNameCtrl.text.trim(),
        branchCode: _branchCodeCtrl.text.trim(),
        regionCode: _regionCodeCtrl.text.trim(),
        regionalOfficerId: _regionalOfficerIdCtrl.text.trim(),
        sourceSystem: _sourceSystemCtrl.text.trim(),
        sourceRefNo: _sourceRefNoCtrl.text.trim().isEmpty ? null : _sourceRefNoCtrl.text.trim(),
        meetingDay: _meetingDayCtrl.text.trim(),
        meetingFrequency: _meetingFrequencyCtrl.text.trim(),
        groupStatus: _groupStatus ? 'A' : 'C',
      );

      String? message;
      if (_view == MFView.edit) {
        message = await ClientGroupApiService.updateClientGroup(record);
      } else {
        message = await ClientGroupApiService.createClientGroup(record);
      }

      if (message == 'Sent for authorization') {
        showAuthPendingDialog(context, onGoToQueue: () {
          if (widget.onNavigateToAuthQueue != null) {
            widget.onNavigateToAuthQueue!();
          }
        });
        _go(MFView.list);
      } else {
        showSuccessDialog(
          context, 
          _view == MFView.edit ? 'Client Group updated successfully!' : 'Client Group created successfully!', 
          onConfirm: () => _go(MFView.list)
        );
      }
    } catch (e) {
      setState(() => _formErr = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (!_delConfirmed) {
      setState(() => _delConfirmed = true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ClientGroupApiService.deleteClientGroup(_sel!.groupCode);
      showSuccessDialog(context, 'Client Group deleted successfully', onConfirm: () {
        _loadData();
        _go(MFView.list);
      });
    } catch (e) {
      MFToast.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isLoading = false);
    }
  }
  
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: onTap == null ? bg.withOpacity(0.5) : bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: onTap == null ? border.withOpacity(0.5) : border)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: fg), const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _hBtn(String label, {required IconData icon, required VoidCallback onTap, Color fg = const Color(0xFF64748B), Color border = const Color(0xFFE2E8F0)}) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: fg), const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
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

  Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.groupCode.toLowerCase().contains(q) || r.groupName.toLowerCase().contains(q) || r.branchCode.toLowerCase().contains(q);
    }).toList();

    final pages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > filtered.length) ? filtered.length : start + _itemsPerPage;
    final pagedList = filtered.isEmpty ? <ClientGroupMaster>[] : filtered.sublist(start, end);
    final activeCount = _data.where((e) => e.groupStatus == 'A').length;
    final inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Client Group Master', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: inactiveCount),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          SizedBox(
            width: 300, height: 40,
            child: TextField(
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
              },
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              ),
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
                Expanded(flex: 3, child: _colHdr('GROUP NAME')),
                Expanded(flex: 2, child: _colHdr('BRANCH')),
                Expanded(flex: 2, child: _colHdr('REGION')),
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
                Text('No groups found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
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
                      Expanded(flex: 3, child: Text(r.groupName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Text(r.branchCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Text(r.regionCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: r.groupStatus == 'A' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                      child: Text(r.groupStatus == 'A' ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.groupStatus == 'A' ? const Color(0xFF166534) : const Color(0xFF991B1B))),
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
      ]),
    );
  }

  Widget _fieldBox(Widget child, BoxConstraints c) => SizedBox(width: (c.maxWidth - (24 * 3)) / 4, child: child);

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
            Text(isView ? 'View Client Group' : (isEdit ? 'Edit Client Group' : (isDelete ? 'Delete Client Group' : 'Create Client Group')),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 24),
          if (_formErr != null)
            Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))), child: Text(_formErr!, style: const TextStyle(color: Color(0xFF991B1B)))),
          _card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('GROUP DETAILS'),
                const SizedBox(height: 32),
                Wrap(spacing: 24, runSpacing: 40, children: [
                  _fieldBox(MFFloatingLabelField(label: 'Group Code', ctrl: _groupCodeCtrl, icon: Icons.numbers_rounded, readOnly: isEdit || isView || isDelete, required: !isView && !isDelete), constraints),
                  _fieldBox(MFFloatingLabelField(label: 'Group Name', ctrl: _groupNameCtrl, icon: Icons.text_fields_rounded, readOnly: isView || isDelete, required: !isView && !isDelete), constraints),
                  _fieldBox(MFFloatingLabelField(label: 'Branch Code', ctrl: _branchCodeCtrl, icon: Icons.store_rounded, readOnly: isView || isDelete, required: !isView && !isDelete), constraints),
                  _fieldBox(MFFloatingLabelField(label: 'Region Code', ctrl: _regionCodeCtrl, icon: Icons.map_rounded, readOnly: isView || isDelete, required: !isView && !isDelete), constraints),
                  _fieldBox(MFFloatingLabelField(label: 'Regional Officer ID', ctrl: _regionalOfficerIdCtrl, icon: Icons.person_rounded, readOnly: isView || isDelete, required: !isView && !isDelete), constraints),
                  _fieldBox(MFApiDropdownField(label: 'Source System', icon: Icons.computer_rounded, items: const [{'id': 'LOS'}, {'id': 'MANUAL'}], displayKeys: const ['id'], selectedItem: {'id': _sourceSystemCtrl.text}, onChanged: (v) => setState(() => _sourceSystemCtrl.text = v?['id'] ?? ''), enabled: !isView && !isDelete), constraints),
                  _fieldBox(MFFloatingLabelField(label: 'Source Ref No', ctrl: _sourceRefNoCtrl, icon: Icons.receipt_long_rounded, readOnly: isView || isDelete), constraints),
                  _fieldBox(MFApiDropdownField(label: 'Meeting Day', icon: Icons.calendar_today_rounded, items: const [{'id': 'Monday'}, {'id': 'Tuesday'}, {'id': 'Wednesday'}, {'id': 'Thursday'}, {'id': 'Friday'}, {'id': 'Saturday'}, {'id': 'Sunday'}], displayKeys: const ['id'], selectedItem: _meetingDayCtrl.text.isNotEmpty ? {'id': _meetingDayCtrl.text} : null, onChanged: (v) => setState(() => _meetingDayCtrl.text = v?['id'] ?? ''), enabled: !isView && !isDelete), constraints),
                  _fieldBox(MFApiDropdownField(label: 'Meeting Frequency', icon: Icons.update_rounded, items: const [{'id': 'Weekly'}, {'id': 'Fortnightly'}, {'id': 'Monthly'}], displayKeys: const ['id'], selectedItem: _meetingFrequencyCtrl.text.isNotEmpty ? {'id': _meetingFrequencyCtrl.text} : null, onChanged: (v) => setState(() => _meetingFrequencyCtrl.text = v?['id'] ?? ''), enabled: !isView && !isDelete), constraints),
                ]),
                const SizedBox(height: 32),
                _secHdr('STATUS'),
                const SizedBox(height: 32),
                Switch(value: _groupStatus, onChanged: (isView || isDelete) ? null : (v) => setState(() => _groupStatus = v)),
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
                      Text('Delete Client Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                      SizedBox(height: 4),
                      Text('This action cannot be undone and will remove all members from the group.', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                    ])),
                    _hBtn(_delConfirmed ? 'Confirm Delete' : 'Delete Record', icon: Icons.delete_outline_rounded, fg: const Color(0xFFDC2626), border: const Color(0xFFFCA5A5), onTap: _isLoading ? () {} : _deleteRecord),
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
                  onPressed: _save,
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
