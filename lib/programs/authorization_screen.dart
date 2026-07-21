import 'package:flutter/material.dart';
import 'dart:async';
import 'models/auth_models.dart';
import 'services/queue_api_service.dart';
import 'mf_shared_widgets.dart';

class AuthorizationScreen extends StatefulWidget {
  const AuthorizationScreen({super.key});

  @override
  State<AuthorizationScreen> createState() => _AuthorizationScreenState();
}

class _AuthorizationScreenState extends State<AuthorizationScreen> {
  MFView _view = MFView.list;
  AuthRecord? _sel;
  String _search = '';
  bool _isLoading = true;
  String? _loadError;
  Timer? _debounce;
  
  List<AuthRecord> _data = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final records = await QueueApiService.getAuthQueue();
      if (mounted) {
        setState(() {
          _data = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  List<AuthRecord> get _filtered {
    if (_search.isEmpty) return _data;
    final q = _search.toLowerCase();
    return _data.where((r) {
      return r.authSl.toLowerCase().contains(q) || 
             r.programId.toLowerCase().contains(q) || 
             r.displayRemarks.toLowerCase().contains(q);
    }).toList();
  }

  void _go(MFView v, [AuthRecord? r]) {
    setState(() {
      _view = v;
      _sel = r;
      if (v == MFView.list) {
        _search = '';
      }
    });
    if (v == MFView.list) {
      _loadQueue();
    }
  }

  void _toast(String msg, {bool isError = false}) => MFToast.show(context, msg, isError: isError);

  Future<void> _processRecord(bool approve) async {
    if (_sel == null) return;
    setState(() => _isLoading = true);
    try {
      await QueueApiService.processAuth(
        authSl: _sel!.authSl,
        action: approve ? '1' : '0',
        level: 1,
        user: 'admin',
      );
      showSuccessDialog(context, 'Record ${approve ? 'approved' : 'rejected'} successfully.', onConfirm: () => _go(MFView.list));
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5F9), // Background matching am_masters layout
    body: switch (_view) {
      MFView.list   => _list(),
      MFView.view   => _detail(),
      _ => const SizedBox(), // Create, Edit, Delete are not used in this screen
    },
  );

  // ── List View ──────────────────────────────────────────────────────────────
  Widget _list() {
    final list = _filtered;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pageHeader(title: 'Authorization Queue'),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _statCard('${_data.length}', 'Pending Authorizations', const Color(0xFF1E3050), const Color(0xFFE3F2FD), const Color(0xFFE2E8F0), Icons.pending_actions, const Color(0xFF1E3050)),
          const Spacer(),
          Container(
            width: 280, height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              onChanged: (v) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => _search = v));
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              decoration: InputDecoration(
                hintText: 'Search queue...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF64748B)),
                border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12), isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _rowBtn(Icons.refresh_rounded, const Color(0xFF1E293B), _loadQueue),
        ]),
        const SizedBox(height: 16),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3050),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(children: [
              Expanded(flex: 2, child: _colHdr('AUTH SL')),
              Expanded(flex: 2, child: _colHdr('PROGRAM ID')),
              Expanded(flex: 3, child: _colHdr('REMARKS')),
              Expanded(child: _colHdr('USER')),
              Expanded(child: _colHdr('DATE')),
              const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white), textAlign: TextAlign.center)),
            ]),
          ),
          if (_isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Color(0xFF1E3050))))
          else if (_loadError != null)
            Padding(padding: const EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)), const SizedBox(height: 16),
              Text('Failed to load data', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))), const SizedBox(height: 8),
              Text(_loadError!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ])))
          else if (list.isEmpty)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, size: 48, color: Color(0xFFCBD5E1)), const SizedBox(height: 16),
              Text('No records found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
            ])))
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (_, i) {
                final r = list[i];
                return Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text(r.authSl, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text(r.programId, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(flex: 3, child: Text(r.displayRemarks, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.eUser, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    Expanded(child: Text(r.eDate, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)))),
                    SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _rowBtn(Icons.visibility_rounded, const Color(0xFF1E3050), () => _go(MFView.view, r)),
                    ])),
                  ]),
                );
              },
            ),
        ])),
      ]),
    );
  }

  // ── Detail View ────────────────────────────────────────────────────────────
  Widget _detail() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(title: 'Review Details: ${r.authSl}', actions: [
              _hBtn('Back', icon: Icons.arrow_back_rounded, onTap: () => _go(MFView.list)),
            ]),
            _card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment, color: Color(0xFF1E3050))),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.programId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.person, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                      Text('User: ${r.eUser}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF64748B)), const SizedBox(width: 4),
                      Text('Date: ${r.eDate}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 32),
                _secHdr('REMARKS'),
                const SizedBox(height: 8),
                Text(r.displayRemarks, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B))),
                const SizedBox(height: 32),
                _secHdr('DATA BLOCKS'),
                const SizedBox(height: 16),
                ...r.dataBlocks.map((block) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                          ),
                          child: Row(children: [
                            const Icon(Icons.table_chart, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 8),
                            Text('Table: ${block.tableName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                          ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: block.data.entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 160, child: Text('${e.key}:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
                                  Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)))),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ]),
            )),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          const Spacer(),
          _hBtn('Back', onTap: () => _go(MFView.list)),
          const SizedBox(width: 12),
          _fBtn('Reject', Icons.close_rounded, const Color(0xFFDC2626), Colors.white, const Color(0xFFDC2626), onTap: _isLoading ? null : () => _processRecord(false)),
          const SizedBox(width: 12),
          _fBtn('Approve', Icons.check_circle_rounded, const Color(0xFF16A34A), Colors.white, const Color(0xFF16A34A), onTap: _isLoading ? null : () => _processRecord(true)),
        ]),
      ),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _pageHeader({required String title, List<Widget> actions = const []}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: -0.3))),
          ...actions,
        ]),
      );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _statCard(String num, String lbl, Color numC, Color bg, Color border, IconData icon, Color iconC) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: iconC)),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: numC, height: 1.1)),
            Text(lbl, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          ]),
        ]),
      );

  Widget _hBtn(String label, {Color bg = Colors.white, Color fg = const Color(0xFF64748B), Color border = const Color(0xFFE2E8F0), IconData? icon, VoidCallback? onTap}) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: onTap == null ? bg.withOpacity(0.5) : bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: onTap == null ? border.withOpacity(0.5) : border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _rowBtn(IconData icon, Color color, VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
      );

  Widget _secHdr(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(height: 1, color: Color(0xFFF1F5F9)),
      const SizedBox(height: 10),
      Text(t, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1E3050), letterSpacing: 1)),
    ]),
  );

  Widget _colHdr(String label) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
}
