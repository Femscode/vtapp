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

  void updateBeneficiaryToggle(bool value) {
    setState(() {
      beneficiary_toggle = value;
    });
  }

  void selectNetwork(String name, int id) {
    setState(() {
      _selectedNetwork = id;
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Data'),
        backgroundColor: const Color(0xFF001f3e),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF001f3e).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Network',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001f3e),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                  const Text(
                    'Select Plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001f3e),
                    ),
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Beneficiary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001f3e),
                        ),
                      ),
                      BeneficiaryToggle(
                        phone: _phone,
                        isToggled: beneficiary_toggle,
                        updateToggle: updateBeneficiaryToggle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (beneficiary_toggle)
                    BeneficiarySelector(
                      type: 'data',
                      phoneController: _phoneController,
                      isToggled: beneficiary_toggle,
                      updateToggle: updateBeneficiaryToggle,
                    )
                  else
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter Phone Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF001f3e),
                          ),
                        ),
                      ),
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
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('token') ?? '';

                                final response = await http.post(
                                  Uri.parse('https://vtubiz.com/api/purchase/buydata'),
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

                                final responseData = jsonDecode(response.body);

                                if (!mounted) return;

                                if (response.statusCode == 200) {
                                  if (responseData['success'] == true) {
                                    _showResultDialog(
                                      'Success',
                                      responseData['message'] ?? 'Purchase Successful!',
                                      true,
                                    );
                                  } else {
                                    _showResultDialog(
                                      'Transaction Failed',
                                      responseData['message'] ?? 'Transaction failed',
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const RecentTransactions(recentType: 'data',),
          ],
        ),
      ),
    );
  }
}