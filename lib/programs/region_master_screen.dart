import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'shared_widgets.dart';

class RegionMasterScreen extends StatefulWidget {
  const RegionMasterScreen({super.key});

  @override
  State<RegionMasterScreen> createState() => _RegionMasterScreenState();
}

class _RegionMasterScreenState extends State<RegionMasterScreen> {
  final MockDatabase _db = MockDatabase();
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  RegionMaster? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  final _regionCodeController = TextEditingController();
  final _regionNameController = TextEditingController();
  final _stateController = TextEditingController();
  final _zoneController = TextEditingController();
  bool _statusValue = true;

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
    _regionCodeController.dispose();
    _regionNameController.dispose();
    _stateController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) setState(() {});
  }

  void _resetForm() {
    _orgCodeController.text = 'ORG01';
    _regionCodeController.clear();
    _regionNameController.clear();
    _stateController.clear();
    _zoneController.clear();
    _statusValue = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(RegionMaster record) {
    _orgCodeController.text = record.orgCode;
    _regionCodeController.text = record.regionCode;
    _regionNameController.text = record.regionName;
    _stateController.text = record.state;
    _zoneController.text = record.zone;
    _statusValue = record.status;
    _deleteConfirmed = false;
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = RegionMaster(
        orgCode: _orgCodeController.text,
        regionCode: _regionCodeController.text,
        regionName: _regionNameController.text,
        state: _stateController.text,
        zone: _zoneController.text,
        status: _statusValue,
      );

      if (_viewMode == 'CREATE') {
        _db.addRegion(record);
      } else if (_viewMode == 'EDIT') {
        _db.updateRegion(record);
      }

      setState(() {
        _viewMode = 'GRID';
      });
    }
  }

  void _confirmDelete() {
    if (_selectedRecord != null) {
      _db.deleteRegion(_selectedRecord!.regionCode);
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
          // Screen Title / Navigation Header
          _buildScreenHeader(),
          const SizedBox(height: 24),
          // Main dynamic area
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
    String title = 'Region Master';
    if (_viewMode == 'CREATE') title = 'Add New Region Master';
    if (_viewMode == 'EDIT') title = 'Edit Region Master';
    if (_viewMode == 'VIEW') title = 'View Region Master';
    if (_viewMode == 'DELETE') title = 'Delete Region Master';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1628),
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

  // --- Grid View Screen ---
  Widget _buildGrid() {
    final filteredList = _db.regions.where((r) {
      final code = r.regionCode.toLowerCase();
      final name = r.regionName.toLowerCase();
      final state = r.state.toLowerCase();
      final zone = r.zone.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query) || state.contains(query) || zone.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid Summary Card & Action Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _db.regions.length,
              label: 'Total Regions',
              icon: Icons.location_city,
            ),
            Row(
              children: [
                // Search bar
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
                            hintText: 'Search regions...',
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Create Button
                ElevatedButton.icon(
                  onPressed: () {
                    _resetForm();
                    setState(() {
                      _viewMode = 'CREATE';
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('New Region', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF152238),
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

        // Grid Table
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
              // Table Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF152238),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(child: Text('ORG CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('REGION CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('REGION NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('ZONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('STATUS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 140, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.orgCode)),
                          Expanded(child: Text(item.regionCode, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(item.regionName)),
                          Expanded(child: Text(item.state)),
                          Expanded(child: Text(item.zone)),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.status))),
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
                                  color: const Color(0xFF152238),
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

  // --- Create/Edit/View Form Screen ---
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
            // Detail Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Region Master Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
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

            // Form Inputs Grid
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Organization Code',
                    controller: _orgCodeController,
                    prefixIcon: Icons.business,
                    isRequired: true,
                    isLocked: isEdit || isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Region Code',
                    controller: _regionCodeController,
                    prefixIcon: Icons.qr_code,
                    isRequired: true,
                    isLocked: isEdit || isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Region Name',
                    controller: _regionNameController,
                    prefixIcon: Icons.map,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'State',
                    controller: _stateController,
                    prefixIcon: Icons.location_on,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Zone',
                    controller: _zoneController,
                    prefixIcon: Icons.explore,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _statusValue,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _statusValue = val;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Form Buttons
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

  // --- Delete Screen ---
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

          // Record Details Display
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
                _buildDeleteField('Org Code:', _selectedRecord?.orgCode ?? ''),
                _buildDeleteField('Region Code:', _selectedRecord?.regionCode ?? ''),
                _buildDeleteField('Region Name:', _selectedRecord?.regionName ?? ''),
                _buildDeleteField('State:', _selectedRecord?.state ?? ''),
                _buildDeleteField('Zone:', _selectedRecord?.zone ?? ''),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Warning check box
          DeleteConfirmationBox(
            checked: _deleteConfirmed,
            onChanged: (val) {
              setState(() {
                _deleteConfirmed = val ?? false;
              });
            },
          ),

          // Actions
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
