import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/delinquency_bucket_api_service.dart';
import 'services/loan_product_api_service.dart';
import 'models/delinquency_bucket_master.dart';
import 'models/loan_product_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class DelinquencyBucketMasterScreen extends StatefulWidget {
  const DelinquencyBucketMasterScreen({super.key});

  @override
  State<DelinquencyBucketMasterScreen> createState() => _DelinquencyBucketMasterScreenState();
}

class _DelinquencyBucketMasterScreenState extends State<DelinquencyBucketMasterScreen> {
  MFView _view = MFView.list;
  DelinquencyBucketMaster? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<DelinquencyBucketMaster> _data = [];
  List<LoanProductMaster> _loanProducts = [];
  String _currentOrgCode = '101';

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _delinquencyCodeCtrl = TextEditingController();
  final _bucketLabelCtrl = TextEditingController();
  final _overdueDaysFromCtrl = TextEditingController();
  final _overdueDaysToCtrl = TextEditingController();
  final _stageOrderCtrl = TextEditingController();
  final _provisionPctCtrl = TextEditingController();
  bool _isNpaFlagValue = false;
  bool _bucketStatus = true;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadData();
  }

  Future<void> _initUserAndLoadData() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    _resetForm();
    await _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final buckets = await DelinquencyBucketApiService.getBuckets(_currentOrgCode);
      final products = await LoanProductApiService.getProducts(_currentOrgCode);
      if (mounted) {
        setState(() {
          _data = buckets;
          _loanProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  List<DelinquencyBucketMaster> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((d) {
      return d.delinquencyCode.toLowerCase().contains(q) || 
             d.bucketLabel.toLowerCase().contains(q) || 
             d.productCode.toLowerCase().contains(q);
    }).toList();
  }

  void _go(MFView v, [DelinquencyBucketMaster? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _delConfirmed = false;
      if (v == MFView.list) {
        _search = '';
        _currentPage = 1;
      }
    });
    if (v == MFView.list) {
      _fetchData();
    } else if (v == MFView.create) {
      _resetForm();
    } else if (v == MFView.edit || v == MFView.view || v == MFView.delete) {
      if (r != null) _loadRecord(r);
    }
  }

  void _toast(String msg, {bool isError = false}) => MFToast.show(context, msg, isError: isError);

  void _resetForm() {
    _orgCodeCtrl.text = _currentOrgCode;
    _productCodeCtrl.text = _loanProducts.isNotEmpty ? _loanProducts.first.productCode : '';
    _delinquencyCodeCtrl.clear();
    _bucketLabelCtrl.clear();
    _overdueDaysFromCtrl.clear();
    _overdueDaysToCtrl.clear();
    _stageOrderCtrl.clear();
    _provisionPctCtrl.clear();
    _isNpaFlagValue = false;
    _bucketStatus = true;
  }

  void _loadRecord(DelinquencyBucketMaster r) {
    _orgCodeCtrl.text = r.orgCode;
    _productCodeCtrl.text = r.productCode;
    _delinquencyCodeCtrl.text = r.delinquencyCode;
    _bucketLabelCtrl.text = r.bucketLabel;
    _overdueDaysFromCtrl.text = r.overdueDaysFrom.toString();
    _overdueDaysToCtrl.text = r.overdueDaysTo.toString();
    _stageOrderCtrl.text = r.stageOrder.toString();
    _provisionPctCtrl.text = r.provisionPct.toString();
    _isNpaFlagValue = r.isNpaFlag;
    _bucketStatus = r.bucketStatus;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (_formKey.currentState!.validate()) {
      if (_productCodeCtrl.text.isEmpty) {
        _toast('Please select a Product Code', isError: true);
        return;
      }
      
      final record = DelinquencyBucketMaster(
        orgCode: _orgCodeCtrl.text,
        productCode: _productCodeCtrl.text,
        delinquencyCode: _delinquencyCodeCtrl.text,
        bucketLabel: _bucketLabelCtrl.text,
        overdueDaysFrom: int.tryParse(_overdueDaysFromCtrl.text) ?? 0,
        overdueDaysTo: int.tryParse(_overdueDaysToCtrl.text) ?? 0,
        stageOrder: int.tryParse(_stageOrderCtrl.text) ?? 0,
        isNpaFlag: _isNpaFlagValue,
        provisionPct: double.tryParse(_provisionPctCtrl.text) ?? 0.0,
        bucketStatus: _bucketStatus,
      );

      setState(() => _isLoading = true);
      try {
        if (isEdit) {
          await DelinquencyBucketApiService.updateBucket(record);
          showSuccessDialog(context, 'Delinquency Bucket updated successfully!', onConfirm: () => _go(MFView.list));
        } else {
          await DelinquencyBucketApiService.createBucket(record);
          showSuccessDialog(context, 'Delinquency Bucket created successfully!', onConfirm: () => _go(MFView.list));
        }
      } catch (e) {
        _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    if (_sel != null) {
      _toast('Delete not supported by API', isError: true);
      _go(MFView.list);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _orgCodeCtrl.dispose();
    _productCodeCtrl.dispose();
    _delinquencyCodeCtrl.dispose();
    _bucketLabelCtrl.dispose();
    _overdueDaysFromCtrl.dispose();
    _overdueDaysToCtrl.dispose();
    _stageOrderCtrl.dispose();
    _provisionPctCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9),
    body: switch (_view) {
      MFView.list   => _list(),
      MFView.create => _form(isEdit: false),
      MFView.view   => _form(isView: true),
      MFView.edit   => _form(isEdit: true),
      MFView.delete => _delete(),
    },
  );

  // ── List View ──────────────────────────────────────────────────────────────
  Widget _list() {
    final list = _filtered;
    final int totalPages = (list.length / _itemsPerPage).ceil();
    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage > list.length) ? list.length : startIndex + _itemsPerPage;
    final pagedList = list.isEmpty ? <DelinquencyBucketMaster>[] : list.sublist(startIndex, endIndex);

    final int activeCount = _data.where((e) => e.bucketStatus).length;
    final int inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Delinquency Bucket Master'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: inactiveCount),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(
            width: 280, height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: const InputDecoration(
                hintText: 'Search buckets...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12), isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _fBtn('New Bucket', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
        ]),
        const SizedBox(height: 16),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3050),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(child: _colHdr('PRODUCT CODE')),
              Expanded(child: _colHdr('BUCKET CODE')),
              Expanded(flex: 2, child: _colHdr('LABEL')),
              Expanded(child: _colHdr('DAYS RANGE')),
              Expanded(child: _colHdr('ORDER')),
              Expanded(child: _colHdr('PROVISION')),
              Expanded(child: _colHdr('NPA')),
              Expanded(child: _colHdr('STATUS')),
              const SizedBox(width: 110, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
            ]),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
          else if (_loadError != null)
            Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
              const Text('Failed to load data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))), const SizedBox(height: 8),
              Text(_loadError!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ])))
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
                final r = pagedList[i];
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(child: Text(r.productCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.delinquencyCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.bucketLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.overdueDaysFrom} - ${r.overdueDaysTo}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.stageOrder}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.provisionPct}%', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _boolIcon(r.isNpaFlag))),
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusBadge(r.bucketStatus))),
                    SizedBox(width: 110, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _go(MFView.view, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.edit_rounded, const Color(0xFF1E3050), () => _go(MFView.edit, r)), const SizedBox(width: 6),
                      _rowBtn(Icons.delete_rounded, const Color(0xFFDC2626), () => _go(MFView.delete, r)),
                    ])),
                  ]),
                );
              },
            ),
        ])),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MFPaginationControls(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPrev: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
              onNext: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ]),
    );
  }

  Widget _form({bool isEdit = false, bool isView = false}) {
    final productItems = _loanProducts.map((p) => {'id': p.productCode, 'name': p.productName}).toList();
    
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(
              title: isView ? 'View Delinquency Bucket' : (isEdit ? 'Edit Delinquency Bucket' : 'Create Delinquency Bucket'),
              actions: [
                _fBtn('Back', Icons.arrow_back_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.list)),
              ],
            ),
            if (isEdit)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFFDE68A))),
                child: const Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFB45309)), const SizedBox(width: 10),
                  Expanded(child: Text('Editing an existing bucket may affect financial reporting.', style: TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
                ]),
              ),
            _card(child: Form(key: _formKey, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('BUCKET DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                    SizedBox(width: 300, child: MFApiDropdownField(
                      label: 'Product Code', icon: Icons.shopping_basket, required: !isView,
                      items: productItems,
                      displayKeys: const ['id', 'name'],
                      selectedItem: _productCodeCtrl.text.isNotEmpty ? productItems.firstWhere((e) => e['id'] == _productCodeCtrl.text, orElse: () => {'id': _productCodeCtrl.text, 'name': ''}) : null,
                      onChanged: (v) { if (v != null) setState(() => _productCodeCtrl.text = v['id']); },
                      enabled: !isEdit && !isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Delinquency Code', ctrl: _delinquencyCodeCtrl, icon: Icons.code, required: !isView,
                      readOnly: isEdit || isView, showLock: isEdit || isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Bucket Label', ctrl: _bucketLabelCtrl, icon: Icons.label, required: !isView,
                      readOnly: isView, showLock: isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Overdue Days From', ctrl: _overdueDaysFromCtrl, icon: Icons.hourglass_empty, required: !isView,
                      keyboardType: TextInputType.number,
                      readOnly: isView, showLock: isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Overdue Days To', ctrl: _overdueDaysToCtrl, icon: Icons.hourglass_full, required: !isView,
                      keyboardType: TextInputType.number,
                      readOnly: isView, showLock: isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Stage Order', ctrl: _stageOrderCtrl, icon: Icons.format_list_numbered, required: !isView,
                      keyboardType: TextInputType.number,
                      readOnly: isView, showLock: isView,
                    )),
                    SizedBox(width: 300, child: MFFloatingLabelField(
                      label: 'Provision Percentage (%)', ctrl: _provisionPctCtrl, icon: Icons.percent, required: !isView,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      readOnly: isView, showLock: isView,
                    )),
                  ]),
                const SizedBox(height: 32),
                _secHdr('SETTINGS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  Container(
                    width: 300, height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Is NPA?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      Switch(
                        value: _isNpaFlagValue,
                        onChanged: !isView ? ((v) => setState(() => _isNpaFlagValue = v)) : null,
                        activeColor: const Color(0xFFDC2626),
                        activeTrackColor: const Color(0xFFFEE2E2),
                      ),
                    ]),
                  ),
                  Container(
                    width: 300, height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                      Switch(
                        value: _bucketStatus,
                        onChanged: !isView ? ((v) => setState(() => _bucketStatus = v)) : null,
                        activeColor: const Color(0xFF1E3050),
                        activeTrackColor: const Color(0xFFE3F2FD),
                      ),
                    ]),
                  ),
                ]),
              ]),
            ))),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          const Spacer(),
          if (!isView) ...[
            const SizedBox(width: 12),
            _fBtn(isEdit ? 'Save Changes' : 'Create Record', isEdit ? Icons.save_rounded : Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
          ]
        ]),
      ),
    ]);
  }

  // ── Detail View ────────────────────────────────────────────────────────────
  Widget _detail() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Delinquency Bucket Details', actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          const SizedBox(width: 10),
          _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, r)),
        ]),
        _card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment_late, color: Color(0xFF1E3050))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.delinquencyCode} ${r.bucketLabel}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  _statusBadge(r.bucketStatus),
                  const SizedBox(width: 12),
                  const Icon(Icons.shopping_basket, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                  Text('Product: ${r.productCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  const Icon(Icons.apartment, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                  Text('Org: ${r.orgCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ]),
              ])),
            ]),
            const SizedBox(height: 32),
            _secHdr('PROPERTIES'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Days Range', '${r.overdueDaysFrom} - ${r.overdueDaysTo} days'),
              _info('Stage Order', r.stageOrder.toString()),
              _info('Provision %', '${r.provisionPct}%'),
              SizedBox(
                width: 200,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('NPA Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  Row(children: [
                    _boolIcon(r.isNpaFlag),
                    const SizedBox(width: 6),
                    Text(r.isNpaFlag ? 'Yes' : 'No', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                  ])
                ]),
              ),
            ]),
          ]),
        )),
      ]),
    );
  }

  // ── Delete View ────────────────────────────────────────────────────────────
  Widget _delete() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    
    return Center(child: Container(
      width: 500, margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626))),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delete Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
              Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
            ])),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(children: [
              _delRow('Product', r.productCode),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Bucket Code', r.delinquencyCode),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Label', r.bucketLabel),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Days Range', '${r.overdueDaysFrom} - ${r.overdueDaysTo} days'),
            ]),
          ),
          const SizedBox(height: 24),
          Row(children: [
            SizedBox(
              width: 24, height: 24,
              child: Checkbox(
                value: _delConfirmed,
                onChanged: (v) => setState(() => _delConfirmed = v ?? false),
                activeColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('I understand that deleting this record is permanent.', style: TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
          ]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            
            const SizedBox(width: 12),
            _fBtn('Confirm Delete', Icons.delete_rounded, const Color(0xFFDC2626), Colors.white, const Color(0xFFDC2626), onTap: _delConfirmed ? _confirmDelete : null),
          ]),
        ),
      ]),
    ));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _pageHeader({required String title, List<Widget> actions = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3))),
          ...actions,
        ]),
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _statCard(String num, String lbl, Color numC, Color bg, Color border, IconData icon, Color iconC) =>
      Container(
        width: 180,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconC)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: numC, height: 1.1)),
            Text(lbl, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ]),
        ]),
      );

  Widget _hBtn(String label, {Color bg = Colors.white, Color fg = const Color(0xFF64748B), Color border = const Color(0xFFE2E8F0), IconData? icon, VoidCallback? onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: onTap == null ? bg.withOpacity(0.5) : bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: onTap == null ? border.withOpacity(0.5) : border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      );

  Widget _secHdr(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E3050), letterSpacing: 1)),
    ]),
  );

  Widget _statusBadge(bool active) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? const Color(0xFF16A34A).withOpacity(0.3) : const Color(0xFFDC2626).withOpacity(0.3))),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626), shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(active ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
      ]),
    ),
  );

  Widget _boolIcon(bool val) => Icon(
    val ? Icons.check_circle_rounded : Icons.cancel_rounded,
    size: 16,
    color: val ? const Color(0xFFDC2626) : const Color(0xFF16A34A), // NPA true = bad (red), NPA false = good (green)
  );

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _info(String lbl, String val) => SizedBox(
    width: 200,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(lbl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
      const SizedBox(height: 4),
      Text(val.isEmpty ? '—' : val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
    ]),
  );

  Widget _delRow(String lbl, String val) => Row(children: [
    SizedBox(width: 100, child: Text(lbl, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
    Expanded(child: Text(val.isEmpty ? '—' : val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
  ]);
}
