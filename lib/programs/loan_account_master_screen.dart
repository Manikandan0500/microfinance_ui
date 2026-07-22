import 'package:flutter/material.dart';
import 'dart:async';
import 'services/loan_account_api_service.dart';
import 'services/client_group_api_service.dart';
import 'services/loan_product_api_service.dart';
import 'models/loan_application.dart';
import 'models/cif_master.dart';
import 'models/client_group_master.dart';
import 'models/loan_product_master.dart';
import '../../am_masters/services/auth_service.dart';
import 'mf_shared_widgets.dart';
import 'shared_widgets.dart';
import 'package:intl/intl.dart';

class LoanAccountMasterScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAuthQueue;
  const LoanAccountMasterScreen({super.key, this.onNavigateToAuthQueue});

  @override
  State<LoanAccountMasterScreen> createState() => _LoanAccountMasterScreenState();
}

class _LoanAccountMasterScreenState extends State<LoanAccountMasterScreen> {
  MFView _view = MFView.list;
  LoanApplication? _sel;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<LoanApplication> _data = [];
  
  List<CifMaster> _cifList = [];
  List<ClientGroupMemberMap> _groupMapList = [];
  List<LoanProductMaster> _productList = [];
  List<ClientGroupMaster> _groupList = [];

  // Form controllers
  final _groupCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _queueIdCtrl = TextEditingController();
  final _currCtrl = TextEditingController(text: 'INR');
  final _sourceSysCtrl = TextEditingController(text: 'MANUAL');
  final _apprAmtCtrl = TextEditingController();
  final _apprTenureCtrl = TextEditingController();
  final _apprIntRateCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  
  String? _formErr;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadData();
  }

  void _onSearchChanged() {
    if (_searchCtrl.text == _search) return;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = _searchCtrl.text; _currentPage = 1; }));
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final futures = await Future.wait([
        LoanAccountApiService.getLoanAccounts(),
        ClientGroupApiService.getCifMasters(),
        ClientGroupApiService.getClientGroupMemberMaps(),
        LoanProductApiService.getProducts('101'),
        ClientGroupApiService.getClientGroups(),
      ]);
      _data = futures[0] as List<LoanApplication>;
      _cifList = futures[1] as List<CifMaster>;
      _groupMapList = futures[2] as List<ClientGroupMemberMap>;
      _productList = futures[3] as List<LoanProductMaster>;
      _groupList = futures[4] as List<ClientGroupMaster>;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().getUser();
      final username = user?.id ?? 'SYS';
      
      final rec = LoanApplication(
        orgCode: '101',
        queueId: _queueIdCtrl.text,
        sourceSystem: _sourceSysCtrl.text,
        clientId: _clientCtrl.text,
        groupCode: _groupCtrl.text.isEmpty ? null : _groupCtrl.text,
        productCode: _prodCtrl.text,
        approvedAmount: double.tryParse(_apprAmtCtrl.text) ?? 0.0,
        approvedTenureMonths: int.tryParse(_apprTenureCtrl.text) ?? 0,
        approvedInterestRate: double.tryParse(_apprIntRateCtrl.text) ?? 0.0,
        queueDate: DateTime.now(),
        assignedToUserId: username,
        disbursementStatus: 'PENDING',
        currencyCode: _currCtrl.text,
      );

      String? message;
      if (_view == MFView.create) {
        message = await LoanAccountApiService.createLoanAccount(rec);
      } else {
        message = await LoanAccountApiService.updateLoanAccount(rec);
      }
      
      setState(() { _view = MFView.list; _formErr = null; });
      _loadData();

      if (message == 'Sent for authorization') {
        showAuthPendingDialog(context, onGoToQueue: () {
          if (widget.onNavigateToAuthQueue != null) {
            widget.onNavigateToAuthQueue!();
          }
        });
      } else {
        MFToast.show(context, 'Record saved successfully!');
      }
    } catch (e) {
      setState(() { _formErr = e.toString().replaceFirst('Exception: ', ''); _isLoading = false; });
    }
  }

  void _delete(String queueId) async {
    final conf = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Loan Application'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('DELETE')),
        ],
      )
    );
    if (conf != true) return;
    setState(() => _isLoading = true);
    try {
      await LoanAccountApiService.deleteLoanAccount(queueId);
      _loadData();
    } catch (e) {
      setState(() { _formErr = e.toString(); _isLoading = false; });
    }
  }

  void _setView(MFView v, [LoanApplication? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _formErr = null;
      if (v == MFView.create) {
        _groupCtrl.text = '';
        _clientCtrl.text = '';
        _prodCtrl.text = '';
        _queueIdCtrl.text = '';
        _currCtrl.text = 'INR';
        _sourceSysCtrl.text = 'MANUAL';
        _apprAmtCtrl.text = '';
        _apprTenureCtrl.text = '';
        _apprIntRateCtrl.text = '';
      } else if (r != null) {
        _groupCtrl.text = r.groupCode ?? '';
        _clientCtrl.text = r.clientId;
        _prodCtrl.text = r.productCode;
        _queueIdCtrl.text = r.queueId;
        _currCtrl.text = r.currencyCode;
        _sourceSysCtrl.text = r.sourceSystem;
        _apprAmtCtrl.text = r.approvedAmount.toString();
        _apprTenureCtrl.text = r.approvedTenureMonths.toString();
        _apprIntRateCtrl.text = r.approvedInterestRate.toString();
      }
    });
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))],
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: child,
  );

  Widget _secHdr(String title) => Row(children: [
    Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
  ]);

  Widget _fieldBox(Widget child, BoxConstraints c) => SizedBox(width: (c.maxWidth - (24 * 3)) / 4, child: child);

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

  Widget _list() {
    var fData = _data;
    if (_search.isNotEmpty) {
      final s = _search.toLowerCase();
      fData = fData.where((e) => e.queueId.toLowerCase().contains(s) || e.clientId.toLowerCase().contains(s)).toList();
    }
    
    final tPages = (fData.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    final pagedList = fData.sublist(start, end > fData.length ? fData.length : end);
    final activeCount = _data.length;
    final inactiveCount = 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Loan Applications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: inactiveCount),
        ]),
        const SizedBox(height: 16),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        SizedBox(
          width: 300, height: 40,
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search Queue ID / Client ID...',
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
          onPressed: () => _setView(MFView.create),
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
      _card(child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3050),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(flex: 2, child: Text('QUEUE ID', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              Expanded(flex: 2, child: Text('GROUP CODE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              Expanded(flex: 2, child: Text('CLIENT ID', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              Expanded(flex: 2, child: Text('PRODUCT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              Expanded(flex: 2, child: Text('SOURCE', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              const SizedBox(width: 110, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
            ]),
          ),
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              const Text('Failed to load data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(_loadError!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ]))
          )
        else if (pagedList.isEmpty)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFCBD5E1)), const SizedBox(height: 16),
            Text('No records found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
          ])))
        else
          ListView.separated(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            itemCount: pagedList.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (_, i) {
              final e = pagedList[i];
              return Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Expanded(flex: 2, child: Text(e.queueId, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                  Expanded(flex: 2, child: Text(e.groupCode ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                  Expanded(flex: 2, child: Text(e.clientId, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                  Expanded(flex: 2, child: Text(e.productCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                  Expanded(flex: 2, child: Text(e.sourceSystem ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                  SizedBox(width: 110, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _setView(MFView.view, e)), const SizedBox(width: 6),
                    _rowBtn(Icons.edit_rounded, const Color(0xFF1E3050), () => _setView(MFView.edit, e)), const SizedBox(width: 6),
                    _rowBtn(Icons.delete_rounded, const Color(0xFFDC2626), () => _delete(e.queueId)),
                  ])),
                ]),
              );
            },
          ),
      ]))),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MFPaginationControls(
            currentPage: _currentPage,
            totalPages: tPages,
            onPrev: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            onNext: _currentPage < tPages ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    ]));
  }

  Widget _form() {
    final isView = _view == MFView.view;
    final isEdit = _view == MFView.edit;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
              onPressed: () { _formErr = null; _setView(MFView.list); },
              tooltip: 'Back to list',
            ),
            const SizedBox(width: 8),
            Text('${_view == MFView.create ? 'New' : (_view == MFView.edit ? 'Edit' : 'View')} Loan Application',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          ]),
          const SizedBox(height: 24),
          
          if (_formErr != null)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(_formErr!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500))),
              ]),
            ),
          _card(child: Padding(
            padding: const EdgeInsets.all(24),
            child: LayoutBuilder(builder: (context, constraints) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('APPLICATION DETAILS'),
                const SizedBox(height: 32),
                Wrap(spacing: 24, runSpacing: 32, children: [
                  _fieldBox(MFApiDropdownField(
                    label: 'Group Code',
                    icon: Icons.group,
                    required: true,
                    items: _groupList.map((g) => {'id': g.groupCode, 'display': '${g.groupCode} - ${g.groupName}'}).toList(),
                    displayKeys: const ['display'],
                    selectedItem: _groupCtrl.text.isNotEmpty ? {'display': '${_groupCtrl.text} - ${_groupList.where((g) => g.groupCode == _groupCtrl.text).map((g) => g.groupName).join('')}'} : null,
                    onChanged: (v) {
                      setState(() {
                        _groupCtrl.text = v?['id'] ?? '';
                        if (_groupCtrl.text.isNotEmpty && _clientCtrl.text.isNotEmpty) {
                          bool validClient = _groupMapList.any((m) => m.groupCode == _groupCtrl.text && m.clientId == _clientCtrl.text && m.memberStatus == 'A');
                          if (!validClient) _clientCtrl.text = '';
                        }
                      });
                    },
                    enabled: !isView,
                  ), constraints),
                  _fieldBox(MFApiDropdownField(
                    label: 'Client ID',
                    icon: Icons.person_outline,
                    required: true,
                    items: _cifList.where((c) => _groupCtrl.text.isEmpty || _groupMapList.any((m) => m.groupCode == _groupCtrl.text && m.clientId == c.cifId && m.memberStatus == 'A')).map((c) => {'id': c.cifId, 'display': '${c.cifId} - ${c.fullName}'}).toList(),
                    displayKeys: const ['display'],
                    selectedItem: _clientCtrl.text.isNotEmpty ? {'display': '${_clientCtrl.text} - ${_cifList.where((c) => c.cifId == _clientCtrl.text).map((c) => c.fullName).join('')}'} : null,
                    onChanged: (v) {
                      _clientCtrl.text = v?['id'] ?? '';
                      if (_clientCtrl.text.isNotEmpty) {
                        try {
                          final match = _groupMapList.firstWhere(
                            (m) => m.clientId == _clientCtrl.text && m.memberStatus == 'A'
                          );
                          _groupCtrl.text = match.groupCode;
                        } catch (e) { _groupCtrl.text = ''; }
                      } else { _groupCtrl.text = ''; }
                      setState(() {});
                    },
                    enabled: !isView,
                  ), constraints),
                  _fieldBox(MFApiDropdownField(
                    label: 'Product Code',
                    icon: Icons.account_balance,
                    required: true,
                    items: _productList.map((p) => {'id': p.productCode, 'display': '${p.productCode} - ${p.productName}'}).toList(),
                    displayKeys: const ['display'],
                    selectedItem: _prodCtrl.text.isNotEmpty ? {'display': '${_prodCtrl.text} - ${_productList.where((p) => p.productCode == _prodCtrl.text).map((p) => p.productName).join('')}'} : null,
                    onChanged: (v) => setState(() => _prodCtrl.text = v?['id'] ?? ''),
                    enabled: !isView,
                  ), constraints),
                  _fieldBox(MFFloatingLabelField(
                    label: 'Queue ID', required: true, ctrl: _queueIdCtrl, icon: Icons.queue, readOnly: isView || isEdit, showLock: isView || isEdit,
                  ), constraints),
                  _fieldBox(MFFloatingLabelField(
                    label: 'Currency Code', required: true, ctrl: _currCtrl, icon: Icons.money, readOnly: isView, showLock: isView,
                  ), constraints),
                  _fieldBox(MFApiDropdownField(
                    label: 'Source System', required: true, icon: Icons.desktop_windows, selectedItem: {'id': _sourceSysCtrl.text}, items: const [{'id': 'LOS'}, {'id': 'MANUAL'}], displayKeys: const ['id'], onChanged: (v) { if (v != null) setState(() => _sourceSysCtrl.text = v['id'] ?? 'MANUAL'); }, enabled: !isView,
                  ), constraints),
                ]),
                const SizedBox(height: 32),
                _secHdr('APPROVAL DETAILS'),
                const SizedBox(height: 32),
                Wrap(spacing: 24, runSpacing: 32, children: [
                  _fieldBox(MFFloatingLabelField(
                    label: 'Approved Amount', required: true, ctrl: _apprAmtCtrl, icon: Icons.attach_money, readOnly: isView, showLock: isView,
                  ), constraints),
                  _fieldBox(MFFloatingLabelField(
                    label: 'Approved Tenure (Months)', required: true, ctrl: _apprTenureCtrl, icon: Icons.calendar_today, readOnly: isView, showLock: isView,
                  ), constraints),
                  _fieldBox(MFFloatingLabelField(
                    label: 'Approved Interest Rate', required: true, ctrl: _apprIntRateCtrl, icon: Icons.percent, readOnly: isView, showLock: isView,
                  ), constraints),
                ]),
              ]);
            }),
          )),
          
          if (!isView) ...[
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                onPressed: () { _formErr = null; _setView(MFView.list); },
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('CANCEL', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                ),
                child: Text(_view == MFView.create ? 'CREATE' : 'SAVE CHANGES', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ]),
          ]
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: EdgeInsets.zero,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _view == MFView.list ? _list() : _form(),
    );
  }
}
