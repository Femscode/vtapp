import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:vtubiz/component/ErrorToast.dart';
import 'package:vtubiz/pages/Dashboard.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/providers/authprovider.dart';

class AuthScreen extends ConsumerWidget {
  AuthScreen({super.key});

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String email_address = '';
    String user_password = '';
    String full_name = '';
    String phone_number = '';

    void _showErrorNotification(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (!ref.watch(isLoading) && ref.watch(errorMessage) != '') {
      // Navigator.push(context,
      //       MaterialPageRoute(builder: (context) => const OtpScreen()));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showErrorNotification(context, ref.watch(errorMessage));
        ref.read(errorMessage.notifier).state = ''; // Clear the error
      });
    }
    // ... existing error handling code ...

    final TextEditingController _passwordController = TextEditingController();

    // ... existing toggle and login functions ...

    void toggleLogin() {
      ref.read(isLogin.notifier).state = !ref.watch(isLogin);
    }

    void logUserIn(email, password) async {
      try {
        ref.read(isLoading.notifier).state = true;

        String url = 'https://vtubiz.com/api/auth/login';
        final loginResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        );
        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body);
          final tokenNotifier = ref.read(tokenStateProvider.notifier);
          print(data);
          print('Login successful: ${data['message']}');
          ref.read(authUser.notifier).state = data;
          await tokenNotifier.saveToken(data['token']);
          ref.read(isLoading.notifier).state = false;
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const Dashboard()));
        } else {
          final error = jsonDecode(loginResponse.body);
          print('Login failed: ${error['message']}');
          ref.read(isLoading.notifier).state = false;
          ref.read(errorMessage.notifier).state = error['message'];
        }
      } catch (e) {
        print('An error occurred: $e');
        ref.read(isLoading.notifier).state = false;
        ref.read(errorMessage.notifier).state = e.toString();
      }
    }

    void signUserIn(email, fullname, phone, password) async {
      try {
        ref.read(isLoading.notifier).state = true;
        String url = 'https://vtubiz.com/api/auth/register';
        final loginResponse = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': fullname,
            'phone': phone,
            'email': email,
            'password': password,
            'password_confirmation': password,
          }),
        );
        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body);
          print(data);
          print(
              'Registered successful: ${data['message']}'); // Example response handling
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const OtpScreen()));
          // Handle token or user data
          ref.read(isLoading.notifier).state = false;
        } else {
          final error = jsonDecode(loginResponse.body);
          print('Login failed: ${error['message']}');
          ref.read(isLoading.notifier).state = false;
          ref.read(errorMessage.notifier).state = error['message'];
        }
      } catch (e) {
        print('An error occurred: $e');
        ref.read(isLoading.notifier).state = false;
        ref.read(errorMessage.notifier).state = e.toString();
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFF001f3e).withOpacity(0.05),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SizedBox(height: constraints.maxHeight * 0.08),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        '/logo-dark.png',
                        height: constraints.maxHeight * 0.07,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.05),
                    Text(
                      ref.watch(isLogin) ? "Welcome Back!" : "Create Account",
                      style:
                          Theme.of(context).textTheme.headlineSmall!.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF001f3e),
                                fontSize: 25,
                              ),
                    ),
                    Text(
                      ref.watch(isLogin)
                          ? "Sign in to continue"
                          : "Get started with your account",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: constraints.maxHeight * 0.04),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!ref.watch(isLogin))
                              _buildTextField(
                                hintText: 'Full name',
                                icon: Icons.person_outline,
                                onSaved: (value) => full_name = value!,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Full name must not be empty";
                                  }
                                  return null;
                                },
                              ),
                            if (!ref.watch(isLogin)) const SizedBox(height: 16),
                            if (!ref.watch(isLogin))
                              _buildTextField(
                                hintText: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                onSaved: (value) => phone_number = value!,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Phone number must not be empty";
                                  }
                                  if (value.length != 11) {
                                    return "Phone number must be 11 digits";
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              hintText: 'Email Address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (value) => email_address = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Email must not be empty";
                                }
                                if (!RegExp(
                                        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                                    .hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              controller: _passwordController,
                              onSaved: (value) => user_password = value!,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password cannot be empty";
                                }
                                if (value.length < 6) {
                                  return "Password must be more than 6 characters";
                                }
                                return null;
                              },
                            ),
                            if (!ref.watch(isLogin))
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    hintText: 'Confirm Password',
                                    icon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Password cannot be empty";
                                      }
                                      if (value.length < 6) {
                                        return "Password must be more than 6";
                                      }
                                      if (value != _passwordController.text) {
                                        return "Password does not match";
                                      }
                                      return null;
                                    },
                                    onSaved: (password) {
                                      user_password = password!;
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  ref.watch(isLogin)
                                      ? logUserIn(email_address, user_password)
                                      : signUserIn(email_address, full_name,
                                          phone_number, user_password);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001f3e),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: ref.watch(isLoading)
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      ref.watch(isLogin)
                                          ? "Sign In"
                                          : "Create Account",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: toggleLogin,
                      child: Text.rich(
                        TextSpan(
                          text: ref.watch(isLogin)
                              ? "Don't have an account? "
                              : "Already have an account? ",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                          ),
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    TextEditingController? controller,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: validator,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF001f3e),
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 15,
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF001f3e),
          size: 22,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: const Color(0xFF001f3e).withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF001f3e),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade300,
            width: 1.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}
