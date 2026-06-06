import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:vtubiz/config.dart';
import 'package:vtubiz/pages/Dashboard.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/providers/authprovider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Focus Nodes for animated border/icon states
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _fullNameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // Local state
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    // Force UI refresh on focus change to animate icons/borders
    _emailFocus.addListener(_onFocusChange);
    _passwordFocus.addListener(_onFocusChange);
    _fullNameFocus.addListener(_onFocusChange);
    _phoneFocus.addListener(_onFocusChange);
    _confirmPasswordFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();
    _fullNameFocus.dispose();
    _phoneFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
      ),
    );
  }

  Future<void> _loginUser() async {
    try {
      ref.read(isLoading.notifier).state = true;
      final response = await http.post(
        Uri.parse('${AppConfig.liveUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ref.read(authUser.notifier).state = data;
        await ref.read(tokenStateProvider.notifier).saveToken(data['token']);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Dashboard()),
        );
      } else {
        ref.read(errorMessage.notifier).state =
            data['message'] ?? 'Login failed';
      }
    } catch (e) {
      ref.read(errorMessage.notifier).state = 'Connection error. Please try again.';
    } finally {
      ref.read(isLoading.notifier).state = false;
    }
  }

  Future<void> _registerUser() async {
    try {
      ref.read(isLoading.notifier).state = true;
      final response = await http.post(
        Uri.parse('${AppConfig.liveUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OtpScreen()),
        );
      } else {
        ref.read(errorMessage.notifier).state =
            data['message'] ?? 'Registration failed';
      }
    } catch (e) {
      ref.read(errorMessage.notifier).state = 'Connection error. Please try again.';
    } finally {
      ref.read(isLoading.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(isLoading);
    final error = ref.watch(errorMessage);
    final isLoginMode = ref.watch(isLogin);

    // Watch for backend/auth errors and trigger dynamic SnackBars
    if (!loading && error.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(context, error);
        ref.read(errorMessage.notifier).state = '';
      });
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFAFBFD),
              Color(0xFFF1F5F9),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Premium Decorative Mesh Gradient Circles
            Positioned(
              top: -120,
              left: -120,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00D2FF).withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF001f3e).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 220,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF5E5CE6).withOpacity(0.06),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Styled logo with glassmorphic backing
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF001f3e).withOpacity(0.08),
                              blurRadius: 24,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/logo.png',
                            height: 52,
                            width: 52,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                alignment: Alignment.center,
                                width: 52,
                                height: 52,
                                child: Text(
                                  "VT",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF001f3e),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Typographic App Branding
                      Text(
                        "VTUBiz",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF001f3e),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Premium Glassmorphic Form Container Card
                      Container(
                        width: screenWidth > 500 ? 460 : double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF001f3e).withOpacity(0.06),
                              blurRadius: 36,
                              spreadRadius: 4,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.78),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sliding Segment Selector Tab Bar
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        final tabWidth = constraints.maxWidth / 2;
                                        return Container(
                                          height: 50,
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Stack(
                                            children: [
                                              AnimatedAlign(
                                                duration: const Duration(milliseconds: 240),
                                                curve: Curves.easeInOut,
                                                alignment: isLoginMode
                                                    ? Alignment.centerLeft
                                                    : Alignment.centerRight,
                                                child: Container(
                                                  width: tabWidth - 4,
                                                  height: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF001f3e),
                                                    borderRadius: BorderRadius.circular(10),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF001f3e).withOpacity(0.25),
                                                        blurRadius: 10,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        ref.read(isLogin.notifier).state = true;
                                                      },
                                                      behavior: HitTestBehavior.opaque,
                                                      child: Center(
                                                        child: Text(
                                                          "Sign In",
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: isLoginMode
                                                                ? Colors.white
                                                                : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        ref.read(isLogin.notifier).state = false;
                                                      },
                                                      behavior: HitTestBehavior.opaque,
                                                      child: Center(
                                                        child: Text(
                                                          "Register",
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: !isLoginMode
                                                                ? Colors.white
                                                                : const Color(0xFF64748B),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 24),

                                    // Greeting with dynamic switcher
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 200),
                                      child: Column(
                                        key: ValueKey<bool>(isLoginMode),
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isLoginMode ? "Welcome Back 👋" : "Get Started 🚀",
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF001f3e),
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            isLoginMode
                                                ? "Sign in to access your secure digital wallet."
                                                : "Register an account to start smart utility purchases.",
                                            style: GoogleFonts.plusJakartaSans(
                                              color: Colors.grey[500],
                                              fontSize: 13,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Form fields
                                    if (!isLoginMode) ...[
                                      _buildRedesignedField(
                                        controller: _fullNameController,
                                        focusNode: _fullNameFocus,
                                        hint: "Full Name",
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildRedesignedField(
                                        controller: _phoneController,
                                        focusNode: _phoneFocus,
                                        hint: "Phone Number",
                                        icon: Icons.phone_outlined,
                                        keyboard: TextInputType.phone,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _buildRedesignedField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      hint: "Email Address",
                                      icon: Icons.email_outlined,
                                      keyboard: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildRedesignedField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      hint: "Password",
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscureText: _obscurePassword,
                                      onToggleVisibility: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    if (!isLoginMode) ...[
                                      const SizedBox(height: 16),
                                      _buildRedesignedField(
                                        controller: _confirmPasswordController,
                                        focusNode: _confirmPasswordFocus,
                                        hint: "Confirm Password",
                                        icon: Icons.lock_outline_rounded,
                                        isPassword: true,
                                        obscureText: _obscureConfirmPassword,
                                        onToggleVisibility: () {
                                          setState(() {
                                            _obscureConfirmPassword = !_obscureConfirmPassword;
                                          });
                                        },
                                        validator: (v) => v != _passwordController.text
                                            ? "Passwords don’t match"
                                            : null,
                                      ),
                                    ],
                                    const SizedBox(height: 28),

                                    // Premium Submit Button with Gradient background
                                    Container(
                                      width: double.infinity,
                                      height: 54,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF001f3e),
                                            Color(0xFF003870),
                                          ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF001f3e).withOpacity(0.2),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: loading
                                            ? null
                                            : () {
                                                if (_formKey.currentState!.validate()) {
                                                  isLoginMode ? _loginUser() : _registerUser();
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: loading
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                isLoginMode ? "Sign In" : "Create Account",
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
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

                      const SizedBox(height: 28),
                      // Bottom helpful navigation
                      GestureDetector(
                        onTap: () {
                          ref.read(isLogin.notifier).state = !isLoginMode;
                        },
                        child: Text.rich(
                          TextSpan(
                            text: isLoginMode
                                ? "Don’t have an account? "
                                : "Already have an account? ",
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: isLoginMode ? "Sign Up" : "Sign In",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF001f3e),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // REDESIGNED: Polished TextFormField Builder with responsive focus states and glow shadow
  Widget _buildRedesignedField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final hasFocus = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (hasFocus)
            BoxShadow(
              color: const Color(0xFF00D2FF).withOpacity(0.12),
              blurRadius: 10,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        obscureText: isPassword ? (obscureText ?? true) : false,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        validator: validator ??
            (v) => v == null || v.isEmpty ? "$hint cannot be empty" : null,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: const Color(0xFF001f3e),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: hasFocus ? const Color(0xFF00D2FF) : Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(
            icon,
            color: hasFocus ? const Color(0xFF00D2FF) : Colors.grey[400],
            size: 20,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (obscureText ?? true)
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: hasFocus ? const Color(0xFF00D2FF) : Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          filled: true,
          fillColor: hasFocus ? Colors.white : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFF001f3e).withOpacity(0.08),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF00D2FF),
              width: 1.8,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFF2D55),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFFF2D55),
              width: 2.0,
            ),
          ),
          errorStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFFFF2D55),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
