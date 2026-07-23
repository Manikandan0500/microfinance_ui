import 'package:flutter/material.dart';
import 'services/loan_repayment_schedule_api_service.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _searched = false;
  String? _loadError;
  List<LoanRepaymentSchedule> _data = [];
  List<String> _accountNos = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final res = await LoanRepaymentScheduleApiService.getLoanRepaymentSchedules();
      final set = res.map((e) => e.loanAccountNo).where((no) => no.isNotEmpty).toSet();
      if (mounted) {
        setState(() {
          _accountNos = set.toList()..sort();
        });
      }
    } catch (_) {
      // Fail silently for suggestions
    }
  }

  Future<void> _performSearch() async {
    final loanNo = _searchCtrl.text.trim();
    if (loanNo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Loan Account Number')),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
      _searched = true;
      _data = [];
      _view = MFView.list;
      _sel = null;
    });

    try {
      final res = await LoanRepaymentScheduleApiService.getLoanRepaymentSchedules(loanAccountNo: loanNo);
      if (mounted) {
        setState(() {
          _data = res;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _go(MFView v, [LoanRepaymentSchedule? r]) {
    setState(() {
      _view = v;
      _sel = r;
    });
  }

  Widget _pageHeader({required String title, List<Widget> actions = const []}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(color: Colors.white),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      const Spacer(),
      ...actions,
    ]),
  );

  Widget _secHdr(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2));
  
  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_view == MFView.view) return _form();
    return _list();
  }

  Widget _list() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeader(title: 'Loan Repayment Schedule'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: _card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: MFAutocompleteField(
                      controller: _searchCtrl,
                      suggestions: _accountNos,
                      onSubmitted: _performSearch,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _performSearch,
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3050),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildContent(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1E3050)),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text(_loadError!, style: const TextStyle(color: Color(0xFFDC2626))),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _performSearch,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3050),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (!_searched) {
      return const Center(
        child: Text(
          'Enter a Loan Account Number to retrieve repayment schedule.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
    }

    if (_data.isEmpty) {
      return const Center(
        child: Text(
          'No records found',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
    }

    final firstRecord = _data.first;

    return SingleChildScrollView(
      child: _card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secHdr('SCHEDULE DETAILS'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Org Code', ctrl: TextEditingController(text: firstRecord.orgCode ?? '101'), icon: Icons.domain, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account Number', ctrl: TextEditingController(text: firstRecord.loanAccountNo), icon: Icons.numbers_rounded, readOnly: true, showLock: true,
                  )),
                ],
              ),
              const SizedBox(height: 32),
              _secHdr('REPAYMENT SCHEDULES'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E3050),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: _colHdr('INST.')),
                          Expanded(flex: 2, child: _colHdr('DUE DATE')),
                          Expanded(flex: 2, child: _colHdr('PRINCIPAL DUE')),
                          Expanded(flex: 2, child: _colHdr('INTEREST DUE')),
                          Expanded(flex: 2, child: _colHdr('TOTAL DUE')),
                          Expanded(flex: 2, child: _colHdr('STATUS')),
                          const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _data.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      itemBuilder: (_, i) {
                        final r = _data[i];
                        return InkWell(
                          onTap: () => _go(MFView.view, r),
                          hoverColor: const Color(0xFFF8FAFC),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(flex: 1, child: Text(r.installmentNo.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                Expanded(flex: 2, child: Text(r.dueDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                Expanded(flex: 2, child: Text(r.principalDue.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                Expanded(flex: 2, child: Text(r.interestDue.toStringAsFixed(2), style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                                Expanded(flex: 2, child: Text(r.totalDue.toStringAsFixed(2), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                                Expanded(flex: 2, child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: r.installmentStatus.toUpperCase() == 'PAID' ? const Color(0xFFDCFCE7) : (r.installmentStatus.toUpperCase() == 'OVERDUE' ? const Color(0xFFFEE2E2) : const Color(0xFFFEF9C3)), borderRadius: BorderRadius.circular(6)),
                                    child: Text(r.installmentStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.installmentStatus.toUpperCase() == 'PAID' ? const Color(0xFF16A34A) : (r.installmentStatus.toUpperCase() == 'OVERDUE' ? const Color(0xFFDC2626) : const Color(0xFFCA8A04)))),
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
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
