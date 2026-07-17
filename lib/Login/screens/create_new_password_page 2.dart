import 'package:flutter/material.dart';
import '../services/auth_service 4.dart';
import '../services/password_policy_service.dart';
import '../models/password_policy_model.dart';
import '../utils/password_validator.dart';

class CreateNewPasswordPage extends StatefulWidget {
  final String email;
  final String userScd;
  final int orgCode;
  final String? tokenKey;

  const CreateNewPasswordPage({
    super.key,
    required this.email,
    required this.userScd,
    required this.orgCode,
    this.tokenKey,
  });

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _passwordHasError = false;
  bool _confirmHasError = false;

  PasswordPolicy? _policy;
  bool _policyLoading = true;
  List<String> _policyRequirements = [];

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

    _passwordController.addListener(() {
      if (_passwordHasError && _passwordController.text.isNotEmpty) {
        setState(() => _passwordHasError = false);
      }
      // Re-evaluate confirm error if it's already shown
      if (_confirmHasError) setState(() {});
    });

    _confirmController.addListener(() {
      if (_confirmHasError && _confirmController.text.isNotEmpty) {
        setState(() => _confirmHasError = false);
      }
    });

    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmFocusNode.addListener(() => setState(() {}));
    
    // Fetch password policy for the organization
    _fetchPasswordPolicy();
  }

  Future<void> _fetchPasswordPolicy() async {
    try {
      final policy = await PasswordPolicyService.getPolicyByOrgCode();
      if (mounted) {
        setState(() {
          _policy = policy;
          _policyRequirements = PasswordValidator.getPolicyRequirements(policy);
          _policyLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching password policy: $e');
      if (mounted) {
        // Create a default policy with standard requirements
        final defaultPolicy = PasswordPolicy(
          minLength: 6,
          maxLength: 12,
          requireUppercase: true,
          requireLowercase: true,
          requireNumber: true,
          requireSpecialChar: false,
        );
        setState(() {
          _policy = defaultPolicy;
          _policyRequirements = PasswordValidator.getPolicyRequirements(defaultPolicy);
          _policyLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Validation helpers ──────────────────────────────────────────────────────

  String? get _passwordErrorText {
    if (!_passwordHasError) return null;
    if (_passwordController.text.isEmpty) return 'Please enter your password';
    
    if (_policy != null) {
      final result = PasswordValidator.validate(_passwordController.text, _policy!);
      return result.errorMessage;
    }
    
    if (_passwordController.text.length < 6) return 'Minimum 6 characters required';
    return null;
  }

  String? get _confirmErrorText {
    if (!_confirmHasError) return null;
    if (_confirmController.text.isEmpty) return 'Please confirm your password';
    if (_confirmController.text != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  bool get _passwordIsInvalid => _passwordErrorText != null;
  bool get _confirmIsInvalid => _confirmErrorText != null;

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

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _updatePassword() async {
    setState(() {
      _passwordHasError = true;
      _confirmHasError = true;
    });

    if (_passwordIsInvalid || _confirmIsInvalid) return;
    
    // Final validation against policy before submission
    if (_policy != null) {
      final result = PasswordValidator.validate(_passwordController.text, _policy!);
      if (!result.isValid) {
        _showErrorDialog('Password does not meet requirements: ${result.unmetRequirements.join(', ')}');
        return;
      }
    }

    setState(() => _isLoading = true);

    final result = widget.tokenKey != null 
      ? await _authService.resetPasswordWithToken(
          widget.tokenKey!,
          _passwordController.text,
          _confirmController.text,
        )
      : await _authService.resetPassword(
          widget.userScd,
          widget.orgCode,
          _passwordController.text,
          _confirmController.text,
        );

    if (mounted) setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      final errorMessage = result['message'] ?? 'Failed to update password';
      setState(() => _confirmHasError = true);
      _showErrorDialog(errorMessage);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded,
                      size: 36, color: Colors.green),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Password Updated',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your password has been updated successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/login',
                        (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('Back to Login',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      size: 36, color: errorColor),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Update Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isWide = screenWidth > 700;

    if (_policyLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    Color passwordLabelColor() {
      if (_passwordFocusNode.hasFocus) return primaryColor;
      if (_passwordIsInvalid) return errorColor;
      return Colors.grey.shade600;
    }

    Color confirmLabelColor() {
      if (_confirmFocusNode.hasFocus) return primaryColor;
      if (_confirmIsInvalid) return errorColor;
      return Colors.grey.shade600;
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
                            // LEFT: GIF
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
                            // RIGHT: Form
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
                                      passwordLabelColor: passwordLabelColor,
                                      confirmLabelColor: confirmLabelColor,
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
                              passwordLabelColor: passwordLabelColor,
                              confirmLabelColor: confirmLabelColor,
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
    required Color Function() passwordLabelColor,
    required Color Function() confirmLabelColor,
  }) {
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
          child: const Icon(
            Icons.lock_outline_rounded,
            color: primaryColor,
            size: 32,
          ),
        ),

        const SizedBox(height: 20),

        // ── Title ──
        const Text(
          'CREATE NEW PASSWORD',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: 2.5,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Enter your new password below',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),

        const SizedBox(height: 28),

        // ── Password Requirements ──
        if (_policyRequirements.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Password Requirements',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._policyRequirements.map((req) {
                    final isMet = _policy != null && 
                        PasswordValidator.requirementMet(_passwordController.text, req, _policy!);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            isMet ? Icons.check_circle : Icons.circle_outlined,
                            size: 16,
                            color: isMet ? Colors.green : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              req,
                              style: TextStyle(
                                fontSize: 12,
                                color: isMet ? Colors.green : Colors.grey.shade600,
                                fontWeight: isMet ? FontWeight.w500 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

        // ── New Password ──
        FractionallySizedBox(
          widthFactor: 0.78,
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _confirmFocusNode.requestFocus(),
            onChanged: (_) {
              setState(() {
                if (_passwordHasError && _passwordController.text.isNotEmpty) {
                  _passwordHasError = false;
                }
                if (_confirmHasError) {
                  _confirmHasError = false;
                }
              });
            },
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: TextStyle(color: passwordLabelColor()),
              floatingLabelStyle: TextStyle(
                color: passwordLabelColor(),
                fontWeight: FontWeight.w500,
              ),
              hintText: _passwordIsInvalid
                  ? _passwordErrorText
                  : 'Enter new password',
              hintStyle: TextStyle(
                color: _passwordIsInvalid ? errorColor : Colors.grey.shade400,
                fontSize: 14,
              ),
              floatingLabelBehavior: _passwordIsInvalid
                  ? FloatingLabelBehavior.always
                  : FloatingLabelBehavior.auto,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: _border(hasFocus: false, hasError: false),
              enabledBorder:
                  _border(hasFocus: false, hasError: _passwordIsInvalid),
              focusedBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              errorBorder:
                  _border(hasFocus: false, hasError: _passwordIsInvalid),
              focusedErrorBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            validator: (_) => null,
          ),
        ),

        const SizedBox(height: 20),

        // ── Confirm Password ──
        FractionallySizedBox(
          widthFactor: 0.78,
          child: TextFormField(
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _updatePassword(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: TextStyle(color: confirmLabelColor()),
              floatingLabelStyle: TextStyle(
                color: confirmLabelColor(),
                fontWeight: FontWeight.w500,
              ),
              hintText: _confirmIsInvalid
                  ? _confirmErrorText
                  : 'Re-enter new password',
              hintStyle: TextStyle(
                color: _confirmIsInvalid ? errorColor : Colors.grey.shade400,
                fontSize: 14,
              ),
              floatingLabelBehavior: _confirmIsInvalid
                  ? FloatingLabelBehavior.always
                  : FloatingLabelBehavior.auto,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey.shade600,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: _border(hasFocus: false, hasError: false),
              enabledBorder:
                  _border(hasFocus: false, hasError: _confirmIsInvalid),
              focusedBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              errorBorder:
                  _border(hasFocus: false, hasError: _confirmIsInvalid),
              focusedErrorBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            validator: (_) => null,
          ),
        ),

        const SizedBox(height: 24),

        // ── Update button ──
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _updatePassword,
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
                : const Text(
                    'Update Password',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Back ──
        TextButton(
          onPressed: () => Navigator.pop(context),
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
    );
  }
}