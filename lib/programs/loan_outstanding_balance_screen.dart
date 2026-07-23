import 'package:flutter/material.dart';
import 'services/queries_api_service.dart';
import 'services/loan_repayment_schedule_api_service.dart';
import 'models/loan_outstanding_balance.dart';
import 'mf_shared_widgets.dart';

class LoanOutstandingBalanceScreen extends StatefulWidget {
  const LoanOutstandingBalanceScreen({super.key});

  @override
  State<LoanOutstandingBalanceScreen> createState() => _LoanOutstandingBalanceScreenState();
}

class _LoanOutstandingBalanceScreenState extends State<LoanOutstandingBalanceScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _searched = false;
  String? _loadError;
  LoanOutstandingBalance? _data;
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
      _data = null;
    });

    try {
      final res = await QueriesApiService.getLoanOutstandingBalance(loanNo);
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

  Widget _pageHeader({required String title}) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(color: Colors.white),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
    ]),
  );

  Widget _secHdr(String t) => Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 1.2));
  
  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _pageHeader(title: 'Loan Outstanding Balance'),
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
          'Enter a Loan Account Number to retrieve outstanding balance.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
    }

    if (_data == null) {
      return const Center(
        child: Text(
          'No records found',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
      );
    }

    final r = _data!;
    return SingleChildScrollView(
      child: _card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _secHdr('OUTSTANDING DETAILS'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Org Code', ctrl: TextEditingController(text: r.orgCode), icon: Icons.domain, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account Number', ctrl: TextEditingController(text: r.loanAccountNo), icon: Icons.numbers_rounded, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'As On Date', ctrl: TextEditingController(text: r.asOnDate.toIso8601String().substring(0, 10)), icon: Icons.calendar_today, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Principal Outstanding', ctrl: TextEditingController(text: r.principalOutstanding.toStringAsFixed(2)), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Interest Outstanding', ctrl: TextEditingController(text: r.interestOutstanding.toStringAsFixed(2)), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Penalty Outstanding', ctrl: TextEditingController(text: r.penaltyOutstanding?.toStringAsFixed(2) ?? '0.00'), icon: Icons.attach_money, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Total Outstanding', ctrl: TextEditingController(text: r.totalOutstanding.toStringAsFixed(2)), icon: Icons.account_balance_wallet, readOnly: true, showLock: true,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
