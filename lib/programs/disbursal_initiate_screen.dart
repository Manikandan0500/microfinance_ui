import 'package:flutter/material.dart';
import 'mf_shared_widgets.dart';
import 'models/disbursal_queue.dart';
import 'services/disbursal_api_service.dart';

// --------------------------------------------------------------------------
// Initiate Disbursal Screen (DISB001)
// Fields: Client Type (I/C/G), Client ID, Loan Amount
// Queue ID is auto-generated. clientType stored in the model.
// On save → creates DisbursalQueue + linked PendingDisbursal.
// --------------------------------------------------------------------------
class DisbursalInitiateScreen extends StatefulWidget {
  const DisbursalInitiateScreen({super.key});

  @override
  State<DisbursalInitiateScreen> createState() =>
      _DisbursalInitiateScreenState();
}

class _DisbursalInitiateScreenState extends State<DisbursalInitiateScreen> {
  // ─── Navigation ───────────────────────────────────────────────────────────
  MFView _view = MFView.list;
  DisbursalQueue? _sel;

  // ─── Data ─────────────────────────────────────────────────────────────────
  List<DisbursalQueue> _data = [];
  String _search = '';
  int _page = 1;
  static const int _pageSize = 10;
  bool _isLoading = false;
  bool _deleteConfirmed = false;

  // ─── Form ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  String _clientType = 'I'; // I = Individual, C = Corporate, G = Group
  final _clientIdCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();

  static const _clientTypeItems = [
    {'id': 'I', 'name': 'I – Individual'},
    {'id': 'C', 'name': 'C – Corporate'},
    {'id': 'G', 'name': 'G – Group'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _loanAmtCtrl.dispose();
    super.dispose();
  }

  // ─── Data helpers ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await DisbursalApiService.getDisbursalQueue();
      if (mounted) setState(() => _data = records);
    } catch (e) {
      if (mounted) _toast('Failed to load records: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    final loanAmt = double.tryParse(_loanAmtCtrl.text.trim()) ?? 0.0;
    if (loanAmt <= 0) {
      _toast('Please enter a valid loan amount greater than 0', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final autoQueueId = 'Q-${ts.substring(ts.length - 6)}';

    final record = DisbursalQueue(
      orgCode: '101',
      queueId: autoQueueId,
      clientType: _clientType,
      sourceSystem: 'MANUAL',
      sourceRefNo: null,
      clientId: _clientIdCtrl.text.trim().toUpperCase(),
      groupCode: null, // group is selected in Pending Disbursal
      productCode: 'DISBQUEUE',
      approvedAmount: loanAmt,
      approvedTenureMonths: 0,
      approvedInterestRate: 0.0,
      queuedDate: DateTime.now(),
      assignedToUserId: 'admin',
      disbursementStatus: 'Pending Input',
    );

    try {
      await DisbursalApiService.createDisbursalQueue(record);
      _toast(
        'Disbursal initiated (${_clientTypeName(_clientType)}). '
        'Complete details in Disbursement Queue.',
        isError: false,
      );
      await _loadData();
      setState(() => _view = MFView.list);
    } catch (e) {
      _toast('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (_sel == null) return;
    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.deleteDisbursalQueue(_sel!.queueId);
      _toast('Record deleted.', isError: false);
      await _loadData();
      setState(() {
        _view = MFView.list;
        _sel = null;
      });
    } catch (e) {
      _toast('Delete failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Navigation helper ────────────────────────────────────────────────────

  void _go(MFView v, [DisbursalQueue? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _deleteConfirmed = false;
      if (v == MFView.create) {
        _clientType = 'I';
        _clientIdCtrl.clear();
        _loanAmtCtrl.clear();
      } else if (r != null && (v == MFView.view)) {
        _clientType = r.clientType;
        _clientIdCtrl.text = r.clientId;
        _loanAmtCtrl.text = r.approvedAmount.toStringAsFixed(2);
      }
    });
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

  Color _statusFg(String s) {
    switch (s) {
      case 'Approved':               return const Color(0xFF16A34A);
      case 'Rejected':               return const Color(0xFFDC2626);
      case 'Pending Authorization':  return const Color(0xFF2563EB);
      case 'Pending Input':          return const Color(0xFFD97706);
      default:                       return const Color(0xFF64748B);
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'Approved':               return const Color(0xFFDCFCE7);
      case 'Rejected':               return const Color(0xFFFEE2E2);
      case 'Pending Authorization':  return const Color(0xFFDBEAFE);
      case 'Pending Input':          return const Color(0xFFFEF3C7);
      default:                       return const Color(0xFFF1F5F9);
    }
  }

  Widget _statusBadge(String s) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _statusBg(s), borderRadius: BorderRadius.circular(20)),
      child: Text(s,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: _statusFg(s))),
    ),
  );

  Widget _clientTypeBadge(String code) {
    final label = _clientTypeName(code);
    Color bg;
    Color fg;
    switch (code) {
      case 'G':
        bg = const Color(0xFFEDE9FE); fg = const Color(0xFF7C3AED); break;
      case 'C':
        bg = const Color(0xFFFFEDD5); fg = const Color(0xFFEA580C); break;
      default:
        bg = const Color(0xFFDBEAFE); fg = const Color(0xFF1D4ED8); break;
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: switch (_view) {
        MFView.list   => _buildList(),
        MFView.create => _buildForm(isView: false),
        MFView.view   => _buildForm(isView: true),
        MFView.delete => _buildDeleteConfirm(),
        MFView.edit   => _buildForm(isView: false),
      },
    );
  }

  // ─── List View ────────────────────────────────────────────────────────────

  Widget _buildList() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty ||
          r.clientId.toLowerCase().contains(q) ||
          r.disbursementStatus.toLowerCase().contains(q) ||
          _clientTypeName(r.clientType).toLowerCase().contains(q);
    }).toList();

    final totalPages = (filtered.length / _pageSize).ceil().clamp(1, 9999);
    final start = (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    final pageItems = filtered.isEmpty ? <DisbursalQueue>[] : filtered.sublist(start, end);

    final approvedCnt = _data.where((r) => r.disbursementStatus == 'Approved').length;
    final pendingCnt = _data.where((r) => r.disbursementStatus == 'Pending Input').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Page Header ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Row(
            children: [
              const Text('Initiate Disbursal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B))),
              const Spacer(),
              // Search
              SizedBox(
                width: 260, height: 40,
                child: TextField(
                  onChanged: (v) => setState(() { _search = v; _page = 1; }),
                  decoration: InputDecoration(
                    hintText: 'Search client, status…',
                    prefixIcon: const Icon(Icons.search, size: 18,
                        color: Color(0xFF94A3B8)),
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
              const SizedBox(width: 12),
              // New button
              ElevatedButton.icon(
                onPressed: () => _go(MFView.create),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Initiate Disbursal',
                    style: TextStyle(fontWeight: FontWeight.w600,
                        fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3050),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),

        // ── Summary cards ──
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: MFActiveInactiveSummary(
            activeCount: approvedCnt,
            inactiveCount: pendingCnt,
          ),
        ),

        // ── Table ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: _isLoading
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                        color: Color(0xFF1E3050))))
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12, offset: const Offset(0, 4)),
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
                            Expanded(flex: 2, child: _th('CLIENT TYPE')),
                            Expanded(flex: 2, child: _th('CLIENT ID')),
                            Expanded(flex: 2, child: _th('LOAN AMOUNT')),
                            Expanded(flex: 2, child: _th('STATUS')),
                            Expanded(flex: 2, child: _th('QUEUED DATE')),
                            const SizedBox(
                              width: 80,
                              child: Text('ACTIONS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11,
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
                              child: Text('No records found.',
                                  style: TextStyle(
                                      color: Color(0xFF94A3B8))),
                            ),
                          )
                        else
                          ...pageItems.asMap().entries.map((e) {
                            final r = e.value;
                            final isLast = e.key == pageItems.length - 1;
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
                                Expanded(flex: 2,
                                    child: _clientTypeBadge(r.clientType)),
                                Expanded(flex: 2,
                                    child: Text(r.clientId,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B)))),
                                Expanded(flex: 2,
                                    child: Text(
                                        'INR ${r.approvedAmount.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            color: Color(0xFF475569)))),
                                Expanded(flex: 2,
                                    child: _statusBadge(r.disbursementStatus)),
                                Expanded(flex: 2,
                                    child: Text(
                                        r.queuedDate.toIso8601String()
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
                                      _iconBtn(Icons.visibility_outlined,
                                          const Color(0xFF64748B),
                                          () => _go(MFView.view, r)),
                                      const SizedBox(width: 8),
                                      _iconBtn(
                                          Icons.delete_outline_rounded,
                                          const Color(0xFFDC2626),
                                          () => _go(MFView.delete, r)),
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
                                      ? () =>
                                          setState(() => _page--)
                                      : null,
                                  onNext: _page < totalPages
                                      ? () =>
                                          setState(() => _page++)
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

  // ─── Form View (Create / View) ────────────────────────────────────────────

  Widget _buildForm({required bool isView}) {
    return Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Row(
            children: [
              Text(
                isView ? 'View Disbursal Record' : 'Initiate New Disbursal',
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
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
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Disbursal Details',
                            style: TextStyle(fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B))),
                        if (isView && _sel != null)
                          _statusBadge(_sel!.disbursementStatus),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isView
                          ? 'Read-only view of the initiated disbursal.'
                          : 'Fill in the fields below. Remaining details '
                            'are completed in the Disbursement Queue.',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF64748B)),
                    ),

                    // Info banner (create only)
                    if (!isView) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded,
                              color: Color(0xFF1D4ED8), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Selecting "G – Group" enables a Group field in '
                              'the Disbursement Queue for group-specific disbursals.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E40AF)),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 20),

                    // Fields
                    Wrap(
                      spacing: 24,
                      runSpacing: 20,
                      children: [
                        // ── Client Type dropdown ──
                        SizedBox(
                          width: 300,
                          child: isView
                              ? _readonlyField(
                                  'Client Type',
                                  _clientTypeName(_sel?.clientType ?? 'I'),
                                  Icons.person_pin_outlined,
                                )
                              : _clientTypeDropdown(),
                        ),

                        // ── Client ID ──
                        SizedBox(
                          width: 300,
                          child: isView
                              ? _readonlyField('Client ID',
                                  _sel?.clientId ?? '', Icons.badge_outlined)
                              : MFFloatingLabelField(
                                  label: 'Client ID',
                                  ctrl: _clientIdCtrl,
                                  icon: Icons.badge_outlined,
                                  required: true,
                                ),
                        ),

                        // ── Loan Amount ──
                        SizedBox(
                          width: 300,
                          child: isView
                              ? _readonlyField(
                                  'Loan Amount (INR)',
                                  _sel != null
                                      ? 'INR ${_sel!.approvedAmount.toStringAsFixed(2)}'
                                      : '',
                                  Icons.currency_rupee_rounded,
                                )
                              : MFFloatingLabelField(
                                  label: 'Loan Amount (INR)',
                                  ctrl: _loanAmtCtrl,
                                  icon: Icons.currency_rupee_rounded,
                                  required: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                ),
                        ),
                      ],
                    ),

                    // View-only extra info
                    if (isView && _sel != null) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),
                      Text('Additional Info',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 24, runSpacing: 16, children: [
                        _readonlyField('Queue ID', _sel!.queueId,
                            Icons.qr_code_2_rounded),
                        _readonlyField('Source System', _sel!.sourceSystem,
                            Icons.input_rounded),
                        _readonlyField('Queued Date',
                            _sel!.queuedDate.toIso8601String().substring(0, 10),
                            Icons.calendar_today_outlined),
                        if (_sel!.groupCode != null && _sel!.groupCode!.isNotEmpty)
                          _readonlyField('Group Code', _sel!.groupCode!,
                              Icons.group_outlined),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Bottom action bar ──
        if (!isView)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 28, vertical: 16),
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
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveRecord,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Initiate Disbursal',
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
            ),
          ),
      ],
    );
  }

  // ── Client Type Dropdown (native DropdownButtonFormField) ──────────────────
  Widget _clientTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _clientType,
      decoration: InputDecoration(
        labelText: 'Client Type *',
        labelStyle: const TextStyle(
            color: Color(0xFF0288D1), fontSize: 14),
        prefixIcon: const Icon(Icons.person_pin_outlined,
            color: Color(0xFF0288D1), size: 20),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFF0288D1), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.red, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      style: const TextStyle(
          color: Color(0xFF01579B), fontSize: 14),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: Color(0xFF0288D1)),
      validator: (v) =>
          v == null || v.isEmpty ? 'Please select a client type' : null,
      onChanged: (val) => setState(() => _clientType = val ?? 'I'),
      items: _clientTypeItems.map((item) {
        return DropdownMenuItem<String>(
          value: item['id']!,
          child: Text(item['name']!,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF1E293B))),
        );
      }).toList(),
    );
  }

  // ── Read-only display field ────────────────────────────────────────────────
  Widget _readonlyField(String label, String value, IconData icon) {
    return SizedBox(
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
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          suffixIcon: const Icon(Icons.lock_outline,
              color: Colors.grey, size: 18),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  // ─── Delete Confirmation ──────────────────────────────────────────────────

  Widget _buildDeleteConfirm() {
    final r = _sel;
    if (r == null) return const SizedBox();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 20),
          child: Row(children: [
            const Text('Delete Disbursal Record',
                style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B))),
            const Spacer(),
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
          child: Center(
            child: Container(
              width: 520,
              margin: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Red header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(15)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFFECACA))),
                        child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626), size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Confirm Deletion',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF991B1B))),
                            SizedBox(height: 2),
                            Text(
                                'This will also remove the linked '
                                'Disbursement Queue entry.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFB91C1C))),
                          ],
                        ),
                      ),
                    ]),
                  ),
                  // Details
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow('Queue ID', r.queueId),
                        const SizedBox(height: 8),
                        _detailRow('Client Type',
                            _clientTypeName(r.clientType)),
                        const SizedBox(height: 8),
                        _detailRow('Client ID', r.clientId),
                        const SizedBox(height: 8),
                        _detailRow('Loan Amount',
                            'INR ${r.approvedAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 20),
                        // Confirm checkbox
                        InkWell(
                          onTap: () => setState(
                              () => _deleteConfirmed = !_deleteConfirmed),
                          borderRadius: BorderRadius.circular(6),
                          child: Row(children: [
                            Checkbox(
                              value: _deleteConfirmed,
                              onChanged: (v) => setState(
                                  () => _deleteConfirmed = v ?? false),
                              activeColor: const Color(0xFFDC2626),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(4)),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                                'I understand this action cannot be undone.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  // Buttons
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(15)),
                      border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _go(MFView.list),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF334155),
                            side: const BorderSide(
                                color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: (_deleteConfirmed && !_isLoading)
                              ? _deleteRecord
                              : null,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : const Icon(
                                  Icons.delete_forever_rounded,
                                  size: 16),
                          label: const Text('Delete Record',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFFFCA5A5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10)),
                            elevation: 0,
                          ),
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

  // ─── Small helpers ────────────────────────────────────────────────────────

  Widget _th(String t) => Text(t,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: Colors.white, letterSpacing: 0.5));

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      );

  Widget _detailRow(String label, String value) => Row(children: [
        SizedBox(
          width: 130,
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ),
        Text(value,
            style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ]);
}
