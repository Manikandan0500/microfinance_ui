import 'package:flutter/material.dart';
import 'services/asset_classification_gl_map_api_service.dart';
import 'models/asset_classification_gl_map.dart';
import 'shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

class AssetClassificationGlMapScreen extends StatefulWidget {
  const AssetClassificationGlMapScreen({super.key});

  @override
  State<AssetClassificationGlMapScreen> createState() => _AssetClassificationGlMapScreenState();
}

class _AssetClassificationGlMapScreenState extends State<AssetClassificationGlMapScreen> {
  List<AssetClassificationGlMap> _assetGlMaps = [];
  bool _isLoading = false;
  String _currentOrgCode = '1';
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  AssetClassificationGlMap? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  String? _selectedProductCode;
  String? _selectedDelinquencyCode;
  final _prinGlController = TextEditingController();
  final _intGlController = TextEditingController();
  final _provisionGlController = TextEditingController();
  bool _mapStatus = true;

  // Delete confirm state
  bool _deleteConfirmed = false;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadMaps();
  }

  Future<void> _initUserAndLoadMaps() async {
    final user = await AuthService().getUser();
    if (user != null && user.orgCode != null) {
      _currentOrgCode = user.orgCode.toString();
    }
    _resetForm();
    await _loadMaps();
  }

  Future<void> _loadMaps() async {
    setState(() => _isLoading = true);
    try {
      final maps = await AssetClassificationGlMapApiService.getMaps(_currentOrgCode);
      if (mounted) setState(() => _assetGlMaps = maps);
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
    _prinGlController.dispose();
    _intGlController.dispose();
    _provisionGlController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _orgCodeController.text = _currentOrgCode;
    _selectedProductCode = null;
    _selectedDelinquencyCode = null;
    _prinGlController.clear();
    _intGlController.clear();
    _provisionGlController.clear();
    _mapStatus = true;
    _deleteConfirmed = false;
  }



  void _loadRecord(AssetClassificationGlMap record) {
    _orgCodeController.text = record.orgCode;
    _selectedProductCode = record.productCode;
    _selectedDelinquencyCode = record.delinquencyCode;
    _prinGlController.text = record.prinGl;
    _intGlController.text = record.intGl;
    _provisionGlController.text = record.provisionGl;
    _mapStatus = record.mapStatus;
    _deleteConfirmed = false;
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final record = AssetClassificationGlMap(
          orgCode: _orgCodeController.text,
          productCode: _selectedProductCode ?? '',
          delinquencyCode: _selectedDelinquencyCode ?? '',
          prinGl: _prinGlController.text,
          intGl: _intGlController.text,
          provisionGl: _provisionGlController.text,
          mapStatus: _mapStatus,
        );

        if (_viewMode == 'CREATE') {
          await AssetClassificationGlMapApiService.createMap(record);
          if (mounted) _showSnackbar('GL Mapping created successfully!');
        } else if (_viewMode == 'EDIT') {
          await AssetClassificationGlMapApiService.updateMap(record);
          if (mounted) _showSnackbar('GL Mapping updated successfully!');
        }

        await _loadMaps();
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
    String title = 'Asset Classification GL Map';
    if (_viewMode == 'CREATE') title = 'Add New GL Mapping';
    if (_viewMode == 'EDIT') title = 'Edit GL Mapping';
    if (_viewMode == 'VIEW') title = 'View GL Mapping';
    if (_viewMode == 'DELETE') title = 'Delete GL Mapping';

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
    final filteredList = _assetGlMaps.where((a) {
      final prod = a.productCode.toLowerCase();
      final del = a.delinquencyCode.toLowerCase();
      final pGl = a.prinGl.toLowerCase();
      final iGl = a.intGl.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return prod.contains(query) || del.contains(query) || pGl.contains(query) || iGl.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _assetGlMaps.length,
              label: 'Total GL Mappings',
              icon: Icons.account_tree,
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
                            hintText: 'Search GL maps...',
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
                  label: const Text('New GL Map', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    Expanded(child: Text('DELINQUENCY BUCKET', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('PRINCIPAL GL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('INTEREST GL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('PROVISION GL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                          Expanded(child: Text(item.prinGl)),
                          Expanded(child: Text(item.intGl)),
                          Expanded(child: Text(item.provisionGl)),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.mapStatus))),
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
                      'Asset GL Map Details',
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
                    label: 'Delinquency Bucket',
                    controller: TextEditingController(text: _selectedDelinquencyCode)..addListener(() { _selectedDelinquencyCode = _selectedDelinquencyCode; }),
                    prefixIcon: Icons.warning_amber_rounded,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onChanged: (val) {
                      _selectedDelinquencyCode = val;
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Principal GL Account',
                    controller: _prinGlController,
                    prefixIcon: Icons.account_balance_wallet,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Interest GL Account',
                    controller: _intGlController,
                    prefixIcon: Icons.savings,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Provision GL Account',
                    controller: _provisionGlController,
                    prefixIcon: Icons.shield_outlined,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _mapStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _mapStatus = val;
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
                _buildDeleteField('Principal GL:', _selectedRecord?.prinGl ?? ''),
                _buildDeleteField('Interest GL:', _selectedRecord?.intGl ?? ''),
                _buildDeleteField('Provision GL:', _selectedRecord?.provisionGl ?? ''),
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
