import 'package:flutter/material.dart';
import '../services/auth_service 4.dart';
import 'forgot_password_page 1.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _emailHasError = false;
  bool _passwordHasError = false;

  static const Color primaryColor = Color(0xFF1A5CBF);
  static const Color backgroundColor = Color(0xFFE8EEF6);
  static const Color errorColor = Colors.red;

  @override
  void initState() {
    super.initState();

    // When user starts typing → clear error → border+label turn blue
    _emailController.addListener(() {
      if (_emailHasError && _emailController.text.isNotEmpty) {
        setState(() => _emailHasError = false);
      }
    });
    _passwordController.addListener(() {
      if (_passwordHasError && _passwordController.text.isNotEmpty) {
        setState(() => _passwordHasError = false);
      }
    });

    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _showAngularStyleAlert({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check_circle : Icons.error,
                      size: 40,
                      color: isSuccess ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF355872),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF355872),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (isSuccess) {
                          Navigator.pushReplacementNamed(context, '/dashboard');
                        }
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    print("LOG: _handleLogin entered");
    // Trigger error state for both fields
    setState(() {
      _emailHasError = true;
      _passwordHasError = true;
    });

    // Manual validation (we handle errors visually inside the box)
    final emailEmpty = _emailController.text.trim().isEmpty;
    final passwordEmpty = _passwordController.text.isEmpty;
    print("LOG: emailEmpty: $emailEmpty, passwordEmpty: $passwordEmpty");

    if (emailEmpty || passwordEmpty) {
      if (emailEmpty) setState(() => _emailHasError = true);
      if (passwordEmpty) setState(() => _passwordHasError = true);
      print("LOG: Validation failed, returning");
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("LOG: Calling authService.login...");
      final response = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      print("LOG: authService.login returned: $response");

      if (response != null &&
          response.childToken != null &&
          response.childToken!.isNotEmpty) {
        _showAngularStyleAlert(
          title: "Login Successful",
          message: "Welcome back to Access Manager!",
          isSuccess: true,
        );
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showAngularStyleAlert(
          title: "Login Failed",
          message: "Invalid email or password.",
          isSuccess: false,
        );
      }
    } catch (e, stack) {
      print("LOG: Error in _handleLogin: $e");
      print("LOG: Stacktrace: $stack");
      String error = e.toString();
      if (error.contains("blocked") || error.contains("Blocked")) {
        String msg = error.replaceAll("Exception: ", "");
        _showAngularStyleAlert(
          title: "Account Blocked",
          message: msg,
          isSuccess: false,
        );
      } else if (error.contains("User not found")) {
        _showAngularStyleAlert(
          title: "Login Failed",
          message: "No account found with this email.",
          isSuccess: false,
        );
      } else if (error.contains("Invalid password")) {
        _showAngularStyleAlert(
          title: "Login Failed",
          message: "Incorrect password.",
          isSuccess: false,
        );
      } else {
        _showAngularStyleAlert(
          title: "Login Failed",
          message: "Invalid email or password.",
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== BORDER HELPER =====
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

  // ===== COMPUTE EMAIL ERROR MESSAGE (shown inside box as hint) =====
  String? get _emailErrorText {
    if (!_emailHasError) return null;
    if (_emailController.text.trim().isEmpty) return 'Please enter your email';
    return null;
  }

  // ===== COMPUTE PASSWORD ERROR MESSAGE (shown inside box as hint) =====
  String? get _passwordErrorText {
    if (!_passwordHasError) return null;
    if (_passwordController.text.isEmpty) return 'Please enter your password';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isWide = screenWidth > 700;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
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
                          /// LEFT: GIF
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

                          /// RIGHT: Form
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
                                children: [_buildForm(screenWidth)],
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
                          child: _buildForm(screenWidth),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double screenWidth) {
    final bool emailIsInvalid = _emailErrorText != null;
    final bool passwordIsInvalid = _passwordErrorText != null;

    // Label color logic
    Color emailLabelColor() {
      if (_emailFocusNode.hasFocus) return primaryColor;
      if (emailIsInvalid) return errorColor;
      return Colors.grey.shade600;
    }

    Color passwordLabelColor() {
      if (_passwordFocusNode.hasFocus) return primaryColor;
      if (passwordIsInvalid) return errorColor;
      return Colors.grey.shade600;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [

        // ===== TITLE =====
        const Text(
          "WELCOME TO MICRO FINANCE",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: 2.5,
          ),
        ),

        const SizedBox(height: 28),

        // ===== EMAIL =====
        FractionallySizedBox(
          widthFactor: 0.78,
          child: TextFormField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: emailLabelColor()),
              floatingLabelStyle: TextStyle(
                color: emailLabelColor(),
                fontWeight: FontWeight.w500,
              ),
              // ✅ Error shown INSIDE the box as hint text in red
              hintText: emailIsInvalid
                  ? _emailErrorText
                  : 'Enter your email',
              hintStyle: TextStyle(
                color: emailIsInvalid ? errorColor : Colors.grey.shade400,
                fontSize: 14,
              ),
              // Label always floats up when error is present so hint is visible
              floatingLabelBehavior: emailIsInvalid
                  ? FloatingLabelBehavior.always
                  : FloatingLabelBehavior.auto,
              border: _border(hasFocus: false, hasError: false),
              enabledBorder: _border(hasFocus: false, hasError: emailIsInvalid),
              focusedBorder: _border(hasFocus: true, hasError: false, width: 2),
              // No errorBorder needed — we handle it manually
              errorBorder: _border(hasFocus: false, hasError: emailIsInvalid),
              focusedErrorBorder: _border(hasFocus: true, hasError: false, width: 2),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              // ✅ No errorText — error is shown inside via hintText
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            // No autovalidate — we handle it manually
            validator: (_) => null,
          ),
        ),

        const SizedBox(height: 20),

        // ===== PASSWORD =====
        FractionallySizedBox(
          widthFactor: 0.78,
          child: TextFormField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleLogin(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: passwordLabelColor()),
              floatingLabelStyle: TextStyle(
                color: passwordLabelColor(),
                fontWeight: FontWeight.w500,
              ),
              // ✅ Error shown INSIDE the box as hint text in red
              hintText: passwordIsInvalid
                  ? _passwordErrorText
                  : 'Enter your password',
              hintStyle: TextStyle(
                color: passwordIsInvalid ? errorColor : Colors.grey.shade400,
                fontSize: 14,
              ),
              // Label always floats up when error is present so hint is visible
              floatingLabelBehavior: passwordIsInvalid
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
                  _border(hasFocus: false, hasError: passwordIsInvalid),
              focusedBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              errorBorder:
                  _border(hasFocus: false, hasError: passwordIsInvalid),
              focusedErrorBorder:
                  _border(hasFocus: true, hasError: false, width: 2),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              // ✅ No errorText — error is shown inside via hintText
              errorText: null,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
            ),
            validator: (_) => null,
          ),
        ),

        // ===== FORGOT PASSWORD =====
        FractionallySizedBox(
          widthFactor: 0.78,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordPage(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                overlayColor: Colors.transparent,
                backgroundColor: Colors.transparent,
              ),
              child: const Text(
                "Forgot password?",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ===== LOGIN BUTTON =====
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
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
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // ===== SIGN UP =====
        // Center(
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Text(
        //         "Create your account to begin? ",
        //         style: TextStyle(
        //           color: Colors.grey.shade600,
        //           fontSize: 13,
        //         ),
        //       ),
        //       MouseRegion(
        //         cursor: SystemMouseCursors.click,
        //         child: GestureDetector(
        //           onTap: () {
        //             ScaffoldMessenger.of(context).showSnackBar(
        //               const SnackBar(content: Text("Sign up is not configured.")),
        //             );
        //           },
        //           child: const Text(
        //             "Sign up now",
        //             style: TextStyle(
        //               color: primaryColor,
        //               fontSize: 13,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),

        const SizedBox(height: 8),
      ],
    );
  }
}