import 'package:flutter/material.dart';
import 'mf_shared_widgets.dart';
import 'services/disbursal_api_service.dart';
import 'mock_database.dart';

// Helper class for schedule items
class ScheduleItem {
  final double installmentAmount;
  final String loanAccountNo;
  final double principalDue;
  final double interestDue;
  final double totalDue;
  final DateTime dueDate;
  final int installmentNo;
  final String status;

  ScheduleItem({
    required this.installmentAmount,
    required this.loanAccountNo,
    required this.principalDue,
    required this.interestDue,
    required this.totalDue,
    required this.dueDate,
    required this.installmentNo,
    required this.status,
  });
}

// --------------------------------------------------------------------------
// Disbursement Queue Screen (DISB002)
// Records flow here from Initiate Disbursal (DISB001).
// Users complete all details, generate repayment schedule, and submit to Authorization Queue.
// --------------------------------------------------------------------------
class DisbursalPendingScreen extends StatefulWidget {
  const DisbursalPendingScreen({super.key});
  @override
  State<DisbursalPendingScreen> createState() => _DisbursalPendingScreenState();
}

class _DisbursalPendingScreenState extends State<DisbursalPendingScreen> {
  // ─── Navigation ───────────────────────────────────────────────────────────
  MFView _view = MFView.list;
  PendingDisbursal? _selPending;
  DisbursalQueue? _selQueue;

  // ─── List data ────────────────────────────────────────────────────────────
  List<PendingDisbursal> _data = [];
  String _search = '';
  int _page = 1;
  static const int _pageSize = 10;
  bool _isLoading = false;

  // ─── Form: locked fields from DISB001 ────────────────────────────────────
  String _clientType = 'I'; // read from DisbursalQueue
  final _queueIdCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();
  final _sourceSystemCtrl = TextEditingController();
  final _sourceRefNoCtrl = TextEditingController();
  final _queuedDateCtrl = TextEditingController();

  // ─── Form: Group (only for clientType == 'G') ─────────────────────────────
  String? _selectedGroupId;
  List<Map<String, String>> _groups = [];

  // ─── Form: editable disbursal fields ─────────────────────────────────────
  final _productCodeCtrl = TextEditingController();
  final _approvedTenureCtrl = TextEditingController();
  final _approvedInterestRateCtrl = TextEditingController();
  final _loanAccountNoCtrl = TextEditingController();
  final _disbursementSeqNoCtrl = TextEditingController();
  final _bankRefNoCtrl = TextEditingController();
  final _disbursedByUserCtrl = TextEditingController();
  final _disbursementDateCtrl = TextEditingController();
  final _disbursementAmtCtrl = TextEditingController();
  String _disbursementMode = 'Bank';

  // ─── Repayment Frequency ──────────────────────────────────────────────────
  String _repaymentFrequency = 'Monthly';
  static const List<String> _frequencies = [
    'Monthly',
    'Every 2 Months',
    'Every 3 Months',
    'Half Yearly',
    'Yearly',
  ];

  // ─── Generated Repayment Schedule ─────────────────────────────────────────
  List<ScheduleItem> _repaymentSchedule = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadGroups();
    _disbursementAmtCtrl.addListener(_onDisbursementAmtChanged);
    _approvedTenureCtrl.addListener(_onRepaymentFieldChanged);
    _approvedInterestRateCtrl.addListener(_onRepaymentFieldChanged);
  }

  void _onDisbursementAmtChanged() {
    if (_repaymentSchedule.isNotEmpty) {
      setState(() {
        _repaymentSchedule = [];
      });
    }
  }

  void _onRepaymentFieldChanged() {
    if (_repaymentSchedule.isNotEmpty) {
      setState(() {
        _repaymentSchedule = [];
      });
    }
  }

  String? _disbursementAmountError() {
    final loanAmt = double.tryParse(_loanAmtCtrl.text.trim()) ?? 0.0;
    final disbAmt = double.tryParse(_disbursementAmtCtrl.text.trim()) ?? 0.0;
    if (disbAmt > loanAmt) {
      return 'Disbursement Amount cannot be greater than the Loan Amount.';
    }
    return null;
  }

  @override
  void dispose() {
    _queueIdCtrl.dispose();
    _clientIdCtrl.dispose();
    _loanAmtCtrl.dispose();
    _sourceSystemCtrl.dispose();
    _sourceRefNoCtrl.dispose();
    _queuedDateCtrl.dispose();
    _productCodeCtrl.dispose();
    _approvedTenureCtrl.dispose();
    _approvedInterestRateCtrl.dispose();
    _loanAccountNoCtrl.dispose();
    _disbursementSeqNoCtrl.dispose();
    _bankRefNoCtrl.dispose();
    _disbursedByUserCtrl.dispose();
    _disbursementDateCtrl.dispose();
    _disbursementAmtCtrl.dispose();
    super.dispose();
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await DisbursalApiService.getPendingDisbursals();
      if (mounted) setState(() => _data = records);
    } catch (e) {
      _toast('Failed to load records: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroups() async {
    try {
      final g = await DisbursalApiService.getGroups();
      if (mounted) setState(() => _groups = g);
    } catch (_) {}
  }

  DisbursalQueue? _findQueueFor(PendingDisbursal p) {
    final clientId = p.loanAccountNo.replaceFirst('L-', '');
    try {
      return MockDatabase().disbursalQueue
          .firstWhere((q) => q.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  void _go(MFView v, [PendingDisbursal? r]) {
    setState(() {
      _view = v;
      _repaymentSchedule = []; // reset schedule on view change
      if (r != null) {
        _selPending = r;
        _selQueue = _findQueueFor(r);
        final q = _selQueue;

        // Locked fields from DISB001
        _clientType = q?.clientType ?? 'I';
        _queueIdCtrl.text = q?.queueId ?? '';
        _clientIdCtrl.text = q?.clientId ?? '';
        _loanAmtCtrl.text = q != null
            ? q.approvedAmount.toStringAsFixed(2)
            : r.disbursementAmount.toStringAsFixed(2);
        _sourceSystemCtrl.text = q?.sourceSystem ?? '';
        _sourceRefNoCtrl.text = q?.sourceRefNo ?? '';
        _queuedDateCtrl.text =
            q?.queuedDate.toIso8601String().substring(0, 10) ?? '';

        // Auto-populate Disbursement Amount with the Loan Amount
        _disbursementAmtCtrl.text = q != null
            ? q.approvedAmount.toStringAsFixed(2)
            : r.disbursementAmount.toStringAsFixed(2);

        // Pre-fill group if already set
        _selectedGroupId = (q?.groupCode?.isNotEmpty ?? false)
            ? q!.groupCode
            : null;

        // Editable fields
        _productCodeCtrl.text = q?.productCode ?? '';
        _approvedTenureCtrl.text =
            (q?.approvedTenureMonths ?? 0) > 0
                ? q!.approvedTenureMonths.toString()
                : '12';
        _approvedInterestRateCtrl.text =
            (q?.approvedInterestRate ?? 0) > 0
                ? q!.approvedInterestRate.toString()
                : '12.0';
        _loanAccountNoCtrl.text = r.loanAccountNo;
        _disbursementSeqNoCtrl.text = r.disbursementSeqNo.toString();
        _bankRefNoCtrl.text = r.bankRefNo ?? '';
        _disbursedByUserCtrl.text = r.disbursedByUserId;
        _disbursementDateCtrl.text =
            r.disbursementDate.toIso8601String().substring(0, 10);
        _disbursementMode = r.disbursementMode;
        _repaymentFrequency = 'Monthly';
      }
    });
  }

  // ─── Generate Repayment Schedule Logic ────────────────────────────────────

  void _generateRepaymentSchedule({bool showToast = true}) {
    final amountError = _disbursementAmountError();
    if (amountError != null) {
      if (showToast) _toast(amountError, isError: true);
      return;
    }
    final loanAcc = _loanAccountNoCtrl.text.trim();
    final disbursementAmount = double.tryParse(_disbursementAmtCtrl.text.trim()) ?? 0.0;
    final tenureMonths = int.tryParse(_approvedTenureCtrl.text.trim()) ?? 12;
    final startDate = DateTime.tryParse(_disbursementDateCtrl.text.trim()) ?? DateTime.now();

    if (loanAcc.isEmpty) {
      if (showToast) _toast('Loan Account No is required.', isError: true);
      return;
    }
    if (disbursementAmount <= 0) {
      if (showToast) _toast('Valid Disbursement Amount is required.', isError: true);
      return;
    }

    // Determine installment frequency in months/days
    int monthsInterval = 1;
    if (_repaymentFrequency == 'Every 2 Months') monthsInterval = 2;
    if (_repaymentFrequency == 'Every 3 Months') monthsInterval = 3;
    if (_repaymentFrequency == 'Half Yearly') monthsInterval = 6;
    if (_repaymentFrequency == 'Yearly') monthsInterval = 12;

    int totalInstallments = (tenureMonths / monthsInterval).ceil();
    if (totalInstallments <= 0) totalInstallments = 12;

    double principalDue = disbursementAmount / totalInstallments;
    // Add minor interest component for mock display
    double interestRate = double.tryParse(_approvedInterestRateCtrl.text.trim()) ?? 12.0;
    double interestDue = (disbursementAmount * (interestRate / 100)) / totalInstallments;
    double totalDue = principalDue + interestDue;
    double installmentAmount = totalDue;

    List<ScheduleItem> list = [];
    DateTime currentDate = startDate;

    for (int i = 1; i <= totalInstallments; i++) {
      currentDate = DateTime(currentDate.year, currentDate.month + monthsInterval, currentDate.day);

      list.add(ScheduleItem(
        installmentAmount: installmentAmount,
        loanAccountNo: loanAcc,
        principalDue: principalDue,
        interestDue: interestDue,
        totalDue: totalDue,
        dueDate: currentDate,
        installmentNo: i,
        status: 'Pending',
      ));
    }

    setState(() {
      _repaymentSchedule = list;
    });
    if (showToast) {
      _toast('Repayment schedule generated successfully!', isError: false);
    }
  }

  Future<void> _submitToAuthQueue() async {
    if (_selPending == null || _selQueue == null) return;
    // Validate mandatory Group for Group client type
    if (_clientType == 'G' && (_selectedGroupId == null || _selectedGroupId!.isEmpty)) {
      _toast('Please select a Group before submitting.', isError: true);
      return;
    }
    if (_loanAccountNoCtrl.text.isEmpty || _productCodeCtrl.text.isEmpty) {
      _toast('Loan Account No and Product Code are required.', isError: true);
      return;
    }
    final amountError = _disbursementAmountError();
    if (amountError != null) {
      _toast(amountError, isError: true);
      return;
    }
    final disbursementAmount = double.tryParse(_disbursementAmtCtrl.text.trim()) ?? 0.0;
    if (disbursementAmount <= 0) {
      _toast('Please enter a valid disbursement amount greater than 0.', isError: true);
      return;
    }

    final updatedPending = _selPending!.copyWith(
      loanAccountNo: _loanAccountNoCtrl.text.trim(),
      disbursementSeqNo: int.tryParse(_disbursementSeqNoCtrl.text) ?? 1,
      disbursementAmount: disbursementAmount,
      currencyCode: 'INR',
      disbursementMode: _disbursementMode,
      bankRefNo: _bankRefNoCtrl.text.trim(),
      disbursedByUserId: _disbursedByUserCtrl.text.trim(),
      disbursementDate:
          DateTime.tryParse(_disbursementDateCtrl.text) ?? DateTime.now(),
      disbursementStatus: 'Pending Authorization',
    );

    final updatedQueue = _selQueue!.copyWith(
      productCode: _productCodeCtrl.text.trim(),
      groupCode: _selectedGroupId,
      approvedTenureMonths: int.tryParse(_approvedTenureCtrl.text) ??
          _selQueue!.approvedTenureMonths,
      approvedInterestRate: double.tryParse(_approvedInterestRateCtrl.text) ??
          _selQueue!.approvedInterestRate,
    );

    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.submitToAuthQueue(
          updatedPending.loanAccountNo, updatedPending, updatedQueue);
      _toast('Submitted to Authorization Queue!', isError: false);
      await _loadData();
      setState(() => _view = MFView.list);
    } catch (e) {
      _toast('Submit failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toast(String msg, {required bool isError}) {
    if (!mounted) return;
    MFToast.show(context, msg, isError: isError);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _clientTypeName(String code) {
    switch (code) {
      case 'I': return 'I – Individual';
      case 'C': return 'C – Corporate';
      case 'G': return 'G – Group';
      default:  return code;
    }
  }

  Widget _statusBadge(String s) {
    Color bg, fg;
    switch (s) {
      case 'Completed':             bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A); break;
      case 'Failed':                bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); break;
      case 'Pending Authorization': bg = const Color(0xFFDBEAFE); fg = const Color(0xFF2563EB); break;
      case 'Pending Input':         bg = const Color(0xFFFEF3C7); fg = const Color(0xFFD97706); break;
      default:                      bg = const Color(0xFFF1F5F9); fg = const Color(0xFF64748B);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(s,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  Widget _lockedField(String label, String value, IconData icon) => SizedBox(
        width: 300,
        child: TextFormField(
          initialValue: value,
          readOnly: true,
          style: const TextStyle(
              color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                TextStyle(color: Colors.grey.shade500, fontSize: 14),
            prefixIcon:
                Icon(icon, color: Colors.grey.shade400, size: 20),
            suffixIcon:
                const Icon(Icons.lock_outline, color: Colors.grey, size: 18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      );

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: switch (_view) {
        MFView.list   => _buildList(),
        MFView.view   => _buildForm(isView: true),
        MFView.edit   => _buildForm(isView: false),
        MFView.create => _buildList(),
        MFView.delete => _buildList(),
      },
    );
  }

  // ─── List View ────────────────────────────────────────────────────────────

  Widget _buildList() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty ||
          r.loanAccountNo.toLowerCase().contains(q) ||
          r.disbursementStatus.toLowerCase().contains(q) ||
          r.disbursementMode.toLowerCase().contains(q);
    }).toList();

    final totalPages =
        (filtered.length / _pageSize).ceil().clamp(1, 9999);
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems =
        filtered.isEmpty ? <PendingDisbursal>[] : filtered.sublist(start, end);

    final pendingInputCnt =
        _data.where((r) => r.disbursementStatus == 'Pending Input').length;
    final pendingAuthCnt = _data
        .where((r) => r.disbursementStatus == 'Pending Authorization').length;

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
                    items: const [{'id': 'I', 'name': 'I - Individual'}, {'id': 'C', 'name': 'C - Corporate'}, {'id': 'G', 'name': 'G - Group'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _clientType},
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
