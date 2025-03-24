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
          duration: const Duration(seconds: 2), // Disappears after 30 seconds
          margin: const EdgeInsets.all(16.0),
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

    final TextEditingController _passwordController = TextEditingController();

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
        String url =
            'https://vtubiz.com/api/auth/register';
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
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Image.network(
                    "https://i.postimg.cc/nz0YBQcH/Logo-light.png",
                    height: 100,
                  ),
                  SizedBox(height: constraints.maxHeight * 0.1),
                  Text(
                    ref.watch(isLogin) ? "Sign In" : "Create New Account",
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: constraints.maxHeight * 0.05),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!ref.watch(isLogin))
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Full name',
                              filled: true,
                              fillColor: Color(0xFFFFFAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Full name must not be empty";
                              }

                              return null;
                            },
                            keyboardType: TextInputType.text,
                            onSaved: (value) {
                              full_name = value!;
                            },
                          ),
                        const Padding(padding: EdgeInsets.all(10)),
                        if (!ref.watch(isLogin))
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Phone Number',
                              filled: true,
                              fillColor: Color(0xFFFFFAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Phone number must not be empty";
                              }
                              if (value.length < 11 || value.length > 11) {
                                return "Phone number must be 11 digits";
                              }

                              return null;
                            },
                            keyboardType: TextInputType.number,
                            onSaved: (value) {
                              phone_number = value!;
                            },
                          ),
                        const Padding(padding: EdgeInsets.all(10)),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Email Address',
                            filled: true,
                            fillColor: Color(0xFFFFFAFB),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0 * 1.5, vertical: 16.0),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(50)),
                            ),
                          ),
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
                          keyboardType: TextInputType.text,
                          onSaved: (email) {
                            email_address = email!;
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: TextFormField(
                            obscureText: true,
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: Color(0xFFFFFAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0 * 1.5, vertical: 16.0),
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(50)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password cannot be empty";
                              }
                              if (value.length < 6) {
                                return "Password must be more than 6";
                              }
                              return null;
                            },
                            onSaved: (password) {
                              user_password = password!;
                              // Save it
                            },
                          ),
                        ),
                        if (!ref.watch(isLogin))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: TextFormField(
                              obscureText: true,
                              decoration: const InputDecoration(
                                hintText: 'Confirm Password',
                                filled: true,
                                fillColor: Color(0xFFFFFAFB),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0 * 1.5, vertical: 16.0),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(50)),
                                ),
                              ),
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
                                // Save it
                              },
                            ),
                          ),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              ref.watch(isLogin)
                                  ? logUserIn(email_address, user_password)
                                  : signUserIn(email_address, full_name,
                                      phone_number, user_password);

                              // Navigate to the main screen
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF333333),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                            shape: const StadiumBorder(),
                          ),
                          child: ref.watch(isLoading)
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth:
                                      2.0, // Adjust thickness if needed
                                )
                              : ref.watch(isLogin)
                                  ? const Text("Sign in")
                                  : const Text("Create Account"),
                        ),
                        const Padding(padding: EdgeInsets.all(20)),
                    
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Forgot Password?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withOpacity(0.64),
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text.rich(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withOpacity(0.64),
                                ),
                            ref.watch(isLogin)
                                ? TextSpan(
                                    text: "Don’t have an account? ",
                                    children: [
                                      TextSpan(
                                        text: "Sign Up",
                                        style: const TextStyle(
                                            color: Color(0xFF333333)),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = toggleLogin,
                                      ),
                                    ],
                                  )
                                : TextSpan(
                                    text: "Already have an account? ",
                                    children: [
                                      TextSpan(
                                        text: "Sign In",
                                        style: const TextStyle(
                                            color: Color(0xFF333333)),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = toggleLogin,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
