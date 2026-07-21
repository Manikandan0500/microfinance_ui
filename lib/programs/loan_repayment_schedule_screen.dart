import 'package:flutter/material.dart';
import 'dart:async';
import 'services/queries_api_service.dart';
import 'models/loan_repayment_schedule.dart';
import 'mf_shared_widgets.dart';

class LoanRepaymentScheduleScreen extends StatefulWidget {
  const LoanRepaymentScheduleScreen({super.key});

  @override
  State<LoanRepaymentScheduleScreen> createState() => _LoanRepaymentScheduleScreenState();
}

class _LoanRepaymentScheduleScreenState extends State<LoanRepaymentScheduleScreen> {
  MFView _view = MFView.list;
  LoanRepaymentSchedule? _sel;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<LoanRepaymentSchedule> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final res = await QueriesApiService.getLoanRepaymentSchedules();
      _data = res;
    } catch (e) {
      _loadError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go(MFView v, [LoanRepaymentSchedule? r]) {
    setState(() {
      _view = v;
      _sel = r;
    });
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

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

  Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.loanAccountNo.toLowerCase().contains(q) || r.installmentStatus.toLowerCase().contains(q);
    }).toList();

    final pages = (filtered.length / _itemsPerPage).ceil();
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage > filtered.length) ? filtered.length : start + _itemsPerPage;
    final items = filtered.isEmpty ? <LoanRepaymentSchedule>[] : filtered.sublist(start, end);

    return Column(children: [
      _pageHeader(title: 'Loan Repayment Schedule', actions: []),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Spacer(),
            SizedBox(
              width: 280, height: 40,
              child: TextField(
                onChanged: (v) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () => setState(() { _search = v; _currentPage = 1; }));
                },
                decoration: InputDecoration(
                  hintText: 'Search schedules...',
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                  filled: true, fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3050), width: 2)),
                ),
              ),
            ),
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
                Expanded(flex: 2, child: _colHdr('LOAN ACCOUNT NO')),
                Expanded(flex: 1, child: _colHdr('INST.')),
                Expanded(flex: 2, child: _colHdr('DUE DATE')),
                Expanded(flex: 2, child: _colHdr('TOTAL DUE')),
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
                          Expanded(flex: 1, child: Text(r.installmentNo.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(r.dueDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Text(r.totalDue.toStringAsFixed(2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                          Expanded(flex: 2, child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: r.installmentStatus == 'Paid' ? const Color(0xFFDCFCE7) : (r.installmentStatus == 'Overdue' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF9C3)), borderRadius: BorderRadius.circular(6)),
                              child: Text(r.installmentStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.installmentStatus == 'Paid' ? const Color(0xFF16A34A) : (r.installmentStatus == 'Overdue' ? const Color(0xFFDC2626) : const Color(0xFFCA8A04)))),
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
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    return Column(children: [
      _pageHeader(
        title: 'View Repayment Schedule',
        actions: [
          _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
        ],
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('SCHEDULE DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Org Code', ctrl: TextEditingController(text: r.orgCode), icon: Icons.domain, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account No', ctrl: TextEditingController(text: r.loanAccountNo), icon: Icons.numbers_rounded, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Installment No', ctrl: TextEditingController(text: r.installmentNo.toString()), icon: Icons.format_list_numbered, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Due Date', ctrl: TextEditingController(text: r.dueDate.toIso8601String().substring(0, 10)), icon: Icons.calendar_today, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Installment Status', ctrl: TextEditingController(text: r.installmentStatus), icon: Icons.info_outline, readOnly: true, showLock: true,
                  )),
                ]),
                const SizedBox(height: 32),
                _secHdr('DUE VS PAID'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Principal Due', ctrl: TextEditingController(text: r.principalDue.toStringAsFixed(2)), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Interest Due', ctrl: TextEditingController(text: r.interestDue.toStringAsFixed(2)), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Total Due', ctrl: TextEditingController(text: r.totalDue.toStringAsFixed(2)), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Principal Paid', ctrl: TextEditingController(text: r.principalPaid?.toStringAsFixed(2) ?? '0.00'), icon: Icons.check_circle_outline, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Interest Paid', ctrl: TextEditingController(text: r.interestPaid?.toStringAsFixed(2) ?? '0.00'), icon: Icons.check_circle_outline, readOnly: true, showLock: true,
                  )),
                ]),
              ]),
            )),
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
