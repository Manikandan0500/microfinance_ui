import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service 4.dart';
import 'create_new_password_page 2.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

enum _Step { email, otp }

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _emailHasError = false;
  bool _otpHasError = false;
  String? _serverError;

  _Step _currentStep = _Step.email;
  String? _tokenKey;
  int? _orgCode;

  // ── OTP countdown timer ──────────────────────────────────────────────────
  static const int _otpTotalSeconds = 5 * 60; // 5 minutes
  Timer? _otpTimer;
  int _otpSecondsLeft = _otpTotalSeconds;
  bool _otpExpired = false;

  static const Color primaryColor = Color(0xFF1A5CBF);
  static const Color backgroundColor = Color(0xFFE8EEF6);
  static const Color errorColor = Colors.red;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    _emailController.addListener(() {
      if (_emailHasError && _emailController.text.isNotEmpty) {
        setState(() {
          _emailHasError = false;
          _serverError = null;
        });
      }
    });

    _otpController.addListener(() {
      if (_otpHasError && _otpController.text.isNotEmpty) {
        setState(() {
          _otpHasError = false;
          _serverError = null;
        });
      }
    });

    _emailFocusNode.addListener(() => setState(() {}));
    _otpFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cancelOtpTimer();
    _emailController.dispose();
    _emailFocusNode.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Validators ────────────────────────────────────────────────────────────

  bool get _emailIsInvalid {
    if (!_emailHasError) return false;
    final text = _emailController.text.trim();
    if (text.isEmpty) return true;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) return true;
    return false;
  }

  String? get _emailErrorText {
    if (!_emailHasError) return null;
    final text = _emailController.text.trim();
    if (text.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(text)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  bool get _otpIsInvalid {
    if (!_otpHasError) return false;
    final text = _otpController.text.trim();
    if (text.isEmpty || text.length < 6) return true;
    return false;
  }

  String? get _otpErrorText {
    if (!_otpHasError) return null;
    final text = _otpController.text.trim();
    if (text.isEmpty) return 'Please enter the OTP';
    if (text.length < 6) return 'OTP must be 6 digits';
    return null;
  }

  /// True when the backend has rate-limited or blocked the user.
  bool get _isLockedOut {
    if (_serverError == null) return false;
    final msg = _serverError!.toLowerCase();
    return msg.contains('blocked') ||
        msg.contains('retry after') ||
        msg.contains('try again after') ||
        msg.contains('maximum attempts');
  }

  // ── Timer helpers ─────────────────────────────────────────────────────────

  void _startOtpTimer() {
    _cancelOtpTimer();
    setState(() {
      _otpSecondsLeft = _otpTotalSeconds;
      _otpExpired = false;
    });
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_otpSecondsLeft > 0) {
          _otpSecondsLeft--;
        } else {
          _otpExpired = true;
          t.cancel();
        }
      });
    });
  }

  void _cancelOtpTimer() {
    _otpTimer?.cancel();
    _otpTimer = null;
  }

  String get _timerLabel {
    final m = _otpSecondsLeft ~/ 60;
    final s = _otpSecondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Border helper ─────────────────────────────────────────────────────────

  OutlineInputBorder _border({
    required bool hasFocus,
    required bool hasError,
    double width = 1.0,
  }) {
    Color color;
    if (hasError) {
      color = errorColor;
    } else {
      color = hasFocus ? primaryColor : const Color(0xFFBDBDBD);
    }
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _handleEmailSubmit() async {
    setState(() {
      _emailHasError = true;
      _serverError = null;
    });

    if (_emailIsInvalid) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final response = await _authService.verifyEmail(email);

    if (response != null) {
      if (response.containsKey('status') &&
          response['status']?.toString() == '401' &&
          (response['message']?.toString().contains("You can't reset your password now") ?? false)) {
        if (mounted) setState(() => _isLoading = false);
        _showUnavailableAlert();
        return;
      }
      final genOtpResp = await _authService.generateOtp({
        'email': email,
        'firstName': response['firstName'],
        'userScd': response['userScd'],
        'orgCode': response['orgCode'],
      });

      if (mounted) setState(() => _isLoading = false);

      if (genOtpResp != null && genOtpResp['error'] != true && genOtpResp['tokenKey'] != null) {
        setState(() {
          _tokenKey = genOtpResp['tokenKey'];
          _orgCode = response['orgCode'];
          _currentStep = _Step.otp;
          _serverError = null;
          _emailHasError = false;
        });
        _startOtpTimer();
      } else {
        setState(() {
          _serverError = genOtpResp?['message'] ?? 'Failed to generate OTP. Please try again.';
          _emailHasError = true;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
      setState(() {
        _serverError = 'Email not found. Please check and try again.';
        _emailHasError = true;
      });
    }
  }

  Future<void> _handleOtpSubmit() async {
    setState(() {
      _otpHasError = true;
      _serverError = null;
    });

    if (_otpIsInvalid) return;

    setState(() => _isLoading = true);

    final otp = _otpController.text.trim();
    final response = await _authService.verifyOtp(_tokenKey!, otp);

    if (mounted) setState(() => _isLoading = false);

    // ── Success ──────────────────────────────────────────────────────────────
    if (response != null && response['error'] != true && response['tokenKey'] != null) {
      _cancelOtpTimer();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreateNewPasswordPage(
            tokenKey: response['tokenKey'],
            orgCode: _orgCode ?? 0,
            email: _emailController.text.trim(),
            userScd: '',
          ),
        ),
      );
      return;
    }

    // ── Error handling ───────────────────────────────────────────────────────
    final message = response?['message'] ?? 'Invalid OTP or expired.';

    // Block expired → force new OTP generation
    if (message.contains('Block period expired')) {
      _cancelOtpTimer();
      setState(() {
        _currentStep = _Step.email;
        _otpController.clear();
        _otpHasError = false;
        _otpExpired = false;
        _otpSecondsLeft = _otpTotalSeconds;
        _serverError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Too many wrong attempts. Please generate a new OTP.',
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Blocked with countdown → show seconds remaining
    if (message.contains('Please retry after')) {
      setState(() {
        _serverError = message;
        _otpHasError = true;
      });
      return;
    }

    // All other errors (wrong OTP, expired, already used)
    setState(() {
      _serverError = message;
      _otpHasError = true;
    });
  }

  void _goBackToEmail() {
    _cancelOtpTimer();
    setState(() {
      _currentStep = _Step.email;
      _serverError = null;
      _otpHasError = false;
      _otpExpired = false;
      _otpSecondsLeft = _otpTotalSeconds;
      _otpController.clear();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isWide = screenWidth > 700;

    final bool showError = _emailIsInvalid || _serverError != null;

    Color emailLabelColor() {
      if (_emailFocusNode.hasFocus) return primaryColor;
      if (showError) return errorColor;
      return Colors.grey.shade600;
    }

    String? hintText() {
      if (_serverError != null) return _serverError;
      return _emailErrorText ?? 'Enter your email';
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.05,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 30,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: isWide
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Image.asset(
                                    'assets/bbotslogo.gif',
                                    width: double.infinity,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: screenWidth * 0.005,
                                  right: screenWidth * 0.025,
                                  top: screenHeight * 0.06,
                                  bottom: screenHeight * 0.06,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildForm(
                                      emailLabelColor: emailLabelColor,
                                      showError: showError,
                                      hintText: hintText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Image.asset(
                                  'assets/bbotslogo.gif',
                                  width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 32),
                            child: _buildForm(
                              emailLabelColor: emailLabelColor,
                              showError: showError,
                              hintText: hintText,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required Color Function() emailLabelColor,
    required bool showError,
    required String? Function() hintText,
  }) {
    final bool isEmail = _currentStep == _Step.email;

    String? otphintText() {
      if (_serverError != null && !isEmail) return _serverError;
      return _otpErrorText ?? 'Enter 6-digit OTP';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Lock icon ──
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isEmail ? Icons.lock_reset_rounded : Icons.mark_email_read_rounded,
            color: primaryColor,
            size: 32,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          isEmail ? 'FORGOT PASSWORD' : 'VERIFY OTP',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: 2.5,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          isEmail
              ? 'Enter your email to reset your password'
              : 'An OTP has been sent to ${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),

        const SizedBox(height: 28),

        // ── Fields ──
        if (isEmail)
          FractionallySizedBox(
            widthFactor: 0.78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _isLoading ? null : _handleEmailSubmit(),
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: emailLabelColor()),
                    floatingLabelStyle: TextStyle(
                      color: emailLabelColor(),
                      fontWeight: FontWeight.w500,
                    ),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    border: _border(hasFocus: false, hasError: false),
                    enabledBorder: _border(hasFocus: false, hasError: showError),
                    focusedBorder: _border(hasFocus: true, hasError: false, width: 2),
                    errorBorder: _border(hasFocus: false, hasError: showError),
                    focusedErrorBorder: _border(hasFocus: true, hasError: false, width: 2),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    errorText: null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                  validator: (_) => null,
                ),
                if (_serverError != null || _emailIsInvalid)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _serverError ?? _emailErrorText ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: errorColor, fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          )
        else if (_otpExpired)
          // ── OTP expired state ─────────────────────────────────────────────
          Column(
            children: [
              const Icon(Icons.timer_off_rounded, color: errorColor, size: 36),
              const SizedBox(height: 10),
              const Text(
                'Your OTP has expired.',
                style: TextStyle(
                  color: errorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please generate a new OTP.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 180,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _goBackToEmail,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Generate OTP',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // ── Active OTP input with countdown ───────────────────────────────
          Column(
            children: [
              // Countdown timer row
              Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _otpSecondsLeft < 60
                          ? Colors.red.shade600
                          : _otpSecondsLeft <= 120
                              ? Colors.orange.shade700
                              : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'OTP expires in $_timerLabel minutes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _otpSecondsLeft < 60
                            ? Colors.red.shade600
                            : _otpSecondsLeft <= 120
                                ? Colors.orange.shade700
                                : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _OtpInputBoxes(
                controller: _otpController,
                hasError: _otpIsInvalid || _serverError != null,
                onSubmitted: () {
                  if (!_isLoading) _handleOtpSubmit();
                },
              ),
              if (_otpIsInvalid || _serverError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    otphintText() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: errorColor, fontSize: 13),
                  ),
                ),
            ],
          ),

        // ── Button + back link (hidden when OTP expired) ──────────────────
        if (!_otpExpired) ...[
          const SizedBox(height: 24),

          SizedBox(
            width: 180,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (!isEmail && _isLockedOut
                      ? _goBackToEmail
                      : (isEmail ? _handleEmailSubmit : _handleOtpSubmit)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      (!isEmail && _isLockedOut)
                          ? 'Back'
                          : (isEmail ? 'Get OTP' : 'Verify OTP'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              if (isEmail) {
                Navigator.pop(context);
              } else {
                _goBackToEmail();
              }
            },
            style: TextButton.styleFrom(
              overlayColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
            ),
            child: const Text(
              'Back',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _showUnavailableAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Container(
                padding: const EdgeInsets.all(32), // Spacious padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 44,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Password Reset Unavailable',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 26,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your account password has not been initialized.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Please contact your Administrator to set your initial password.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OtpInputBoxes extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final bool hasError;

  const _OtpInputBoxes({
    required this.controller,
    required this.onSubmitted,
    required this.hasError,
  });

  @override
  State<_OtpInputBoxes> createState() => _OtpInputBoxesState();
}

class _OtpInputBoxesState extends State<_OtpInputBoxes> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (i) => TextEditingController());
    _focusNodes = List.generate(6, (i) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) {
          int firstEmptyIndex = _controllers.indexWhere((c) => c.text.isEmpty);
          if (firstEmptyIndex != -1 && i > firstEmptyIndex) {
            _focusNodes[firstEmptyIndex].requestFocus();
          }
        }
      });
      return node;
    });

    if (widget.controller.text.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.controller.text[i];
      }
    }

    widget.controller.addListener(_syncFromMainController);
  }

  void _syncFromMainController() {
    if (widget.controller.text.isEmpty) {
      for (var c in _controllers) {
        c.clear();
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromMainController);
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _updateMainController() {
    widget.controller.text = _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return SizedBox(
            width: 45,
            height: 55,
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (event) {
                if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
                final key = event.logicalKey;
                if (key == LogicalKeyboardKey.arrowLeft) {
                  if (index > 0) _focusNodes[index - 1].requestFocus();
                } else if (key == LogicalKeyboardKey.arrowRight) {
                  if (index < 5 && _controllers[index].text.isNotEmpty) {
                    _focusNodes[index + 1].requestFocus();
                  }
                } else if (key == LogicalKeyboardKey.backspace) {
                  if (_controllers[index].text.isEmpty && index > 0) {
                    _controllers[index - 1].clear();
                    _updateMainController();
                    _focusNodes[index - 1].requestFocus();
                  }
                }
              },
              child: TextFormField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
                textAlign: TextAlign.center,
                maxLength: 1,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.hasError ? Colors.red : Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.hasError ? Colors.red : const Color(0xFF1A5CBF), width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: widget.hasError ? Colors.red : Colors.grey.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  _updateMainController();
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    } else {
                      _focusNodes[index].unfocus();
                      if (widget.controller.text.length == 6) {
                        widget.onSubmitted();
                      }
                    }
                  }
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

