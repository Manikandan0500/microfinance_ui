import '../models/access_privileges.dart';
import '../services/program_service.dart';
import '../widgets/audit_details_dialog.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/organization_service.dart';
import '../services/product_service.dart';
import '../services/product_mapping_service.dart';
import '../services/operational_log_service.dart';
import 'package:flutter/services.dart';
import '../models/product_map_dto.dart';

// ── Brand colours ──────────────────────────────────────────────────────────────
const _kP = Color(0xFF3D6EBE);
const _kPL = Color(0xFFEEF3FB);
const _kPB = Color(0xFFC5D3E8);
const _kR = Color(0xFFDC2626);
const _kRL = Color(0xFFFEF2F2);
const _kRB = Color(0xFFFECACA);
const _kG = Color(0xFF16A34A);
const _kGL = Color(0xFFDCFCE7);
const _kGB = Color(0xFFBBF7D0);
const _kOB = Color(0xFFFED7AA);
const _kOBG = Color(0xFFFFF7ED);
const _kOT = Color(0xFFC2410C);
const _kWarnBG = Color(0xFFFFFBEB);
const _kWarnB = Color(0xFFFDE68A);
const _kWarnT = Color(0xFFB45309);
const _kText = Color(0xFF1E293B);
const _kMuted = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kSurface = Color(0xFFF8FAFC);
const _kRowAlt = Color(0xFFF0F5FD);

enum _V { list, create, view, edit, delete }

// ── Data model ────────────────────────────────────────────────────────────────
class _Mapping {
  String orgCode;
  List<String> prodCodes;
  String status;
  bool enabled;
  String? cuser, cdate, euser, edate, auser, adate;
  _Mapping({
    required this.orgCode,
    required this.prodCodes,
    required this.status,
    this.enabled = true,
    this.cuser,
    this.cdate,
    this.euser,
    this.edate,
    this.auser,
    this.adate,
  });
}

// ── Toast ─────────────────────────────────────────────────────────────────────
class _ProdToast {
  static OverlayEntry? _cur;
  static void show(BuildContext ctx, String msg, {bool isError = false}) {
    _cur?.remove();
    final bg = isError ? _kRL : _kGL;
    final fg = isError ? _kR : _kG;
    final bd = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final ic = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    late OverlayEntry e;
    e = OverlayEntry(
      builder: (_) => _ToastW(
        msg: msg,
        bg: bg,
        fg: fg,
        border: bd,
        icon: ic,
        onDismiss: () {
          e.remove();
          if (_cur == e) _cur = null;
        },
      ),
    );
    _cur = e;
    Overlay.of(ctx).insert(e);
    Future.delayed(const Duration(seconds: 3), () {
      if (_cur == e) {
        e.remove();
        _cur = null;
      }
    });
  }
}

class _ToastW extends StatefulWidget {
  final String msg;
  final Color bg, fg, border;
  final IconData icon;
  final VoidCallback onDismiss;
  const _ToastW({
    required this.msg,
    required this.bg,
    required this.fg,
    required this.border,
    required this.icon,
    required this.onDismiss,
  });
  @override
  State<_ToastW> createState() => _ToastWState();
}

class _ToastWState extends State<_ToastW> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s, _f;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _s = Tween<double>(
      begin: -50,
      end: 0,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _f = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned(
    top: 18,
    left: 0,
    right: 0,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, ch) => Transform.translate(
        offset: Offset(0, _s.value),
        child: Opacity(opacity: _f.value, child: ch),
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.bg,
            border: Border.all(color: widget.border),
            borderRadius: BorderRadius.circular(9),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.msg,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.fg,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(Icons.close_rounded, size: 13, color: widget.fg),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Org Filter Button (same style as Products)
// ─────────────────────────────────────────────────────────────────────────────
class _OrgFilterButton extends StatefulWidget {
  final String? selectedOrgCode;
  final List<String> orgs; // full "code - name" strings
  final ValueChanged<String?> onChanged;
  const _OrgFilterButton({
    this.selectedOrgCode,
    required this.orgs,
    required this.onChanged,
  });
  @override
  State<_OrgFilterButton> createState() => _OrgFilterButtonState();
}

class _OrgFilterButtonState extends State<_OrgFilterButton> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  final TextEditingController _sc = TextEditingController();
  String _q = '';
  int _hlIdx = 0;
  List<String> _filteredItems = [];
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _rm();
    _sc.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _rm() {
    _ov?.remove();
    _ov = null;
  }

  void _scrollToHl() {
    const itemH = 40.0;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _hlIdx * itemH,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _open() {
    _rm();
    _sc.clear();
    _q = '';
    _filteredItems = List.from(widget.orgs);
    final selIdx = _filteredItems.indexWhere(
      (o) => o.startsWith(widget.selectedOrgCode ?? ''),
    );
    _hlIdx = selIdx >= 0
        ? selIdx + 1
        : 0; // +1 offset for "All Organizations" row

    final rb = _key.currentContext?.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final ov = Overlay.of(context).context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov);
    final sz = rb.size;
    const dropW = 300.0;
    final left = pos.dx + sz.width - dropW;

    _ov = OverlayEntry(
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _rm,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: left,
                top: pos.dy + sz.height + 4,
                width: dropW,
                child: StatefulBuilder(
                  builder: (c2, ss) {
                    _filteredItems = widget.orgs
                        .where(
                          (o) =>
                              _q.isEmpty ||
                              o.toLowerCase().contains(_q.toLowerCase()),
                        )
                        .toList();
                    final totalRows = 1 + _filteredItems.length;
                    if (_hlIdx >= totalRows) _hlIdx = totalRows - 1;

                    void selectHighlighted() {
                      if (_hlIdx == 0) {
                        widget.onChanged(null);
                        _rm();
                        return;
                      }
                      final org = _filteredItems[_hlIdx - 1];
                      final code = org.split(' - ').first.trim();
                      widget.onChanged(code);
                      _rm();
                    }

                    return KeyboardListener(
                      focusNode: FocusNode(),
                      autofocus: true,
                      onKeyEvent: (event) {
                        if (event is! KeyDownEvent && event is! KeyRepeatEvent)
                          return;
                        final key = event.logicalKey;
                        if (key == LogicalKeyboardKey.arrowDown) {
                          ss(
                            () => _hlIdx = (_hlIdx + 1).clamp(0, totalRows - 1),
                          );
                          _scrollToHl();
                        } else if (key == LogicalKeyboardKey.arrowUp) {
                          ss(
                            () => _hlIdx = (_hlIdx - 1).clamp(0, totalRows - 1),
                          );
                          _scrollToHl();
                        } else if (key == LogicalKeyboardKey.enter ||
                            key == LogicalKeyboardKey.numpadEnter) {
                          selectHighlighted();
                        } else if (key == LogicalKeyboardKey.escape) {
                          _rm();
                        }
                      },
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _kBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  controller: _sc,
                                  autofocus: true,
                                  onChanged: (v) => ss(() {
                                    _q = v;
                                    _hlIdx = 0;
                                  }),
                                  onSubmitted: (_) => selectHighlighted(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search organization...',
                                    hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    filled: true,
                                    fillColor: _kSurface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kP,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const Divider(height: 1, color: _kBorder),
                              Flexible(
                                child: ListView(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  shrinkWrap: true,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        widget.onChanged(null);
                                        _rm();
                                      },
                                      onHover: (h) {
                                        if (h) ss(() => _hlIdx = 0);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        color: _hlIdx == 0
                                            ? _kPL
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.business_rounded,
                                              size: 14,
                                              color: _kMuted,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'All Organizations',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      (widget.selectedOrgCode ==
                                                              null ||
                                                          _hlIdx == 0)
                                                      ? _kP
                                                      : _kText,
                                                  fontWeight:
                                                      (widget.selectedOrgCode ==
                                                              null ||
                                                          _hlIdx == 0)
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            if (widget.selectedOrgCode == null)
                                              const Icon(
                                                Icons.check_rounded,
                                                size: 14,
                                                color: _kP,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ..._filteredItems.asMap().entries.map((e) {
                                      final i = e.key + 1;
                                      final org = e.value;
                                      final parts = org.split(' - ');
                                      final code = parts.first.trim();
                                      final name = parts.length > 1
                                          ? parts.sublist(1).join(' - ').trim()
                                          : '';
                                      final isSel =
                                          widget.selectedOrgCode == code;
                                      final isHl = i == _hlIdx;
                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged(code);
                                          _rm();
                                        },
                                        onHover: (h) {
                                          if (h) ss(() => _hlIdx = i);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          color: isHl
                                              ? _kPL.withOpacity(0.5)
                                              : (isSel
                                                    ? _kPL
                                                    : Colors.transparent),
                                          child: Row(
                                            children: [
                                              if (code.isNotEmpty)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  margin: const EdgeInsets.only(
                                                    right: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _kPL,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    code,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: _kP,
                                                    ),
                                                  ),
                                                ),
                                              Expanded(
                                                child: Text(
                                                  name.isEmpty ? org : name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: (isSel || isHl)
                                                        ? _kP
                                                        : _kText,
                                                    fontWeight: (isSel || isHl)
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isSel)
                                                const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: _kP,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  @override
  Widget build(BuildContext ctx) {
    final has =
        widget.selectedOrgCode != null && widget.selectedOrgCode!.isNotEmpty;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          key: _key,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: has ? const Color(0xFF2A55A5) : _kP,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.filter_list_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              const Text(
                'Filter',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (has) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => widget.onChanged(null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ] else ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Search Box (same as Products)
// ─────────────────────────────────────────────────────────────────────────────
class _SBox extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  const _SBox({required this.width, required this.onChanged});
  @override
  State<_SBox> createState() => _SBoxState();
}

class _SBoxState extends State<_SBox> {
  final _f = FocusNode();
  bool _foc = false;
  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() => _foc = _f.hasFocus));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _foc ? _kP : _kBorder, width: _foc ? 2.0 : 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _foc
          ? [
              BoxShadow(
                color: _kP.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
    ),
    child: TextField(
      focusNode: _f,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search mappings...',
        hintStyle: TextStyle(
          fontSize: 12,
          color: _foc ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 16,
          color: _foc ? _kP : const Color(0xFF94A3B8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        isDense: true,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Floating-label dropdown with search
// ─────────────────────────────────────────────────────────────────────────────
// ── Premium Dropdown with Search (matches Branches.dart style) ────────────────
class _OrgDropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final bool readOnly, hasError, hideLock;

  const _OrgDropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.readOnly = false,
    this.hasError = false,
    this.hideLock = false,
  });

  @override
  State<_OrgDropdownField> createState() => _OrgDropdownFieldState();
}

class _OrgDropdownFieldState extends State<_OrgDropdownField>
    with TickerProviderStateMixin {
  late AnimationController _lA, _dA;
  late Animation<double> _lTop, _lSz, _dF, _dS;
  OverlayEntry? _ov;
  final _link = LayerLink();
  bool _open = false;
  final TextEditingController _searchCtrl = TextEditingController();
  int _hlIdx = 0;
  List<String> _filteredItems = [];
  final ScrollController _scrollCtrl = ScrollController();

  bool get _floated =>
      _open ||
      (widget.value != null && widget.value!.isNotEmpty) ||
      widget.hasError;

  @override
  void initState() {
    super.initState();
    _lA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: _floated ? 1.0 : 0.0,
    );
    _lTop = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _lSz = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _lA, curve: Curves.easeOut));
    _dA = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _dF = CurvedAnimation(parent: _dA, curve: Curves.easeOut);
    _dS = Tween<double>(
      begin: -4,
      end: 0,
    ).animate(CurvedAnimation(parent: _dA, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_OrgDropdownField o) {
    super.didUpdateWidget(o);
    _floated ? _lA.forward() : _lA.reverse();
    if (_open) _ov?.markNeedsBuild();
  }

  @override
  void dispose() {
    _rmOv();
    _lA.dispose();
    _dA.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _rmOv() {
    _ov?.remove();
    _ov = null;
  }

  void _scrollToHl() {
    const itemH = 40.0;
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _hlIdx * itemH,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _open_() {
    if (widget.readOnly || _open) return;
    _hlIdx = 0;
    _filteredItems = List.from(widget.items);
    final selIdx = _filteredItems.indexWhere((it) => it == widget.value);
    if (selIdx >= 0) _hlIdx = selIdx;

    setState(() => _open = true);
    _lA.forward();
    _dA.forward(from: 0);
    _searchCtrl.clear();
    final box = context.findRenderObject() as RenderBox?;
    final sz = box?.size ?? Size.zero;
    _ov = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _close_,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              offset: Offset(0, sz.height + 3),
              child: Material(
                color: Colors.transparent,
                child: AnimatedBuilder(
                  animation: _dA,
                  builder: (_, ch) => Transform.translate(
                    offset: Offset(0, _dS.value),
                    child: Opacity(opacity: _dF.value, child: ch),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      final query = _searchCtrl.text.toLowerCase().trim();
                      _filteredItems = widget.items
                          .where((i) => i.toLowerCase().contains(query))
                          .toList();
                      if (_hlIdx >= _filteredItems.length) {
                        _hlIdx = _filteredItems.isEmpty
                            ? 0
                            : _filteredItems.length - 1;
                      }

                      void selectHighlighted() {
                        if (_filteredItems.isNotEmpty) {
                          widget.onChanged(_filteredItems[_hlIdx]);
                          _close_();
                        }
                      }

                      return KeyboardListener(
                        focusNode: FocusNode(),
                        autofocus: true,
                        onKeyEvent: (event) {
                          if (event is! KeyDownEvent &&
                              event is! KeyRepeatEvent)
                            return;
                          final key = event.logicalKey;
                          if (key == LogicalKeyboardKey.arrowDown) {
                            setOverlayState(
                              () => _hlIdx = (_hlIdx + 1).clamp(
                                0,
                                _filteredItems.length - 1,
                              ),
                            );
                            _scrollToHl();
                          } else if (key == LogicalKeyboardKey.arrowUp) {
                            setOverlayState(
                              () => _hlIdx = (_hlIdx - 1).clamp(
                                0,
                                _filteredItems.length - 1,
                              ),
                            );
                            _scrollToHl();
                          } else if (key == LogicalKeyboardKey.enter ||
                              key == LogicalKeyboardKey.numpadEnter) {
                            selectHighlighted();
                          } else if (key == LogicalKeyboardKey.escape) {
                            _close_();
                          }
                        },
                        child: Container(
                          width: sz.width,
                          constraints: const BoxConstraints(maxHeight: 280),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kP, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.07),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextField(
                                  controller: _searchCtrl,
                                  autofocus: true,
                                  onChanged: (v) {
                                    setOverlayState(() => _hlIdx = 0);
                                  },
                                  onSubmitted: (_) => selectHighlighted(),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: _kText,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 16,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    filled: true,
                                    fillColor: _kSurface,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                        color: _kP,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              Expanded(
                                child: Scrollbar(
                                  child: ListView.separated(
                                    controller: _scrollCtrl,
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredItems.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFF1F5F9),
                                    ),
                                    itemBuilder: (_, i) {
                                      final it = _filteredItems[i];
                                      final sel = it == widget.value;
                                      final hl = i == _hlIdx;
                                      final parts = it.split(' - ');
                                      final code = parts.first;
                                      final name = parts.length > 1
                                          ? parts.last
                                          : '';
                                      return InkWell(
                                        onTap: () {
                                          _close_();
                                          widget.onChanged(it);
                                        },
                                        onHover: (h) {
                                          if (h)
                                            setOverlayState(() => _hlIdx = i);
                                        },
                                        hoverColor: Colors.transparent,
                                        child: Container(
                                          color: hl
                                              ? _kPL.withOpacity(0.5)
                                              : (sel
                                                    ? _kPL.withOpacity(0.4)
                                                    : Colors.transparent),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 9,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _kPL,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  code,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: _kP,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  name,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: (sel || hl)
                                                        ? _kP
                                                        : _kText,
                                                    fontWeight: (sel || hl)
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (sel)
                                                const Icon(
                                                  Icons.check_rounded,
                                                  size: 14,
                                                  color: _kP,
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_ov!);
  }

  void _close_() {
    _dA.reverse().then((_) => _rmOv());
    setState(() => _open = false);
    if (!_floated) _lA.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bc = widget.hasError ? _kR : _kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CompositedTransformTarget(
          link: _link,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: widget.readOnly ? null : _open_,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.readOnly ? _kSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bc, width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(40, 12, 36, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.value != null
                                  ? widget.value!.split(' - ').first
                                  : (_floated ? 'Search organization...' : ''),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: widget.value != null ? _kText : _kMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          (widget.readOnly && !widget.hideLock)
                              ? const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: _kMuted,
                                )
                              : Icon(
                                  Icons.unfold_more_rounded,
                                  size: 16,
                                  color: bc,
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 0,
                bottom: 0,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(widget.icon, size: 14, color: bc),
                ),
              ),
              AnimatedBuilder(
                animation: _lA,
                builder: (_, __) => Positioned(
                  top: _lTop.value,
                  left: 28,
                  child: GestureDetector(
                    onTap: widget.readOnly ? null : _open_,
                    child: Container(
                      color: widget.readOnly ? _kSurface : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text.rich(
                        TextSpan(
                          text: widget.label,
                          children: [
                            const TextSpan(
                              text: ' *',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: _lSz.value,
                          fontWeight: FontWeight.w600,
                          color: bc,
                          letterSpacing: 0.2,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.value != null && widget.value!.contains(' - '))
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              widget.value!.split(' - ').last,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kP,
                height: 1.2,
              ),
            ),
          ),
        if (widget.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              '${widget.label} is required',
              style: const TextStyle(fontSize: 11, color: _kR),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Read-only floating-label field
// ─────────────────────────────────────────────────────────────────────────────
class _ROF extends StatefulWidget {
  final String label, value;
  final IconData icon;
  const _ROF({required this.label, required this.value, required this.icon});
  @override
  State<_ROF> createState() => _ROFState();
}

class _ROFState extends State<_ROF> with SingleTickerProviderStateMixin {
  late AnimationController _a;
  late Animation<double> _t, _s;
  @override
  void initState() {
    super.initState();
    _a = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: widget.value.isNotEmpty ? 1.0 : 0.0,
    );
    _t = Tween<double>(
      begin: 13,
      end: -8,
    ).animate(CurvedAnimation(parent: _a, curve: Curves.easeOut));
    _s = Tween<double>(
      begin: 13,
      end: 10.5,
    ).animate(CurvedAnimation(parent: _a, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_ROF o) {
    super.didUpdateWidget(o);
    widget.value.isNotEmpty ? _a.forward() : _a.reverse();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        height: 44,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kP, width: 1.5),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, right: 6),
              child: Icon(widget.icon, size: 14, color: _kP),
            ),
            Expanded(
              child: widget.value.isNotEmpty
                  ? Text(
                      widget.value,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _kText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  : const Text(
                      '—',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Positioned(
          top: _t.value,
          left: 28,
          child: IgnorePointer(
            child: Container(
              color: _kSurface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: _s.value,
                  fontWeight: FontWeight.w600,
                  color: _kP,
                  letterSpacing: 0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Product Grid
// ─────────────────────────────────────────────────────────────────────────────
class _ProdGrid extends StatefulWidget {
  final List<String> all, selected;
  final ValueChanged<String>? onToggle;
  final bool hasError;
  const _ProdGrid({
    required this.all,
    required this.selected,
    this.onToggle,
    this.hasError = false,
  });
  @override
  State<_ProdGrid> createState() => _ProdGridState();
}

class _ProdGridState extends State<_ProdGrid> {
  String _q = '';

  IconData _ic(String p) => switch (p.toLowerCase()) {
    'access manager' => Icons.admin_panel_settings_rounded,
    'connect' => Icons.link_rounded,
    'hrm' => Icons.people_rounded,
    'crm' => Icons.handshake_rounded,
    'payroll' => Icons.account_balance_wallet_rounded,
    'fixed asset' => Icons.warehouse_rounded,
    'finance' => Icons.account_balance_rounded,
    // keep old ones in case
    'payments' => Icons.payment_rounded,
    'tickets' => Icons.confirmation_number_rounded,
    'projects' => Icons.folder_special_rounded,
    'test' => Icons.bug_report_rounded,
    _ => Icons.apps_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final ro = widget.onToggle == null;
    final borderColor = widget.hasError ? _kR : _kP;
    final filtered = widget.all
        .where((p) => p.toLowerCase().contains(_q.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'PRODUCTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kP,
                      letterSpacing: 1,
                    ),
                  ),
                  if (!ro) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.hasError ? _kRL : _kPL,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: widget.hasError ? _kRB : _kPB,
                        ),
                      ),
                      child: Text(
                        widget.hasError
                            ? 'Select at least one product'
                            : '${widget.selected.length}/${widget.all.length} selected',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: widget.hasError ? _kR : _kP,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _ProdSearch(
                    width: 190,
                    onChanged: (v) => setState(() => _q = v),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: widget.selected.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                'No products selected',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFCBD5E1),
                                ),
                              ),
                            )
                          : Row(
                              children: widget.selected
                                  .map(
                                    (p) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: _SelChip(
                                        label: p,
                                        icon: _ic(p),
                                        readOnly: ro,
                                        onRemove: ro
                                            ? null
                                            : () => widget.onToggle!(p),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'No products found',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (_, cons) {
                    final cardW = (cons.maxWidth - 30) / 4;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: filtered.map((p) {
                        final sel = widget.selected.contains(p);
                        return SizedBox(
                          width: cardW,
                          height: 52,
                          child: _ProdCard(
                            label: p,
                            icon: _ic(p),
                            selected: sel,
                            readOnly: ro,
                            onYes: ro
                                ? null
                                : () {
                                    if (!sel) widget.onToggle!(p);
                                  },
                            onNo: ro
                                ? null
                                : () {
                                    if (sel) widget.onToggle!(p);
                                  },
                          ),
                        );
                      }).toList(),
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

class _SelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onRemove;
  const _SelChip({
    required this.label,
    required this.icon,
    required this.readOnly,
    this.onRemove,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 6, 5),
    decoration: BoxDecoration(
      color: _kPL,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kPB, width: 1.2),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: _kP),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kP,
          ),
        ),
        if (!readOnly && onRemove != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: _kP.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 9, color: _kP),
            ),
          ),
        ],
      ],
    ),
  );
}

class _ProdCard extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected, readOnly;
  final VoidCallback? onYes, onNo;
  const _ProdCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.readOnly,
    this.onYes,
    this.onNo,
  });
  @override
  State<_ProdCard> createState() => _ProdCardState();
}

class _ProdCardState extends State<_ProdCard> {
  bool _hov = false;
  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      cursor: widget.readOnly
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: sel
              ? _kPL
              : (_hov && !widget.readOnly
                    ? const Color(0xFFF8FAFF)
                    : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel ? _kP : (_hov && !widget.readOnly ? _kPB : _kBorder),
            width: sel ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: sel ? _kP.withOpacity(0.12) : _kSurface,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: sel ? _kPB : _kBorder, width: 1),
              ),
              child: Icon(widget.icon, size: 14, color: sel ? _kP : _kMuted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _kP : _kText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            // _RadioBtn(label: 'Yes', active: sel, activeColor: _kG, activeBg: _kGL, activeBorder: _kGB, readOnly: widget.readOnly, onTap: widget.onYes),
            // const SizedBox(width: 4),
            // _RadioBtn(label: 'No', active: !sel, activeColor: _kR, activeBg: _kRL, activeBorder: _kRB, readOnly: widget.readOnly, onTap: widget.onNo),
            // REPLACE this in _ProdCard build()

            // WITH this:
            GestureDetector(
              onTap: widget.readOnly
                  ? null
                  : () => sel ? widget.onNo?.call() : widget.onYes?.call(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 22,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: sel ? _kG : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      alignment: sel
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// class _RadioBtn extends StatelessWidget {
//   final String label; final bool active, readOnly;
//   final Color activeColor, activeBg, activeBorder;
//   final VoidCallback? onTap;
//   const _RadioBtn({required this.label, required this.active, required this.activeColor,
//     required this.activeBg, required this.activeBorder, required this.readOnly, this.onTap});
//   @override Widget build(BuildContext context) => MouseRegion(
//     cursor: readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
//     child: GestureDetector(
//       onTap: readOnly ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 120),
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         decoration: BoxDecoration(
//           color: active ? activeBg : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: active ? activeBorder : _kBorder, width: active ? 1.4 : 1.0),
//         ),
//         child: Row(mainAxisSize: MainAxisSize.min, children: [
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 120),
//             width: 7, height: 7,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: active ? activeColor : Colors.white,
//               border: Border.all(color: active ? activeColor : const Color(0xFFCBD5E1), width: 1.4),
//             ),
//             child: active ? Center(child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
//           ),
//           const SizedBox(width: 4),
//           Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: active ? activeColor : _kMuted)),
//         ]),
//       ),
//     ),
//   );
// }
class _StatusToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool hasError, readOnly;

  const _StatusToggle({
    required this.isActive,
    required this.onChanged,
    this.hasError = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final bc = hasError ? _kR : _kP;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      Icons.signal_cellular_alt_rounded,
                      size: 14,
                      color: bc,
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      key: ValueKey(isActive),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? _kG : _kMuted,
                      ),
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: readOnly
                        ? SystemMouseCursors.basic
                        : SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: readOnly ? null : () => onChanged(!isActive),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 18,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isActive ? _kG : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Stack(
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              alignment: isActive
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -8,
              left: 28,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  const TextSpan(
                    text: 'Status',
                    children: [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: bc,
                    letterSpacing: 0.2,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 10),
            child: Text(
              'Status is required',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kR,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class _ProdSearch extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  const _ProdSearch({required this.width, required this.onChanged});
  @override
  State<_ProdSearch> createState() => _ProdSearchState();
}

class _ProdSearchState extends State<_ProdSearch> {
  final _f = FocusNode();
  bool _foc = false;
  @override
  void initState() {
    super.initState();
    _f.addListener(() => setState(() => _foc = _f.hasFocus));
  }

  @override
  void dispose() {
    _f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _foc ? _kP : _kBorder, width: _foc ? 1.5 : 1.0),
      borderRadius: BorderRadius.circular(9),
      boxShadow: _foc
          ? [
              BoxShadow(
                color: _kP.withOpacity(0.10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ]
          : [],
    ),
    child: TextField(
      focusNode: _f,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 12.5, color: _kText),
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: TextStyle(
          fontSize: 12,
          color: _foc ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 15,
          color: _foc ? _kP : const Color(0xFF94A3B8),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 7),
        isDense: true,
      ),
    ),
  );
}

class ProductOrganization extends StatefulWidget {
  final AccessPrivileges? accessPrivileges;
  const ProductOrganization({super.key, this.accessPrivileges});
  @override
  State<ProductOrganization> createState() => _POState();
}

class _POState extends State<ProductOrganization> {
  _V _view = _V.list;
  _Mapping? _sel;
  bool _delOk = false;
  String _search = '';
  String? _selectedOrgFilter;

  List<String> _orgs = [];
  List<String> _prods = [];
  final List<String> _statuses = ['A - Active', 'I - Inactive'];
  final Map<String, int> _productNameToCode = {};
  final Map<int, String> _productCodeToName = {};
  // Store product code -> product display name (e.g., "1 - xConnect")
  final Map<String, String> _productDisplayNames = {};
  bool _loading = true;
  String? _loadError;

  int _currentPage = 0;
  static const int _pageSize = 10;
  int _totalElements = 0;
  int _activeCount = 0;
  int _inactiveCount = 0;
  Timer? _searchDebounce;

  String _code(String orgFull) => orgFull.split(' - ').first.trim();

  List<_Mapping> _data = [];
  int? _pgmId;

  @override
  void initState() {
    super.initState();
    _loadMeta();
    _fetchPgmId();
  }

  Future<void> _fetchPgmId() async {
    try {
      final programs = await ProgramService().getAllPrograms();
      final pgm = programs.firstWhere(
        (p) =>
            p.descn.toLowerCase() == 'product mapping' ||
            p.descn.toLowerCase() == 'product organization mapping' ||
            p.descn.toLowerCase() == 'product org',
      );
      _pgmId = pgm.pgmId;
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      final orgResponse = await OrganizationService().getAllOrganizations();
      final products = await ProductService().getAllProducts();

      final orgs = orgResponse
          .map((org) {
            final code = _extractOrgCode(org);
            final name = _extractOrgName(org);
            return '$code - $name';
          })
          .where((entry) => entry.contains(' - '))
          .toList();

      final prods = products
          .map((product) => product.productName)
          .toSet()
          .toList();
      final prodNameToCode = <String, int>{};
      final prodCodeToName = <int, String>{};
      for (final product in products) {
        prodNameToCode[product.productName] = product.productCode;
        prodCodeToName[product.productCode] = product.productName;
      }

      // Build product display names: "productCode - productName"
      final productDisplayNames = <String, String>{};
      for (final product in products) {
        final key = product.productName;
        productDisplayNames[key] =
            '${product.productCode} - ${product.productName}';
      }

      _orgs = orgs;
      _prods = prods;
      _productNameToCode.clear();
      _productNameToCode.addAll(prodNameToCode);
      _productCodeToName.clear();
      _productCodeToName.addAll(prodCodeToName);
      _productDisplayNames.clear();
      _productDisplayNames.addAll(productDisplayNames);

      await _loadMappingsInternal();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMappingsInternal() async {
    final offset = _currentPage * _pageSize;
    final response = await ProductMappingService().getMappingsPaginated(
      offset,
      _pageSize,
      search: _search,
      orgCode: _selectedOrgFilter,
    );

    final List<Map<String, dynamic>> content = response['content'] ?? [];
    _totalElements = response['totalElements'] ?? 0;
    _activeCount = response['activeCount'] ?? 0;
    _inactiveCount = response['inactiveCount'] ?? 0;

    _data = content.map((item) {
      final orgCode = item['orgCode'] ?? item['orgcode'];
      final codeStr = orgCode?.toString() ?? '';
      final status =
          item['status'] == true ||
          item['status']?.toString().toLowerCase() == 'true' ||
          item['status'] == 1 ||
          item['status'] == 'A';
      final prodCodes = <String>[];
      if (item['prodCodes'] is List) {
        for (final rawCode in item['prodCodes'] as List<dynamic>) {
          final parsed = int.tryParse(rawCode.toString());
          if (parsed != null && _productCodeToName.containsKey(parsed)) {
            prodCodes.add(_productCodeToName[parsed]!);
          } else {
            prodCodes.add(rawCode.toString());
          }
        }
      }
      final uniqueProdCodes = prodCodes.toSet().toList();
      return _Mapping(
        orgCode: codeStr,
        prodCodes: uniqueProdCodes,
        status: status ? 'A - Active' : 'I - Inactive',
        enabled: status,
        cuser: item['cuser']?.toString(),
        cdate: _formatAuditDate(item['cdate']?.toString()),
        euser: item['euser']?.toString(),
        edate: _formatAuditDate(item['edate']?.toString()),
        auser: item['auser']?.toString(),
        adate: _formatAuditDate(item['adate']?.toString()),
      );
    }).toList();
  }

  Future<void> _loadMappings() async {
    setState(() => _loading = true);
    try {
      await _loadMappingsInternal();
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  String _formatAuditDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final d = DateTime.parse(dateStr).toLocal();
      const ms = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      final h = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final m = d.minute.toString().padLeft(2, '0');
      final p = d.hour >= 12 ? 'PM' : 'AM';
      return '${d.day.toString().padLeft(2, '0')} ${ms[d.month - 1]} ${d.year}, ${h.toString().padLeft(2, '0')}:$m $p';
    } catch (_) {
      return dateStr;
    }
  }

  String _extractOrgCode(Map<String, dynamic> org) {
    final raw =
        org['orgCode'] ?? org['orgcode'] ?? org['code'] ?? org['org_code'];
    return raw?.toString() ?? '';
  }

  String _extractOrgName(Map<String, dynamic> org) {
    final raw =
        org['orgName'] ?? org['orgname'] ?? org['name'] ?? org['org_name'];
    return raw?.toString() ?? '';
  }

  String _orgFull(String code) =>
      _orgs.firstWhere((o) => _code(o) == code, orElse: () => code);

  // Get display name for product: "productCode - productName"
  String _prodDisplay(String prodName) =>
      _productDisplayNames[prodName] ?? prodName;

  List<_Mapping> get _fil => _data;

  void _go(_V v, [_Mapping? r]) => setState(() {
    _view = v;
    _sel = r;
    _delOk = false;
    if (v == _V.list) {
      _search = '';
      _currentPage = 0;
      _loadMappings();
    }
  });
  void _toast(String m, {bool err = false}) =>
      _ProdToast.show(context, m, isError: err);

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: switch (_view) {
        _V.list => _list(),
        _V.create => _formV(false),
        _V.view => _detail(),
        _V.edit => _formV(true),
        _V.delete => _del(),
      },
    );
  }

  Widget _page_({required Widget child}) =>
      SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );

  Widget _fBtn(
    String lbl,
    IconData ic,
    Color bg,
    Color fg,
    Color bd, {
    VoidCallback? onTap,
  }) => MouseRegion(
    cursor: onTap == null
        ? SystemMouseCursors.forbidden
        : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: bd, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              lbl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _rBtn(IconData ic, Color col, VoidCallback tap) => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: tap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        child: Icon(ic, size: 14, color: col),
      ),
    ),
  );

  Widget _statusBadge(bool en) => IntrinsicWidth(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: en ? _kGL : _kRL,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: en ? _kG : _kR,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            en ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: en ? _kG : _kR,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _pageBtn(String l, {required bool en, required VoidCallback onTap}) =>
      MouseRegion(
        cursor: en ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: en ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kBorder),
            ),
            child: Text(
              l,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: en ? _kMuted : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      );

  // ── LIST ──────────────────────────────────────────────────────────────────
  Widget _list() {
    final tp = (_totalElements / _pageSize).ceil().clamp(1, 9999);
    final st = _totalElements == 0 ? 0 : _currentPage * _pageSize + 1;
    final en = _currentPage * _pageSize + _data.length;

    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'Product Organization',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _kText,
                letterSpacing: -0.3,
              ),
            ),
          ),

          // ── Stats (same style as Products) ────────────────────────────────
          Row(
            children: [
              _sc(
                '$_totalElements',
                'Total',
                _kP,
                _kPL,
                _kPB,
                Icons.business_rounded,
                _kP,
              ),
              const SizedBox(width: 10),
              _sc(
                '$_activeCount',
                'Enabled',
                _kG,
                _kGL,
                _kGB,
                Icons.check_circle_outline_rounded,
                _kG,
              ),
              const SizedBox(width: 10),
              _sc(
                '$_inactiveCount',
                'Disabled',
                _kR,
                _kRL,
                _kRB,
                Icons.block_rounded,
                _kR,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Search + Filter button + New (same layout as Products) ─────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _SBox(
                width: 220,
                onChanged: (v) {
                  _search = v;
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 300),
                    () {
                      _currentPage = 0;
                      _loadMappings();
                    },
                  );
                },
              ),
              const SizedBox(width: 10),
              _OrgFilterButton(
                selectedOrgCode: _selectedOrgFilter,
                orgs: _orgs,
                onChanged: (v) {
                  _selectedOrgFilter = v;
                  _currentPage = 0;
                  _loadMappings();
                },
              ),
              if (widget.accessPrivileges?.canCreate ?? true) ...[
                const SizedBox(width: 10),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _go(_V.create),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _kP,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kP, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 15, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'New Mapping',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading mappings...'),
                  ],
                ),
              ),
            )
          else if (_loadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Failed to load product mapping data: $_loadError',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          else
            _card(
              child: LayoutBuilder(
                builder: (_, con) {
                  final w = con.maxWidth;
                  final cols = [w * .30, w * .35, w * .14, w * .21];

                  Widget hC(String t) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    child: Center(
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  );

                  return Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(color: _kP),
                        child: Row(
                          children: [
                            SizedBox(width: cols[0], child: hC('ORGANIZATION')),
                            SizedBox(width: cols[1], child: hC('PRODUCTS')),
                            SizedBox(width: cols[2], child: hC('STATUS')),
                            SizedBox(width: cols[3], child: hC('ACTIONS')),
                          ],
                        ),
                      ),

                      if (_data.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(28),
                          child: Center(
                            child: Text(
                              'No records found',
                              style: TextStyle(fontSize: 13, color: _kMuted),
                            ),
                          ),
                        ),

                      // ── Rows with alternating background (same as Products) ────────
                      ..._data.asMap().entries.map((e) {
                        final i = e.key;
                        final r = e.value;
                        final orgFull = _orgFull(r.orgCode);
                        final isEven = i % 2 == 1;

                        return StatefulBuilder(
                          builder: (_, ss) {
                            bool hov = false;
                            return MouseRegion(
                              cursor: SystemMouseCursors.click,
                              onEnter: (_) => ss(() => hov = true),
                              onExit: (_) => ss(() => hov = false),
                              child: Container(
                                decoration: BoxDecoration(
                                  // Alternating row colors like Products screen
                                  color: hov
                                      ? _kPL
                                      : (isEven ? _kRowAlt : Colors.white),
                                  border: const Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFF1F5F9),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Organization: "orgCode - orgName"
                                    SizedBox(
                                      width: cols[0],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: Text(
                                            orgFull,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: _kP,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Products: show "productCode - productName" chips
                                    SizedBox(
                                      width: cols[1],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            spacing: 3,
                                            runSpacing: 3,
                                            children: r.prodCodes
                                                .map(
                                                  (p) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 7,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _kPL,
                                                      border: Border.all(
                                                        color: _kPB,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            5,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _prodDisplay(
                                                        p,
                                                      ), // "1 - xConnect" format
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: _kP,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Status
                                    SizedBox(
                                      width: cols[2],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Center(
                                          child: _statusBadge(r.enabled),
                                        ),
                                      ),
                                    ),
                                    // Actions
                                    SizedBox(
                                      width: cols[3],
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (widget.accessPrivileges?.canView ?? true) ...[
                                              _rBtn(
                                                Icons.visibility_outlined,
                                                const Color(0xFF475569),
                                                () => _go(_V.view, r),
                                              ),
                                              const SizedBox(width: 5),
                                            ],
                                            if (widget.accessPrivileges?.canEdit ?? true) ...[
                                              _rBtn(
                                                Icons.edit_outlined,
                                                _kP,
                                                () => _go(_V.edit, r),
                                              ),
                                              const SizedBox(width: 5),
                                            ],
                                            if (widget.accessPrivileges?.canDelete ?? true) ...[
                                              _rBtn(
                                                Icons.delete_outline_rounded,
                                                _kR,
                                                () => _go(_V.delete, r),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _data.isEmpty
                                  ? 'No records found'
                                  : 'Showing $st–$en of $_totalElements records',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Row(
                              children: [
                                _pageBtn(
                                  '‹ Prev',
                                  en: _currentPage > 0,
                                  onTap: () {
                                    _currentPage--;
                                    _loadMappings();
                                  },
                                ),
                                const SizedBox(width: 6),
                                _pageBtn(
                                  'Next ›',
                                  en: _currentPage < tp - 1,
                                  onTap: () {
                                    _currentPage++;
                                    _loadMappings();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _sc(
    String n,
    String l,
    Color nc,
    Color bg,
    Color bd,
    IconData ic,
    Color iC,
  ) => Container(
    width: 180,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: bd),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(ic, size: 18, color: iC),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              n,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: nc,
                height: 1.1,
              ),
            ),
            Text(l, style: const TextStyle(fontSize: 10, color: _kMuted)),
          ],
        ),
      ],
    ),
  );

  // ── VIEW DETAIL ───────────────────────────────────────────────────────────
  Widget _detail() {
    final r = _sel!;
    final orgFull = _orgFull(r.orgCode);
    return _page_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mapping Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _fBtn(
                  'Audit Details',
                  Icons.history_rounded,
                  Colors.white,
                  _kP,
                  _kP,
                  onTap: () => AuditDetailsDialog.show(
                    context,
                    cuser: r.euser,
                    cdate: r.edate,
                    euser: r.cuser,
                    edate: r.cdate,
                    auser: r.auser,
                    adate: r.adate,
                    subtitle: 'Product organization mapping audit trail',
                  ),
                ),
                const SizedBox(width: 10),
                _fBtn(
                  'Back',
                  Icons.arrow_back_rounded,
                  _kP,
                  Colors.white,
                  _kP,
                  onTap: () => _go(_V.list),
                ),
              ],
            ),
          ),

          _card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEEF3FB), Colors.white],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    border: Border(bottom: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              orgFull,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _kP,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _statusBadge(r.enabled),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _OrgDropdownField(
                              label: 'Organization',
                              value: orgFull,
                              items: const [],
                              onChanged: (v) {},
                              icon: Icons.business_rounded,
                              readOnly: true,
                              hideLock: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _StatusToggle(
                              isActive: r.enabled,
                              hasError: false,
                              readOnly: true,
                              onChanged: (v) {},
                            ),
                          ),
                          const Expanded(child: SizedBox()),
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                      // Products shown with "code - name" format
                      _ProdGrid(all: r.prodCodes, selected: r.prodCodes),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: _kBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _fBtn(
                        'Back',
                        Icons.arrow_back_rounded,
                        _kP,
                        Colors.white,
                        _kP,
                        onTap: () => _go(_V.list),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CREATE / EDIT ─────────────────────────────────────────────────────────
  // Widget _formV(bool isEdit) {
  //   final ex = isEdit ? _sel : null;
  //   String? sOrg = ex != null ? _orgFull(ex.orgCode) : null;
  //   return _FView(
  //     isEdit: isEdit,
  //     initOrg: sOrg,
  //     initStatus: ex?.status,
  //     initProds: ex != null ? List.from(ex.prodCodes) : [],
  //     orgs: _orgs,
  //     prods: _prods,
  //     statuses: _statuses,
  //     prodNameToCode: _productNameToCode,
  //     mappings: _data,
  //     onSave: (m) {
  //       setState(() {
  //         if (isEdit) {
  //           final idx = _data.indexWhere((x) => x.orgCode == _sel!.orgCode);
  //           if (idx != -1) _data[idx] = m;
  //         } else {
  //           _data.add(m);
  //         }
  //       });
  //       _go(_V.list);
  //       _toast(isEdit ? 'Mapping updated!' : 'Mapping created!');
  //     },
  //     onCancel: () => _go(_V.list),
  //     fBtn: _fBtn, card: _card, page_: _page_,
  //   );
  // }
  Widget _formV(bool isEdit) {
    final ex = isEdit ? _sel : null;
    String? sOrg = ex != null ? _orgFull(ex.orgCode) : null;

    // For new mapping, exclude orgs that already have a mapping
    final availableOrgs = isEdit
        ? _orgs
        : _orgs.where((o) => !_data.any((m) => m.orgCode == _code(o))).toList();

    return _FView(
      isEdit: isEdit,
      initOrg: sOrg,
      initStatus: ex?.status,
      initProds: ex != null ? List.from(ex.prodCodes) : [],
      orgs: availableOrgs,
      prods: _prods,
      statuses: _statuses,
      prodNameToCode: _productNameToCode,
      mappings: _data,
      onSave: (m) async {
        await _loadMeta(); // Reload to get fresh audit dates
        _go(_V.list);
        _toast(isEdit ? 'Mapping updated!' : 'Mapping created!');
      },
      onCancel: () => _go(_V.list),
      fBtn: _fBtn,
      card: _card,
      page_: _page_,
      pgmId: _pgmId,
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  Widget _del() {
    final r = _sel!;
    final orgFull = _orgFull(r.orgCode);
    return StatefulBuilder(
      builder: (_, ls) => _page_(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Delete Mapping',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _kText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  _fBtn(
                    'Back',
                    Icons.arrow_back_rounded,
                    _kP,
                    Colors.white,
                    _kP,
                    onTap: () => _go(_V.list),
                  ),
                ],
              ),
            ),

            _card(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: _kRL,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: _kR,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete Confirmation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kR,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Text(
                          'Are you sure you want to delete this mapping? This action cannot be undone.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: _kMuted),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _kBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'RECORD TO BE DELETED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _dr('Organization:', orgFull, red: true),
                              const SizedBox(height: 6),
                              _dr('Products:', r.prodCodes.join(', ')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                ls(() => setState(() => _delOk = !_delOk)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                color: _kRL,
                                border: Border.all(color: _kRB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: _delOk ? _kR : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: _kR,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: _delOk
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'I understand this will permanently delete this mapping.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _kR,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: _kBorder)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _fBtn(
                          'Cancel',
                          Icons.close_rounded,
                          Colors.white,
                          _kP,
                          _kP,
                          onTap: () => _go(_V.list),
                        ),
                        const SizedBox(width: 10),
                        _fBtn(
                          'Confirm Delete',
                          Icons.delete_outline_rounded,
                          _delOk ? _kR : Colors.white,
                          _delOk ? Colors.white : const Color(0xFFCBD5E1),
                          _delOk ? _kR : _kBorder,
                          onTap: _delOk
                              ? () async {
                                  try {
                                    final orgCode = int.tryParse(r.orgCode);
                                    if (orgCode != null) {
                                      await ProductMappingService().deleteMapping(orgCode);
                                      OperationalLogService().logAction(programId: 'Product Mapping', action: 'D');
                                    }
                                    setState(
                                      () => _data.removeWhere(
                                        (x) => x.orgCode == r.orgCode,
                                      ),
                                    );
                                    _go(_V.list);
                                    _toast('Mapping deleted!');
                                  } catch (e) {
                                    _ProdToast.show(
                                      context,
                                      'Failed to delete mapping: $e',
                                      isError: true,
                                    );
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dr(String k, String v, {bool red = false}) => Row(
    children: [
      SizedBox(
        width: 120,
        child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted)),
      ),
      Expanded(
        child: Text(
          v,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: red ? _kR : _kText,
          ),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Form View
// ─────────────────────────────────────────────────────────────────────────────
class _FView extends StatefulWidget {
  final bool isEdit;
  final String? initOrg, initStatus;
  final List<String> initProds, orgs, prods, statuses;
  final Map<String, int> prodNameToCode;
  final List<_Mapping> mappings;
  final Function(_Mapping) onSave; // Changed from ValueChanged to allow async
  final VoidCallback onCancel;
  final Widget Function(
    String,
    IconData,
    Color,
    Color,
    Color, {
    VoidCallback? onTap,
  })
  fBtn;
  final Widget Function({required Widget child}) card;
  final Widget Function({required Widget child}) page_;
  final int? pgmId;

  const _FView({
    required this.isEdit,
    required this.initOrg,
    required this.initStatus,
    required this.initProds,
    required this.orgs,
    required this.prods,
    required this.statuses,
    required this.prodNameToCode,
    required this.mappings,
    required this.onSave,
    required this.onCancel,
    required this.fBtn,
    required this.card,
    required this.page_,
    this.pgmId,
  });
  @override
  State<_FView> createState() => _FViewState();
}

class _FViewState extends State<_FView> {
  late String? _org, _status;
  late List<String> _prods;
  bool _sub = false;

  @override
  void initState() {
    super.initState();
    _org = widget.initOrg;
    _status = widget.initStatus;
    _prods = List.from(widget.initProds);
  }

  String? get _code => _org != null ? _org!.split(' - ').first.trim() : null;

  // List<String> get _filteredProds {
  //   if (_code == null) return widget.prods;
  //   final mapping = widget.mappings.firstWhere(
  //     (m) => m.orgCode == _code,
  //     orElse: () => _Mapping(orgCode: '', prodCodes: [], status: '', enabled: false),
  //   );
  //   if (mapping.orgCode.isEmpty) return widget.prods;
  //   return widget.prods.where((prod) => mapping.prodCodes.contains(prod)).toList();
  // }
  List<String> get _filteredProds => widget.prods;

  bool get _orgE => _sub && (_org == null || _org!.isEmpty);
  bool get _statusE => _sub && (_status == null || _status!.isEmpty);
  bool get _prodE => _sub && _prods.isEmpty;

  Future<void> _save() async {
    setState(() => _sub = true);
    if (_orgE || _statusE || _prodE) {
      _ProdToast.show(
        context,
        'Please fill all required fields.',
        isError: true,
      );
      return;
    }
    final orgCodeString = _code;
    if (orgCodeString == null || orgCodeString.isEmpty) {
      _ProdToast.show(context, 'Invalid organization selected.', isError: true);
      return;
    }
    final orgCode = int.tryParse(orgCodeString);
    if (orgCode == null) {
      _ProdToast.show(context, 'Organization code is invalid.', isError: true);
      return;
    }
    final selectedCodes = _prods
        .map((name) => widget.prodNameToCode[name])
        .whereType<int>()
        .toList();
    if (selectedCodes.isEmpty) {
      _ProdToast.show(
        context,
        'Please select at least one product.',
        isError: true,
      );
      return;
    }
    final payload = {
      'orgCode': orgCode,
      'prodCodes': selectedCodes,
      'status': _status == 'A - Active',
      'pgmId': widget.pgmId,
    };
    try {
      if (widget.isEdit) {
        await ProductMappingService().updateMapping(payload);
        OperationalLogService().logAction(programId: 'Product Mapping', action: 'U');
      } else {
        final List<ProductMapDto> payloadList = selectedCodes.map((code) => ProductMapDto(
          orgcode: orgCode,
          prodcode: code,
          status: _status == 'A - Active',
        )).toList();
        await ProductMappingService().saveMapping(payloadList, widget.pgmId);
        OperationalLogService().logAction(programId: 'Product Mapping', action: 'I');
      }
      final dummy = _Mapping(
        orgCode: orgCodeString,
        prodCodes: List.from(_prods),
        status: _status!,
        enabled: _status == 'A - Active',
      );
      await widget.onSave(dummy);
    } catch (e) {
      _ProdToast.show(context, 'Failed to save mapping: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.page_(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.isEdit ? 'Edit Mapping' : 'Add New Mapping',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              widget.fBtn(
                'Back',
                Icons.arrow_back_rounded,
                _kP,
                Colors.white,
                _kP,
                onTap: widget.onCancel,
              ),
            ],
          ),
        ),

        widget.card(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEdit
                                ? 'Edit Mapping Details'
                                : 'Mapping Details',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _kText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isEdit
                                ? 'Organization field is locked'
                                : 'Fill all required fields',
                            style: const TextStyle(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isEdit ? _kOBG : _kPL,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.isEdit ? _kOB : _kPB),
                      ),
                      child: Text(
                        widget.isEdit ? 'EDIT MODE' : 'NEW RECORD',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.isEdit ? _kOT : _kP,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.isEdit)
                Container(
                  margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _kWarnBG,
                    border: Border.all(color: _kWarnB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock_outline, size: 15, color: _kWarnT),
                      SizedBox(width: 8),
                      Text(
                        'Organization field cannot be modified',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _kWarnT,
                        ),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _OrgDropdownField(
                            label: 'Organization',
                            value: _org,
                            items: widget.orgs,
                            onChanged: (v) => setState(() {
                              _org = v;
                              _prods = [];
                            }),
                            icon: Icons.business_rounded,
                            hasError: _orgE,
                            readOnly: widget.isEdit,
                          ),
                        ),

                        const SizedBox(width: 14),
                        Expanded(
                          child: _StatusToggle(
                            isActive: _status == 'A - Active',
                            hasError: _statusE,
                            onChanged: (v) => setState(
                              () => _status = v ? 'A - Active' : 'I - Inactive',
                            ),
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _ProdGrid(
                      all: _filteredProds,
                      selected: _prods,
                      onToggle: (p) => setState(() {
                        _prods.contains(p) ? _prods.remove(p) : _prods.add(p);
                      }),
                      hasError: _prodE,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    widget.fBtn(
                      'Cancel',
                      Icons.close_rounded,
                      Colors.white,
                      _kP,
                      _kP,
                      onTap: widget.onCancel,
                    ),
                    const SizedBox(width: 10),
                    widget.fBtn(
                      widget.isEdit ? 'Update' : 'Create',
                      Icons.check_rounded,
                      _kP,
                      Colors.white,
                      _kP,
                      onTap: _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
