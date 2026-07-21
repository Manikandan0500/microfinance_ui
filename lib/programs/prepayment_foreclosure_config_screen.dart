import 'package:flutter/material.dart';
import 'services/prepayment_foreclosure_api_service.dart';
import 'models/prepayment_foreclosure_config.dart';
import 'shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class PrepaymentForeclosureConfigScreen extends StatefulWidget {
  const PrepaymentForeclosureConfigScreen({super.key});

  @override
  State<PrepaymentForeclosureConfigScreen> createState() => _PrepaymentForeclosureConfigScreenState();
}

class _PrepaymentForeclosureConfigScreenState extends State<PrepaymentForeclosureConfigScreen> {
  List<PrepaymentForeclosureConfig> _configs = [];
  bool _isLoading = false;
  String _currentOrgCode = '1';
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  PrepaymentForeclosureConfig? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  String? _selectedProductCode;
  final _lockInPeriodController = TextEditingController();
  String _prepaymentPenaltyType = 'Percentage'; // Percentage, Fixed
  final _prepaymentPenaltyValueController = TextEditingController();
  String _foreclosureFeeType = 'Percentage'; // Percentage, Fixed
  final _foreclosureFeeValueController = TextEditingController();
  String _scheduleRecalcMethod = 'Re-amortization'; // Re-amortization, Tenure Reduction
  bool _configStatus = true;

  // Delete confirm state
  bool _deleteConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadConfigs();
  }

  Future<void> _initUserAndLoadConfigs() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    _resetForm();
    await _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() => _isLoading = true);
    try {
      final configs = await PrepaymentForeclosureApiService.getConfigs(_currentOrgCode);
      if (mounted) setState(() => _configs = configs);
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
    _lockInPeriodController.dispose();
    _prepaymentPenaltyValueController.dispose();
    _foreclosureFeeValueController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _orgCodeController.text = _currentOrgCode;
    _selectedProductCode = null;
    _lockInPeriodController.clear();
    _prepaymentPenaltyType = 'Percentage';
    _prepaymentPenaltyValueController.clear();
    _foreclosureFeeType = 'Percentage';
    _foreclosureFeeValueController.clear();
    _scheduleRecalcMethod = 'Re-amortization';
    _configStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(PrepaymentForeclosureConfig record) {
    _orgCodeController.text = record.orgCode;
    _selectedProductCode = record.productCode;
    _lockInPeriodController.text = record.lockInPeriodMonths.toString();
    _prepaymentPenaltyType = record.prepaymentPenaltyType;
    _prepaymentPenaltyValueController.text = record.prepaymentPenaltyValue.toString();
    _foreclosureFeeType = record.foreclosureFeeType;
    _foreclosureFeeValueController.text = record.foreclosureFeeValue.toString();
    _scheduleRecalcMethod = record.scheduleRecalcMethod;
    _configStatus = record.configStatus;
    _deleteConfirmed = false;
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final record = PrepaymentForeclosureConfig(
          orgCode: _orgCodeController.text,
          productCode: _selectedProductCode ?? '',
          lockInPeriodMonths: int.tryParse(_lockInPeriodController.text) ?? 0,
          prepaymentPenaltyType: _prepaymentPenaltyType,
          prepaymentPenaltyValue: double.tryParse(_prepaymentPenaltyValueController.text) ?? 0.0,
          foreclosureFeeType: _foreclosureFeeType,
          foreclosureFeeValue: double.tryParse(_foreclosureFeeValueController.text) ?? 0.0,
          scheduleRecalcMethod: _scheduleRecalcMethod,
          configStatus: _configStatus,
        );

        if (_viewMode == 'CREATE') {
          await PrepaymentForeclosureApiService.createConfig(record);
          if (mounted) _showSnackbar('Configuration created successfully!');
        } else if (_viewMode == 'EDIT') {
          await PrepaymentForeclosureApiService.updateConfig(record);
          if (mounted) _showSnackbar('Configuration updated successfully!');
        }

        await _loadConfigs();
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
    String title = 'Prepayment / Foreclosure Configuration';
    if (_viewMode == 'CREATE') title = 'Add New Prepayment Configuration';
    if (_viewMode == 'EDIT') title = 'Edit Prepayment Configuration';
    if (_viewMode == 'VIEW') title = 'View Prepayment Configuration';
    if (_viewMode == 'DELETE') title = 'Delete Prepayment Configuration';

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
    final filteredList = _configs.where((p) {
      final prod = p.productCode.toLowerCase();
      final method = p.scheduleRecalcMethod.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return prod.contains(query) || method.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _configs.length,
              label: 'Total Configurations',
              icon: Icons.settings,
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
                            hintText: 'Search configs...',
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
                  label: const Text('New Config', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Expanded(child: Text('LOCK-IN PERIOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('PREPAY PENALTY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('FORECLOSURE FEE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('RECALC METHOD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                    final prepVal = item.prepaymentPenaltyType == 'Percentage' ? '${item.prepaymentPenaltyValue}%' : 'Rs. ${item.prepaymentPenaltyValue}';
                    final foreVal = item.foreclosureFeeType == 'Percentage' ? '${item.foreclosureFeeValue}%' : 'Rs. ${item.foreclosureFeeValue}';
                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.productCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(child: Text('${item.lockInPeriodMonths} months')),
                          Expanded(child: Text(prepVal)),
                          Expanded(child: Text(foreVal)),
                          Expanded(flex: 2, child: Text(item.scheduleRecalcMethod)),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.configStatus))),
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
                      'Prepayment Details',
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
                    onChanged: (val) {
                      _selectedProductCode = val;
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Lock-In Period (Months)',
                    controller: _lockInPeriodController,
                    prefixIcon: Icons.lock_clock,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Prepayment Penalty Type',
                    value: _prepaymentPenaltyType,
                    items: const ['Percentage', 'Fixed'],
                    prefixIcon: Icons.receipt_long,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _prepaymentPenaltyType = val ?? 'Percentage';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Prepayment Penalty Value',
                    controller: _prepaymentPenaltyValueController,
                    prefixIcon: Icons.money,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Foreclosure Fee Type',
                    value: _foreclosureFeeType,
                    items: const ['Percentage', 'Fixed'],
                    prefixIcon: Icons.policy,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _foreclosureFeeType = val ?? 'Percentage';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Foreclosure Fee Value',
                    controller: _foreclosureFeeValueController,
                    prefixIcon: Icons.attach_money,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Schedule Recalc Method',
                    value: _scheduleRecalcMethod,
                    items: const ['Re-amortization', 'Tenure Reduction'],
                    prefixIcon: Icons.settings_suggest,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _scheduleRecalcMethod = val ?? 'Re-amortization';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _configStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _configStatus = val;
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
                _buildDeleteField('Lock-In Months:', '${_selectedRecord?.lockInPeriodMonths} months'),
                _buildDeleteField('Prepayment Fee:', '${_selectedRecord?.prepaymentPenaltyValue} (${_selectedRecord?.prepaymentPenaltyType})'),
                _buildDeleteField('Foreclosure Fee:', '${_selectedRecord?.foreclosureFeeValue} (${_selectedRecord?.foreclosureFeeType})'),
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
