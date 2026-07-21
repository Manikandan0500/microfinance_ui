import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'services/penalty_rate_api_service.dart';
import 'models/penalty_rate_history.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class PenaltyRateHistoryScreen extends StatefulWidget {
  const PenaltyRateHistoryScreen({super.key});

  @override
  State<PenaltyRateHistoryScreen> createState() => _PenaltyRateHistoryScreenState();
}

class _PenaltyRateHistoryScreenState extends State<PenaltyRateHistoryScreen> {
  MFView _view = MFView.list;
  PenaltyRateHistory? _sel;
  bool _delConfirmed = false;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  List<PenaltyRateHistory> _data = [];
  String _currentOrgCode = '1';

  final _formKey = GlobalKey<FormState>();
  final _orgCodeCtrl = TextEditingController();
  final _productCodeCtrl = TextEditingController();
  final _delinquencyCodeCtrl = TextEditingController();
  DateTime _selectedEffDate = DateTime.now();
  String _penaltyType = 'Percentage'; // Percentage, Fixed Amount
  final _penaltyValueCtrl = TextEditingController();
  bool _rateStatus = true;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadRates();
  }

  Future<void> _initUserAndLoadRates() async {
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
      final rates = await PenaltyRateApiService.getRates(_currentOrgCode);
      if (mounted) {
        setState(() {
          _data = rates;
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

  List<PenaltyRateHistory> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) {
      return r.productCode.toLowerCase().contains(q) || 
             r.delinquencyCode.toLowerCase().contains(q);
    }).toList();
  }

  void _go(MFView v, [PenaltyRateHistory? r]) {
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
    _delinquencyCodeCtrl.clear();
    _selectedEffDate = DateTime.now();
    _penaltyType = 'Percentage';
    _penaltyValueCtrl.clear();
    _rateStatus = true;
  }

  void _loadRecord(PenaltyRateHistory r) {
    _orgCodeCtrl.text = r.orgCode;
    _productCodeCtrl.text = r.productCode;
    _delinquencyCodeCtrl.text = r.delinquencyCode;
    _selectedEffDate = r.effDate;
    _penaltyType = r.penaltyType;
    _penaltyValueCtrl.text = r.penaltyValue.toString();
    _rateStatus = r.rateStatus;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (_formKey.currentState!.validate()) {
      final record = PenaltyRateHistory(
        orgCode: _orgCodeCtrl.text,
        productCode: _productCodeCtrl.text,
        delinquencyCode: _delinquencyCodeCtrl.text,
        effDate: _selectedEffDate,
        penaltyType: _penaltyType,
        penaltyValue: double.tryParse(_penaltyValueCtrl.text) ?? 0.0,
        rateStatus: _rateStatus,
      );

      setState(() => _isLoading = true);
      try {
        if (isEdit) {
          await PenaltyRateApiService.updateRate(record);
          showSuccessDialog(context, 'Penalty Rate updated successfully!', onConfirm: () => _go(MFView.list));
        } else {
          await PenaltyRateApiService.createRate(record);
          showSuccessDialog(context, 'Penalty Rate created successfully!', onConfirm: () => _go(MFView.list));
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
    _penaltyValueCtrl.dispose();
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
    final pagedList = list.isEmpty ? <PenaltyRateHistory>[] : list.sublist(startIndex, endIndex);

    final int activeCount = _data.where((e) => e.rateStatus).length;
    final int inactiveCount = _data.length - activeCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Penalty Rate History'),
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
                hintText: 'Search products/delinquency...',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                prefixIcon: Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 12), isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _fBtn('New Penalty Rate', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
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
              Expanded(child: _colHdr('PRODUCT')),
              Expanded(child: _colHdr('DELINQUENCY')),
              Expanded(child: _colHdr('EFFECTIVE DATE')),
              Expanded(child: _colHdr('TYPE')),
              Expanded(child: _colHdr('VALUE')),
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
                    Expanded(child: Text(r.delinquencyCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text('${r.effDate.day.toString().padLeft(2, '0')}-${r.effDate.month.toString().padLeft(2, '0')}-${r.effDate.year}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.penaltyType, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.penaltyType == 'Percentage' ? '${r.penaltyValue}%' : r.penaltyValue.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Align(alignment: Alignment.centerLeft, child: _statusBadge(r.rateStatus))),
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
              title: isView ? 'View Penalty Rate Configuration' : (isEdit ? 'Edit Penalty Rate Configuration' : 'Create Penalty Rate Configuration'),
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
                  Expanded(child: Text('Editing an existing penalty rate affects active loans from the effective date.', style: TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
                ]),
              ),
            _card(child: Form(key: _formKey, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('CONFIGURATION DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Product Code', ctrl: _productCodeCtrl, icon: Icons.shopping_basket, required: !isView,
                    readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Delinquency Code', ctrl: _delinquencyCodeCtrl, icon: Icons.warning_amber_rounded, required: !isView,
                    readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: InkWell(
                    onTap: (isEdit || isView) ? null : () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedEffDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedEffDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: (isEdit || isView) ? const Color(0xFFF8FAFC) : Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, size: 20, color: Color(0xFF64748B)),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Effective Date *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3050))),
                          const SizedBox(height: 4),
                          Text('${_selectedEffDate.day.toString().padLeft(2, '0')}-${_selectedEffDate.month.toString().padLeft(2, '0')}-${_selectedEffDate.year}', style: TextStyle(fontSize: 14, color: (isEdit || isView) ? const Color(0xFF64748B) : const Color(0xFF1E293B))),
                        ]),
                      ]),
                    ),
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('PENALTY VALUE SETTINGS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Penalty Type', icon: Icons.payment, required: !isView,
                    items: const [{'id': 'Percentage', 'name': 'Percentage'}, {'id': 'Fixed Amount', 'name': 'Fixed Amount'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _penaltyType, 'name': _penaltyType},
                    onChanged: (v) { if (v != null) setState(() => _penaltyType = v['id']!); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Penalty Value', ctrl: _penaltyValueCtrl, icon: Icons.money, required: !isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                      value: _rateStatus,
                      onChanged: !isView ? ((v) => setState(() => _rateStatus = v)) : null,
                      activeColor: const Color(0xFF1E3050),
                      activeTrackColor: const Color(0xFFE3F2FD),
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
        _pageHeader(title: 'Penalty Rate Details', actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          const SizedBox(width: 10),
          _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, r)),
        ]),
        _card(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.gavel, color: Color(0xFF1E3050))),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${r.productCode} - ${r.delinquencyCode}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 4),
                Row(children: [
                  _statusBadge(r.rateStatus),
                  const SizedBox(width: 12),
                  const Icon(Icons.apartment, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                  Text('Org: ${r.orgCode}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ]),
              ])),
            ]),
            const SizedBox(height: 32),
            _secHdr('CONFIGURATION'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Product Code', r.productCode),
              _info('Delinquency Code', r.delinquencyCode),
              _info('Effective Date', '${r.effDate.day.toString().padLeft(2, '0')}-${r.effDate.month.toString().padLeft(2, '0')}-${r.effDate.year}'),
            ]),
            const SizedBox(height: 32),
            _secHdr('PENALTY DETAILS'),
            const SizedBox(height: 16),
            Wrap(spacing: 40, runSpacing: 24, children: [
              _info('Penalty Type', r.penaltyType),
              _info('Penalty Value', r.penaltyType == 'Percentage' ? '${r.penaltyValue}%' : r.penaltyValue.toString()),
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
    final dateStr = '${r.effDate.day.toString().padLeft(2, '0')}-${r.effDate.month.toString().padLeft(2, '0')}-${r.effDate.year}';
    
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
              _delRow('Delinquency', r.delinquencyCode),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Effective Date', dateStr),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFE2E8F0))),
              _delRow('Penalty Value', r.penaltyType == 'Percentage' ? '${r.penaltyValue}%' : r.penaltyValue.toString()),
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
