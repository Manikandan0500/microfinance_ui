import 'package:flutter/material.dart';

class SuccessDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    bool isDelete = false,
    VoidCallback? onDismiss,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _SuccessDialogWidget(
        title: title,
        message: message,
        buttonText: buttonText,
        isDelete: isDelete,
        onDismiss: onDismiss,
      ),
    );
  }
}

class _SuccessDialogWidget extends StatefulWidget {
  final String title;
  final String message;
  final String buttonText;
  final bool isDelete;
  final VoidCallback? onDismiss;

  const _SuccessDialogWidget({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.isDelete,
    this.onDismiss,
  });

  @override
  State<_SuccessDialogWidget> createState() => _SuccessDialogWidgetState();
}

class _SuccessDialogWidgetState extends State<_SuccessDialogWidget>
    with TickerProviderStateMixin {
  late AnimationController _dialogCtrl;
  late AnimationController _iconCtrl;
  late AnimationController _checkCtrl;

  late Animation<double> _dialogScale;
  late Animation<double> _dialogFade;
  late Animation<double> _iconScale;
  late Animation<double> _iconBounce;
  late Animation<double> _checkDraw;
  late Animation<double> _circleFade;

  @override
  void initState() {
    super.initState();

    // Dialog entrance
    _dialogCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dialogScale = CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeOutBack);
    _dialogFade  = CurvedAnimation(parent: _dialogCtrl, curve: Curves.easeOut);

    // Icon pop
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconScale  = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _iconBounce = CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOut);

    // Check/tick draw
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _checkDraw  = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeInOut);
    _circleFade = CurvedAnimation(parent: _checkCtrl, curve: Curves.easeOut);

    // Sequence: dialog → icon → check
    _dialogCtrl.forward().then((_) {
      _iconCtrl.forward().then((_) {
        _checkCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _dialogCtrl.dispose();
    _iconCtrl.dispose();
    _checkCtrl.dispose();
    super.dispose();
  }

  Color get _primary => widget.isDelete ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
  Color get _lightBg => widget.isDelete ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7);
  Color get _borderC => widget.isDelete
      ? const Color(0xFFDC2626).withOpacity(0.25)
      : const Color(0xFF16A34A).withOpacity(0.25);
  Color get _btnColor => widget.isDelete ? const Color(0xFFDC2626) : const Color(0xFF3D6EBE);

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _dialogFade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: ScaleTransition(
          scale: _dialogScale,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Animated icon ──────────────────────────────
                      ScaleTransition(
                        scale: _iconScale,
                        child: AnimatedBuilder(
                          animation: _iconBounce,
                          builder: (_, child) => Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _lightBg,
                              border: Border.all(color: _borderC, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withOpacity(0.15 * _iconBounce.value),
                                  blurRadius: 18,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedBuilder(
                                animation: _checkCtrl,
                                builder: (_, __) => CustomPaint(
                                  size: const Size(32, 32),
                                  painter: widget.isDelete
                                      ? _CrossPainter(
                                          progress: _checkDraw.value,
                                          color: _primary,
                                          fadeIn: _circleFade.value,
                                        )
                                      : _CheckPainter(
                                          progress: _checkDraw.value,
                                          color: _primary,
                                          fadeIn: _circleFade.value,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Title ──────────────────────────────────────
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF152A51),
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // ── Message ────────────────────────────────────
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Button ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDismiss?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _btnColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            widget.buttonText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated tick painter ─────────────────────────────────────────────────────
class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double fadeIn;

  const _CheckPainter({
    required this.progress,
    required this.color,
    required this.fadeIn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(fadeIn)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Tick path: short left leg then long right leg
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.74)
      ..lineTo(size.width * 0.82, size.height * 0.28);

    for (final metric in path.computeMetrics()) {
  canvas.drawPath(
    metric.extractPath(0, metric.length * progress),
    paint,
  );
}
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.fadeIn != fadeIn;
}

// ── Animated cross painter (for delete) ──────────────────────────────────────
class _CrossPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double fadeIn;

  const _CrossPainter({
    required this.progress,
    required this.color,
    required this.fadeIn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(fadeIn)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final half = progress / 2;

    // First diagonal: top-left → bottom-right
    if (progress > 0) {
      final p1 = Path()
        ..moveTo(size.width * 0.22, size.height * 0.22)
        ..lineTo(size.width * 0.78, size.height * 0.78);
      final m1 = p1.computeMetrics().first;
      canvas.drawPath(
        m1.extractPath(0, m1.length * (progress < 0.5 ? progress * 2 : 1.0)),
        paint,
      );
    }

    // Second diagonal: top-right → bottom-left
    if (progress > 0.5) {
      final p2 = Path()
        ..moveTo(size.width * 0.78, size.height * 0.22)
        ..lineTo(size.width * 0.22, size.height * 0.78);
      final m2 = p2.computeMetrics().first;
      canvas.drawPath(
        m2.extractPath(0, m2.length * ((progress - 0.5) * 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CrossPainter old) =>
      old.progress != progress || old.fadeIn != fadeIn;
}