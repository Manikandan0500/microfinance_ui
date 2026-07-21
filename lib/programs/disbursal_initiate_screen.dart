import 'package:flutter/material.dart';
import 'shared_widgets.dart';
import 'models/disbursal_queue.dart';
import 'services/disbursal_api_service.dart';

// --------------------------------------------------------------------------
// Initiate Disbursal Screen
// Shows only 3 fields: Queue ID, Client ID, Loan Amount
// On submission, auto-creates a linked PendingDisbursal record
// --------------------------------------------------------------------------
class DisbursalInitiateScreen extends StatefulWidget {
  const DisbursalInitiateScreen({super.key});

  @override
  State<DisbursalInitiateScreen> createState() => _DisbursalInitiateScreenState();
}

class _DisbursalInitiateScreenState extends State<DisbursalInitiateScreen> {
  // ---- State ----
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, DELETE
  DisbursalQueue? _selectedRecord;
  String _searchQuery = '';

  List<DisbursalQueue> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---- Controllers (only 3 shown on form) ----
  final _formKey = GlobalKey<FormState>();
  final _queueIdController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _loanAmountController = TextEditingController();
  bool _deleteConfirmed = false;

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
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Data loading
  // --------------------------------------------------------------------------

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final records = await DisbursalApiService.getDisbursalQueue();
      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final double loanAmt = double.tryParse(_loanAmountController.text) ?? 0.0;

    final record = DisbursalQueue(
      orgCode: '101',
      queueId: _queueIdController.text.trim().toUpperCase(),
      sourceSystem: 'MANUAL',
      sourceRefNo: null,
      clientId: _clientIdController.text.trim().toUpperCase(),
      groupCode: null,
      productCode: 'DISBQUEUE', // defaulted; completed in Disbursement Queue
      approvedAmount: loanAmt,
      approvedTenureMonths: 0,   // completed in Disbursement Queue
      approvedInterestRate: 0.0, // completed in Disbursement Queue
      queuedDate: DateTime.now(),
      assignedToUserId: 'admin',
      disbursementStatus: 'Pending Input',
    );

    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.createDisbursalQueue(record);
      _showSnackbar('Disbursal initiated. Complete details in Disbursement Queue.', isError: false);
      await _loadRecords();
      setState(() => _viewMode = 'GRID');
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    if (_selectedRecord == null) return;
    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.deleteDisbursalQueue(_selectedRecord!.queueId);
      _showSnackbar('Disbursal record deleted.', isError: false);
      await _loadRecords();
      setState(() {
        _viewMode = 'GRID';
        _selectedRecord = null;
      });
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

  void _resetForm() {
    _queueIdController.text = 'Q-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _clientIdController.clear();
    _loanAmountController.clear();
    _deleteConfirmed = false;
  }

  void _loadRecord(DisbursalQueue record) {
    _queueIdController.text = record.queueId;
    _clientIdController.text = record.clientId;
    _loanAmountController.text = record.approvedAmount.toString();
    _deleteConfirmed = false;
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
    String title = 'Initiate Disbursal';
    if (_viewMode == 'CREATE') title = 'Initiate New Disbursal';
    if (_viewMode == 'VIEW') title = 'View Disbursal';
    if (_viewMode == 'DELETE') title = 'Delete Disbursal Record';

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
          const Text('Could not load disbursal data',
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
    switch (_viewMode) {
      case 'CREATE':
        return _buildForm();
      case 'VIEW':
        return _buildViewDetail();
      case 'DELETE':
        return _buildDeleteConfirmation();
      case 'GRID':
      default:
        return _buildGrid();
    }
  }

  // --------------------------------------------------------------------------
  // Grid
  // --------------------------------------------------------------------------
  Widget _buildGrid() {
    final filteredList = _records.where((r) {
      final query = _searchQuery.toLowerCase();
      return query.isEmpty ||
          r.queueId.toLowerCase().contains(query) ||
          r.clientId.toLowerCase().contains(query) ||
          r.disbursementStatus.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _records.length,
              label: 'Disbursal Records',
              icon: Icons.payments_outlined,
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
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _resetForm();
                    setState(() => _viewMode = 'CREATE');
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Initiate Disbursal', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF152238),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    Expanded(child: Text('QUEUE ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('CLIENT ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('LOAN AMOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('QUEUED DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 120, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              // Rows
              if (filteredList.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('No records found', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    final isEven = idx % 2 == 0;

                    Color statusColor = Colors.orange.shade700;
                    Color statusBg = Colors.orange.shade50;
                    if (item.disbursementStatus == 'Approved') { statusColor = Colors.green.shade700; statusBg = Colors.green.shade50; }
                    if (item.disbursementStatus == 'Rejected') { statusColor = Colors.red.shade700; statusBg = Colors.red.shade50; }
                    if (item.disbursementStatus == 'Pending Authorization') { statusColor = Colors.blue.shade700; statusBg = Colors.blue.shade50; }
                    if (item.disbursementStatus == 'Pending Input') { statusColor = Colors.deepOrange.shade700; statusBg = Colors.deepOrange.shade50; }

                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.queueId, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text(item.clientId)),
                          Expanded(child: Text('INR ${item.approvedAmount.toStringAsFixed(2)}')),
                          Expanded(child: Text(item.queuedDate.toIso8601String().substring(0, 10))),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                              child: Text(item.disbursementStatus,
                                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ActionIconBtn(
                                  icon: Icons.visibility_outlined,
                                  color: Colors.grey,
                                  onTap: () {
                                    _loadRecord(item);
                                    setState(() { _viewMode = 'VIEW'; _selectedRecord = item; });
                                  },
                                ),
                                ActionIconBtn(
                                  icon: Icons.delete_outline,
                                  color: Colors.red,
                                  onTap: () {
                                    _loadRecord(item);
                                    setState(() { _viewMode = 'DELETE'; _selectedRecord = item; });
                                  },
                                ),
                              ],
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
  // Create Form — only 3 fields
  // --------------------------------------------------------------------------
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Initiate Disbursal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
                    const SizedBox(height: 4),
                    Text('Fill all required fields marked with *',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
                  child: const Text('NEW RECORD',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E88E5))),
                ),
              ],
            ),
            const Divider(height: 32),

            // Info banner
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF1565C0), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Remaining disbursal details (product, tenure, interest, mode) can be filled in the Disbursement Queue screen.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
            ),

            // Only 3 input fields
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 300,
                  child: ProgramFormField(
                    label: 'Queue ID',
                    controller: _queueIdController,
                    prefixIcon: Icons.qr_code,
                    isRequired: true,
                    isLocked: false,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: ProgramFormField(
                    label: 'Client ID',
                    controller: _clientIdController,
                    prefixIcon: Icons.person_outline,
                    isRequired: true,
                    isLocked: false,
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: ProgramFormField(
                    label: 'Loan Amount',
                    controller: _loanAmountController,
                    prefixIcon: Icons.currency_rupee,
                    isRequired: true,
                    isLocked: false,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required field';
                      if (double.tryParse(val) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StandardButton(
                  label: 'Cancel',
                  isPrimary: false,
                  onPressed: () => setState(() => _viewMode = 'GRID'),
                ),
                const SizedBox(width: 16),
                StandardButton(
                  label: 'Initiate',
                  isPrimary: true,
                  onPressed: _saveRecord,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // View Detail (read-only)
  // --------------------------------------------------------------------------
  Widget _buildViewDetail() {
    final r = _selectedRecord!;
    Color statusColor = Colors.orange.shade700;
    if (r.disbursementStatus == 'Approved') statusColor = Colors.green.shade700;
    if (r.disbursementStatus == 'Rejected') statusColor = Colors.red.shade700;
    if (r.disbursementStatus == 'Pending Authorization') statusColor = Colors.blue.shade700;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Disbursal Record Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(r.disbursementStatus,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const Divider(height: 32),
          _viewRow('Queue ID', r.queueId),
          _viewRow('Client ID', r.clientId),
          _viewRow('Loan Amount', 'INR ${r.approvedAmount.toStringAsFixed(2)}'),
          _viewRow('Source System', r.sourceSystem),
          if (r.productCode.isNotEmpty) _viewRow('Product Code', r.productCode),
          if (r.approvedTenureMonths > 0) _viewRow('Approved Tenure', '${r.approvedTenureMonths} Months'),
          if (r.approvedInterestRate > 0) _viewRow('Interest Rate', '${r.approvedInterestRate}%'),
          _viewRow('Queued Date', r.queuedDate.toIso8601String().substring(0, 10)),
          const SizedBox(height: 24),
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

  Widget _viewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Delete Confirmation
  // --------------------------------------------------------------------------
  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RedDeleteBanner(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RECORD TO BE DELETED',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1.1)),
                const SizedBox(height: 16),
                _viewRow('Queue ID:', _selectedRecord?.queueId ?? ''),
                _viewRow('Client ID:', _selectedRecord?.clientId ?? ''),
                _viewRow('Loan Amount:', 'INR ${_selectedRecord?.approvedAmount.toStringAsFixed(2)}'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          DeleteConfirmationBox(
            checked: _deleteConfirmed,
            onChanged: (val) => setState(() => _deleteConfirmed = val ?? false),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StandardButton(
                label: 'Cancel',
                isPrimary: false,
                onPressed: () => setState(() => _viewMode = 'GRID'),
              ),
              const SizedBox(width: 16),
              StandardButton(
                label: 'Confirm Delete',
                isPrimary: true,
                isDestructive: true,
                onPressed: _deleteConfirmed ? _confirmDelete : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
