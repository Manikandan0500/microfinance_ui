import 'package:flutter/material.dart';
import 'dart:async';
import 'services/client_group_api_service.dart';
import 'models/client_group_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class ClientGroupMasterScreen extends StatefulWidget {
  const ClientGroupMasterScreen({super.key});

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
  final _meetingFrequencyCtrl = TextEditingController(text: 'Monthly');
  bool _groupStatus = true;

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
      if (v == MFView.create) {
        _resetForm();
      } else if (v == MFView.edit || v == MFView.view) {
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
    _meetingFrequencyCtrl.text = 'Monthly';
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

  bool _validateForm() {
    if (_groupCodeCtrl.text.trim().isEmpty || 
        _groupNameCtrl.text.trim().isEmpty || 
        _branchCodeCtrl.text.trim().isEmpty || 
        _regionCodeCtrl.text.trim().isEmpty || 
        _regionalOfficerIdCtrl.text.trim().isEmpty) {
      MFToast.show(context, 'Please fill in all required fields.', isError: true);
      return false;
    }
    return true;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (_validateForm()) {
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

        if (isEdit) {
          await ClientGroupApiService.updateClientGroup(record);
          showSuccessDialog(context, 'Client Group updated successfully!', onConfirm: () => _go(MFView.list));
        } else {
          await ClientGroupApiService.createClientGroup(record);
          showSuccessDialog(context, 'Client Group created successfully!', onConfirm: () => _go(MFView.list));
        }
      } catch (e) {
        MFToast.show(context, e.toString().replaceFirst('Exception: ', ''), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  // List View
  Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.groupCode.toLowerCase().contains(q) || r.groupName.toLowerCase().contains(q) || r.branchCode.toLowerCase().contains(q);
    }).toList();

    final activeCount = _data.where((r) => r.groupStatus == 'A').length;
    final closedCount = _data.where((r) => r.groupStatus == 'C').length;

    final pages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > filtered.length) ? filtered.length : start + _itemsPerPage;
    final items = filtered.isEmpty ? <ClientGroupMaster>[] : filtered.sublist(start, end);

    return Column(children: [
      _pageHeader(title: 'Client Group Master', actions: []),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: closedCount),
            const Spacer(),
            SizedBox(
              width: 280, height: 40,
              child: TextField(
                onChanged: (v) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
                },
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3050), width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _fBtn('Create Group', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
          ],
        ),
      ),
      Expanded(
        child: _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFF1E3050), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(children: [
                Expanded(flex: 2, child: _colHdr('GROUP CODE')),
                Expanded(flex: 3, child: _colHdr('GROUP NAME')),
                Expanded(flex: 2, child: _colHdr('BRANCH')),
                Expanded(flex: 2, child: _colHdr('REGION')),
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
              const Expanded(child: Center(child: Text('No groups found', style: TextStyle(color: Color(0xFF64748B)))))
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
                          Expanded(flex: 3, child: Text(r.groupName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(r.branchCode, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Text(r.regionCode, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                          Expanded(flex: 2, child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: r.groupStatus == 'A' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(r.groupStatus == 'A' ? 'Active' : 'Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.groupStatus == 'A' ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
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
    ]);
  }

  // Form View (Create, Edit & View)
  Widget _form() {
    final isEdit = _view == MFView.edit;
    final isView = _view == MFView.view;
    return Column(children: [
      _pageHeader(
        title: isView ? 'View Client Group' : (isEdit ? 'Edit Client Group' : 'Create Client Group'),
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
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('GROUP DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Group Code', ctrl: _groupCodeCtrl, icon: Icons.numbers_rounded, required: !isView,
                    readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Group Name', ctrl: _groupNameCtrl, icon: Icons.text_fields_rounded, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Branch Code', ctrl: _branchCodeCtrl, icon: Icons.store_rounded, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Region Code', ctrl: _regionCodeCtrl, icon: Icons.map_rounded, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Regional Officer ID', ctrl: _regionalOfficerIdCtrl, icon: Icons.person_rounded, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Source System', icon: Icons.computer_rounded, required: !isView,
                    items: const [{'id': 'LOS'}, {'id': 'MANUAL'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _sourceSystemCtrl.text},
                    onChanged: (v) => _sourceSystemCtrl.text = v?['id'] ?? '',
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Source Ref No', ctrl: _sourceRefNoCtrl, icon: Icons.receipt_long_rounded,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Meeting Day', icon: Icons.calendar_today_rounded, required: !isView,
                    items: const [{'id': 'Monday'}, {'id': 'Tuesday'}, {'id': 'Wednesday'}, {'id': 'Thursday'}, {'id': 'Friday'}, {'id': 'Saturday'}, {'id': 'Sunday'}],
                    displayKeys: const ['id'],
                    selectedItem: _meetingDayCtrl.text.isNotEmpty ? {'id': _meetingDayCtrl.text} : null,
                    onChanged: (v) => _meetingDayCtrl.text = v?['id'] ?? '',
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Meeting Frequency', icon: Icons.update_rounded, required: !isView,
                    items: const [{'id': 'Weekly'}, {'id': 'Fortnightly'}, {'id': 'Monthly'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _meetingFrequencyCtrl.text},
                    onChanged: (v) => _meetingFrequencyCtrl.text = v?['id'] ?? '',
                    enabled: !isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('STATUS'),
                const SizedBox(height: 16),
                Row(children: [
                  const Text('Active Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  const SizedBox(width: 12),
                  Switch(
                    value: _groupStatus,
                    onChanged: isView ? null : (v) => setState(() => _groupStatus = v),
                    activeColor: const Color(0xFF1E3050),
                    activeTrackColor: const Color(0xFFCBD5E1),
                  ),
                ]),
              ]),
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
                        Text('Delete Client Group', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                        SizedBox(height: 4),
                        Text('This action cannot be undone and will remove all members from the group.', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                      ])),
                      _hBtn(_delConfirmed ? 'Confirm Delete' : 'Delete Record', icon: Icons.delete_outline_rounded, fg: const Color(0xFFDC2626), border: const Color(0xFFFCA5A5), onTap: _isLoading ? () {} : _deleteRecord),
                    ]),
                  ),
                ]),
              )),
            ] else ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _fBtn(isEdit ? 'Save Changes' : 'Create Record', isEdit ? Icons.save_rounded : Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
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
