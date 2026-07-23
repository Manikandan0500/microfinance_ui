import 'package:flutter/material.dart';
import 'services/queries_api_service.dart';
import 'services/loan_repayment_schedule_api_service.dart';
import 'models/loan_status_history.dart';
import 'mf_shared_widgets.dart';

class LoanStatusHistoryScreen extends StatefulWidget {
  const LoanStatusHistoryScreen({super.key});

  @override
  State<LoanStatusHistoryScreen> createState() => _LoanStatusHistoryScreenState();
}

class _LoanStatusHistoryScreenState extends State<LoanStatusHistoryScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = false;
  bool _searched = false;
  String? _loadError;
  List<LoanStatusHistory> _data = [];
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
    });

    try {
      final res = await QueriesApiService.getLoanStatusHistory(loanNo);
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

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));

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
        _pageHeader(title: 'Loan Status History'),
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
          'Enter a Loan Account Number to retrieve status history.',
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
              _secHdr('HISTORY DETAILS'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Org Code', ctrl: TextEditingController(text: firstRecord.orgCode), icon: Icons.domain, readOnly: true, showLock: true,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Account Number', ctrl: TextEditingController(text: firstRecord.loanAccountNo), icon: Icons.numbers_rounded, readOnly: true, showLock: true,
                  )),
                ],
              ),
              const SizedBox(height: 32),
              _secHdr('STATUS TRANSITIONS'),
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
                          Expanded(flex: 2, child: _colHdr('STATUS FROM')),
                          Expanded(flex: 2, child: _colHdr('STATUS TO')),
                          Expanded(flex: 2, child: _colHdr('CHANGED DATE')),
                          Expanded(flex: 2, child: _colHdr('CHANGED BY')),
                          Expanded(flex: 3, child: _colHdr('REMARKS')),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(r.statusFrom ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text(r.statusTo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                              Expanded(flex: 2, child: Text(r.changedDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                              Expanded(flex: 2, child: Text(r.changedBy, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)))),
                              Expanded(flex: 3, child: Text(r.remarks ?? '-', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                            ],
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
}
