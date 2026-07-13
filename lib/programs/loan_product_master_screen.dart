import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'shared_widgets.dart';

class LoanProductMasterScreen extends StatefulWidget {
  const LoanProductMasterScreen({super.key});

  @override
  State<LoanProductMasterScreen> createState() => _LoanProductMasterScreenState();
}

class _LoanProductMasterScreenState extends State<LoanProductMasterScreen> {
  final MockDatabase _db = MockDatabase();
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  LoanProductMaster? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  final _productCodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();
  final _interestRateController = TextEditingController();
  String _interestType = 'Reducing'; // Flat, Reducing
  String _rateType = 'Fixed'; // Fixed, Floating
  final _benchmarkRateCodeController = TextEditingController();
  final _minTenureController = TextEditingController();
  final _maxTenureController = TextEditingController();
  String _repayFrequency = 'Monthly'; // Monthly, Weekly, Fortnightly
  final _prinGlController = TextEditingController();
  final _intGlController = TextEditingController();
  final _penalGlController = TextEditingController();
  bool _productStatus = true;

  // Delete confirm state
  bool _deleteConfirmed = false;

  @override
  void initState() {
    super.initState();
    _db.addListener(_onDbChanged);
  }

  @override
  void dispose() {
    _db.removeListener(_onDbChanged);
    _orgCodeController.dispose();
    _productCodeController.dispose();
    _productNameController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _interestRateController.dispose();
    _benchmarkRateCodeController.dispose();
    _minTenureController.dispose();
    _maxTenureController.dispose();
    _prinGlController.dispose();
    _intGlController.dispose();
    _penalGlController.dispose();
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) setState(() {});
  }

  void _resetForm() {
    _orgCodeController.text = 'ORG01';
    _productCodeController.clear();
    _productNameController.clear();
    _minAmountController.clear();
    _maxAmountController.clear();
    _interestRateController.clear();
    _interestType = 'Reducing';
    _rateType = 'Fixed';
    _benchmarkRateCodeController.text = 'BASE-RATE';
    _minTenureController.clear();
    _maxTenureController.clear();
    _repayFrequency = 'Monthly';
    _prinGlController.clear();
    _intGlController.clear();
    _penalGlController.clear();
    _productStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(LoanProductMaster record) {
    _orgCodeController.text = record.orgCode;
    _productCodeController.text = record.productCode;
    _productNameController.text = record.productName;
    _minAmountController.text = record.minAmount.toString();
    _maxAmountController.text = record.maxAmount.toString();
    _interestRateController.text = record.interestRate.toString();
    _interestType = record.interestType;
    _rateType = record.rateType;
    _benchmarkRateCodeController.text = record.benchmarkRateCode;
    _minTenureController.text = record.minTenureMonths.toString();
    _maxTenureController.text = record.maxTenureMonths.toString();
    _repayFrequency = record.repayFrequency;
    _prinGlController.text = record.prinGl;
    _intGlController.text = record.intGl;
    _penalGlController.text = record.penalGl;
    _productStatus = record.productStatus;
    _deleteConfirmed = false;
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = LoanProductMaster(
        orgCode: _orgCodeController.text,
        productCode: _productCodeController.text,
        productName: _productNameController.text,
        minAmount: double.tryParse(_minAmountController.text) ?? 0.0,
        maxAmount: double.tryParse(_maxAmountController.text) ?? 0.0,
        interestRate: double.tryParse(_interestRateController.text) ?? 0.0,
        interestType: _interestType,
        rateType: _rateType,
        benchmarkRateCode: _benchmarkRateCodeController.text,
        minTenureMonths: int.tryParse(_minTenureController.text) ?? 0,
        maxTenureMonths: int.tryParse(_maxTenureController.text) ?? 0,
        repayFrequency: _repayFrequency,
        prinGl: _prinGlController.text,
        intGl: _intGlController.text,
        penalGl: _penalGlController.text,
        productStatus: _productStatus,
      );

      if (_viewMode == 'CREATE') {
        _db.addLoanProduct(record);
      } else if (_viewMode == 'EDIT') {
        _db.updateLoanProduct(record);
      }

      setState(() {
        _viewMode = 'GRID';
      });
    }
  }

  void _confirmDelete() {
    if (_selectedRecord != null) {
      _db.deleteLoanProduct(_selectedRecord!.productCode);
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
    String title = 'Loan Product Master';
    if (_viewMode == 'CREATE') title = 'Add New Loan Product';
    if (_viewMode == 'EDIT') title = 'Edit Loan Product';
    if (_viewMode == 'VIEW') title = 'View Loan Product';
    if (_viewMode == 'DELETE') title = 'Delete Loan Product';

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
    final filteredList = _db.loanProducts.where((l) {
      final code = l.productCode.toLowerCase();
      final name = l.productName.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _db.loanProducts.length,
              label: 'Total Loan Products',
              icon: Icons.account_balance,
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
                            hintText: 'Search products...',
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
                  label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Expanded(flex: 2, child: Text('PRODUCT NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('INT RATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('RATE TYPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('AMOUNT RANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('TENURE RANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.productCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(item.productName)),
                          Expanded(child: Text('${item.interestRate}% (${item.interestType})')),
                          Expanded(child: Text(item.rateType)),
                          Expanded(child: Text('${item.minAmount.toInt()} - ${item.maxAmount.toInt()}')),
                          Expanded(child: Text('${item.minTenureMonths}m - ${item.maxTenureMonths}m')),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.productStatus))),
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
                      'Loan Product Details',
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
                    controller: _productCodeController,
                    prefixIcon: Icons.code,
                    isRequired: true,
                    isLocked: isEdit || isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Product Name',
                    controller: _productNameController,
                    prefixIcon: Icons.badge,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Interest Rate (%)',
                    controller: _interestRateController,
                    prefixIcon: Icons.percent,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Interest Type',
                    value: _interestType,
                    items: const ['Flat', 'Reducing'],
                    prefixIcon: Icons.timeline,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _interestType = val ?? 'Reducing';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Rate Type',
                    value: _rateType,
                    items: const ['Fixed', 'Floating'],
                    prefixIcon: Icons.trending_up,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _rateType = val ?? 'Fixed';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Benchmark Rate Code',
                    controller: _benchmarkRateCodeController,
                    prefixIcon: Icons.show_chart,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Min Amount',
                    controller: _minAmountController,
                    prefixIcon: Icons.attach_money,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Max Amount',
                    controller: _maxAmountController,
                    prefixIcon: Icons.monetization_on,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Min Tenure (Months)',
                    controller: _minTenureController,
                    prefixIcon: Icons.calendar_today,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Max Tenure (Months)',
                    controller: _maxTenureController,
                    prefixIcon: Icons.date_range,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Repayment Frequency',
                    value: _repayFrequency,
                    items: const ['Monthly', 'Weekly', 'Fortnightly'],
                    prefixIcon: Icons.repeat,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _repayFrequency = val ?? 'Monthly';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Principal GL Code',
                    controller: _prinGlController,
                    prefixIcon: Icons.account_balance_wallet,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Interest GL Code',
                    controller: _intGlController,
                    prefixIcon: Icons.savings,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Penal GL Code',
                    controller: _penalGlController,
                    prefixIcon: Icons.gavel,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _productStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _productStatus = val;
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
                _buildDeleteField('Product Name:', _selectedRecord?.productName ?? ''),
                _buildDeleteField('Interest Rate:', '${_selectedRecord?.interestRate}%'),
                _buildDeleteField('Principal GL Code:', _selectedRecord?.prinGl ?? ''),
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
            width: 150,
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
