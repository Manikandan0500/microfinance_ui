import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/loan_product_api_service.dart';
import 'models/loan_product_master.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class LoanProductMasterScreen extends StatefulWidget {
  const LoanProductMasterScreen({super.key});

  @override
  State<LoanProductMasterScreen> createState() => _LoanProductMasterScreenState();
}

class _LoanProductMasterScreenState extends State<LoanProductMasterScreen> {
  MFView _view = MFView.list;
  LoanProductMaster? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<LoanProductMaster> _data = [];
  String _currentOrgCode = '101';

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _productNameCtrl = TextEditingController();
  final _minAmountCtrl = TextEditingController();
  final _maxAmountCtrl = TextEditingController();
  final _interestRateCtrl = TextEditingController();
  String _interestType = 'Reducing'; // Flat, Reducing
  String _rateType = 'Fixed'; // Fixed, Floating
  final _benchmarkRateCodeCtrl = TextEditingController(text: 'BASE-RATE');
  final _minTenureCtrl = TextEditingController();
  final _maxTenureCtrl = TextEditingController();
  String _repayFrequency = 'Monthly'; // Monthly, Weekly, Fortnightly
  final _prinGlCtrl = TextEditingController();
  final _intGlCtrl = TextEditingController();
  final _penalGlCtrl = TextEditingController();
  bool _productStatus = true;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadProducts();
  }

  Future<void> _initUserAndLoadProducts() async {
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
      final products = await LoanProductApiService.getProducts(_currentOrgCode);
      if (mounted) {
        setState(() {
          _data = products;
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

  List<LoanProductMaster> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((l) {
      return l.productCode.toLowerCase().contains(q) || 
             l.productName.toLowerCase().contains(q);
    }).toList();
  }

  void _go(MFView v, [LoanProductMaster? r]) {
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
    _productCodeCtrl.clear();
    _productNameCtrl.clear();
    _minAmountCtrl.clear();
    _maxAmountCtrl.clear();
    _interestRateCtrl.clear();
    _interestType = 'Reducing';
    _rateType = 'Fixed';
    _benchmarkRateCodeCtrl.text = 'BASE-RATE';
    _minTenureCtrl.clear();
    _maxTenureCtrl.clear();
    _repayFrequency = 'Monthly';
    _prinGlCtrl.clear();
    _intGlCtrl.clear();
    _penalGlCtrl.clear();
    _productStatus = true;
  }

  void _loadRecord(LoanProductMaster r) {
    _orgCodeCtrl.text = r.orgCode;
    _productCodeCtrl.text = r.productCode;
    _productNameCtrl.text = r.productName;
    _minAmountCtrl.text = r.minAmount.toString();
    _maxAmountCtrl.text = r.maxAmount.toString();
    _interestRateCtrl.text = r.interestRate.toString();
    _interestType = r.interestType;
    _rateType = r.rateType;
    _benchmarkRateCodeCtrl.text = r.benchmarkRateCode;
    _minTenureCtrl.text = r.minTenureMonths.toString();
    _maxTenureCtrl.text = r.maxTenureMonths.toString();
    _repayFrequency = r.repayFrequency;
    _prinGlCtrl.text = r.prinGl;
    _intGlCtrl.text = r.intGl;
    _penalGlCtrl.text = r.penalGl;
    _productStatus = r.productStatus;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (_formKey.currentState!.validate()) {
      final record = LoanProductMaster(
        orgCode: _orgCodeCtrl.text,
        productCode: _productCodeCtrl.text,
        productName: _productNameCtrl.text,
        minAmount: double.tryParse(_minAmountCtrl.text) ?? 0.0,
        maxAmount: double.tryParse(_maxAmountCtrl.text) ?? 0.0,
        interestRate: double.tryParse(_interestRateCtrl.text) ?? 0.0,
        interestType: _interestType,
        rateType: _rateType,
        benchmarkRateCode: _benchmarkRateCodeCtrl.text,
        minTenureMonths: int.tryParse(_minTenureCtrl.text) ?? 0,
        maxTenureMonths: int.tryParse(_maxTenureCtrl.text) ?? 0,
        repayFrequency: _repayFrequency,
        prinGl: _prinGlCtrl.text,
        intGl: _intGlCtrl.text,
        penalGl: _penalGlCtrl.text,
        productStatus: _productStatus,
      );

      setState(() => _isLoading = true);
      try {
        if (isEdit) {
          await LoanProductApiService.updateProduct(record);
          showSuccessDialog(context, 'Loan Product updated successfully!', onConfirm: () => _go(MFView.list));
        } else {
          await LoanProductApiService.createProduct(record);
          showSuccessDialog(context, 'Loan Product created successfully!', onConfirm: () => _go(MFView.list));
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
    _productNameCtrl.dispose();
    _minAmountCtrl.dispose();
    _maxAmountCtrl.dispose();
    _interestRateCtrl.dispose();
    _benchmarkRateCodeCtrl.dispose();
    _minTenureCtrl.dispose();
    _maxTenureCtrl.dispose();
    _prinGlCtrl.dispose();
    _intGlCtrl.dispose();
    _penalGlCtrl.dispose();
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
    final pagedList = list.isEmpty ? <LoanProductMaster>[] : list.sublist(startIndex, endIndex);

    final int activeCount = _data.where((e) => e.productStatus).length;
    final int inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Loan Product Master'),
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
                hintText: 'Search products...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12), isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _fBtn('New Product', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
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
              Expanded(flex: 2, child: _colHdr('PRODUCT NAME')),
              Expanded(child: _colHdr('INT RATE')),
              Expanded(child: _colHdr('RATE TYPE')),
              Expanded(child: _colHdr('AMOUNT RANGE')),
              Expanded(child: _colHdr('TENURE RANGE')),
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
                    Expanded(child: Text(r.productCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.productName, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.interestRate}% (${r.interestType})', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.rateType, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.minAmount.toInt()} - ${r.maxAmount.toInt()}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.minTenureMonths}m - ${r.maxTenureMonths}m', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusBadge(r.productStatus))),
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
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(
              title: isView ? 'View Loan Product' : (isEdit ? 'Edit Loan Product' : 'Create Loan Product'),
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
                  Expanded(child: Text('Editing an existing loan product may affect active loans.', style: TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
                ]),
              ),
            _card(child: Form(key: _formKey, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('PRODUCT DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Product Code', ctrl: _productCodeCtrl, icon: Icons.code, required: !isView,
                    readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Product Name', ctrl: _productNameCtrl, icon: Icons.badge, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('LOAN PARAMETERS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Min Amount', ctrl: _minAmountCtrl, icon: Icons.attach_money, required: !isView,
                    keyboardType: TextInputType.number,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Max Amount', ctrl: _maxAmountCtrl, icon: Icons.monetization_on, required: !isView,
                    keyboardType: TextInputType.number,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Min Tenure (Months)', ctrl: _minTenureCtrl, icon: Icons.calendar_today, required: !isView,
                    keyboardType: TextInputType.number,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Max Tenure (Months)', ctrl: _maxTenureCtrl, icon: Icons.date_range, required: !isView,
                    keyboardType: TextInputType.number,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Repayment Frequency', icon: Icons.repeat, required: !isView,
                    items: const [{'id': 'Monthly', 'name': 'Monthly'}, {'id': 'Weekly', 'name': 'Weekly'}, {'id': 'Fortnightly', 'name': 'Fortnightly'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _repayFrequency, 'name': _repayFrequency},
                    onChanged: (v) { if (v != null) setState(() => _repayFrequency = v['id']!); },
                    enabled: !isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('INTEREST SETTINGS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Interest Rate (%)', ctrl: _interestRateCtrl, icon: Icons.percent, required: !isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Interest Type', icon: Icons.timeline, required: !isView,
                    items: const [{'id': 'Flat', 'name': 'Flat'}, {'id': 'Reducing', 'name': 'Reducing'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _interestType, 'name': _interestType},
                    onChanged: (v) { if (v != null) setState(() => _interestType = v['id']!); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Rate Type', icon: Icons.trending_up, required: !isView,
                    items: const [{'id': 'Fixed', 'name': 'Fixed'}, {'id': 'Floating', 'name': 'Floating'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _rateType, 'name': _rateType},
                    onChanged: (v) { if (v != null) setState(() => _rateType = v['id']!); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Benchmark Rate Code', ctrl: _benchmarkRateCodeCtrl, icon: Icons.show_chart,
                    readOnly: isView, showLock: isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('GL ACCOUNTS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Principal GL Code', ctrl: _prinGlCtrl, icon: Icons.account_balance_wallet, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Interest GL Code', ctrl: _intGlCtrl, icon: Icons.savings, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Penal GL Code', ctrl: _penalGlCtrl, icon: Icons.gavel, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('SETTINGS'),
                const SizedBox(height: 16),
                Container(
                  width: 300, height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    Switch(
                      value: _productStatus,
                      onChanged: !isView ? ((v) => setState(() => _productStatus = v)) : null,
                      activeColor: const Color(0xFF1E3050),
                      activeTrackColor: const Color(0xFFCBD5E1),
                    ),
                  ]),
                ),
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
        _pageHeader(title: 'Loan Product Details', actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          const SizedBox(width: 10),
          _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, r)),
        ]),
        _card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_balance, color: Color(0xFF1E3050))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.productCode} - ${r.productName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  _statusBadge(r.productStatus),
                  const SizedBox(width: 12),
                  const Icon(Icons.apartment, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                  Text('Org: ${r.orgCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ]),
              ])),
            ]),
            const SizedBox(height: 32),
            _secHdr('PARAMETERS'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Amount Range', '${r.minAmount} - ${r.maxAmount}'),
              _info('Tenure Range', '${r.minTenureMonths} - ${r.maxTenureMonths} months'),
              _info('Repayment Freq', r.repayFrequency),
            ]),
            const SizedBox(height: 32),
            _secHdr('INTEREST'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Interest Rate', '${r.interestRate}%'),
              _info('Interest Type', r.interestType),
              _info('Rate Type', r.rateType),
              _info('Benchmark Rate', r.benchmarkRateCode),
            ]),
            const SizedBox(height: 32),
            _secHdr('GL ACCOUNTS'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Principal GL', r.prinGl),
              _info('Interest GL', r.intGl),
              _info('Penal GL', r.penalGl),
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
              _delRow('Product Code', r.productCode),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Product Name', r.productName),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Interest Rate', '${r.interestRate}%'),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Principal GL', r.prinGl),
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
