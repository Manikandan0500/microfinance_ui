import 'package:flutter/material.dart';
import 'services/penalty_rate_api_service.dart';
import 'models/penalty_rate_history.dart';
import 'shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class PenaltyRateHistoryScreen extends StatefulWidget {
  const PenaltyRateHistoryScreen({super.key});

  @override
  State<PenaltyRateHistoryScreen> createState() => _PenaltyRateHistoryScreenState();
}

class _PenaltyRateHistoryScreenState extends State<PenaltyRateHistoryScreen> {
  List<PenaltyRateHistory> _penaltyRates = [];
  bool _isLoading = false;
  String _currentOrgCode = '1';
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  PenaltyRateHistory? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  String? _selectedProductCode;
  String? _selectedDelinquencyCode;
  DateTime _selectedEffDate = DateTime.now();
  String _penaltyType = 'Percentage'; // Percentage, Fixed Amount
  final _penaltyValueController = TextEditingController();
  bool _rateStatus = true;

  // Delete confirm state
  bool _deleteConfirmed = false;

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
    await _loadRates();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoading = true);
    try {
      final rates = await PenaltyRateApiService.getRates(_currentOrgCode);
      if (mounted) setState(() => _penaltyRates = rates);
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
    _penaltyValueController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _orgCodeController.text = _currentOrgCode;
    _selectedProductCode = null;
    _selectedDelinquencyCode = null;
    _selectedEffDate = DateTime.now();
    _penaltyType = 'Percentage';
    _penaltyValueController.clear();
    _rateStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(PenaltyRateHistory record) {
    _orgCodeController.text = record.orgCode;
    _selectedProductCode = record.productCode;
    _selectedDelinquencyCode = record.delinquencyCode;
    _selectedEffDate = record.effDate;
    _penaltyType = record.penaltyType;
    _penaltyValueController.text = record.penaltyValue.toString();
    _rateStatus = record.rateStatus;
    _deleteConfirmed = false;
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final record = PenaltyRateHistory(
          orgCode: _orgCodeController.text,
          productCode: _selectedProductCode ?? '',
          delinquencyCode: _selectedDelinquencyCode ?? '',
          effDate: _selectedEffDate,
          penaltyType: _penaltyType,
          penaltyValue: double.tryParse(_penaltyValueController.text) ?? 0.0,
          rateStatus: _rateStatus,
        );

        if (_viewMode == 'CREATE') {
          await PenaltyRateApiService.createRate(record);
          if (mounted) _showSnackbar('Rate created successfully!');
        } else if (_viewMode == 'EDIT') {
          await PenaltyRateApiService.updateRate(record);
          if (mounted) _showSnackbar('Rate updated successfully!');
        }
        
        await _loadRates();
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
      child: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
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
    String title = 'Penalty Rate History';
    if (_viewMode == 'CREATE') title = 'Add New Penalty Rate Configuration';
    if (_viewMode == 'EDIT') title = 'Edit Penalty Rate Configuration';
    if (_viewMode == 'VIEW') title = 'View Penalty Rate Configuration';
    if (_viewMode == 'DELETE') title = 'Delete Penalty Rate Configuration';

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
    final filteredList = _penaltyRates.where((r) {
      final prod = r.productCode.toLowerCase();
      final delinq = r.delinquencyCode.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return prod.contains(query) || delinq.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _penaltyRates.length,
              label: 'Total Penalty Rates',
              icon: Icons.gavel,
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
                            hintText: 'Search...',
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
                  label: const Text('New Penalty Rate', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0288D1),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(child: Text('PRODUCT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('DELINQUENCY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('TYPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('VALUE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 100, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ],
                ),
              ),
              if (filteredList.isEmpty)
                const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No records found'))),
              ...filteredList.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  children: [
                    Expanded(child: Text(item.productCode)),
                    Expanded(child: Text(item.delinquencyCode)),
                    Expanded(child: Text('${item.effDate.day}-${item.effDate.month}-${item.effDate.year}')),
                    Expanded(child: Text(item.penaltyType)),
                    Expanded(child: Text(item.penaltyValue.toString())),
                    Expanded(child: StatusPill(status: item.rateStatus)),
                    SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ActionIconBtn(
                            icon: Icons.visibility_outlined,
                            color: Colors.blue,
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
                            color: Colors.orange,
                            onTap: () {
                              _loadRecord(item);
                              setState(() {
                                _viewMode = 'EDIT';
                                _selectedRecord = item;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final isView = _viewMode == 'VIEW';
    final isEdit = _viewMode == 'EDIT';

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
                      'Penalty Rate Details',
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
                    controller: TextEditingController(text: _selectedProductCode)..addListener(() { _selectedProductCode = _selectedProductCode; }),
                    prefixIcon: Icons.shopping_basket,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onChanged: (val) { _selectedProductCode = val; },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Delinquency Code',
                    controller: TextEditingController(text: _selectedDelinquencyCode)..addListener(() { _selectedDelinquencyCode = _selectedDelinquencyCode; }),
                    prefixIcon: Icons.warning_amber_rounded,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onChanged: (val) { _selectedDelinquencyCode = val; },
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
                  child: ProgramDropdownField(
                    label: 'Penalty Type',
                    value: _penaltyType,
                    items: const ['Percentage', 'Fixed'],
                    prefixIcon: Icons.payment,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _penaltyType = val ?? 'Percentage';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Penalty Value',
                    controller: _penaltyValueController,
                    prefixIcon: Icons.money,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _rateStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _rateStatus = val;
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
                _buildDeleteField('Delinquency Code:', _selectedRecord?.delinquencyCode ?? ''),
                _buildDeleteField('Effective Date:', dateStr),
                _buildDeleteField('Penalty Rate:', _selectedRecord?.penaltyType == 'Percentage' ? '${_selectedRecord?.penaltyValue}%' : 'Rs. ${_selectedRecord?.penaltyValue}'),
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
