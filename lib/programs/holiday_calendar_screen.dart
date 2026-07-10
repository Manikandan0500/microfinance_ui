import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'shared_widgets.dart';

class HolidayCalendarScreen extends StatefulWidget {
  const HolidayCalendarScreen({super.key});

  @override
  State<HolidayCalendarScreen> createState() => _HolidayCalendarScreenState();
}

class _HolidayCalendarScreenState extends State<HolidayCalendarScreen> {
  final MockDatabase _db = MockDatabase();
  String _viewMode = 'GRID'; // GRID, VIEW, CREATE, EDIT, DELETE
  HolidayCalendar? _selectedRecord;
  String _searchQuery = '';

  // Controllers
  final _formKey = GlobalKey<FormState>();
  final _orgCodeController = TextEditingController();
  final _branchCodeController = TextEditingController();
  DateTime _selectedHolidayDate = DateTime.now();
  final _holidayNameController = TextEditingController();
  String _holidayType = 'National'; // National, Public, Regional
  String _dueDateShiftRule = 'Shift Next'; // Shift Next, Shift Prev, No Shift
  bool _calendarStatus = true;

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
    _branchCodeController.dispose();
    _holidayNameController.dispose();
    super.dispose();
  }

  void _onDbChanged() {
    if (mounted) setState(() {});
  }

  void _resetForm() {
    _orgCodeController.text = 'ORG01';
    _branchCodeController.text = 'ALL';
    _selectedHolidayDate = DateTime.now();
    _holidayNameController.clear();
    _holidayType = 'National';
    _dueDateShiftRule = 'Shift Next';
    _calendarStatus = true;
    _deleteConfirmed = false;
  }

  void _loadRecord(HolidayCalendar record) {
    _orgCodeController.text = record.orgCode;
    _branchCodeController.text = record.branchCode;
    _selectedHolidayDate = record.holidayDate;
    _holidayNameController.text = record.holidayName;
    _holidayType = record.holidayType;
    _dueDateShiftRule = record.dueDateShiftRule;
    _calendarStatus = record.calendarStatus;
    _deleteConfirmed = false;
  }

  void _saveRecord() {
    if (_formKey.currentState!.validate()) {
      final record = HolidayCalendar(
        orgCode: _orgCodeController.text,
        branchCode: _branchCodeController.text,
        holidayDate: _selectedHolidayDate,
        holidayName: _holidayNameController.text,
        holidayType: _holidayType,
        dueDateShiftRule: _dueDateShiftRule,
        calendarStatus: _calendarStatus,
      );

      if (_viewMode == 'CREATE') {
        _db.addHoliday(record);
      } else if (_viewMode == 'EDIT') {
        _db.updateHoliday(record);
      }

      setState(() {
        _viewMode = 'GRID';
      });
    }
  }

  void _confirmDelete() {
    if (_selectedRecord != null) {
      _db.deleteHoliday(_selectedRecord!.branchCode, _selectedRecord!.holidayDate);
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
    String title = 'Holiday Calendar';
    if (_viewMode == 'CREATE') title = 'Add New Holiday';
    if (_viewMode == 'EDIT') title = 'Edit Holiday';
    if (_viewMode == 'VIEW') title = 'View Holiday';
    if (_viewMode == 'DELETE') title = 'Delete Holiday';

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

  Widget _buildGrid() {
    final filteredList = _db.holidays.where((h) {
      final branch = h.branchCode.toLowerCase();
      final name = h.holidayName.toLowerCase();
      final type = h.holidayType.toLowerCase();
      final query = _searchQuery.toLowerCase();
      return branch.contains(query) || name.contains(query) || type.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TotalRecordsCard(
              count: _db.holidays.length,
              label: 'Total Holidays Set',
              icon: Icons.calendar_month,
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
                            hintText: 'Search holidays...',
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
                  label: const Text('New Holiday', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: Color(0xFF152238),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: const Row(
                  children: [
                    Expanded(child: Text('BRANCH CODE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('HOLIDAY DATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('HOLIDAY NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('HOLIDAY TYPE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('DUE DATE SHIFT RULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
                    final dateStr = '${item.holidayDate.day.toString().padLeft(2, '0')}-${item.holidayDate.month.toString().padLeft(2, '0')}-${item.holidayDate.year}';
                    return Container(
                      color: isEven ? Colors.white : const Color(0xFFF8F9FA),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(item.branchCode)),
                          Expanded(child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(item.holidayName)),
                          Expanded(child: Text(item.holidayType)),
                          Expanded(flex: 2, child: Text(item.dueDateShiftRule)),
                          Expanded(child: Align(alignment: Alignment.centerLeft, child: StatusPill(status: item.calendarStatus))),
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
                      'Holiday Details',
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
                    label: 'Branch Code',
                    controller: _branchCodeController,
                    prefixIcon: Icons.store,
                    isRequired: true,
                    isLocked: isEdit || isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDateField(
                    label: 'Holiday Date',
                    selectedDate: _selectedHolidayDate,
                    prefixIcon: Icons.calendar_today,
                    isRequired: true,
                    isLocked: isEdit || isView,
                    onDateSelected: (date) {
                      setState(() {
                        _selectedHolidayDate = date;
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramFormField(
                    label: 'Holiday Name',
                    controller: _holidayNameController,
                    prefixIcon: Icons.event,
                    isRequired: true,
                    isLocked: isView,
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Holiday Type',
                    value: _holidayType,
                    items: const ['National', 'Public', 'Regional'],
                    prefixIcon: Icons.category,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _holidayType = val ?? 'National';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramDropdownField(
                    label: 'Due Date Shift Rule',
                    value: _dueDateShiftRule,
                    items: const ['Shift Next', 'Shift Prev', 'No Shift'],
                    prefixIcon: Icons.next_plan,
                    isRequired: true,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _dueDateShiftRule = val ?? 'Shift Next';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: ProgramStatusToggle(
                    value: _calendarStatus,
                    isLocked: isView,
                    onChanged: (val) {
                      setState(() {
                        _calendarStatus = val;
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
        ? '${_selectedRecord!.holidayDate.day.toString().padLeft(2, '0')}-${_selectedRecord!.holidayDate.month.toString().padLeft(2, '0')}-${_selectedRecord!.holidayDate.year}'
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
                _buildDeleteField('Org Code:', _selectedRecord?.orgCode ?? ''),
                _buildDeleteField('Branch Code:', _selectedRecord?.branchCode ?? ''),
                _buildDeleteField('Holiday Date:', dateStr),
                _buildDeleteField('Holiday Name:', _selectedRecord?.holidayName ?? ''),
                _buildDeleteField('Shift Rule:', _selectedRecord?.dueDateShiftRule ?? ''),
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A1628)),
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
