import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/access_privileges.dart';
import 'package:file_picker/file_picker.dart';
import 'head_menu_tab.dart';
import 'menu_tab.dart';
import 'sub_menu_tab.dart';
import 'menu_program_tab.dart';

const kP = Color(0xFF3D6EBE);
const kPL = Color(0xFFEEF3FB);
const kPB = Color(0xFFC5D3E8);
const kR = Color(0xFFDC2626);
const kRL = Color(0xFFFEF2F2);
const kG = Color(0xFF16A34A);
const kGL = Color(0xFFDCFCE7);
const kText = Color(0xFF1E293B);
const kMuted = Color(0xFF64748B);
const kBorder = Color(0xFFE2E8F0);
const kSurface = Color(0xFFF8FAFC);
const kO = Color(0xFFF97316);

class MNToast {
  static OverlayEntry? _c;
  static void show(BuildContext context, String message, {bool isError = false}) {
    _c?.remove();
    _c = null;
    final bg = isError ? kRL : kGL;
    final fg = isError ? kR : kG;
    final border = isError ? kR.withOpacity(0.4) : kG.withOpacity(0.4);
    final icon = isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    final entry = OverlayEntry(
      builder: (_) => _ToastW(
        message: message, bg: bg, fg: fg, border: border, icon: icon,
        onDismiss: () { _c?.remove(); _c = null; },
      ),
    );
    _c = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      entry.remove();
      if (_c == entry) _c = null;
    });
  }
}

class ImageUploadWidget extends StatefulWidget {
  final Uint8List? logoBytes;
  final String? logoName;
  final String? logoError;
  final String label;
  final bool readOnly;
  final void Function(Uint8List? bytes, String? name, String? error) onPicked;
  final VoidCallback onRemove;

  const ImageUploadWidget({
    super.key,
    required this.logoBytes,
    required this.logoName,
    required this.logoError,
    required this.label,
    required this.onPicked,
    required this.onRemove,
    this.readOnly = false,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  bool _hovering = false;
  static const _kMaxLogoBytes = 5 * 1024 * 1024; // 5 MB
  static const _kAllowedExts = ['png', 'jpg', 'jpeg'];

  Future<void> _pick() async {
    if (widget.readOnly) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    final name = file.name;
    if (bytes == null) return;

    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    if (!_kAllowedExts.contains(ext)) {
      widget.onPicked(
        null,
        null,
        'Invalid format. Only PNG and JPG are allowed.',
      );
      return;
    }
    if (bytes.lengthInBytes > _kMaxLogoBytes) {
      widget.onPicked(
        null,
        null,
        'File too large. Maximum allowed size is 5 MB.',
      );
      return;
    }
    widget.onPicked(bytes, name, null);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.logoBytes != null;
    final hasError = widget.logoError != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kPL,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.image_rounded, size: 18, color: kP),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label.replaceAll(' *', ''),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kText),
                ),
                const Text(
                  'PNG, JPG only — max 5 MB',
                  style: TextStyle(fontSize: 11, color: kMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasImage) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(widget.logoBytes!, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              if (!widget.readOnly)
                Row(
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _pick,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kBorder),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 14, color: kP),
                              SizedBox(width: 6),
                              Text('Edit', style: TextStyle(fontSize: 12, color: kP, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: widget.onRemove,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: kR,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kR),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Remove', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              if (widget.logoName != null) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Text(widget.logoName!, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: kMuted)),
                ),
              ],
            ],
          ),
        ] else ...[
          MouseRegion(
            cursor: widget.readOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovering = true),
            onExit: (_) => setState(() => _hovering = false),
            child: GestureDetector(
              onTap: _pick,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: hasError ? kRL : (_hovering ? kPL : kSurface),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: _DottedBorderBox(
                  isHovered: _hovering,
                  hasError: hasError,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: hasError ? kR.withOpacity(0.10) : (_hovering ? kP.withOpacity(0.12) : kPL),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          hasError ? Icons.error_outline_rounded : Icons.cloud_upload_rounded,
                          size: 24,
                          color: hasError ? kR : (_hovering ? kP : const Color(0xFF93A8C9)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hasError ? 'Try again' : 'Click to upload',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: hasError ? kR : (_hovering ? kP : kMuted)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 13, color: kR),
                  const SizedBox(width: 5),
                  Text(widget.logoError!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kR)),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _DottedBorderBox extends StatelessWidget {
  final Widget child;
  final bool isHovered;
  final bool hasError;
  const _DottedBorderBox({required this.child, required this.isHovered, this.hasError = false});
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBorderPainter(color: hasError ? kR : (isHovered ? kP : kBorder)),
    child: SizedBox(width: 160, height: 160, child: Center(child: child)),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    const dashWidth = 6.0, dashSpace = 4.0, radius = 16.0;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(radius)));
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dashWidth), paint);
        d += dashWidth + dashSpace;
      }
    }
  }
  @override bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}

class _ToastW extends StatefulWidget {
  final String message; final Color bg, fg, border; final IconData icon; final VoidCallback onDismiss;
  const _ToastW({required this.message, required this.bg, required this.fg, required this.border, required this.icon, required this.onDismiss});
  @override State<_ToastW> createState() => _ToastWState();
}
class _ToastWState extends State<_ToastW> with SingleTickerProviderStateMixin {
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
            color: widget.fg, decoration: TextDecoration.none))),
        ]),
      )),
    ),
  );
}

class FloatingLabelField extends StatefulWidget {
  final String label; final TextEditingController controller; final IconData icon;
  final bool readOnly, isRequired, isNumber, autofocus; final String? errorText; final String? hintText;
  final FocusNode? focusNode;
  const FloatingLabelField({
    super.key, required this.label, required this.controller, required this.icon,
    this.readOnly = false, this.isRequired = false, this.isNumber = false, this.autofocus = false, this.errorText, this.hintText, this.focusNode,
  });
  @override State<FloatingLabelField> createState() => _FloatingLabelFieldState();
}
class _FloatingLabelFieldState extends State<FloatingLabelField> with SingleTickerProviderStateMixin {
  late FocusNode _f; late AnimationController _c; late Animation<double> _t, _s;
  bool _internalFocus = false;
  String? _invalidNumberError;
  bool get _v => widget.controller.text.isNotEmpty;
  bool get _fl => _f.hasFocus || _v || widget.errorText != null || _invalidNumberError != null;
  @override void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _f = widget.focusNode!;
    } else {
      _f = FocusNode();
      _internalFocus = true;
    }
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _fl ? 1 : 0);
    _t = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _s = Tween<double>(begin: 12.5, end: 10.5).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _f.addListener(_h); widget.controller.addListener(_h);
  }
  void _h() { if (mounted) { _invalidNumberError = null; setState(() {}); final to = _fl ? 1.0 : 0.0; if (_c.value != to) _c.animateTo(to); } }
  @override void dispose() { _f.removeListener(_h); if (_internalFocus) _f.dispose(); widget.controller.removeListener(_h); _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final currentError = widget.errorText ?? _invalidNumberError;
    final hc = currentError != null ? kR : kP;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: widget.readOnly ? kSurface : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: currentError != null ? kR : kP, width: 1.5)),
          child: Row(children: [
            Icon(widget.icon, size: 14, color: currentError != null ? kR : kP), const SizedBox(width: 10),
            Expanded(child: TextField(
              controller: widget.controller, focusNode: _f, readOnly: widget.readOnly, autofocus: widget.autofocus,
              keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,
              inputFormatters: widget.isNumber ? [
                TextInputFormatter.withFunction((oldValue, newValue) {
                  if (newValue.text.isEmpty) return newValue;
                  if (RegExp(r'^[0-9]*$').hasMatch(newValue.text)) return newValue;
                  if (mounted) setState(() => _invalidNumberError = 'Only numbers allowed');
                  return oldValue;
                })
              ] : null,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kText, height: 1.2),
              decoration: InputDecoration(
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                hintText: _f.hasFocus ? (widget.hintText ?? 'Enter ${widget.label}') : '',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500, fontSize: 13),
              ),
            )),
          ]),
        ),
        AnimatedBuilder(animation: _c, builder: (_, __) => Positioned(
          top: _t.value, left: 28,
          child: IgnorePointer(child: Container(
            color: _c.value > 0.1 ? (widget.readOnly ? kSurface : Colors.white) : Colors.transparent, padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text.rich(
              TextSpan(text: widget.label, children: [
                if (widget.isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ]),
              style: TextStyle(fontSize: _s.value, fontWeight: FontWeight.w700,
                color: currentError != null ? kR : kP, letterSpacing: 0.2, height: 1),
            ),
          )),
        )),
      ]),
      if (currentError != null)
        Padding(
          padding: const EdgeInsets.only(top: 5, left: 2),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 13, color: kR),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  currentError,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kR, height: 1.2),
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}

class DropdownField extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final bool isRequired, readOnly, splitCodeDesc, isLocked, showSearch;
  final String? errorText;

  const DropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon,
    this.isRequired = false,
    this.readOnly = false,
    this.splitCodeDesc = false,
    this.isLocked = false,
    this.showSearch = true,
    this.errorText,
  });

  @override
  State<DropdownField> createState() => _DropdownFieldState();
}

class _DropdownFieldState extends State<DropdownField> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  late AnimationController _ac;
  late Animation<double> _top, _sz;
  
  bool _isOpen = false;
  int _hlIndex = -1;
  String _searchQuery = '';
  bool get _floated => _isOpen || (widget.value != null && widget.value!.isNotEmpty) || widget.errorText != null;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 180), value: _floated ? 1 : 0);
    _top = Tween<double>(begin: 13, end: -8).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _sz = Tween<double>(begin: 12.5, end: 10.5).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant DropdownField old) {
    super.didUpdateWidget(old);
    if (_floated && _ac.value != 1) _ac.animateTo(1);
    else if (!_floated && _ac.value != 0) _ac.animateTo(0);
  }
  
  @override void dispose() { _ac.dispose(); _rm(notify: false); super.dispose(); }
  void _rm({bool notify = true, bool picked = false}) { 
    _ov?.remove(); _ov = null; 
    if (notify && mounted) {
      setState(() => _isOpen = false);
      final hasValue = widget.value != null && widget.value!.isNotEmpty;
      if (!picked && !hasValue && widget.errorText == null && _ac.value != 0) _ac.animateTo(0);
    }
  }

  void _open() {
    if (widget.readOnly) return;
    if (_ov != null) { _rm(); return; }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    
    setState(() { _isOpen = true; _hlIndex = widget.items.indexOf(widget.value ?? ''); _searchQuery = ''; });
    if (_floated && _ac.value != 1) _ac.animateTo(1);
    
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final maxH = MediaQuery.of(context).size.height - pos.dy - size.height - 20;

    _ov = OverlayEntry(builder: (ctx) => Stack(children: [
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _rm)),
      Positioned(
        left: pos.dx, top: pos.dy + size.height + 6, width: size.width,
        child: StatefulBuilder(builder: (context, ss) {
          final filteredItems = _searchQuery.isEmpty 
              ? widget.items 
              : widget.items.where((i) => i.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Material(
            elevation: 12, borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxH > 100 ? maxH : 300),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSearch)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(fontSize: 13, color: kMuted),
                          prefixIcon: const Icon(Icons.search, size: 16, color: kMuted),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kP)),
                        ),
                        onChanged: (v) {
                          ss(() {
                            _searchQuery = v;
                            _hlIndex = -1;
                          });
                        },
                      ),
                    ),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                      itemBuilder: (_, i) {
                        final item = filteredItems[i];
                        final isSel = item == widget.value;
                        final isHl = i == _hlIndex;
                        return InkWell(
                          onTap: () { widget.onChanged(item); _rm(picked: true); },
                          onHover: (h) { if (h) ss(() => _hlIndex = i); },
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            color: isSel ? kPL : (isHl ? kPL.withOpacity(0.5) : Colors.transparent),
                            child: Row(children: [
                              Expanded(child: Text(item, style: TextStyle(fontSize: 13, color: isSel || isHl ? kP : kText, fontWeight: isSel || isHl ? FontWeight.w700 : FontWeight.w500))),
                              if (isSel) const Icon(Icons.check_rounded, size: 14, color: kP),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ]));
    Overlay.of(context).insert(_ov!);
  }

  @override
  Widget build(BuildContext context) {
    final hc = widget.errorText != null ? kR : kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.isLocked ? null : _open,
              child: Container(
                key: _key,
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: widget.readOnly ? kSurface : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.errorText != null ? kR : kP, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 14, color: hc),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _floated ? (widget.value?.isNotEmpty == true ? (widget.splitCodeDesc && widget.value!.contains(' - ') ? widget.value!.split(' - ').first : widget.value!) : 'Please select') : '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: (widget.value?.isNotEmpty == true) ? kText : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(widget.isLocked ? Icons.lock : Icons.keyboard_arrow_down_rounded, size: 20, color: hc),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _ac,
              builder: (_, __) => Positioned(
                top: _top.value,
                left: 28,
                child: IgnorePointer(
                  child: Container(
                    color: _ac.value > 0.1 ? (widget.readOnly ? kSurface : Colors.white) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text.rich(
                      TextSpan(
                        text: widget.label,
                        children: [
                          if (widget.isRequired)
                            const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: _sz.value,
                        fontWeight: FontWeight.w700,
                        color: hc,
                        letterSpacing: 0.2,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: kR),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: kR,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (widget.splitCodeDesc && widget.value != null && widget.value!.contains(' - '))
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              widget.value!.split(' - ').last,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kP,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class ToggleField extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isRequired, readOnly;
  final String? errorText;
  final ValueChanged<bool> onChanged;
  final String activeText;
  final String inactiveText;
  final Color? activeColor;
  const ToggleField({
    super.key,
    required this.label,
    required this.isActive,
    required this.onChanged,
    this.isRequired = false,
    this.readOnly = false,
    this.errorText,
    this.activeText = 'Active',
    this.inactiveText = 'Inactive',
    this.activeColor,
  });
  @override
  State<ToggleField> createState() => _ToggleFieldState();
}

class _ToggleFieldState extends State<ToggleField> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final hc = widget.errorText != null ? kR : kP;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: () {
                  if (widget.readOnly) return;
                  widget.onChanged(!widget.isActive);
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.readOnly ? kSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: hc, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.signal_cellular_alt_rounded, size: 16, color: hc),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isActive ? widget.activeText : widget.inactiveText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: kText,
                          ),
                        ),
                      ),
                      // iOS style toggle switch
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 20,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: widget.isActive ? (widget.activeColor ?? const Color(0xFF10B981)) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: widget.isActive ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -6,
              left: 28,
              child: IgnorePointer(
                child: Container(
                  color: widget.readOnly ? kSurface : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text.rich(
                    TextSpan(
                      text: widget.label,
                      children: [
                        if (widget.isRequired)
                          const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: hc,
                      letterSpacing: 0.2,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kR,
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }
}

class DeleteConfirmationWidget extends StatefulWidget {
  final String title;
  final Map<String, String> recordDetails;
  final List<String>? impactDetails;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const DeleteConfirmationWidget({
    super.key,
    required this.title,
    required this.recordDetails,
    this.impactDetails,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<DeleteConfirmationWidget> createState() => _DeleteConfirmationWidgetState();
}

class _DeleteConfirmationWidgetState extends State<DeleteConfirmationWidget> {
  bool isConfirmed = false;

  @override
  Widget build(BuildContext context) {
    Widget delRow(String label, String value, {bool isRed = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isRed ? kR : kText))),
        ],
      ),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.3),
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: kRL,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 20, color: kR),
                      SizedBox(width: 8),
                      Text('Delete Confirmation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kR)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Text(
                        'Are you sure you want to delete this record? This action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: kMuted),
                      ),
                      const SizedBox(height: 16),
                      if (widget.impactDetails != null && widget.impactDetails!.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            border: Border.all(color: const Color(0xFFFFEDD5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'CONSEQUENT DELETIONS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...widget.impactDetails!.map((detail) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('• ', style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Expanded(
                                      child: Text(
                                        detail,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF7C2D12), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
                          ),
                        ),
                      ],
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: kBorder),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RECORD TO BE DELETED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 10),
                            ...widget.recordDetails.entries.map((e) => delRow(e.key, e.value, isRed: e.key.toLowerCase().contains('code'))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => isConfirmed = !isConfirmed),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isConfirmed ? kRL : Colors.white,
                                  border: Border.all(color: isConfirmed ? kR : kBorder),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                  child: Row(
                                    children: [
                                      Icon(isConfirmed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, color: isConfirmed ? kR : kMuted, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'I understand this will permanently delete this record and all related data.',
                                          style: TextStyle(fontSize: 12, color: isConfirmed ? kR : kText),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ActionButton('Cancel', bg: Colors.white, fg: kP, border: kBorder, icon: Icons.close_rounded, onTap: widget.onCancel),
                                  const SizedBox(width: 12),
                                  Opacity(
                                    opacity: isConfirmed ? 1.0 : 0.5,
                                    child: ActionButton(
                                      'Confirm Delete',
                                      bg: kR, fg: Colors.white, border: kR, icon: Icons.delete_outline_rounded,
                                      onTap: isConfirmed ? widget.onConfirm : () {},
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget ActionButton(String label, {Color bg = Colors.white, Color fg = kMuted, Color border = kBorder, IconData? icon, VoidCallback? onTap}) => MouseRegion(
  cursor: onTap == null ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
  child: GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border, width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    ),
  ),
);

class SearchBox extends StatefulWidget {
  final double width;
  final ValueChanged<String> onChanged;
  final String hintText;
  final TextEditingController? controller;
  const SearchBox({super.key, required this.width, required this.onChanged, this.hintText = 'Search...', this.controller});
  @override
  State<SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends State<SearchBox> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;
  @override
  void initState() { super.initState(); _focus.addListener(() => setState(() => _focused = _focus.hasFocus)); }
  @override
  void dispose() { _focus.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    width: widget.width, height: 36,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _focused ? kP : kBorder, width: _focused ? 2.0 : 1.5),
      borderRadius: BorderRadius.circular(10),
      boxShadow: _focused ? [BoxShadow(color: kP.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : [],
    ),
    child: TextField(
      controller: widget.controller,
      focusNode: _focus,
      onChanged: widget.onChanged,
      style: const TextStyle(fontSize: 13, color: kText),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(fontSize: 12, color: _focused ? const Color(0xFFB0BEC5) : const Color(0xFFCBD5E1)),
        prefixIcon: Icon(Icons.search_rounded, size: 16, color: _focused ? kP : const Color(0xFF94A3B8)),
        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 10), isDense: true,
      ),
    ),
  );
}

class MenuMaster extends StatefulWidget {
  final VoidCallback? onMenuModified;
  final AccessPrivileges? accessPrivileges;
  const MenuMaster({super.key, this.onMenuModified, this.accessPrivileges});
  @override
  State<MenuMaster> createState() => _MenuMasterState();
}

class _MenuMasterState extends State<MenuMaster> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _totalRecords = 0;
  int _activeRecords = 0;
  int _inactiveRecords = 0;
  bool _isFormActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _statCard(String num, String lbl, Color numC, Color bg, Color border, IconData icon, Color iconC) => Container(
    width: 180,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 18, color: iconC),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(num, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: numC, height: 1.1)),
            Text(lbl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
          ],
        ),
      ],
    ),
  );

  Widget _tabBtn(int idx, String text, IconData icon) {
    final active = _tabController.index == idx;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _tabController.animateTo(idx),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? kP : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? kP : kBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : kMuted),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : const Color(0xFF475569))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isFormActive) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 20),
                      child: Text(
                        'Menu Master Configuration',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.3),
                      ),
                    ),
                    Row(
                      children: [
                        _statCard('$_totalRecords', 'Total Records', kP, kPL, const Color(0xFFC5D3E8), Icons.grid_view_rounded, kP),
                        if (_tabController.index == 0 || _tabController.index == 3) ...[
                          const SizedBox(width: 10),
                          _statCard('$_activeRecords', 'Active', kG, kGL, const Color(0xFFBBF7D0), Icons.check_circle_outline_rounded, kG),
                          const SizedBox(width: 10),
                          _statCard('$_inactiveRecords', 'Inactive', kR, kRL, const Color(0xFFFECACA), Icons.block_rounded, kR),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _tabBtn(0, 'HEAD MENU', Icons.grid_view_rounded),
                        const SizedBox(width: 10),
                        _tabBtn(1, 'MENU', Icons.list_alt_rounded),
                        const SizedBox(width: 10),
                        _tabBtn(2, 'SUBMENU', Icons.subdirectory_arrow_right_rounded),
                        const SizedBox(width: 10),
                        _tabBtn(3, 'PROGRAM MAPPING', Icons.play_arrow_rounded),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  Column(
                    children: [
                      Offstage(
                        offstage: _tabController.index != 0,
                        child: HeadMenuTab(
                          isActive: _tabController.index == 0,
                          onMenuModified: widget.onMenuModified,
                          accessPrivileges: widget.accessPrivileges,
                          onFormChanged: (v) { if(mounted) setState(() => _isFormActive = v); },
                          onTotalChanged: (t) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => _totalRecords = t); }); },
                          onStatusChanged: (a, i) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() { _activeRecords = a; _inactiveRecords = i; }); }); },
                        ),
                      ),
                      Offstage(
                        offstage: _tabController.index != 1,
                        child: MenuTab(
                          isActive: _tabController.index == 1,
                          onMenuModified: widget.onMenuModified,
                          accessPrivileges: widget.accessPrivileges,
                          onFormChanged: (v) { if(mounted) setState(() => _isFormActive = v); },
                          onTotalChanged: (t) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => _totalRecords = t); }); },
                          onStatusChanged: (a, i) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() { _activeRecords = a; _inactiveRecords = i; }); }); },
                        ),
                      ),
                      Offstage(
                        offstage: _tabController.index != 2,
                        child: SubMenuTab(
                          isActive: _tabController.index == 2,
                          onMenuModified: widget.onMenuModified,
                          accessPrivileges: widget.accessPrivileges,
                          onFormChanged: (v) { if(mounted) setState(() => _isFormActive = v); },
                          onTotalChanged: (t) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => _totalRecords = t); }); },
                          onStatusChanged: (a, i) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() { _activeRecords = a; _inactiveRecords = i; }); }); },
                        ),
                      ),
                      Offstage(
                        offstage: _tabController.index != 3,
                        child: MenuProgramTab(
                          isActive: _tabController.index == 3,
                          onMenuModified: widget.onMenuModified,
                          accessPrivileges: widget.accessPrivileges,
                          onFormChanged: (v) { if(mounted) setState(() => _isFormActive = v); },
                          onTotalChanged: (t) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() => _totalRecords = t); }); },
                          onStatusChanged: (a, i) { WidgetsBinding.instance.addPostFrameCallback((_) { if(mounted) setState(() { _activeRecords = a; _inactiveRecords = i; }); }); },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}

class FilterDropdownItem {
  final String id;
  final String label;

  FilterDropdownItem({required this.id, required this.label});
}

class FilterDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<FilterDropdownItem> items;
  final ValueChanged<String?> onChanged;
  final String hintText;
  final String allText;

  const FilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText = 'Search...',
    this.allText = 'All',
  });

  @override
  State<FilterDropdown> createState() => _FilterDropdownState();
}

class _FilterDropdownState extends State<FilterDropdown> {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _ov;
  bool _isOpen = false;
  int _hlIndex = -1;
  String _searchQuery = '';

  @override
  void dispose() {
    _rm(notify: false);
    super.dispose();
  }

  void _rm({bool notify = true, bool picked = false}) {
    _ov?.remove();
    _ov = null;
    if (notify && mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _open() {
    if (_ov != null) {
      _rm();
      return;
    }
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    setState(() {
      _isOpen = true;
      _searchQuery = '';
      if (widget.value == null) {
        _hlIndex = 0; // "All" selected
      } else {
        _hlIndex = widget.items.indexWhere((i) => i.id == widget.value) + 1; // +1 for "All" option
      }
    });

    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final maxH = MediaQuery.of(context).size.height - pos.dy - size.height - 20;
    
    double screenWidth = MediaQuery.of(context).size.width;
    double dropdownWidth = 320.0;
    double leftPos = pos.dx;
    if (pos.dx + dropdownWidth > screenWidth) {
      // Right-align with the button to prevent overflowing the screen
      leftPos = pos.dx + size.width - dropdownWidth;
    }

    _ov = OverlayEntry(builder: (ctx) => Stack(children: [
      Positioned.fill(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: _rm)),
      Positioned(
        left: leftPos, top: pos.dy + size.height + 6, width: dropdownWidth,
        child: StatefulBuilder(builder: (context, ss) {
          final filteredItems = _searchQuery.isEmpty
              ? widget.items
              : widget.items.where((i) =>
                  i.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  i.id.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

          return Material(
            elevation: 12, borderRadius: BorderRadius.circular(14),
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: maxH > 100 ? maxH : 300),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: kBorder)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
                        hintStyle: const TextStyle(fontSize: 13, color: kMuted),
                        prefixIcon: const Icon(Icons.search, size: 16, color: kMuted),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: kP)),
                      ),
                      onChanged: (v) {
                        ss(() {
                          _searchQuery = v;
                          _hlIndex = -1;
                        });
                      },
                    ),
                  ),
                  Flexible(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: filteredItems.length + (_searchQuery.isEmpty ? 1 : 0),
                      separatorBuilder: (_, __) => const Divider(height: 1, color: kBorder),
                      itemBuilder: (_, i) {
                        if (_searchQuery.isEmpty && i == 0) {
                          // "All" option
                          final isSel = widget.value == null;
                          final isHl = _hlIndex == 0;
                          return InkWell(
                            onTap: () { widget.onChanged(null); _rm(picked: true); },
                            onHover: (h) { if (h) ss(() => _hlIndex = 0); },
                            hoverColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              color: isSel ? kPL : (isHl ? kPL.withOpacity(0.5) : Colors.transparent),
                              child: Row(children: [
                                Expanded(child: Text(widget.allText, style: TextStyle(fontSize: 13, color: isSel || isHl ? kP : kText, fontWeight: isSel || isHl ? FontWeight.w700 : FontWeight.w500))),
                                if (isSel) const Icon(Icons.check_rounded, size: 14, color: kP),
                              ]),
                            ),
                          );
                        }

                        final itemIndex = _searchQuery.isEmpty ? i - 1 : i;
                        final item = filteredItems[itemIndex];
                        final isSel = item.id == widget.value;
                        final isHl = _hlIndex == (_searchQuery.isEmpty ? i : i + 1);

                        return InkWell(
                          onTap: () { widget.onChanged(item.id); _rm(picked: true); },
                          onHover: (h) { if (h) ss(() => _hlIndex = _searchQuery.isEmpty ? i : i + 1); },
                          hoverColor: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            color: isSel ? kPL : (isHl ? kPL.withOpacity(0.5) : Colors.transparent),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: kPL,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.id,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kP),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isSel || isHl ? kP : kText,
                                      fontWeight: isSel || isHl ? FontWeight.w700 : FontWeight.w500,
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
                ],
              ),
            ),
          );
        }),
      ),
    ]));
    Overlay.of(context).insert(_ov!);
  }

  @override
  Widget build(BuildContext context) {
    String displayText = widget.allText;
    if (widget.value != null) {
      try {
        final item = widget.items.firstWhere((i) => i.id == widget.value);
        displayText = item.label;
      } catch (_) {}
    }

    return GestureDetector(
      onTap: _open,
      child: Container(
        key: _key,
        height: 38,
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kP,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (widget.value != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.value!,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Icon(_isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
