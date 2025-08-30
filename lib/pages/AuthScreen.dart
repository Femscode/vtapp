import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:vtubiz/pages/Dashboard.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/providers/authprovider.dart';

class AuthScreen extends ConsumerWidget {
  AuthScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String email = '';
    String password = '';
    String fullName = '';
    String phone = '';
    final passwordController = TextEditingController();

    void showError(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (!ref.watch(isLoading) && ref.watch(errorMessage) != '') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showError(context, ref.watch(errorMessage));
        ref.read(errorMessage.notifier).state = '';
      });
    }

    void toggleLogin() {
      ref.read(isLogin.notifier).state = !ref.watch(isLogin);
    }

    Future<void> loginUser() async {
      try {
        ref.read(isLoading.notifier).state = true;
        final response = await http.post(
          Uri.parse('https://vtubiz.com/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          ref.read(authUser.notifier).state = data;
          await ref.read(tokenStateProvider.notifier).saveToken(data['token']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Dashboard()),
          );
        } else {
          ref.read(errorMessage.notifier).state = data['message'];
        }
      } catch (e) {
        ref.read(errorMessage.notifier).state = e.toString();
      } finally {
        ref.read(isLoading.notifier).state = false;
      }
    }

    Future<void> registerUser() async {
      try {
        ref.read(isLoading.notifier).state = true;
        final response = await http.post(
          Uri.parse('https://vtubiz.com/api/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': fullName,
            'phone': phone,
            'email': email,
            'password': password,
            'password_confirmation': password,
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OtpScreen()),
          );
        } else {
          ref.read(errorMessage.notifier).state = data['message'];
        }
      } catch (e) {
        ref.read(errorMessage.notifier).state = e.toString();
      } finally {
        ref.read(isLoading.notifier).state = false;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo / Branding
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Text(
                    "VTUBiz",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF001f3e),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Header
                Text(
                  ref.watch(isLogin) ? "Welcome Back 👋" : "Sign Up 🚀",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001f3e),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(isLogin)
                      ? "Sign in to continue your journey"
                      : "Create your account to get started",
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Auth form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!ref.watch(isLogin)) ...[
                          _inputField(
                            hint: "Full Name",
                            icon: Icons.person_outline,
                            onSaved: (v) => fullName = v!,
                          ),
                          const SizedBox(height: 16),
                          _inputField(
                            hint: "Phone Number",
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            onSaved: (v) => phone = v!,
                          ),
                          const SizedBox(height: 16),
                        ],
                        _inputField(
                          hint: "Email Address",
                          icon: Icons.email_outlined,
                          keyboard: TextInputType.emailAddress,
                          onSaved: (v) => email = v!,
                        ),
                        const SizedBox(height: 16),
                        _inputField(
                          hint: "Password",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          controller: passwordController,
                          onSaved: (v) => password = v!,
                        ),
                        if (!ref.watch(isLogin)) ...[
                          const SizedBox(height: 16),
                          _inputField(
                            hint: "Confirm Password",
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (v) => v != passwordController.text
                                ? "Passwords don’t match"
                                : null,
                          ),
                        ],
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              ref.watch(isLogin) ? loginUser() : registerUser();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001f3e),
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: ref.watch(isLoading)
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  ref.watch(isLogin)
                                      ? "Sign In"
                                      : "Create Account",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color:Color(  0xFFFFECDF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: toggleLogin,
                  child: Text.rich(
                    TextSpan(
                      text: ref.watch(isLogin)
                          ? "Don’t have an account? "
                          : "Already a member? ",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      children: [
                        TextSpan(
                          text: ref.watch(isLogin) ? "Sign Up" : "Sign In",
                          style: const TextStyle(
                            color: Color(0xFF001f3e),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboard,
    TextEditingController? controller,
    Function(String?)? onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboard,
      onSaved: onSaved,
      validator: validator ??
          (v) => v == null || v.isEmpty ? "$hint cannot be empty" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF001f3e)),
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
