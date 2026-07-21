import 'package:flutter/material.dart';
import 'mf_shared_widgets.dart';
import 'models/disbursal_queue.dart';
import 'services/disbursal_api_service.dart';

class DisbursalInitiateScreen extends StatefulWidget {
  const DisbursalInitiateScreen({super.key});
  @override
  State<DisbursalInitiateScreen> createState() => _DisbursalInitiateScreenState();
}

class _DisbursalInitiateScreenState extends State<DisbursalInitiateScreen> {
  MFView _view = MFView.list;
  DisbursalQueue? _sel;
  
  List<DisbursalQueue> _data = [];
  String _search = '';
  int _page = 1;
  final int _size = 10;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  String _clientType = 'I';
  final _clientIdCtrl = TextEditingController();
  final _loanAmtCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _data = await DisbursalApiService.getDisbursalQueue();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go(MFView v, [DisbursalQueue? r]) {
    setState(() {
      _view = v;
      _sel = r;
      if (v == MFView.create || v == MFView.edit || v == MFView.view) {
        _clientType = r?.queueId ?? 'I';
        _clientIdCtrl.text = r?.clientId ?? '';
        _loanAmtCtrl.text = r != null ? r.approvedAmount.toString() : '';
      }
    });
  }

  Future<void> _saveRecord(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final double loanAmt = double.tryParse(_loanAmtCtrl.text) ?? 0.0;
      final record = DisbursalQueue(
        orgCode: '101',
        queueId: _clientType,
        sourceSystem: 'MANUAL',
        sourceRefNo: null,
        clientId: _clientIdCtrl.text.trim().toUpperCase(),
        groupCode: null,
        productCode: 'DISBQUEUE',
        approvedAmount: loanAmt,
        approvedTenureMonths: 0,
        approvedInterestRate: 0.0,
        queuedDate: DateTime.now(),
        assignedToUserId: 'admin',
        disbursementStatus: 'Pending Input',
      );
      if (isEdit) {
        // Not editable per spec, but placeholder
      } else {
        await DisbursalApiService.createDisbursalQueue(record);
      }
      await _loadData();
      } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecord() async {
    if (_sel == null) return;
    setState(() => _isLoading = true);
    try {
      await DisbursalApiService.deleteDisbursalQueue(_sel!.queueId);
      await _loadData();
      } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI Helpers ─────────────────────────────────────────────────────────────
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

  Widget _fBtn(String label, IconData icon, Color bg, Color fg, Color border, {VoidCallback? onTap}) =>
      MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: BoxDecoration(color: onTap == null ? bg.withValues(alpha: 0.5) : bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: onTap == null ? border.withValues(alpha: 0.5) : border, width: 1.5)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 15, color: fg), const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
            ]),
          ),
        ),
      );

  Widget _rowBtn(IconData icon, Color c, VoidCallback onTap) =>
      MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(onTap: onTap, child: Icon(icon, size: 18, color: c)));

  // ── Main Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading && _view == MFView.list
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3050)))
          : switch (_view) {
              MFView.list   => _list(),
              MFView.create => _form(isEdit: false),
              MFView.view   => _form(isView: true),
              MFView.edit   => _form(isEdit: true),
              MFView.delete => _delete(),
            },
    );
  }

  // ── List View ──────────────────────────────────────────────────────────────
    Widget _list() {
    final filtered = _data.where((r) {
      final q = _search.toLowerCase();
      return q.isEmpty || r.queueId.toLowerCase().contains(q) || r.clientId.toLowerCase().contains(q) || r.disbursementStatus.toLowerCase().contains(q);
    }).toList();

    final pages = (filtered.length / _size).ceil();
    final start = (_page - 1) * _size;
    final end = (start + _size > filtered.length) ? filtered.length : start + _size;
    final items = filtered.isEmpty ? <DisbursalQueue>[] : filtered.sublist(start, end);

    // Grouping for status cards
    final approvedCount = _data.where((r) => r.disbursementStatus == 'Approved').length;
    final pendingCount = _data.where((r) => r.disbursementStatus == 'Pending Input').length;

    return Column(children: [
      _pageHeader(title: 'Initiate Disbursal', actions: []),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MFActiveInactiveSummary(activeCount: approvedCount, inactiveCount: pendingCount),
        ],
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 280, height: 40,
            child: TextField(
              onChanged: (v) => setState(() { _search = v; _page = 1; }),
              decoration: InputDecoration(
                hintText: 'Search queues or clients...',
                prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1E3050), width: 2)),
              ),
            ),
          ),
          _fBtn('Initiate Disbursal', Icons.add_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.create)),
        ],
      ),
      const SizedBox(height: 16),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(color: Color(0xFF1E3050), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
                child: Row(children: [
                  Expanded(flex: 2, child: _colHdr('CLIENT TYPE')),
                  Expanded(flex: 2, child: _colHdr('CLIENT ID')),
                  Expanded(flex: 2, child: _colHdr('AMOUNT')),
                  Expanded(flex: 2, child: _colHdr('STATUS')),
                  Expanded(flex: 2, child: _colHdr('DATE')),
                  const SizedBox(width: 80, child: Text('ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.5), textAlign: TextAlign.right)),
                ]),
              ),
              if (items.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No records found', style: TextStyle(color: Color(0xFF64748B)))))
              else
                ...items.asMap().entries.map((e) {
                  final r = e.value;
                  final isLast = e.key == items.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(r.queueId == 'I' ? 'I - Individual' : r.queueId == 'C' ? 'C - Corporate' : r.queueId == 'G' ? 'G - Group' : r.queueId, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B)))),
                      Expanded(flex: 2, child: Text(r.clientId, style: const TextStyle(color: Color(0xFF475569)))),
                      Expanded(flex: 2, child: Text(r.approvedAmount.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      Expanded(flex: 2, child: _statusBadge(r.disbursementStatus)),
                      Expanded(flex: 2, child: Text(r.queuedDate.toIso8601String().substring(0, 10), style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                      SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        _rowBtn(Icons.visibility_rounded, const Color(0xFF64748B), () => _go(MFView.view, r)), const SizedBox(width: 6),
                        _rowBtn(Icons.delete_outline_rounded, const Color(0xFFDC2626), () => _go(MFView.delete, r)),
                      ])),
                    ]),
                  );
                }),
              if (pages > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Showing $start to $end of ${filtered.length} records', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Row(children: [
                      _pageBtn(Icons.chevron_left, _page > 1 ? () => setState(() => _page--) : null),
                      const SizedBox(width: 8),
                      Text('Page $_page of $pages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B))),
                      const SizedBox(width: 8),
                      _pageBtn(Icons.chevron_right, _page < pages ? () => setState(() => _page++) : null),
                    ]),
                  ]),
                ),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _colHdr(String t) => Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.5));
  Widget _pageBtn(IconData icon, VoidCallback? onTap) => MouseRegion(
    cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: onTap == null ? const Color(0xFFF1F5F9) : Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Icon(icon, size: 16, color: onTap == null ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
      ),
    ),
  );

  Widget _statusBadge(String status) {
    Color bg = const Color(0xFFFEF9C3);
    Color fg = const Color(0xFFCA8A04);
    if (status == 'Approved') { bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A); }
    if (status == 'Rejected') { bg = const Color(0xFFFEE2E2); fg = const Color(0xFFDC2626); }
    if (status == 'Pending Authorization') { bg = const Color(0xFFDBEAFE); fg = const Color(0xFF2563EB); }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
      ),
    );
  }

  // ── Form View ──────────────────────────────────────────────────────────────
  Widget _form({bool isEdit = false, bool isView = false}) {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _pageHeader(
              title: isView ? 'View Disbursal' : 'Initiate Disbursal',
              actions: [
                _fBtn('Back', Icons.arrow_back_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: () => _go(MFView.list)),
              ],
            ),
            _card(child: Form(key: _formKey, child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _secHdr('DISBURSAL DETAILS'),
                const SizedBox(height: 16),
                Wrap(spacing: 24, runSpacing: 24, children: [
                  SizedBox(width: 300, child: MFApiDropdownField(
                    label: 'Client Type', icon: Icons.person_outline, required: !isView,
                    items: const [{'id': 'I', 'name': 'I - Individual'}, {'id': 'C', 'name': 'C - Corporate'}, {'id': 'G', 'name': 'G - Group'}],
                    displayKeys: const ['name'],
                    selectedItem: {'id': _clientType},
                    onChanged: (v) { if (!isView) setState(() => _clientType = v?['id'] ?? 'I'); },
                    enabled: !isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Client ID', ctrl: _clientIdCtrl, icon: Icons.person_outline, required: !isView,
                    readOnly: isView, showLock: isView,
                  )),
                  SizedBox(width: 300, child: MFFloatingLabelField(
                    label: 'Loan Amount', ctrl: _loanAmtCtrl, icon: Icons.currency_rupee, required: !isView,
                    readOnly: isView, showLock: isView, keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  )),
                ]),
              ]),
            ))),
          ]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          const Spacer(),
          if (!isView) ...[
            const SizedBox(width: 12),
            _fBtn('Initiate', Icons.check_circle_rounded, const Color(0xFF1E3050), Colors.white, const Color(0xFF1E3050), onTap: _isLoading ? null : () => _saveRecord(isEdit)),
          ]
        ]),
      ),
    ]);
  }

  // ── Delete View ────────────────────────────────────────────────────────────
  Widget _delete() {
    if (_sel == null) return const SizedBox();
    final r = _sel!;
    return Center(child: Container(
      width: 500, margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFFEF2F2), borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626))),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Delete Disbursal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
              SizedBox(height: 4), Text('This action cannot be undone.', style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C))),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Row(children: [ const Text('Client Type: ', style: TextStyle(color: Color(0xFF64748B))), Text(r.queueId == 'I' ? 'I - Individual' : r.queueId == 'C' ? 'C - Corporate' : r.queueId == 'G' ? 'G - Group' : r.queueId, style: const TextStyle(fontWeight: FontWeight.w600)) ]),
            const SizedBox(height: 8),
            Row(children: [ const Text('Client ID: ', style: TextStyle(color: Color(0xFF64748B))), Text(r.clientId, style: const TextStyle(fontWeight: FontWeight.w600)) ]),
          ]),
        ),
        Container(
          padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(bottom: Radius.circular(16))),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _fBtn('Cancel', Icons.close, Colors.white, const Color(0xFF64748B), const Color(0xFFE2E8F0), onTap: () => _go(MFView.list)),
            const SizedBox(width: 12),
            _fBtn('Delete', Icons.delete_outline, const Color(0xFFDC2626), Colors.white, const Color(0xFFDC2626), onTap: _isLoading ? null : _deleteRecord),
          ]),
        ),
      ]),
    ));
  }
}
