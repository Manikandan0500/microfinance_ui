import 'package:flutter/material.dart';
import 'dart:async';
import 'services/loan_account_api_service.dart';
import 'models/loan_account_master.dart';
import 'mf_shared_widgets.dart';
import 'package:intl/intl.dart';

class LoanAccountMasterScreen extends StatefulWidget {
  const LoanAccountMasterScreen({super.key});

  @override
  State<LoanAccountMasterScreen> createState() => _LoanAccountMasterScreenState();
}

class _LoanAccountMasterScreenState extends State<LoanAccountMasterScreen> {
  MFView _view = MFView.list;
  LoanAccountMaster? _sel;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<LoanAccountMaster> _data = [];

  // Form controllers
  final _acctCtrl = TextEditingController();
  final _clientCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _disbAmtCtrl = TextEditingController();
  final _disbDateCtrl = TextEditingController();
  final _matDateCtrl = TextEditingController();
  final _osPrinCtrl = TextEditingController();
  final _osIntCtrl = TextEditingController();
  String? _formErr;
  String _status = 'Active';

  // Delete State
  bool _delConfirmed = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _acctCtrl.dispose();
    _clientCtrl.dispose();
    _prodCtrl.dispose();
    _disbAmtCtrl.dispose();
    _disbDateCtrl.dispose();
    _matDateCtrl.dispose();
    _osPrinCtrl.dispose();
    _osIntCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final res = await LoanAccountApiService.getLoanAccounts();
      _data = res;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go(MFView v, [LoanAccountMaster? r]) {
    setState(() {
      _view = v;
      _sel = r;
      _formErr = null;
      _delConfirmed = false;
      
      if (v == MFView.create) {
        _acctCtrl.text = '';
        _clientCtrl.text = '';
        _prodCtrl.text = '';
        _disbAmtCtrl.text = '';
        _disbDateCtrl.text = '';
        _matDateCtrl.text = '';
        _osPrinCtrl.text = '';
        _osIntCtrl.text = '';
        _status = 'Active';
      } else if (r != null) {
        _acctCtrl.text = r.loanAccountNo;
        _clientCtrl.text = r.clientId;
        _prodCtrl.text = r.productCode;
        _disbAmtCtrl.text = r.disbursedAmount.toStringAsFixed(2);
        _disbDateCtrl.text = r.disbursementDate.toIso8601String().substring(0, 10);
        _matDateCtrl.text = r.maturityDate.toIso8601String().substring(0, 10);
        _osPrinCtrl.text = r.outstandingPrincipal.toStringAsFixed(2);
        _osIntCtrl.text = r.outstandingInterest.toStringAsFixed(2);
        _status = r.loanStatus;
      }
    });
  }

  bool _validateForm() {
    if (_acctCtrl.text.trim().isEmpty) return _err('Loan Account No is required.');
    if (_clientCtrl.text.trim().isEmpty) return _err('Client ID is required.');
    if (_prodCtrl.text.trim().isEmpty) return _err('Product Code is required.');
    if (double.tryParse(_disbAmtCtrl.text) == null) return _err('Disbursed Amount must be a valid number.');
    if (DateTime.tryParse(_disbDateCtrl.text) == null) return _err('Disbursement Date must be YYYY-MM-DD.');
    if (DateTime.tryParse(_matDateCtrl.text) == null) return _err('Maturity Date must be YYYY-MM-DD.');
    if (double.tryParse(_osPrinCtrl.text) == null) return _err('Outstanding Principal must be a valid number.');
    if (double.tryParse(_osIntCtrl.text) == null) return _err('Outstanding Interest must be a valid number.');
    setState(() => _formErr = null);
    return true;
  }

  bool _err(String msg) {
    setState(() => _formErr = msg);
    return false;
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (!_validateForm()) return;
    setState(() => _isLoading = true);
    try {
      final rec = LoanAccountMaster(
        orgCode: '101',
        loanAccountNo: _acctCtrl.text.trim(),
        clientId: _clientCtrl.text.trim(),
        productCode: _prodCtrl.text.trim(),
        disbursedAmount: double.parse(_disbAmtCtrl.text),
        disbursementDate: DateTime.parse(_disbDateCtrl.text),
        maturityDate: DateTime.parse(_matDateCtrl.text),
        outstandingPrincipal: double.parse(_osPrinCtrl.text),
        outstandingInterest: double.parse(_osIntCtrl.text),
        loanStatus: _status,
        eUser: 'SYS',
        eDate: DateTime.now(),
      );
      if (isEdit) {
        await LoanAccountApiService.updateLoanAccount(rec);
      } else {
        await LoanAccountApiService.createLoanAccount(rec);
      }
      if (mounted) {
        await _loadData();
        _go(MFView.list);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Record successfully ${isEdit ? 'updated' : 'created'}.'), backgroundColor: const Color(0xFF16A34A)));
      }
    } catch (e) {
      setState(() => _formErr = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (!_delConfirmed) {
      setState(() => _delConfirmed = true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await LoanAccountApiService.deleteLoanAccount(_sel!.loanAccountNo);
      if (mounted) {
        await _loadData();
        _go(MFView.list);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted.'), backgroundColor: Color(0xFF16A34A)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: const Color(0xFFDC2626)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _pageHeader({required String title, required List<Widget> actions}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(color: Colors.white),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      const Spacer(),
      ...actions,
    ]),
  );

  Widget _secHdr(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2));
  
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _hBtn(String label, {required IconData icon, required VoidCallback onTap, Color fg = const Color(0xFF64748B), Color border = const Color(0xFFE2E8F0)}) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: fg), const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    ),
  );

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) => MouseRegion(
    cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: onTap == null ? const Color(0xFF94A3B8) : bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: onTap == null ? const Color(0xFF94A3B8) : border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: fg), const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
        ]),
      ),
    ),
  );

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.loanAccountNo.toLowerCase().contains(q) || r.clientId.toLowerCase().contains(q);
    }).toList();

    int activeCount = filtered.where((c) => c.loanStatus == 'Active').length;
    int closedCount = filtered.where((c) => c.loanStatus != 'Active').length;

    final pages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > filtered.length) ? filtered.length : start + _itemsPerPage;
    final items = filtered.isEmpty ? <LoanAccountMaster>[] : filtered.sublist(start, end);

    return Column(children: [
      _pageHeader(title: 'Loan Account Master', actions: []),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            MFActiveInactiveSummary(activeCount: activeCount, inactiveCount: closedCount),
            const Spacer(),
            SizedBox(
              width: 280, height: 40,
              child: TextField(
                onChanged: (v) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
                },
                decoration: InputDecoration(
                  hintText: 'Search loans...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3050), width: 2)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            _fBtn('Create Account', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
          ],
        ),
      ),
      Expanded(
        child: _card(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFF1E3050), border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
              child: Row(children: [
                Expanded(flex: 2, child: _colHdr('ACCOUNT NO')),
                Expanded(flex: 2, child: _colHdr('CLIENT ID')),
                Expanded(flex: 2, child: _colHdr('PRODUCT')),
                Expanded(flex: 2, child: _colHdr('AMOUNT')),
                Expanded(flex: 2, child: _colHdr('STATUS')),
                const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
              ]),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
            else if (_loadError != null)
              Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
                Text(_loadError!, style: const TextStyle(color: Color(0xFFDC2626))), const SizedBox(height: 16),
                _hBtn('Retry', icon: Icons.refresh_rounded, onTap: _loadData),
              ])))
            else if (items.isEmpty)
              const Expanded(child: Center(child: Text('No records found', style: TextStyle(color: Color(0xFF64748B)))))
            else
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (_, i) {
                    final r = items[i];
                    return InkWell(
                      onTap: () => _go(MFView.view, r),
                      hoverColor: const Color(0xFFF8FAFC),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text(r.loanAccountNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(r.clientId, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(r.productCode, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(NumberFormat.currency(symbol: '₹').format(r.disbursedAmount), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: r.loanStatus == 'Active' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                              child: Text(r.loanStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.loanStatus == 'Active' ? const Color(0xFF16A34A) : const Color(0xFF64748B))),
                            ),
                          ])),
                          SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _go(MFView.view, r),
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.visibility_rounded, size: 16, color: Color(0xFF1E3050))),
                              ),
                            ),
                            const SizedBox(width: 8),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _go(MFView.edit, r),
                                child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF1E3050))),
                              ),
                            ),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            if (pages > 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Showing $start to $end of ${filtered.length} entries', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Row(children: [
                    _hBtn('Prev', icon: Icons.chevron_left_rounded, onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : () {}),
                    const SizedBox(width: 8),
                    Text('Page $_currentPage of $pages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    const SizedBox(width: 8),
                    _hBtn('Next', icon: Icons.chevron_right_rounded, onTap: _currentPage < pages ? () => setState(() => _currentPage++) : () {}),
                  ]),
                ]),
              ),
          ]),
        ),
      ),
    ]);
  }

  Widget _form() {
    final isEdit = _view == MFView.edit;
    final isView = _view == MFView.view;
    return Column(children: [
      _pageHeader(
        title: isView ? 'View Loan Account' : (isEdit ? 'Edit Loan Account' : 'Create Loan Account'),
        actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
          if (isView) ...[
            const SizedBox(width: 10),
            _hBtn('Edit', icon: Icons.edit_rounded, fg: const Color(0xFF1E3050), border: const Color(0xFF1E3050), onTap: () => _go(MFView.edit, _sel)),
          ]
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_formErr != null)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
                child: Row(children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_formErr!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13, fontWeight: FontWeight.w500))),
                ]),
              ),
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('BASIC DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account No', ctrl: _acctCtrl, icon: Icons.numbers_rounded, readOnly: isEdit || isView, showLock: isEdit || isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Client ID', ctrl: _clientCtrl, icon: Icons.person_outline, readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Product Code', ctrl: _prodCtrl, icon: Icons.account_balance, readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Status', icon: Icons.info_outline, selectedItem: {'id': _status}, items: const [{'id': 'Active'}, {'id': 'Closed'}, {'id': 'WrittenOff'}], displayKeys: const ['id'], onChanged: (v) { if (v != null) setState(() => _status = v['id']); }, enabled: !isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('AMOUNTS & DATES'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Disbursed Amount', ctrl: _disbAmtCtrl, icon: Icons.attach_money, readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Disbursement Date (YYYY-MM-DD)', ctrl: _disbDateCtrl, icon: Icons.calendar_today, readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Maturity Date (YYYY-MM-DD)', ctrl: _matDateCtrl, icon: Icons.calendar_today, readOnly: isView, showLock: isView,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('SERVICING BALANCES'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Outstanding Principal', ctrl: _osPrinCtrl, icon: Icons.account_balance_wallet, readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Outstanding Interest', ctrl: _osIntCtrl, icon: Icons.account_balance_wallet, readOnly: isView, showLock: isView,
                  )),
                ]),
              ]),
            )),
            if (isView) ...[
              const SizedBox(height: 24),
              _card(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _secHdr('DANGER ZONE'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFCA5A5))),
                    child: Row(children: [
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Delete Loan Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF991B1B))),
                        SizedBox(height: 4),
                        Text('This action cannot be undone and will permanently remove the record.', style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C))),
                      ])),
                      _hBtn(_delConfirmed ? 'Confirm Delete' : 'Delete Record', icon: Icons.delete_outline_rounded, fg: const Color(0xFFDC2626), border: const Color(0xFFFCA5A5), onTap: _isLoading ? () {} : _deleteRecord),
                    ]),
                  ),
                ]),
              )),
            ] else ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _fBtn(isEdit ? 'Save Changes' : 'Create Record', isEdit ? Icons.save_rounded : Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
                ],
              ),
            ],
          ]),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_view == MFView.list) return _list();
    return _form();
  }
}
