import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/BeneficiarySelector.dart';
import 'package:vtubiz/component/purchase/BeneficiaryToggle.dart';
import 'package:vtubiz/component/purchase/FetchPlan.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/component/purchase/NetworkSelect.dart';
import 'package:vtubiz/component/purchase/RecentTransactions.dart';
import 'package:vtubiz/component/purchase/SelectTime.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BuyData extends StatefulWidget {
  const BuyData({Key? key}) : super(key: key);

  @override
  State<BuyData> createState() => _BuyDataState();
}

class _BuyDataState extends State<BuyData> {
  final TextEditingController _phoneController = TextEditingController();
  int? _selectedNetwork;
  Map<String, dynamic>? _selectedPlan;
  bool beneficiary_toggle = false;
  String _phone = '';
  bool isSelected = false;

  // Add this function to normalize phone number
  String normalizePhoneNumber(String phone) {
    // Remove any spaces or special characters
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Convert +234 to 0
    if (phone.startsWith('+234')) {
      phone = '0${phone.substring(4)}';
    }
    // Convert 234 to 0
    else if (phone.startsWith('234')) {
      phone = '0${phone.substring(3)}';
    }

    return phone;
  }

  void detectAndSelectNetwork(String phoneNumber) {
    if (phoneNumber.isEmpty) return;

    String normalizedNumber = normalizePhoneNumber(phoneNumber);
    if (normalizedNumber.length >= 4) {
      String prefix = normalizedNumber.substring(0, 4);

      setState(() {
        // MTN prefixes
        if (RegExp(r'^0(703|706|803|806|810|813|814|903|904|906)')
            .hasMatch(prefix)) {
          _selectedNetwork = 1;
        }
        // GLO prefixes
        else if (RegExp(r'^0(705|805|807|811|815|905)').hasMatch(prefix)) {
          _selectedNetwork = 2;
        }
        // Airtel prefixes
        else if (RegExp(r'^0(701|708|802|808|902)').hasMatch(prefix)) {
          _selectedNetwork = 3;
        }
        // 9mobile prefixes
        else if (RegExp(r'^0(809|817|818|908|909)').hasMatch(prefix)) {
          _selectedNetwork = 4;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _phone = _phoneController.text;
        detectAndSelectNetwork(_phone);
      });
    });
  }

  void updateBeneficiaryToggle(bool value) {
    setState(() {
      beneficiary_toggle = value;
    });
  }

  void selectNetwork(String name, int id) {
    if (mounted) {
      setState(() {
        _selectedNetwork = id;
        isSelected = true;
      });
    }
  }

  void _showResultDialog(String title, String message, bool isSuccess) {
    if (!mounted) return;

    Future.microtask(() {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Text(title),
            content: Text(message),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                    ..pop() // Close dialog
                    ..pop(); // Close PIN modal
                },
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF001f3e),
        elevation: 0,
        title: const Text(
          'Buy Data Bundle',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF001f3e).withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecentTransactions(
                  recentType: 'Data Purchase',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Network',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF001f3e),
                            ),
                          ),
                          BeneficiarySelector(
                            type: 'data',
                            phoneController: _phoneController,
                            isToggled: beneficiary_toggle,
                            updateToggle: updateBeneficiaryToggle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          NetworkSelect(
                            imageUrl: 'assets/mtn.png',
                            name: 'MTN',
                            isSelected: _selectedNetwork == 1,
                            onTap: () => selectNetwork('MTN', 1),
                          ),
                          NetworkSelect(
                            imageUrl: 'assets/glo.png',
                            name: 'GLO',
                            isSelected: _selectedNetwork == 2,
                            onTap: () => selectNetwork('GLO', 2),
                          ),
                          NetworkSelect(
                            imageUrl: 'assets/airtel.webp',
                            name: 'Airtel',
                            isSelected: _selectedNetwork == 3,
                            onTap: () => selectNetwork('Airtel', 3),
                          ),
                          NetworkSelect(
                            imageUrl: 'assets/nmobile.png',
                            name: '9mobile',
                            isSelected: _selectedNetwork == 4,
                            onTap: () => selectNetwork('9mobile', 4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phone Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter phone number',
                              hintStyle: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.phone_rounded,
                                color: Color(0xFF001f3e),
                              ),
                              filled: true,
                              fillColor:
                                  const Color(0xFF001f3e).withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      const Color(0xFF001f3e).withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF001f3e),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          BeneficiaryToggle(
                            phone: _phone,
                            isToggled: beneficiary_toggle,
                            updateToggle: updateBeneficiaryToggle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ... rest of the widgets ...

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      FetchPlan(
                        type: 'data',
                        network: _selectedNetwork ?? 1,
                        onPlanSelected: (plan) {
                          setState(() {
                            _selectedPlan = plan;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (_phoneController.text.isNotEmpty &&
                              _selectedPlan != null &&
                              _selectedNetwork != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) => InputPin(
                                onProceed: (pin) async {
                                  try {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final token =
                                        prefs.getString('token') ?? '';

                                    final response = await http.post(
                                      Uri.parse(
                                          'https://vtubiz.com/api/purchase/buydata'),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization': 'Bearer $token',
                                      },
                                      body: jsonEncode({
                                        'phone_number': _phoneController.text,
                                        'network': _selectedNetwork,
                                        'plan': _selectedPlan?['plan_id'],
                                        'pin': pin,
                                      }),
                                    );

                                    final responseData =
                                        jsonDecode(response.body);

                                    if (!mounted) return;

                                    if (response.statusCode == 200) {
                                      if (responseData['success'] == true) {
                                        _showResultDialog(
                                          'Success',
                                          responseData['message'] ??
                                              'Purchase Successful!',
                                          true,
                                        );
                                      } else {
                                        _showResultDialog(
                                          'Transaction Failed',
                                          responseData['message'] ??
                                              'Transaction failed',
                                          false,
                                        );
                                      }
                                    } else {
                                      _showResultDialog(
                                        'Network Error',
                                        'Network error. Please try again.',
                                        false,
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    _showResultDialog(
                                      'Error',
                                      'An error occurred: $e',
                                      false,
                                    );
                                  }
                                },
                                onCancel: () => Navigator.pop(context),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields!'),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001f3e),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Your existing onPressed logic
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF001f3e),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(
                              color: Color(0xFF001f3e),
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Buy Later',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
