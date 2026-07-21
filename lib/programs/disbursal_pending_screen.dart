import 'package:flutter/material.dart';
import 'shared_widgets.dart';
import 'services/disbursal_api_service.dart';
import 'mock_database.dart';

// --------------------------------------------------------------------------
// Disbursement Queue Screen (DISB002)
// Shows records with "Pending Input" status from Initiate Disbursal.
// Users complete all remaining disbursal fields and submit to Auth Queue.
// Post-auth status (Approved/Rejected) is also visible here.
// --------------------------------------------------------------------------
class DisbursalPendingScreen extends StatefulWidget {
  const DisbursalPendingScreen({super.key});

  @override
  State<DisbursalPendingScreen> createState() => _DisbursalPendingScreenState();
}

class _DisbursalPendingScreenState extends State<DisbursalPendingScreen> {
  // ---- State ----
  String _viewMode = 'GRID'; // GRID, EDIT
  PendingDisbursal? _selectedPending;
  DisbursalQueue? _selectedQueue;
  String _searchQuery = '';

  List<PendingDisbursal> _pendingRecords = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---- Form ----
  final _formKey = GlobalKey<FormState>();

  // Queue fields (from DISB001 — locked)
  final _queueIdController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _loanAmountController = TextEditingController();
  final _sourceSystemController = TextEditingController();
  final _sourceRefNoController = TextEditingController();
  final _groupCodeController = TextEditingController();
  final _queuedDateController = TextEditingController();

  // Disbursal detail fields (editable)
  final _productCodeController = TextEditingController();
  final _approvedTenureController = TextEditingController();
  final _approvedInterestRateController = TextEditingController();
  final _loanAccountNoController = TextEditingController();
  final _disbursementSeqNoController = TextEditingController();
  final _bankRefNoController = TextEditingController();
  final _disbursedByUserController = TextEditingController();
  final _disbursementDateController = TextEditingController();
  final _accPostingRefController = TextEditingController();
  String _disbursementMode = 'Bank';
  String _accPostingStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _queueIdController.dispose();
    _clientIdController.dispose();
    _loanAmountController.dispose();
    _sourceSystemController.dispose();
    _sourceRefNoController.dispose();
    _groupCodeController.dispose();
    _queuedDateController.dispose();
    _productCodeController.dispose();
    _approvedTenureController.dispose();
    _approvedInterestRateController.dispose();
    _loanAccountNoController.dispose();
    _disbursementSeqNoController.dispose();
    _bankRefNoController.dispose();
    _disbursedByUserController.dispose();
    _disbursementDateController.dispose();
    _accPostingRefController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Data
  // --------------------------------------------------------------------------

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pending = await DisbursalApiService.getPendingDisbursals();
      setState(() {
        _pendingRecords = pending;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Find the corresponding DisbursalQueue entry for a PendingDisbursal
  DisbursalQueue? _findQueueRecord(PendingDisbursal pending) {
    final clientId = pending.loanAccountNo.replaceFirst('L-', '');
    final db = MockDatabase();
    try {
      return db.disbursalQueue.firstWhere((q) => q.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  void _loadFormData(PendingDisbursal pending) {
    final queue = _findQueueRecord(pending);
    _selectedQueue = queue;

    // Locked fields from queue
    _queueIdController.text = queue?.queueId ?? '';
    _clientIdController.text = queue?.clientId ?? '';
    _loanAmountController.text = queue?.approvedAmount.toStringAsFixed(2) ?? pending.disbursementAmount.toStringAsFixed(2);
    _sourceSystemController.text = queue?.sourceSystem ?? '';
    _sourceRefNoController.text = queue?.sourceRefNo ?? '';
    _groupCodeController.text = queue?.groupCode ?? '';
    _queuedDateController.text = queue?.queuedDate.toIso8601String().substring(0, 10) ?? '';

    // Editable fields
    _productCodeController.text = queue?.productCode ?? '';
    _approvedTenureController.text = (queue?.approvedTenureMonths ?? 0) > 0
        ? queue!.approvedTenureMonths.toString()
        : '';
    _approvedInterestRateController.text = (queue?.approvedInterestRate ?? 0) > 0
        ? queue!.approvedInterestRate.toString()
        : '';
    _loanAccountNoController.text = pending.loanAccountNo;
    _disbursementSeqNoController.text = pending.disbursementSeqNo.toString();
    _bankRefNoController.text = pending.bankRefNo ?? '';
    _disbursedByUserController.text = pending.disbursedByUserId;
    _disbursementDateController.text = pending.disbursementDate.toIso8601String().substring(0, 10);
    _accPostingRefController.text = pending.accPostingRef ?? '';
    _disbursementMode = pending.disbursementMode;
    _accPostingStatus = pending.accPostingStatus ?? 'Pending';
  }

  Future<void> _submitToAuthQueue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPending == null || _selectedQueue == null) return;

    final updatedPending = _selectedPending!.copyWith(
      loanAccountNo: _loanAccountNoController.text.trim(),
      disbursementSeqNo: int.tryParse(_disbursementSeqNoController.text) ?? 1,
      disbursementAmount: double.tryParse(_loanAmountController.text) ?? _selectedPending!.disbursementAmount,
      currencyCode: 'INR',
      disbursementMode: _disbursementMode,
      bankRefNo: _bankRefNoController.text.trim(),
      disbursedByUserId: _disbursedByUserController.text.trim(),
      disbursementDate: DateTime.tryParse(_disbursementDateController.text) ?? DateTime.now(),
      disbursementStatus: 'Pending Authorization',
      accPostingRef: _accPostingRefController.text.trim(),
      accPostingStatus: 'Pending',
    );

    final updatedQueue = _selectedQueue!.copyWith(
      productCode: _productCodeController.text.trim(),
      approvedTenureMonths: int.tryParse(_approvedTenureController.text) ?? _selectedQueue!.approvedTenureMonths,
      approvedInterestRate: double.tryParse(_approvedInterestRateController.text) ?? _selectedQueue!.approvedInterestRate,
    );

    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.submitToAuthQueue(updatedPending.loanAccountNo, updatedPending, updatedQueue);
      _showSnackbar('Disbursal submitted to Authorization Queue successfully!', isError: false);
      await _loadRecords();
      setState(() => _viewMode = 'GRID');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Build
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null && _viewMode == 'GRID')
            Expanded(child: _buildErrorState())
          else
            Expanded(
              child: SingleChildScrollView(
                child: _buildMainContent(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScreenHeader() {
    String title = 'Disbursement Queue';
    if (_viewMode == 'EDIT') title = 'Complete Disbursal Details';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
        if (_viewMode != 'GRID')
          StandardButton(
            label: 'Back',
            isPrimary: false,
            onPressed: () => setState(() => _viewMode = 'GRID'),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Could not load Disbursement Queue data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
          const SizedBox(height: 8),
          Text(_errorMessage ?? 'Unknown error',
              style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF152238),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (_viewMode == 'EDIT') return _buildEditForm();
    return _buildGrid();
  }

  // --------------------------------------------------------------------------
  // Grid — shows all Disbursement Queues
  // --------------------------------------------------------------------------
  Widget _buildGrid() {
    final filtered = _pendingRecords.where((r) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          r.loanAccountNo.toLowerCase().contains(q) ||
          r.disbursementMode.toLowerCase().contains(q) ||
          r.disbursementStatus.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _pendingRecords.length,
              label: 'Disbursal Transactions',
              icon: Icons.pending_actions_outlined,
            ),
            Row(
              children: [
                Container(
                  width: 250,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search...',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadRecords,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF152238),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(child: Text('LOAN ACCOUNT NO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('CLIENT ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('AMOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('MODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('DISB. DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('ACTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Rows
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No Disbursement Queue records', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    final queue = _findQueueRecord(item);
                    final isEven = idx % 2 == 0;

                    // Status badge
                    Color statusColor = Colors.orange.shade700;
                    Color statusBg = Colors.orange.shade50;
                    if (item.disbursementStatus == 'Completed') { statusColor = Colors.green.shade700; statusBg = Colors.green.shade50; }
                    if (item.disbursementStatus == 'Failed') { statusColor = Colors.red.shade700; statusBg = Colors.red.shade50; }
                    if (item.disbursementStatus == 'Pending Authorization') { statusColor = Colors.blue.shade700; statusBg = Colors.blue.shade50; }
                    if (item.disbursementStatus == 'Pending Input') { statusColor = Colors.deepOrange.shade700; statusBg = Colors.deepOrange.shade50; }

                    final canEdit = item.disbursementStatus == 'Pending Input';

                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.loanAccountNo, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text(queue?.clientId ?? '—')),
                          Expanded(child: Text('INR ${item.disbursementAmount.toStringAsFixed(2)}')),
                          Expanded(child: Text(item.disbursementMode)),
                          Expanded(child: Text(item.disbursementDate.toIso8601String().substring(0, 10))),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Text(item.disbursementStatus,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Center(
                              child: canEdit
                                  ? ActionIconBtn(
                                      icon: Icons.edit_outlined,
                                      color: const Color(0xFF0288D1),
                                      onTap: () {
                                        _loadFormData(item);
                                        setState(() {
                                          _selectedPending = item;
                                          _viewMode = 'EDIT';
                                        });
                                      },
                                    )
                                  : ActionIconBtn(
                                      icon: Icons.visibility_outlined,
                                      color: Colors.grey,
                                      onTap: () {
                                        _loadFormData(item);
                                        setState(() {
                                          _selectedPending = item;
                                          _viewMode = 'EDIT';
                                        });
                                      },
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Edit Form — all remaining fields
  // --------------------------------------------------------------------------
  Widget _buildEditForm() {
    final status = _selectedPending?.disbursementStatus ?? '';
    final isReadOnly = status != 'Pending Input';
    final isApproved = status == 'Completed';
    final isRejected = status == 'Failed';

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status banner
          if (isApproved)
            _buildStatusBanner('Approved', 'This disbursal has been approved and completed.', Colors.green),
          if (isRejected)
            _buildStatusBanner('Rejected', 'This disbursal was rejected during authorization.', Colors.red),
          if (status == 'Pending Authorization')
            _buildStatusBanner('Pending Authorization', 'Submitted to Authorization Queue. Awaiting approval.', Colors.blue),

          // Section 1: Initiation Details (locked — from Initiate Disbursal)
          _buildSection(
            icon: Icons.info_outline,
            title: 'Initiation Details',
            subtitle: 'Read-only fields from Initiate Disbursal',
            color: Colors.grey.shade700,
            bgColor: Colors.grey.shade50,
            children: [
              _buildRow([
                _formField('Queue ID', _queueIdController, Icons.qr_code, isLocked: true),
                _formField('Client ID', _clientIdController, Icons.person_outline, isLocked: true),
                _formField('Loan Amount (INR)', _loanAmountController, Icons.currency_rupee, isLocked: true),
              ]),
              _buildRow([
                _formField('Source System', _sourceSystemController, Icons.input, isLocked: true),
                _formField('Source Ref. No', _sourceRefNoController, Icons.tag, isLocked: true),
                _formField('Group Code', _groupCodeController, Icons.group_outlined, isLocked: true),
              ]),
              _buildRow([
                _formField('Queued Date', _queuedDateController, Icons.calendar_today_outlined, isLocked: true),
              ]),
            ],
          ),
          const SizedBox(height: 20),

          // Section 2: Product & Loan Terms
          _buildSection(
            icon: Icons.account_balance_outlined,
            title: 'Product & Loan Terms',
            subtitle: 'Complete the loan product and terms',
            color: const Color(0xFF0288D1),
            bgColor: const Color(0xFFE1F5FE),
            children: [
              _buildRow([
                _formField('Product Code', _productCodeController, Icons.inventory_2_outlined,
                    isRequired: !isReadOnly, isLocked: isReadOnly),
                _formField('Approved Tenure (Months)', _approvedTenureController, Icons.timelapse,
                    isRequired: !isReadOnly,
                    isLocked: isReadOnly,
                    keyboardType: TextInputType.number),
                _formField('Approved Interest Rate (%)', _approvedInterestRateController, Icons.percent,
                    isRequired: !isReadOnly,
                    isLocked: isReadOnly,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              ]),
            ],
          ),
          const SizedBox(height: 20),

          // Section 3: Disbursement Details
          _buildSection(
            icon: Icons.payments_outlined,
            title: 'Disbursement Details',
            subtitle: 'Enter the disbursement transaction information',
            color: const Color(0xFF388E3C),
            bgColor: const Color(0xFFE8F5E9),
            children: [
              _buildRow([
                _formField('Loan Account No', _loanAccountNoController, Icons.account_balance_wallet_outlined,
                    isRequired: !isReadOnly, isLocked: isReadOnly),
                _formField('Disbursement Seq. No', _disbursementSeqNoController, Icons.format_list_numbered,
                    isLocked: isReadOnly, keyboardType: TextInputType.number),
                _formField('Disbursement Date', _disbursementDateController, Icons.calendar_month_outlined,
                    isRequired: !isReadOnly, isLocked: isReadOnly),
              ]),
              _buildRow([
                SizedBox(
                  width: 300,
                  child: isReadOnly
                      ? _formField('Disbursement Mode', _disbursementSeqNoController
                          ..text = _disbursementMode, Icons.account_balance_outlined, isLocked: true)
                      : Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ProgramDropdownField(
                            label: 'Disbursement Mode',
                            value: _disbursementMode,
                            items: const ['Bank', 'Cash', 'Cheque', 'NEFT', 'IMPS', 'UPI'],
                            prefixIcon: Icons.account_balance_outlined,
                            isRequired: true,
                            isLocked: false,
                            onChanged: (val) => setState(() => _disbursementMode = val ?? 'Bank'),
                          ),
                        ),
                ),
                _formField('Bank Ref. No', _bankRefNoController, Icons.receipt_long_outlined, isLocked: isReadOnly),
                _formField('Disbursed By User', _disbursedByUserController, Icons.manage_accounts_outlined,
                    isRequired: !isReadOnly, isLocked: isReadOnly),
              ]),
            ],
          ),
          const SizedBox(height: 20),

          // Section 4: Accounting
          _buildSection(
            icon: Icons.book_outlined,
            title: 'Accounting Information',
            subtitle: 'GL posting reference and status',
            color: const Color(0xFF7B1FA2),
            bgColor: const Color(0xFFF3E5F5),
            children: [
              _buildRow([
                _formField('Accounting Posting Ref.', _accPostingRefController, Icons.receipt_outlined, isLocked: isReadOnly),
                SizedBox(
                  width: 300,
                  child: isReadOnly
                      ? _formField('Acc. Posting Status', TextEditingController(text: _accPostingStatus),
                          Icons.check_circle_outline, isLocked: true)
                      : Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ProgramDropdownField(
                            label: 'Acc. Posting Status',
                            value: _accPostingStatus,
                            items: const ['Pending', 'Posted', 'Failed'],
                            prefixIcon: Icons.check_circle_outline,
                            isLocked: false,
                            onChanged: (val) => setState(() => _accPostingStatus = val ?? 'Pending'),
                          ),
                        ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 32),

          // Action buttons
          if (!isReadOnly)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StandardButton(
                  label: 'Cancel',
                  isPrimary: false,
                  onPressed: () => setState(() => _viewMode = 'GRID'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _submitToAuthQueue,
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  label: const Text('Submit to Authorization',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF152238),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: StandardButton(
                label: 'Close',
                isPrimary: false,
                onPressed: () => setState(() => _viewMode = 'GRID'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String title, String message, MaterialColor color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(
            title == 'Approved' ? Icons.check_circle_outline : title == 'Rejected' ? Icons.cancel_outlined : Icons.hourglass_top_outlined,
            color: color.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color.shade800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: color.shade700, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> fields) {
    return Wrap(spacing: 24, runSpacing: 0, children: fields);
  }

  Widget _formField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    bool isLocked = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 300,
      child: ProgramFormField(
        label: label,
        controller: controller,
        prefixIcon: icon,
        isRequired: isRequired,
        isLocked: isLocked,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }
}
