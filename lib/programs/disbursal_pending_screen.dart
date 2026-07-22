import 'package:flutter/material.dart';
import 'mf_shared_widgets.dart';
import 'models/disbursal_queue.dart';
import 'services/disbursal_api_service.dart';
import 'mock_database.dart';

class DisbursalPendingScreen extends StatefulWidget {
  const DisbursalPendingScreen({super.key});
  @override
  State<DisbursalPendingScreen> createState() => _DisbursalPendingScreenState();
}

class _DisbursalPendingScreenState extends State<DisbursalPendingScreen> {
  MFView _view = MFView.list;
  PendingDisbursal? _selPending;
  DisbursalQueue? _selQueue;
  
  List<PendingDisbursal> _data = [];
  String _search = '';
  int _page = 1;
  final int _size = 10;
  bool _isLoading = false;

  final _queueIdCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();
  final _sourceSystemCtrl = TextEditingController();
  final _sourceRefNoCtrl = TextEditingController();
  final _groupCodeCtrl = TextEditingController();
  final _queuedDateCtrl = TextEditingController();

  final _productCodeCtrl = TextEditingController();
  final _approvedTenureCtrl = TextEditingController();
  final _approvedInterestRateCtrl = TextEditingController();
  final _loanAccountNoCtrl = TextEditingController();
  final _disbursementSeqNoCtrl = TextEditingController();
  final _bankRefNoCtrl = TextEditingController();
  final _disbursedByUserCtrl = TextEditingController();
  final _disbursementDateCtrl = TextEditingController();
  final _accPostingRefCtrl = TextEditingController();
  String _disbursementMode = 'Bank';
  String _accPostingStatus = 'Pending';
  String _clientType = 'I';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _data = await DisbursalApiService.getPendingDisbursals();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DisbursalQueue? _findQueueRecord(PendingDisbursal pending) {
    final clientId = pending.loanAccountNo.replaceFirst('L-', '');
    try {
      return MockDatabase().disbursalQueue.firstWhere((q) => q.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  void _go(MFView v, [PendingDisbursal? r]) {
    setState(() {
      _view = v;
      if (r != null) {
        _selPending = r;
        _selQueue = _findQueueRecord(r);
        final queue = _selQueue;

        _queueIdCtrl.text = queue?.queueId ?? '';
        _clientIdCtrl.text = queue?.clientId ?? '';
        _loanAmtCtrl.text = queue?.approvedAmount.toStringAsFixed(2) ?? r.disbursementAmount.toStringAsFixed(2);
        _sourceSystemCtrl.text = queue?.sourceSystem ?? '';
        _sourceRefNoCtrl.text = queue?.sourceRefNo ?? '';
        _groupCodeCtrl.text = queue?.groupCode ?? '';
        _queuedDateCtrl.text = queue?.queuedDate.toIso8601String().substring(0, 10) ?? '';

        _productCodeCtrl.text = queue?.productCode ?? '';
        _approvedTenureCtrl.text = (queue?.approvedTenureMonths ?? 0) > 0 ? queue!.approvedTenureMonths.toString() : '';
        _approvedInterestRateCtrl.text = (queue?.approvedInterestRate ?? 0) > 0 ? queue!.approvedInterestRate.toString() : '';
        _loanAccountNoCtrl.text = r.loanAccountNo;
        _disbursementSeqNoCtrl.text = r.disbursementSeqNo.toString();
        _bankRefNoCtrl.text = r.bankRefNo ?? '';
        _disbursedByUserCtrl.text = r.disbursedByUserId;
        _disbursementDateCtrl.text = r.disbursementDate.toIso8601String().substring(0, 10);
        _accPostingRefCtrl.text = r.accPostingRef ?? '';
        _disbursementMode = r.disbursementMode;
        _accPostingStatus = r.accPostingStatus ?? 'Pending';
      }
    });
  }

  Future<void> _submitToAuthQueue() async {
    if (_loanAccountNoCtrl.text.isEmpty || _productCodeCtrl.text.isEmpty) return;
    if (_selPending == null || _selQueue == null) return;

    final updatedPending = _selPending!.copyWith(
      loanAccountNo: _loanAccountNoCtrl.text.trim(),
      disbursementSeqNo: int.tryParse(_disbursementSeqNoCtrl.text) ?? 1,
      disbursementAmount: double.tryParse(_loanAmtCtrl.text) ?? _selPending!.disbursementAmount,
      currencyCode: 'INR',
      disbursementMode: _disbursementMode,
      bankRefNo: _bankRefNoCtrl.text.trim(),
      disbursedByUserId: _disbursedByUserCtrl.text.trim(),
      disbursementDate: DateTime.tryParse(_disbursementDateCtrl.text) ?? DateTime.now(),
      disbursementStatus: 'Pending Authorization',
      accPostingRef: _accPostingRefCtrl.text.trim(),
      accPostingStatus: 'Pending',
    );

    final updatedQueue = _selQueue!.copyWith(
      productCode: _productCodeCtrl.text.trim(),
      approvedTenureMonths: int.tryParse(_approvedTenureCtrl.text) ?? _selQueue!.approvedTenureMonths,
      approvedInterestRate: double.tryParse(_approvedInterestRateCtrl.text) ?? _selQueue!.approvedInterestRate,
    );

    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.submitToAuthQueue(updatedPending.loanAccountNo, updatedPending, updatedQueue);
      await _loadData();
      } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: onTap == null ? bg.withValues(alpha: 0.5) : bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: onTap == null ? border.withValues(alpha: 0.5) : border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _rowBtn(IconData icon, Color c, VoidCallback onTap) =>
      MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap, child: Icon(icon, size: 18, color: c)));

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading && _view == MFView.list
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3050)))
          : switch (_view) {
              MFView.list   => _list(),
              MFView.create => const SizedBox(), // not used
              MFView.view   => _form(isView: true),
              MFView.edit   => _form(isEdit: true),
              MFView.delete => const SizedBox(), // not used
            },
    );
  }

  // ── List View ──────────────────────────────────────────────────────────────
    Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.loanAccountNo.toLowerCase().contains(q) || r.disbursementStatus.toLowerCase().contains(q);
    }).toList();

    final pages = (filtered.length / _size).ceil();
    final start = (_page - 1) * _size;
    final end = (start + _size > filtered.length) ? filtered.length : start + _size;
    final items = filtered.isEmpty ? <PendingDisbursal>[] : filtered.sublist(start, end);

    // Grouping for status cards
    final pendingAuthCount = _data.where((r) => r.disbursementStatus == 'Pending Auth').length;
    final pendingInputCount = _data.where((r) => r.disbursementStatus == 'Pending Input').length;

    return Column(children: [
      _pageHeader(title: 'Disbursement Queue', actions: []),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MFActiveInactiveSummary(activeCount: pendingAuthCount, inactiveCount: pendingInputCount),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 280, height: 40,
            child: TextField(
              onChanged: (v) => setState(() { _search = v; _page = 1; }),
              decoration: InputDecoration(
                hintText: 'Search loan accounts...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3050), width: 2)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(color: Color(0xFF1E3050), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: Row(children: [
                  Expanded(flex: 2, child: _colHdr('LOAN ACCOUNT NO')),
                  Expanded(flex: 2, child: _colHdr('AMOUNT')),
                  Expanded(flex: 2, child: _colHdr('MODE')),
                  Expanded(flex: 2, child: _colHdr('STATUS')),
                  Expanded(flex: 2, child: _colHdr('DATE')),
                  const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5), textAlign: TextAlign.right)),
                ]),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No records found', style: TextStyle(color: Color(0xFF64748B)))))
              else
                ...items.asMap().entries.map((e) {
                  final r = e.value;
                  final isLast = e.key == items.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(r.loanAccountNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Text(r.disbursementAmount.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      Expanded(flex: 2, child: Text(r.disbursementMode, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      Expanded(flex: 2, child: _statusBadge(r.disbursementStatus)),
                      Expanded(flex: 2, child: Text(r.disbursementDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _go(MFView.view, r)), const SizedBox(width: 6),
                        if (r.disbursementStatus == 'Pending Input')
                          _rowBtn(Icons.edit_rounded, const Color(0xFF1E3050), () => _go(MFView.edit, r)),
                      ])),
                    ]),
                  );
                }),
              if (pages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Showing $start to $end of ${filtered.length} records', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Row(children: [
                      _pageBtn(Icons.chevron_left, _page > 1 ? () => setState(() => _page--) : null),
                      const SizedBox(width: 8),
                      Text('Page $_page of $pages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      _pageBtn(Icons.chevron_right, _page < pages ? () => setState(() => _page++) : null),
                    ]),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _colHdr(String t) => Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5));
  Widget _pageBtn(IconData icon, VoidCallback? onTap) => MouseRegion(
    cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: onTap == null ? const Color(0xFFF1F5F9) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Icon(icon, size: 16, color: onTap == null ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
      ),
    ),
  );

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFFEF9C3);
    Color fg = const Color(0xFFCA8A04);
    if (status == 'Approved') { bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A); }
    if (status == 'Rejected') { bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); }
    if (status == 'Pending Authorization') { bg = const Color(0xFFDBEAFE); fg = const Color(0xFF2563EB); }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  // ── Form View ──────────────────────────────────────────────────────────────
  Widget _form({bool isEdit = false, bool isView = false}) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(
              title: isView ? 'View Disbursement details' : 'Complete Disbursement',
              actions: [
                _fBtn('Back', Icons.arrow_back_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.list)),
              ],
            ),
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('DISBURSAL DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Client Type', icon: Icons.person_outline, required: false,
                    items: const [{'id': 'I', 'name': 'I Individual'}, {'id': 'C', 'name': 'C Corporate'}, {'id': 'G', 'name': 'G Group'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _clientType, 'name': _clientType == 'I' ? 'I Individual' : _clientType == 'C' ? 'C Corporate' : 'G Group'},
                    onChanged: (v) { if (!isView) setState(() => _clientType = v?['id'] ?? 'I'); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Client ID', ctrl: _clientIdCtrl, icon: Icons.person_outline, required: false,
                    readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Product Code', ctrl: _productCodeCtrl, icon: Icons.category_outlined, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Source System', ctrl: _sourceSystemCtrl, icon: Icons.computer_outlined, required: false,
                    readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Source Ref No', ctrl: _sourceRefNoCtrl, icon: Icons.receipt_long_outlined, required: false,
                    readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Group Code', ctrl: _groupCodeCtrl, icon: Icons.groups_outlined, required: false,
                    readOnly: true, showLock: true,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('FINANCIAL DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Approved Amount', ctrl: _loanAmtCtrl, icon: Icons.currency_rupee, required: false,
                    readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Approved Tenure (Months)', ctrl: _approvedTenureCtrl, icon: Icons.calendar_today_outlined, required: !isView,
                    readOnly: isView, showLock: isView, keyboardType: TextInputType.number,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Approved Interest Rate (%)', ctrl: _approvedInterestRateCtrl, icon: Icons.percent_outlined, required: !isView,
                    readOnly: isView, showLock: isView, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account No', ctrl: _loanAccountNoCtrl, icon: Icons.account_balance_wallet_outlined, required: false,
                    readOnly: true, showLock: true,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('EXECUTION DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Disbursement Date', ctrl: _disbursementDateCtrl, icon: Icons.date_range_outlined, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Disbursement Seq No', ctrl: _disbursementSeqNoCtrl, icon: Icons.format_list_numbered_outlined, required: false,
                    readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Disbursement Mode', icon: Icons.account_balance_outlined, required: !isView,
                    items: const [{'id': 'Bank'}, {'id': 'Cash'}, {'id': 'Cheque'}, {'id': 'NEFT'}, {'id': 'IMPS'}, {'id': 'UPI'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _disbursementMode},
                    onChanged: (v) { if (!isView) setState(() => _disbursementMode = v?['id'] ?? 'Bank'); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Bank Ref No', ctrl: _bankRefNoCtrl, icon: Icons.receipt_outlined, required: false,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Disbursed By User', ctrl: _disbursedByUserCtrl, icon: Icons.person, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('ACCOUNTING INFORMATION'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Acc Posting Ref', ctrl: _accPostingRefCtrl, icon: Icons.receipt_long_outlined, required: false,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Acc Posting Status', icon: Icons.check_circle_outline, required: false,
                    items: const [{'id': 'Pending'}, {'id': 'Posted'}, {'id': 'Failed'}],
                    displayKeys: const ['id'],
                    selectedItem: {'id': _accPostingStatus},
                    onChanged: (v) { if (!isView) setState(() => _accPostingStatus = v?['id'] ?? 'Pending'); },
                    enabled: !isView,
                  )),
                ]),
              ]),
            )),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          const Spacer(),
          if (!isView) ...[
            const SizedBox(width: 12),
            _fBtn('Submit to Authorization', Icons.send_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : _submitToAuthQueue),
          ]
        ]),
      ),
    ]);
  }
}
