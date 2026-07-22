import 'package:flutter/material.dart';
import 'dart:async';
import 'models/auth_models.dart';
import 'services/queue_api_service.dart';
import 'mf_shared_widgets.dart';
import '../am_masters/services/auth_service.dart';

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

  Future<void> _processRecord(AuthRecord r, bool approve, BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final userModel = await AuthService().getUser();
      final userName = [userModel?.fName, userModel?.mName, userModel?.lName]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ');
      final finalUsername = userName.isNotEmpty ? userName : (userModel?.name ?? userModel?.email ?? 'SYS');

      await QueueApiService.processAuth(
        authSl: r.authSl,
        action: approve ? '1' : '0',
        level: 1,
        user: finalUsername,
      );
      if (context.mounted) {
        Navigator.pop(context); // Close detail dialog
        showSuccessDialog(context, 'Record ${approve ? 'approved' : 'rejected'} successfully.', onConfirm: _loadQueue);
      }
    } catch (e) {
      if (context.mounted) _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(BuildContext context, AuthRecord r) {
    final TextEditingController remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Reject Authorization', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide remarks for rejection:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            SizedBox(
              width: 500,
              child: TextField(
                controller: remarksCtrl,
                maxLines: 2,
                minLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter remarks...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () {
              Navigator.pop(ctx);
              _processRecord(r, false, context);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      _ => _list(),
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
                      _rowBtn(Icons.visibility_rounded, const Color(0xFF1E3050), () => _showDetailDialog(context, r)),
                    ])),
                  ]),
                );
              },
            ),
        ])),
      ]),
    );
  }

  void _showDetailDialog(BuildContext context, AuthRecord r) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Container(
            width: 1000,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  color: const Color(0xFF1E3050),
                  child: Row(
                    children: [
                      Expanded(child: Text('Review Details: ${r.authSl}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                    ]
                  )
                ),
                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _card(child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.assignment, color: Color(0xFF1E3050))),
                              const SizedBox(width: 16),
                              Expanded(child: Text(r.programId == 'LOANAPP' ? 'Loan Application' : r.programId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                                child: Row(children: [
                                  const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
                                  const SizedBox(width: 6),
                                  Text('User: ${r.eUser}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                                ]),
                              ),
                            ]),
                            const SizedBox(height: 8),
                            ...r.dataBlocks.map((block) {
                              final hideKeys = ['auser', 'adate', 'euser', 'edate', 'cuser', 'cdate', 'user_name', '__action'];
                              final filteredEntries = block.data.entries.where((e) => !hideKeys.contains(e.key.toLowerCase())).toList();
                              
                              if (filteredEntries.isEmpty) return const SizedBox();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: LayoutBuilder(builder: (context, constraints) {
                                        return Wrap(
                                          spacing: 24,
                                          runSpacing: 16,
                                          children: filteredEntries.map((e) => SizedBox(
                                            width: (constraints.maxWidth - (24 * 3)) / 4,
                                            child: _JsonField(label: e.key, value: e.value?.toString() ?? ''),
                                          )).toList(),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ]),
                        )),
                      ],
                    ),
                  )
                ),
                // Footer Buttons
                StatefulBuilder(builder: (context, setFooterState) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
                    child: Row(children: [
                      const Spacer(),
                      _fBtn('Back', Icons.arrow_back_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => Navigator.pop(dialogContext)),
                      const SizedBox(width: 12),
                      _fBtn('Reject', Icons.close_rounded, const Color(0xFFDC2626), Colors.white, const Color(0xFFDC2626), onTap: _isLoading ? null : () => _showRejectDialog(dialogContext, r)),
                      const SizedBox(width: 12),
                      _fBtn('Approve', Icons.check_circle_rounded, const Color(0xFF16A34A), Colors.white, const Color(0xFF16A34A), onTap: _isLoading ? null : () => _processRecord(r, true, dialogContext)),
                    ]),
                  );
                }),
              ],
            )
          )
        );
      }
    );
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

class _JsonField extends StatefulWidget {
  final String label;
  final String value;
  const _JsonField({required this.label, required this.value});
  @override
  State<_JsonField> createState() => _JsonFieldState();
}

class _JsonFieldState extends State<_JsonField> {
  late TextEditingController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }
  @override
  void didUpdateWidget(_JsonField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.text = widget.value;
    }
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return MFFloatingLabelField(
      label: widget.label,
      ctrl: _ctrl,
      icon: Icons.info_outline,
      readOnly: true,
      showLock: false,
    );
  }
}
