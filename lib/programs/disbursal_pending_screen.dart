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
      disbursementStatus: 'COMPLETED',
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
      await DisbursalApiService.completeDisbursement(
        pending: updatedPending,
        queue: updatedQueue,
        repaymentSchedule: _repaymentSchedule,
      );
      _toast('Disbursement completed successfully!', isError: false);
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Row(children: [
            const Text('Disbursement Queue',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const Spacer(),
            SizedBox(
              width: 260, height: 40,
              child: TextField(
                onChanged: (v) =>
                    setState(() { _search = v; _page = 1; }),
                decoration: InputDecoration(
                  hintText: 'Search loan account, status…',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFF94A3B8)),
                  filled: true, fillColor: const Color(0xFFF1F5F9),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF64748B)),
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),

        // Summary cards
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: MFActiveInactiveSummary(
            activeCount: pendingInputCnt,
            inactiveCount: pendingAuthCnt,
          ),
        ),

        // Table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: Color(0xFF1E3050)),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Table header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3050),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(15)),
                          ),
                          child: Row(children: [
                            Expanded(flex: 2,
                                child: _th('LOAN ACCOUNT NO')),
                            Expanded(flex: 2, child: _th('CLIENT TYPE')),
                            Expanded(flex: 2, child: _th('AMOUNT')),
                            Expanded(flex: 2, child: _th('STATUS')),
                            Expanded(flex: 2, child: _th('DATE')),
                            const SizedBox(
                              width: 80,
                              child: Text('ACTIONS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white70,
                                      letterSpacing: 0.5)),
                            ),
                          ]),
                        ),
                        // Rows
                        if (pageItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                  'No Disbursement Queue records.',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8))),
                            ),
                          )
                        else
                          ...pageItems.asMap().entries.map((e) {
                            final r = e.value;
                            final queue = _findQueueFor(r);
                            final isLast =
                                e.key == pageItems.length - 1;
                            final canEdit =
                                r.disbursementStatus == 'Pending Input';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                border: isLast
                                    ? null
                                    : const Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFF1F5F9))),
                              ),
                              child: Row(children: [
                                Expanded(
                                    flex: 2,
                                    child: Text(r.loanAccountNo,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                Color(0xFF1E293B)))),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        _clientTypeName(
                                            queue?.clientType ?? ''),
                                        style: const TextStyle(
                                            color:
                                                Color(0xFF475569)))),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        'INR ${r.disbursementAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color:
                                                Color(0xFF475569)))),
                                Expanded(
                                    flex: 2,
                                    child: _statusBadge(
                                        r.disbursementStatus)),
                                Expanded(
                                    flex: 2,
                                    child: Text(
                                        r.disbursementDate
                                            .toIso8601String()
                                            .substring(0, 10),
                                        style: const TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13))),
                                SizedBox(
                                  width: 80,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      _iconBtn(
                                          Icons.visibility_outlined,
                                          const Color(0xFF64748B),
                                          () => _go(MFView.view, r)),
                                      if (canEdit) ...[
                                        const SizedBox(width: 8),
                                        _iconBtn(
                                            Icons.edit_outlined,
                                            const Color(0xFF0288D1),
                                            () => _go(MFView.edit, r)),
                                      ],
                                    ],
                                  ),
                                ),
                              ]),
                            );
                          }),
                        // Pagination
                        if (totalPages > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: Color(0xFFE2E8F0)))),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Showing ${start + 1}–$end of '
                                  '${filtered.length} records',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B)),
                                ),
                                MFPaginationControls(
                                  currentPage: _page,
                                  totalPages: totalPages,
                                  onPrev: _page > 1
                                      ? () => setState(() => _page--)
                                      : null,
                                  onNext: _page < totalPages
                                      ? () => setState(() => _page++)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Form View ────────────────────────────────────────────────────────────

  Widget _buildForm({required bool isView}) {
    final isGroup = _clientType == 'G';

    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 20),
          child: Row(children: [
            Text(
              isView
                  ? 'View Disbursement Details'
                  : 'Complete Disbursement',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B)),
            ),
            const Spacer(),
            if (_selPending != null)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: _statusBadge(_selPending!.disbursementStatus),
              ),
            OutlinedButton.icon(
              onPressed: () => _go(MFView.list),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Initiation Details (locked) ──────────────
                _sectionCard(
                  icon: Icons.lock_outline,
                  iconColor: const Color(0xFF64748B),
                  title: 'Initiation Details',
                  subtitle: 'Read-only — from Initiate Disbursal',
                  bgColor: Colors.grey.shade50,
                  borderColor: Colors.grey.shade200,
                  children: [
                    Wrap(spacing: 24, runSpacing: 20, children: [
                      _lockedField('Client Type',
                          _clientTypeName(_clientType),
                          Icons.person_pin_outlined),
                      _lockedField(
                          'Client ID', _clientIdCtrl.text, Icons.badge_outlined),
                      _lockedField('Queue ID', _queueIdCtrl.text, Icons.qr_code_2_rounded),
                      _lockedField('Source System', _sourceSystemCtrl.text,
                          Icons.input_rounded),
                      if (_sourceRefNoCtrl.text.isNotEmpty)
                        _lockedField('Source Ref No', _sourceRefNoCtrl.text,
                            Icons.receipt_long_outlined),
                      _lockedField('Queued Date', _queuedDateCtrl.text,
                          Icons.calendar_today_outlined),
                    ]),

                    // ── Group field — only visible for Group type ──
                    if (isGroup) ...[
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      Row(children: [
                        const Icon(Icons.group_outlined,
                            color: Color(0xFF7C3AED), size: 18),
                        const SizedBox(width: 8),
                        const Text('Group Selection',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text('Required for Group',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF7C3AED))),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 340,
                        child: isView
                            ? _lockedField(
                                'Group',
                                _selectedGroupId ?? '—',
                                Icons.groups_2_outlined)
                            : _groupDropdown(),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ── Section 2: Product & Loan Terms ─────────────────────
                _sectionCard(
                  icon: Icons.account_balance_outlined,
                  iconColor: const Color(0xFF0288D1),
                  title: 'Product & Loan Terms',
                  subtitle: 'Complete the loan product, loan amount, and repayment terms',
                  bgColor: const Color(0xFFE1F5FE),
                  borderColor: const Color(0xFFB3E5FC),
                  children: [
                    Wrap(spacing: 24, runSpacing: 20, children: [
                      // Mandatory read-only Loan Amount (auto-populated from Initiate Disbursal)
                      _lockedField('Loan Amount (INR)', _loanAmtCtrl.text,
                          Icons.currency_rupee_rounded),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Approved Tenure (Months)',
                          ctrl: _approvedTenureCtrl,
                          icon: Icons.timelapse_outlined,
                          required: !isView,
                          readOnly: isView,
                          showLock: isView,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Approved Interest Rate (%)',
                          ctrl: _approvedInterestRateCtrl,
                          icon: Icons.percent_outlined,
                          required: !isView,
                          readOnly: isView,
                          showLock: isView,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      // Mandatory Repayment Frequency Dropdown
                      SizedBox(
                        width: 300,
                        child: _repaymentFrequencyDropdown(isView),
                      ),
                    ]),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Section 3: Disbursement Details ──────────────────────
                _sectionCard(
                  icon: Icons.payments_outlined,
                  iconColor: const Color(0xFF388E3C),
                  title: 'Disbursement Details',
                  subtitle: 'Enter transaction and banking information',
                  bgColor: const Color(0xFFE8F5E9),
                  borderColor: const Color(0xFFA5D6A7),
                  children: [
                    Wrap(spacing: 24, runSpacing: 20, children: [
                      _lockedField('Loan Account No', _loanAccountNoCtrl.text,
                          Icons.account_balance_wallet_outlined),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Disbursement Amount (INR)',
                          ctrl: _disbursementAmtCtrl,
                          icon: Icons.currency_rupee_rounded,
                          required: !isView,
                          readOnly: isView,
                          showLock: isView,
                          errorText: _disbursementAmountError(),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Disbursement Date',
                          ctrl: _disbursementDateCtrl,
                          icon: Icons.calendar_month_outlined,
                          required: !isView,
                          readOnly: isView,
                          showLock: isView,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: _disbursementModeField(isView),
                      ),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Bank Ref No',
                          ctrl: _bankRefNoCtrl,
                          icon: Icons.receipt_long_outlined,
                          readOnly: isView,
                          showLock: isView,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: MFFloatingLabelField(
                          label: 'Disbursed By User',
                          ctrl: _disbursedByUserCtrl,
                          icon: Icons.manage_accounts_outlined,
                          required: !isView,
                          readOnly: isView,
                          showLock: isView,
                        ),
                      ),
                      _lockedField('Seq No', _disbursementSeqNoCtrl.text,
                          Icons.format_list_numbered_outlined),
                    ]),
                  ],
                ),

                // ── Repayment Schedule Section ───────────────────────────
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Repayment Schedule',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B))),
                        Text(
                            'Generate installment schedule prior to submission',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    if (!isView)
                      ElevatedButton.icon(
                        onPressed: _generateRepaymentSchedule,
                        icon: const Icon(Icons.table_chart_outlined, size: 16),
                        label: const Text('Generate Repayment Schedule',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                if (_repaymentSchedule.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Center(
                      child: Text(
                        isView
                            ? 'No schedule generated for this account.'
                            : 'Click "Generate Repayment Schedule" above to preview installment plan.',
                        style: const TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3050),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(13)),
                          ),
                          child: Row(children: [
                            Expanded(flex: 3, child: _th('LOAN ACCOUNT NO')),
                            Expanded(flex: 2, child: _th('INSTALLMENT NO')),
                            Expanded(flex: 3, child: _th('DUE DATE')),
                            Expanded(flex: 2, child: _th('PRINCIPAL DUE')),
                            Expanded(flex: 2, child: _th('INTEREST DUE')),
                            Expanded(flex: 2, child: _th('TOTAL DUE')),
                          ]),
                        ),
                        ..._repaymentSchedule.asMap().entries.map((e) {
                          final item = e.value;
                          final isLast = e.key == _repaymentSchedule.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : const Border(
                                      bottom: BorderSide(
                                          color: Color(0xFFF1F5F9))),
                            ),
                            child: Row(children: [
                              Expanded(
                                  flex: 3,
                                  child: Text(item.loanAccountNo,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF1E293B)))),
                              Expanded(
                                  flex: 2,
                                  child: Text('#${item.installmentNo}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569)))),
                              Expanded(
                                  flex: 3,
                                  child: Text(
                                      item.dueDate
                                          .toIso8601String()
                                          .substring(0, 10),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569)))),
                              Expanded(
                                  flex: 2,
                                  child: Text('INR ${item.principalDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569)))),
                              Expanded(
                                  flex: 2,
                                  child: Text('INR ${item.interestDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569)))),
                              Expanded(
                                  flex: 2,
                                  child: Text('INR ${item.totalDue.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: Color(0xFF1E293B)))),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Bottom action bar ──
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _go(MFView.list),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isView ? 'Close' : 'Cancel'),
              ),
              if (!isView) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: (_isLoading || _repaymentSchedule.isEmpty) ? null : _submitToAuthQueue,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Submit to Authorization',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3050),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Repayment Frequency Dropdown ─────────────────────────────────────────

  Widget _repaymentFrequencyDropdown(bool isView) {
    if (isView) {
      return _lockedField(
          'Repayment Frequency', _repaymentFrequency, Icons.repeat_rounded);
    }
    return DropdownButtonFormField<String>(
      value: _repaymentFrequency,
      decoration: InputDecoration(
        labelText: 'Repayment Frequency *',
        labelStyle:
            const TextStyle(color: Color(0xFF0288D1), fontSize: 14),
        prefixIcon: const Icon(Icons.repeat_rounded,
            color: Color(0xFF0288D1), size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.blue.shade100, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.blue.shade100, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF0288D1), width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF0288D1)),
      onChanged: (val) =>
          setState(() {
            _repaymentFrequency = val ?? 'Monthly';
            _repaymentSchedule = [];
          }),
      items: _frequencies
          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
          .toList(),
    );
  }

  // ─── Group Dropdown (native, for G type only) ─────────────────────────────

  Widget _groupDropdown() {
    return DropdownButtonFormField<String>(
      value: _groups.any((g) => g['id'] == _selectedGroupId)
          ? _selectedGroupId
          : null,
      decoration: InputDecoration(
        labelText: 'Group *',
        labelStyle:
            const TextStyle(color: Color(0xFF7C3AED), fontSize: 14),
        prefixIcon: const Icon(Icons.groups_2_outlined,
            color: Color(0xFF7C3AED), size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.purple.shade100, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.purple.shade100, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF7C3AED), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF7C3AED)),
      hint: const Text('Select a Group',
          style: TextStyle(color: Color(0xFF94A3B8))),
      validator: (v) =>
          v == null || v.isEmpty ? 'Please select a group' : null,
      onChanged: (val) => setState(() => _selectedGroupId = val),
      items: _groups.map((g) {
        return DropdownMenuItem<String>(
          value: g['id'],
          child: Text(g['name'] ?? g['id'] ?? '',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E293B))),
        );
      }).toList(),
    );
  }

  // ─── Disbursement Mode Dropdown ───────────────────────────────────────────

  Widget _disbursementModeField(bool isView) {
    if (isView) {
      return _lockedField('Disbursement Mode', _disbursementMode,
          Icons.account_balance_outlined);
    }
    return DropdownButtonFormField<String>(
      value: _disbursementMode,
      decoration: InputDecoration(
        labelText: 'Disbursement Mode *',
        labelStyle:
            const TextStyle(color: Color(0xFF0288D1), fontSize: 14),
        prefixIcon: const Icon(Icons.account_balance_outlined,
            color: Color(0xFF0288D1), size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.blue.shade100, width: 1)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.blue.shade100, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: Color(0xFF0288D1), width: 1.5)),
        filled: true,
        fillColor: Colors.white,
      ),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF0288D1)),
      onChanged: (val) =>
          setState(() => _disbursementMode = val ?? 'Bank'),
      items: ['Bank', 'Cash', 'Cheque', 'NEFT', 'IMPS', 'UPI']
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
    );
  }

  // ─── Section card wrapper ──────────────────────────────────────────────────

  Widget _sectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color bgColor,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                        fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Color(0xFF64748B), fontSize: 12)),
              ]),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  // ─── Small helpers ────────────────────────────────────────────────────────

  Widget _th(String t) => Text(t,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.5));

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      );
}
