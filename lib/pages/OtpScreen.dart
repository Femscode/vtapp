import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vtubiz/pages/Dashboard.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _pinController1 = TextEditingController();
  final _pinController2 = TextEditingController();
  final _pinController3 = TextEditingController();
  final _pinController4 = TextEditingController();

  void _savePin() async {
    String pin = _pinController1.text +
        _pinController2.text +
        _pinController3.text +
        _pinController4.text;
    // Here you can save the PIN, e.g., save to shared preferences or API call
    String url = 'https://vtubiz.com/api/profile';
   
    final user = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer token'},
    );

    if (user.statusCode == 200) {
      final data = jsonDecode(user.body) as Map<String, dynamic>;
      final userData = data['data'] as Map<String, dynamic>;
      const Dashboard();

    } else {
      throw Exception('Unable to set pin');
    }
    print("Transaction PIN saved: $pin");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () async {
            Navigator.pop(context); // Navigate back when back button is pressed
            return false; // Prevent the default back action
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Set Transaction Pin",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Essential for secure and personalized experience.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF757575)),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    const OtpForm(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    ElevatedButton(
                      onPressed: _savePin,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF333333),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                      ),
                      child: const Text("Continue"),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const authOutlineInputBorder = OutlineInputBorder(
  borderSide: BorderSide(color: Color(0xFF757575)),
  borderRadius: BorderRadius.all(Radius.circular(12)),
);

class OtpForm extends StatelessWidget {
  const OtpForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPinField(context, 1),
          const SizedBox(width: 16),
          _buildPinField(context, 2),
          const SizedBox(width: 16),
          _buildPinField(context, 3),
          const SizedBox(width: 16),
          _buildPinField(context, 4),
        ],
      ),
    );
  }

  Widget _buildPinField(BuildContext context, int fieldIndex) {
    TextEditingController controller;
    switch (fieldIndex) {
      case 1:
        controller = TextEditingController();
        break;
      case 2:
        controller = TextEditingController();
        break;
      case 3:
        controller = TextEditingController();
        break;
      case 4:
        controller = TextEditingController();
        break;
      default:
        controller = TextEditingController();
    }

    return SizedBox(
      height: 64,
      width: 64,
      child: TextFormField(
        controller: controller,
        obscureText: true, // Makes the entered text asterisks
        onChanged: (pin) {
          if (pin.isNotEmpty && fieldIndex < 4) {
            FocusScope.of(context).nextFocus();
          }
        },
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: "0",
          hintStyle: const TextStyle(color: Color(0xFF757575)),
          border: authOutlineInputBorder,
          enabledBorder: authOutlineInputBorder,
          focusedBorder: authOutlineInputBorder.copyWith(
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
        ),
      ),
    );
  }
}
