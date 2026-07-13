import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'shared_widgets.dart';

class DelinquencyBucketMasterScreen extends StatefulWidget {
  const DelinquencyBucketMasterScreen({super.key});

  @override
  State<DelinquencyBucketMasterScreen> createState() => _DelinquencyBucketMasterScreenState();
}

class _DelinquencyBucketMasterScreenState extends State<DelinquencyBucketMasterScreen> {
  final MockDatabase _db = MockDatabase();
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  DelinquencyBucketMaster? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  String? _selectedProductCode;
  final _delinquencyCodeController = TextEditingController();
  final _bucketLabelController = TextEditingController();
  final _overdueDaysFromController = TextEditingController();
  final _overdueDaysToController = TextEditingController();
  final _stageOrderController = TextEditingController();
  bool _isNpaFlagValue = false;
  final _provisionPctController = TextEditingController();
  bool _bucketStatus = true;

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
    _delinquencyCodeController.dispose();
    _bucketLabelController.dispose();
    _overdueDaysFromController.dispose();
    _overdueDaysToController.dispose();
    _stageOrderController.dispose();
    _provisionPctController.dispose();
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) setState(() {});
  }

  void _resetForm() {
    _orgCodeController.text = 'ORG01';
    _selectedProductCode = _db.loanProducts.isNotEmpty ? _db.loanProducts.first.productCode : null;
    _delinquencyCodeController.clear();
    _bucketLabelController.clear();
    _overdueDaysFromController.clear();
    _overdueDaysToController.clear();
    _stageOrderController.clear();
    _isNpaFlagValue = false;
    _provisionPctController.clear();
    _bucketStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(DelinquencyBucketMaster record) {
    _orgCodeController.text = record.orgCode;
    _selectedProductCode = record.productCode;
    _delinquencyCodeController.text = record.delinquencyCode;
    _bucketLabelController.text = record.bucketLabel;
    _overdueDaysFromController.text = record.overdueDaysFrom.toString();
    _overdueDaysToController.text = record.overdueDaysTo.toString();
    _stageOrderController.text = record.stageOrder.toString();
    _isNpaFlagValue = record.isNpaFlag;
    _provisionPctController.text = record.provisionPct.toString();
    _bucketStatus = record.bucketStatus;
    _deleteConfirmed = false;
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = DelinquencyBucketMaster(
        orgCode: _orgCodeController.text,
        productCode: _selectedProductCode ?? '',
        delinquencyCode: _delinquencyCodeController.text,
        bucketLabel: _bucketLabelController.text,
        overdueDaysFrom: int.tryParse(_overdueDaysFromController.text) ?? 0,
        overdueDaysTo: int.tryParse(_overdueDaysToController.text) ?? 0,
        stageOrder: int.tryParse(_stageOrderController.text) ?? 0,
        isNpaFlag: _isNpaFlagValue,
        provisionPct: double.tryParse(_provisionPctController.text) ?? 0.0,
        bucketStatus: _bucketStatus,
      );

      if (_viewMode == 'CREATE') {
        _db.addDelinquencyBucket(record);
      } else if (_viewMode == 'EDIT') {
        _db.updateDelinquencyBucket(record);
      }

      setState(() {
        _viewMode = 'GRID';
      });
    }
  }

  void _confirmDelete() {
    if (_selectedRecord != null) {
      _db.deleteDelinquencyBucket(_selectedRecord!.delinquencyCode);
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
    String title = 'Delinquency Bucket Master';
    if (_viewMode == 'CREATE') title = 'Add New Delinquency Bucket';
    if (_viewMode == 'EDIT') title = 'Edit Delinquency Bucket';
    if (_viewMode == 'VIEW') title = 'View Delinquency Bucket';
    if (_viewMode == 'DELETE') title = 'Delete Delinquency Bucket';

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
    final filteredList = _db.delinquencyBuckets.where((d) {
      final code = d.delinquencyCode.toLowerCase();
      final label = d.bucketLabel.toLowerCase();
      final prod = d.productCode.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || label.contains(query) || prod.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _db.delinquencyBuckets.length,
              label: 'Total Delinquency Buckets',
              icon: Icons.assignment_late,
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
                            hintText: 'Search buckets...',
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
                  label: const Text('New Bucket', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Expanded(child: Text('BUCKET CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('LABEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('DAYS RANGE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STAGE ORDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('PROVISION %', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('NPA?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                          Expanded(child: Text(item.productCode)),
                          Expanded(child: Text(item.delinquencyCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(item.bucketLabel)),
                          Expanded(child: Text('${item.overdueDaysFrom} - ${item.overdueDaysTo}')),
                          Expanded(child: Text('${item.stageOrder}')),
                          Expanded(child: Text('${item.provisionPct}%')),
                          Expanded(
                            child: Icon(
                              item.isNpaFlag ? Icons.check_circle : Icons.cancel_outlined,
                              color: item.isNpaFlag ? Colors.red : Colors.green,
                              size: 20,
                            ),
                          ),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.bucketStatus))),
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

    final productCodes = _db.loanProducts.map((p) => p.productCode).toList();

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
                      'Delinquency Bucket Details',
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
                  child: ProgramDropdownField(
                    label: 'Product Code',
                    value: _selectedProductCode,
                    items: productCodes,
                    prefixIcon: Icons.shopping_basket,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onChanged: (val) {
                      setState(() {
                        _selectedProductCode = val;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Delinquency Code',
                    controller: _delinquencyCodeController,
                    prefixIcon: Icons.code,
                    isRequired: true,
                    isLocked: isEdit || isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Bucket Label',
                    controller: _bucketLabelController,
                    prefixIcon: Icons.label,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Overdue Days From',
                    controller: _overdueDaysFromController,
                    prefixIcon: Icons.hourglass_empty,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Overdue Days To',
                    controller: _overdueDaysToController,
                    prefixIcon: Icons.hourglass_full,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Stage Order',
                    controller: _stageOrderController,
                    prefixIcon: Icons.format_list_numbered,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Provision Percentage (%)',
                    controller: _provisionPctController,
                    prefixIcon: Icons.percent,
                    isRequired: true,
                    isLocked: isView,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: Container(
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isView ? Colors.grey.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isView ? Colors.grey.shade300 : Colors.blue.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Is NPA?', style: TextStyle(color: Color(0xFF0288D1), fontSize: 11, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Regulatory NPA Status', style: TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                        Switch(
                          value: _isNpaFlagValue,
                          onChanged: isView
                              ? null
                              : (val) {
                                  setState(() {
                                    _isNpaFlagValue = val;
                                  });
                                },
                          activeColor: Colors.red,
                          activeTrackColor: Colors.red.shade100,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _bucketStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _bucketStatus = val;
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
                _buildDeleteField('Delinquency Code:', _selectedRecord?.delinquencyCode ?? ''),
                _buildDeleteField('Label:', _selectedRecord?.bucketLabel ?? ''),
                _buildDeleteField('Days Range:', '${_selectedRecord?.overdueDaysFrom} - ${_selectedRecord?.overdueDaysTo} days'),
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
