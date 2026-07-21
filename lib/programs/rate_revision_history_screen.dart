import 'package:flutter/material.dart';
import 'services/rate_revision_api_service.dart';
import 'models/rate_revision_history.dart';
import 'shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class RateRevisionHistoryScreen extends StatefulWidget {
  const RateRevisionHistoryScreen({super.key});

  @override
  State<RateRevisionHistoryScreen> createState() => _RateRevisionHistoryScreenState();
}

class _RateRevisionHistoryScreenState extends State<RateRevisionHistoryScreen> {
  List<RateRevisionHistory> _rateRevisions = [];
  bool _isLoading = false;
  String _currentOrgCode = '1';
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  RateRevisionHistory? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  String? _selectedProductCode;
  DateTime _selectedEffDate = DateTime.now();
  final _revisedRateController = TextEditingController();
  final _benchmarkRateCodeController = TextEditingController();
  final _spreadPctController = TextEditingController();
  final _revisionReasonController = TextEditingController();
  bool _revisionStatus = true;

  // Delete confirm state
  bool _deleteConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadRevisions();
  }

  Future<void> _initUserAndLoadRevisions() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    _resetForm();
    await _loadRevisions();
  }

  Future<void> _loadRevisions() async {
    setState(() => _isLoading = true);
    try {
      final revisions = await RateRevisionApiService.getRevisions(_currentOrgCode);
      if (mounted) setState(() => _rateRevisions = revisions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _orgCodeController.dispose();
    _revisedRateController.dispose();
    _benchmarkRateCodeController.dispose();
    _spreadPctController.dispose();
    _revisionReasonController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _orgCodeController.text = _currentOrgCode;
    _selectedProductCode = null;
    _selectedEffDate = DateTime.now();
    _revisedRateController.clear();
    _benchmarkRateCodeController.text = 'MCLR-6M';
    _spreadPctController.clear();
    _revisionReasonController.clear();
    _revisionStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(RateRevisionHistory record) {
    _orgCodeController.text = record.orgCode;
    _selectedProductCode = record.productCode;
    _selectedEffDate = record.effDate;
    _revisedRateController.text = record.revisedRate.toString();
    _benchmarkRateCodeController.text = record.benchmarkRateCode;
    _spreadPctController.text = record.spreadPct.toString();
    _revisionReasonController.text = record.revisionReason;
    _revisionStatus = record.revisionStatus;
    _deleteConfirmed = false;
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final record = RateRevisionHistory(
          orgCode: _orgCodeController.text,
          productCode: _selectedProductCode ?? '',
          effDate: _selectedEffDate,
          revisedRate: double.tryParse(_revisedRateController.text) ?? 0.0,
          benchmarkRateCode: _benchmarkRateCodeController.text,
          spreadPct: double.tryParse(_spreadPctController.text) ?? 0.0,
          revisionReason: _revisionReasonController.text,
          revisionStatus: _revisionStatus,
        );

        if (_viewMode == 'CREATE') {
          await RateRevisionApiService.createRevision(record);
          if (mounted) _showSnackbar('Revision created successfully!');
        } else if (_viewMode == 'EDIT') {
          await RateRevisionApiService.updateRevision(record);
          if (mounted) _showSnackbar('Revision updated successfully!');
        }
        
        await _loadRevisions();
        if (mounted) setState(() => _viewMode = 'GRID');
      } catch (e) {
        if (mounted) _showSnackbar(e.toString().replaceFirst('Exception: ', ''), isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmDelete() {
    if (_selectedRecord != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Delete not supported by API')));
      setState(() {
        _viewMode = 'GRID';
        _selectedRecord = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(),
          const SizedBox(height: 24),
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
    String title = 'Rate Revision History';
    if (_viewMode == 'CREATE') title = 'Add New Rate Revision';
    if (_viewMode == 'EDIT') title = 'Edit Rate Revision';
    if (_viewMode == 'VIEW') title = 'View Rate Revision';
    if (_viewMode == 'DELETE') title = 'Delete Rate Revision';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF01579B),
          ),
        ),
        if (_viewMode != 'GRID')
          StandardButton(
            label: 'Back',
            isPrimary: false,
            onPressed: () {
              setState(() {
                _viewMode = 'GRID';
              });
            },
          ),
      ],
    );
  }

  Widget _buildMainContent() {
    switch (_viewMode) {
      case 'CREATE':
      case 'EDIT':
      case 'VIEW':
        return _buildForm();
      case 'DELETE':
        return _buildDeleteConfirmation();
      case 'GRID':
      default:
        return _buildGrid();
    }
  }

  Widget _buildGrid() {
    final filteredList = _rateRevisions.where((r) {
      final prod = r.productCode.toLowerCase();
      final reason = r.revisionReason.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return prod.contains(query) || reason.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _rateRevisions.length,
              label: 'Total Rate Revisions',
              icon: Icons.rate_review,
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
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search revisions...',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _resetForm();
                    setState(() {
                      _viewMode = 'CREATE';
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('New Revision', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0288D1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(child: Text('PRODUCT CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('EFFECTIVE DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('REVISED RATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('BENCHMARK CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('SPREAD %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('REASON', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 140, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),

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
                    final dateStr = '${item.effDate.day.toString().padLeft(2, '0')}-${item.effDate.month.toString().padLeft(2, '0')}-${item.effDate.year}';
                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.productCode)),
                          Expanded(child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('${item.revisedRate}%')),
                          Expanded(child: Text(item.benchmarkRateCode)),
                          Expanded(child: Text('${item.spreadPct}%')),
                          Expanded(flex: 2, child: Text(item.revisionReason)),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.revisionStatus))),
                          SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ActionIconBtn(
                                  icon: Icons.visibility_outlined,
                                  color: Colors.grey,
                                  onTap: () {
                                    _loadRecord(item);
                                    setState(() {
                                      _viewMode = 'VIEW';
                                      _selectedRecord = item;
                                    });
                                  },
                                ),
                                ActionIconBtn(
                                  icon: Icons.edit_outlined,
                                  color: const Color(0xFF0288D1),
                                  onTap: () {
                                    _loadRecord(item);
                                    setState(() {
                                      _viewMode = 'EDIT';
                                      _selectedRecord = item;
                                    });
                                  },
                                ),
                                ActionIconBtn(
                                  icon: Icons.delete_outline,
                                  color: Colors.red,
                                  onTap: () {
                                    _loadRecord(item);
                                    setState(() {
                                      _viewMode = 'DELETE';
                                      _selectedRecord = item;
                                    });
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

  Widget _buildForm() {
    final isView = _viewMode == 'VIEW';
    final isEdit = _viewMode == 'EDIT';

    // Since we don't have LoanProduct API loading in this screen yet, we will just use a text field for product code
    // Or we could fetch it, but for simplicity we'll allow free-text input if the list is empty.

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
                    const Text(
                      'Rate Revision Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isView ? 'View-only details for this record' : 'Fill all required fields marked with *',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isView
                        ? Colors.grey.shade100
                        : isEdit
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isView
                        ? 'VIEW RECORD'
                        : isEdit
                            ? 'EDIT MODE'
                            : 'NEW RECORD',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isView
                          ? Colors.grey.shade700
                          : isEdit
                              ? Colors.orange.shade800
                              : const Color(0xFF1E88E5),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            if (isEdit) const YellowNoticeBar(),

            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Product Code',
                    controller: TextEditingController(text: _selectedProductCode)
                      ..addListener(() {
                        _selectedProductCode = _selectedProductCode;
                      }),
                    prefixIcon: Icons.shopping_basket,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onChanged: (val) {
                      _selectedProductCode = val;
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDateField(
                    label: 'Effective Date',
                    selectedDate: _selectedEffDate,
                    prefixIcon: Icons.calendar_today,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedEffDate = date;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Revised Rate (%)',
                    controller: _revisedRateController,
                    prefixIcon: Icons.percent,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Benchmark Rate Code',
                    controller: _benchmarkRateCodeController,
                    prefixIcon: Icons.show_chart,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Spread (%)',
                    controller: _spreadPctController,
                    prefixIcon: Icons.trending_up,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Revision Reason',
                    controller: _revisionReasonController,
                    prefixIcon: Icons.question_answer_outlined,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _revisionStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _revisionStatus = val;
                      });
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
                  label: isView ? 'Close' : 'Cancel',
                  isPrimary: false,
                  onPressed: () {
                    setState(() {
                      _viewMode = 'GRID';
                    });
                  },
                ),
                if (!isView) ...[
                  const SizedBox(width: 16),
                  StandardButton(
                    label: isEdit ? 'Save Changes' : 'Create Record',
                    isPrimary: true,
                    onPressed: _saveRecord,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteConfirmation() {
    final dateStr = _selectedRecord != null
        ? '${_selectedRecord!.effDate.day.toString().padLeft(2, '0')}-${_selectedRecord!.effDate.month.toString().padLeft(2, '0')}-${_selectedRecord!.effDate.year}'
        : '';
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
                Text(
                  'RECORD TO BE DELETED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDeleteField('Product Code:', _selectedRecord?.productCode ?? ''),
                _buildDeleteField('Effective Date:', dateStr),
                _buildDeleteField('Revised Rate:', '${_selectedRecord?.revisedRate}%'),
                _buildDeleteField('Revision Reason:', _selectedRecord?.revisionReason ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 24),

          DeleteConfirmationBox(
            checked: _deleteConfirmed,
            onChanged: (val) {
              setState(() {
                _deleteConfirmed = val ?? false;
              });
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              StandardButton(
                label: 'Cancel',
                isPrimary: false,
                onPressed: () {
                  setState(() {
                    _viewMode = 'GRID';
                  });
                },
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

  Widget _buildDeleteField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF01579B)),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
