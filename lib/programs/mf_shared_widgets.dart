import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- MF Colors (from existing shared_widgets and am_masters) ---
const Color _kP      = Color(0xFF1E3050); // Primary blue
const Color _kPL     = Color(0xFFE3F2FD); // Primary light
const Color _kMuted  = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSurface= Color(0xFFF8FAFC);
const Color _kRowAlt = Color(0xFFF0F5FD);
const Color _kText   = Color(0xFF1E293B);
const Color _kR      = Color(0xFFDC2626);
const Color _kRL     = Color(0xFFFEF2F2);
const Color _kG      = Color(0xFF16A34A);
const Color _kGL     = Color(0xFFDCFCE7);

// --- View Enum ---
enum MFView { list, create, view, edit, delete }

// --- Toast ---
class MFToast {
  static OverlayEntry? _current;
  static void show(BuildContext context, String message, {bool isError = false}) {
    _current?.remove(); _current = null;
    final bg = isError ? _kRL : _kGL;
    final fg = isError ? _kR : _kG;
    final border = isError ? _kR.withOpacity(0.4) : _kG.withOpacity(0.4);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    final entry = OverlayEntry(
      builder: (_) => _MFToastWidget(
        message: message, bg: bg, fg: fg, border: border, icon: icon,
        onDismiss: () { _current?.remove(); _current = null; },
      ),
    );
    _current = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      if (_current == entry) _current = null;
    });
  }
}

class _MFToastWidget extends StatefulWidget {
  final String message; final Color bg, fg, border; final IconData icon; final VoidCallback onDismiss;
  const _MFToastWidget({required this.message, required this.bg, required this.fg,
    required this.border, required this.icon, required this.onDismiss});
  @override State<_MFToastWidget> createState() => _MFToastWidgetState();
}
class _MFToastWidgetState extends State<_MFToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl; late Animation<double> _slide, _fade;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<double>(begin: -80, end: 0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Positioned(
    top: 24, left: 0, right: 0,
    child: AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Transform.translate(offset: Offset(0, _slide.value), child: Opacity(opacity: _fade.value, child: child)),
      child: Center(child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: widget.bg, border: Border.all(color: widget.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(widget.icon, size: 18, color: widget.fg), const SizedBox(width: 10),
          Flexible(child: Text(widget.message, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: widget.fg, decoration: TextDecoration.none, decorationColor: Colors.transparent))),
          const SizedBox(width: 10),
          GestureDetector(onTap: widget.onDismiss, child: Icon(Icons.close_rounded, size: 16, color: widget.fg)),
        ]),
      )),
    ),
  );
}

// --- Rejecting Formatter ---
class MFRejectingFormatter extends TextInputFormatter {
  final RegExp pattern;
  final VoidCallback onReject;
  MFRejectingFormatter(this.pattern, this.onReject);
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    if (pattern.hasMatch(newValue.text)) return newValue;
    onReject();
    return oldValue;
  }
}

// --- Floating Label Field ---
class MFFloatingLabelField extends StatefulWidget {
  final String label; final TextEditingController ctrl; final IconData icon;
  final String hint; final bool readOnly, required, isDatePicker, showLock;
  final String? errorText, subtext; final DateTime? maxDate; final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextInputType? keyboardType;
  final VoidCallback? onDatePickerTap;
  const MFFloatingLabelField({
    super.key, required this.label, required this.ctrl, required this.icon,
    this.hint = '', this.readOnly = false, this.required = false, this.errorText,
    this.isDatePicker = false, this.maxDate, this.focusNode,
    this.inputFormatters, this.maxLength, this.showLock = false,
    this.keyboardType, this.subtext, this.onDatePickerTap,
  });
  @override State<MFFloatingLabelField> createState() => _MFFloatingLabelFieldState();
}
class _MFFloatingLabelFieldState extends State<MFFloatingLabelField> with SingleTickerProviderStateMixin {
  late final FocusNode _focus; bool _focused = false;
  late AnimationController _anim; late Animation<double> _labelTop, _labelSize;

  bool get _hasValue => widget.ctrl.text.isNotEmpty;
  bool get _floated  => _focused || _hasValue || widget.errorText != null;

  @override void initState() {
    super.initState();
    _focus = widget.focusNode ?? FocusNode();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1.0 : 0.0);
    _labelTop  = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _labelSize = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _focus.addListener(() { setState(() => _focused = _focus.hasFocus); _floated ? _anim.forward() : _anim.reverse(); });
    widget.ctrl.addListener(() { if (_floated && _anim.value < 1) _anim.forward(); if (!_floated && _anim.value > 0) _anim.reverse(); setState(() {}); });
  }
  void _requestFocus() {
    if (!widget.readOnly && !widget.isDatePicker) {
      _focus.requestFocus();
    } else if (widget.isDatePicker) {
      if (widget.onDatePickerTap != null) widget.onDatePickerTap!();
    }
  }

  @override void dispose() { if (widget.focusNode == null) _focus.dispose(); _anim.dispose(); super.dispose(); }
  @override void didUpdateWidget(MFFloatingLabelField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_floated && _anim.value < 1) _anim.forward();
    if (!_floated && _anim.value > 0) _anim.reverse();
  }

  @override Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.required ? (_) => widget.ctrl.text.trim().isEmpty ? 'Required field' : null : null,
      builder: (fieldState) {
        final hasError = widget.errorText != null || fieldState.hasError;
        final errorMsg = widget.errorText ?? fieldState.errorText;
        final Color borderColor = hasError ? _kR : _kP;
        Widget textField = TextField(
          controller: widget.ctrl, focusNode: _focus,
          onChanged: (v) => fieldState.didChange(v),
          readOnly: widget.isDatePicker || widget.readOnly,
          showCursor: widget.isDatePicker ? false : null,
          enableInteractiveSelection: !widget.isDatePicker,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kText),
          decoration: InputDecoration(
            hintText: _floated ? widget.hint : '',
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400),
            border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(36, 14, 12, 14), isDense: true,
            suffixIcon: (widget.showLock && widget.readOnly) ? Icon(Icons.lock_outline_rounded, size: 16, color: _kMuted.withOpacity(0.5)) : null,
          ),
        );
        Widget field = Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.readOnly ? _kSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.5),
            child: widget.isDatePicker && !widget.readOnly ? AbsorbPointer(child: textField) : textField,
          ),
        );
        if (widget.isDatePicker && !widget.readOnly) {
          field = MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(onTap: widget.onDatePickerTap, behavior: HitTestBehavior.opaque, child: field),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            field,
            Positioned(left: 10, top: 0, bottom: 0, child: Align(alignment: Alignment.centerLeft,
              child: Icon(widget.isDatePicker && _floated ? Icons.calendar_month_rounded : widget.icon, size: 14, color: hasError ? _kR : _kP))),
            AnimatedBuilder(
              animation: _anim,
              builder: (_, _2) => Positioned(top: _labelTop.value, left: 28,
                child: GestureDetector(
                  onTap: _requestFocus,
                  child: Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        text: widget.label,
                        children: [
                          if (widget.required)
                            const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      style: TextStyle(fontSize: _labelSize.value, fontWeight: FontWeight.w600,
                        color: hasError ? _kR : _kP, letterSpacing: 0.2, decoration: TextDecoration.none),
                    )),
                )),
            ),
          ]),
          if (widget.subtext != null && widget.subtext!.isNotEmpty)
            Padding(padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(widget.subtext!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kP, height: 1.2))),
          if (hasError && errorMsg != null)
            Padding(padding: const EdgeInsets.only(top: 5, left: 2),
              child: Text(errorMsg, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2))),
        ]);
      },
    );
  }
}

// --- Dropdown Field ---
class MFApiDropdownField extends StatefulWidget {
  final String label;
  final IconData icon;
  final Map<String, dynamic>? selectedItem;
  final List<Map<String, dynamic>> items;
  final List<String> displayKeys;
  final ValueChanged<Map<String, dynamic>?> onChanged;
  final bool required;
  final String? errorText;
  final bool isLoading;
  final bool enabled;
  final String disabledHint;

  const MFApiDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.items,
    required this.displayKeys,
    required this.onChanged,
    this.selectedItem,
    this.required = false,
    this.errorText,
    this.isLoading = false,
    this.enabled = true,
    this.disabledHint = '',
  });

  @override
  State<MFApiDropdownField> createState() => _MFApiDropdownFieldState();
}

class _MFApiDropdownFieldState extends State<MFApiDropdownField>
    with SingleTickerProviderStateMixin {
  
  OverlayEntry? _ov;
  bool _ovInserted = false; // tracks whether _ov is currently in the overlay
  final TextEditingController _sc = TextEditingController();
  late AnimationController _ac;
  late Animation<double> _top, _sz;
  bool _isOpen = false;

  String _display(Map<String, dynamic> m) {
    for (final k in widget.displayKeys) {
      final v = m[k];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    }
    return '';
  }

  bool get _floated => widget.selectedItem != null || _isOpen || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz  = Tween<double>(begin: 13, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(MFApiDropdownField o) {
    super.didUpdateWidget(o);
    _floated ? _ac.forward() : _ac.reverse();
  }

  @override
  void dispose() { _rmSafe(); _sc.dispose(); _ac.dispose(); super.dispose(); }

  // Safe removal: only remove if we know it was inserted
  void _rmSafe() {
    if (_ov != null && _ovInserted) {
      try { _ov!.remove(); } catch (_) {}
    }
    _ov = null;
    _ovInserted = false;
  }

  void _rm() {
    _rmSafe();
    if (mounted) setState(() => _isOpen = false);
    if (mounted) _floated ? _ac.forward() : _ac.reverse();
  }

  void _open() {
    if (!widget.enabled || widget.isLoading) return;
    _rm(); _sc.clear();
    if (!mounted) return;
    setState(() => _isOpen = true); _ac.forward();
    final rb = context.findRenderObject() as RenderBox?;
    if (rb == null) return;
    final overlayState = Overlay.of(context);
    final ov = overlayState.context.findRenderObject() as RenderBox;
    final pos = rb.localToGlobal(Offset.zero, ancestor: ov);
    final sz = rb.size;

    _ov = OverlayEntry(builder: (ctx) => GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _rm,
      child: Material(color: Colors.transparent, child: Stack(children: [
        Positioned(
          left: pos.dx, bottom: ov.size.height - pos.dy + 6, width: sz.width,
          child: StatefulBuilder(builder: (c2, ss) {
            final q = _sc.text.toLowerCase();
            final filtered = widget.items.where((m) {
              final d = _display(m).toLowerCase();
              return q.isEmpty || d.contains(q);
            }).toList();

            return Material(
              elevation: 12,
              shadowColor: Colors.black.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _kBorder)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: const BoxDecoration(
                      color: _kPL,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                    ),
                    child: Row(children: [
                      Icon(widget.icon, size: 15, color: _kP),
                      const SizedBox(width: 6),
                      Text('Select ${widget.label}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kP)),
                      const Spacer(),
                      Text('${filtered.length} found', style: const TextStyle(fontSize: 10, color: _kMuted)),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _sc, autofocus: true, onChanged: (_) => ss(() {}),
                      style: const TextStyle(fontSize: 13, color: _kText),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.label.toLowerCase()}...',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: _kP),
                        suffixIcon: _sc.text.isNotEmpty
                          ? GestureDetector(onTap: () { _sc.clear(); ss(() {}); }, child: const Icon(Icons.close_rounded, size: 15, color: _kMuted))
                          : null,
                        filled: true, fillColor: _kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kP, width: 1.5)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 9), isDense: true,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: _kBorder),
                  Flexible(child: filtered.isEmpty
                    ? const Center(child: Padding(padding: EdgeInsets.all(20),
                        child: Text('No results found', style: TextStyle(fontSize: 13, color: _kMuted))))
                    : ListView.builder(
                        padding: EdgeInsets.zero, shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final item = filtered[idx];
                          final isSel = widget.selectedItem != null && _display(widget.selectedItem!) == _display(item);
                          final rowBg = isSel ? _kPL : (idx % 2 == 0 ? Colors.white : _kRowAlt);
                          return InkWell(
                            onTap: () { widget.onChanged(item); _rm(); },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              color: rowBg,
                              child: Row(children: [
                                Expanded(child: Text(_display(item),
                                  style: TextStyle(fontSize: 13, color: _kText, fontWeight: isSel ? FontWeight.w700 : FontWeight.w500))),
                                if (isSel) const Icon(Icons.check_circle_rounded, size: 16, color: _kP),
                              ]),
                            ),
                          );
                        },
                      ),
                  ),
                ]),
              ),
            );
          }),
        ),
      ])),
    ));
    if (mounted) {
      overlayState.insert(_ov!);
      _ovInserted = true;
    } else {
      _ov = null;
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final sel = widget.selectedItem;
    final err = widget.errorText != null;
    final bc = err ? _kR : _kP;
    final disabled = !widget.enabled || widget.isLoading;
    final placeholderText = sel != null
        ? _display(sel)
        : (_floated ? (disabled ? widget.disabledHint : 'Select ${widget.label.toLowerCase()}') : '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Stack(clipBehavior: Clip.none, children: [
        GestureDetector(
          onTap: disabled ? null : _open,
          child: MouseRegion(
            cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bc, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10.5),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 12, 0),
                  child: Row(children: [
                    if (widget.isLoading) ...[
                      const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: _kP)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(child: Text(
                      placeholderText,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                        color: sel != null ? _kText : _kMuted),
                      overflow: TextOverflow.ellipsis,
                    )),
                    Icon(Icons.unfold_more_rounded, size: 16, color: disabled ? _kBorder : bc),
                  ]),
                ),
              ),
            ),
          ),
        ),
        Positioned(left: 10, top: 0, bottom: 0,
          child: Align(alignment: Alignment.centerLeft,
            child: Icon(widget.icon, size: 14, color: err ? _kR : _kP))),
        AnimatedBuilder(
          animation: _ac,
          builder: (_, __) => Positioned(top: _top.value, left: 28,
            child: GestureDetector(
              onTap: disabled ? null : _open,
              child: Container(
                color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text.rich(
                  TextSpan(
                    text: widget.label,
                    children: [
                      if (widget.required)
                        const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  style: TextStyle(fontSize: _sz.value, fontWeight: FontWeight.w600,
                    color: err ? _kR : _kP, letterSpacing: 0.2, decoration: TextDecoration.none),
                ),
              ),
            ),
          ),
        ),
      ]),
      if (widget.errorText != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Text(widget.errorText!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _kR, height: 1.2)),
        ),
    ]);
  }
}

// --- Layout Structure Widgets ---

class MFActiveInactiveSummary extends StatelessWidget {
  final int activeCount;
  final int inactiveCount;

  const MFActiveInactiveSummary({
    super.key,
    required this.activeCount,
    required this.inactiveCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildStatCard(activeCount.toString(), 'Active', const Color(0xFF16A34A), const Color(0xFFDCFCE7), Icons.check_circle_outline),
        const SizedBox(width: 16),
        _buildStatCard(inactiveCount.toString(), 'Inactive', const Color(0xFFDC2626), const Color(0xFFFEF2F2), Icons.cancel_outlined),
      ],
    );
  }

  Widget _buildStatCard(String num, String lbl, Color color, Color bg, IconData icon) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(num, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, height: 1.1)),
              Text(lbl, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class MFPaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const MFPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Page $currentPage of $totalPages',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        _buildPageBtn('Prev', Icons.chevron_left_rounded, onPrev),
        const SizedBox(width: 8),
        _buildPageBtn('Next', Icons.chevron_right_rounded, onNext, isNext: true),
      ],
    );
  }

  Widget _buildPageBtn(String label, IconData icon, VoidCallback? onTap, {bool isNext = false}) {
    final bool disabled = onTap == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF1F5F9) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: disabled ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              if (!isNext) Icon(icon, size: 16, color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
              if (!isNext) const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF1E293B))),
              if (isNext) const SizedBox(width: 4),
              if (isNext) Icon(icon, size: 16, color: disabled ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
            ],
          ),
        ),
      ),
    );
  }
}
void showSuccessDialog(BuildContext context, String message, {VoidCallback? onConfirm}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 24),
            const Text('Success', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3050),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (onConfirm != null) onConfirm();
                },
                child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
