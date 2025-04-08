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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Your BVN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Handle BVN submission
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF383D41),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Generate'),
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
        title: const Text('Account Funding'),
        backgroundColor: const Color(0xFF383D41),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Enter Amount',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RadioListTile(
                        title: const Text('Automatic Bank Transfer'),
                        value: 'transfer',
                        groupValue: selectedPaymentType,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentType = value.toString();
                          });
                        },
                      ),
                      RadioListTile(
                        title: const Text('Pay With Credit Card'),
                        value: 'card',
                        groupValue: selectedPaymentType,
                        onChanged: (value) {
                          setState(() {
                            selectedPaymentType = value.toString();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _proceedToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF383D41),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text('Fund Wallet'),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 32),
              if (userData['account_no'] != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Transfer to Your Virtual Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          title: const Text('Account Number'),
                          subtitle: Text(userData['account_no'] ?? ''),
                        ),
                        ListTile(
                          title: const Text('Bank Name'),
                          subtitle: Text(userData['bank_name'] ?? ''),
                        ),
                        ListTile(
                          title: const Text('Account Name'),
                          subtitle: Text(userData['account_name'] ?? ''),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Get Your Permanent Virtual Account!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('• Send any amount anytime'),
                        const Text('• Enjoy lower charges'),
                        const Text('• Experience faster funding transactions'),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _showBvnField,
                          child: const Text(
                            'Click here to generate your permanent virtual account →',
                            style: TextStyle(color: Color(0xFF383D41)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
