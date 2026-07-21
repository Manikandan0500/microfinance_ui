import 'package:flutter/material.dart';
import 'mock_database.dart';
import 'shared_widgets.dart';
import 'models/auth_models.dart';
import 'services/auth_api_service.dart';

class AuthConfigScreen extends StatefulWidget {
  const AuthConfigScreen({super.key});

  @override
  State<AuthConfigScreen> createState() => _AuthConfigScreenState();
}

class _AuthConfigScreenState extends State<AuthConfigScreen> {
  String _searchQuery = '';
  List<Auth101Config> _configs = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Form State
  bool _showForm = false;
  final String _orgCode = '101 - BBOTS';
  String? _selectedProgram;
  bool _approvalReq = true;
  bool _preApprove = false;
  bool _postApprove = false;
  bool _isTran = false;

  final List<String> _programs = ['LOANMST', 'REGMAS', 'BRANCHMST', 'USERMST', 'LOANDISB', 'LOANDBM', 'LOANPRH', 'LOANGLM', 'LOANRRH', 'HOLICAL', 'LOANPFC'];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final configMap = await AuthApiService.getAuthConfigs();
      setState(() {
        _configs = configMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitForm() async {
    if (_selectedProgram == null) {
      _showSnackbar('Please select a Program Id', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final config = Auth101Config(
        id: _selectedProgram!,
        name: _selectedProgram!,
        approvalReq: _approvalReq,
        preApproveProc: _preApprove,
        postApproveProc: _postApprove,
        isTran: _isTran,
        levels: 1,
        orgCode: 101,
      );
      await AuthApiService.saveAuthConfig(config);
      _showSnackbar('Configuration saved successfully', isError: false);
      _clearForm();
      await _loadConfigs();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.toString(), isError: true);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedProgram = null;
      _approvalReq = true;
      _preApprove = false;
      _postApprove = false;
      _isTran = false;
    });
  }


  void _showSnackbar(String message, {required bool isError}) {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Authorization Configuration',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1628),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text('Error: $_errorMessage', style: const TextStyle(color: Colors.red)),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_showForm) _buildForm(),
                    const SizedBox(height: 24),
                    _buildGrid(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF152238),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AUTH CONFIG', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                  onPressed: () => setState(() => _showForm = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Organisation Code *', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: _orgCode,
                            enabled: false,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              prefixIcon: const Icon(Icons.apartment, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Program Id *', style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedProgram,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            hint: const Text('Select Program'),
                            items: _programs.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (val) => setState(() => _selectedProgram = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildSwitch('Approval Required', _approvalReq, (val) => setState(() => _approvalReq = val))),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSwitch('Pre Approval Required', _preApprove, (val) => setState(() => _preApprove = val))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildSwitch('Post Approval Required', _postApprove, (val) => setState(() => _postApprove = val))),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSwitch('Transaction program', _isTran, (val) => setState(() => _isTran = val))),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: _clearForm,
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF242F50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: _submitForm,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: 14, color: Colors.blue.shade300),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF242F50),
            ),
            const SizedBox(width: 8),
            Text(value ? 'Yes' : 'No', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildGrid() {

    final filteredList = _configs.where((c) {
      final query = _searchQuery.toLowerCase();
      return query.isEmpty ||
          c.id.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_showForm)
              StandardButton(
                label: 'New CONFIG',
                isPrimary: true,
                onPressed: () => setState(() => _showForm = true),
              )
            else
              TotalRecordsCard(
                count: _configs.length,
                label: 'Total Configs',
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
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loadConfigs,
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
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
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
                    Expanded(child: Text('PROGRAM ID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('PROGRAM NAME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('IS TRAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('APPROVAL REQ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Expanded(child: Text('LEVELS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
                          Expanded(child: Text(item.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(item.name)),
                          Expanded(child: Text(item.isTran ? 'Yes' : 'No')),
                          Expanded(child: Text(item.approvalReq ? 'Yes' : 'No')),
                          Expanded(child: Text(item.levels.toString())),
                          SizedBox(
                            width: 80,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ActionIconBtn(
                                  icon: Icons.edit_outlined,
                                  color: Colors.blue.shade700,
                                  onTap: () {
                                    setState(() {
                                      _selectedProgram = item.id;
                                      _approvalReq = item.approvalReq;
                                      _preApprove = item.preApproveProc;
                                      _postApprove = item.postApproveProc;
                                      _isTran = item.isTran;
                                      _showForm = true;
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
}
