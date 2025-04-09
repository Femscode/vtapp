import 'package:flutter/material.dart';
import 'package:vtubiz/component/profile/CardPayment.dart';
import 'package:vtubiz/component/profile/BankTransfer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FundWallet extends StatefulWidget {
  const FundWallet({Key? key}) : super(key: key);

  @override
  State<FundWallet> createState() => _FundWalletState();
}

class _FundWalletState extends State<FundWallet> {
  final _amountController = TextEditingController();
  String? selectedPaymentType;
  Map<String, dynamic> userData = {};
  bool _isGenerating = false;
  final _bvnController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
            title: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001f3e),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 5,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isSuccess ? Colors.green : const Color(0xFF001f3e),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('https://vtubiz.com/api/user'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body);
      });
    }
  }

  void _showBvnField() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(
              controller: _bvnController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Your BVN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isGenerating
                  ? null
                  : () async {
                      setState(() => _isGenerating = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token') ?? '';
                        print(token);

                        final response = await http.post(
                          Uri.parse(
                              'https://vtubiz.com/api/profile/generate-permanent-account'),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            'bvn': _bvnController.text.trim(),
                          }),
                        );

                        print(response.body);

                        if (response.statusCode == 200) {
                          Navigator.pop(context);
                          _loadUserData(); // Refresh user data to show new account

                          _showResultDialog(
                            'Account Generated',
                            'Virtual account generated successfully!',
                            true,
                          );
                        } else {
                          _showResultDialog(
                            'Account Generated',
                            'Failed to generate a permanent account!',
                            false,
                          );
                        }
                      } catch (e) {
                        _showResultDialog(
                          'Account Generation Failed',
                          'An Error Occured, Please try again later!',
                          true,
                        );
                      } finally {
                        setState(() => _isGenerating = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001f3e),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Generate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _proceedToPayment() async {
    if (_amountController.text.isEmpty || selectedPaymentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amount = double.parse(_amountController.text);
    if (selectedPaymentType == 'card') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CardPayment(amount: amount),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BankTransfer(amount: amount),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Fund Wallet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF001f3e),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF001f3e),
              height: 5,
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enter Amount to Fund',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF001f3e),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Select Payment Method',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            child: RadioListTile(
                              title: const Text('Bank Transfer'),
                              value: 'transfer',
                              groupValue: selectedPaymentType,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentType = value.toString();
                                });
                              },
                              activeColor: const Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Card(
                            elevation: 0,
                            color: Colors.grey[50],
                            child: RadioListTile(
                              title: const Text('Credit Card'),
                              value: 'card',
                              groupValue: selectedPaymentType,
                              onChanged: (value) {
                                setState(() {
                                  selectedPaymentType = value.toString();
                                });
                              },
                              activeColor: const Color(0xFF001f3e),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _proceedToPayment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF001f3e),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Proceed to Payment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (userData['account_no'] != null)
                    Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Virtual Account Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001f3e),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              title: const Text(
                                'Account Number',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                userData['account_no'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF001f3e),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text(
                                'Bank Name',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                userData['bank_name'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF001f3e),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListTile(
                              title: const Text(
                                'Account Name',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                userData['account_name'] ?? '',
                                style: const TextStyle(
                                  color: Color(0xFF001f3e),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Card(
                      color: Colors.white, // Set the background color t
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Get Your Own Virtual Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001f3e),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '• Instant wallet funding\n• Zero transfer fees\n• Available 24/7',
                              style: TextStyle(fontSize: 16, height: 1.5),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _showBvnField,
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF001f3e),
                                ),
                                child: const Text(
                                  'Generate Permanent Account →',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
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
      ),
    );
  }
}
