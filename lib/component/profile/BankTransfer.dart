import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BankTransfer extends StatefulWidget {
  final double amount;

  const BankTransfer({Key? key, required this.amount}) : super(key: key);

  @override
  State<BankTransfer> createState() => _BankTransferState();
}

class _BankTransferState extends State<BankTransfer> {
  Map<String, dynamic> accountDetails = {};
  int timeLeft = 1800; // 30 minutes in seconds
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _generateVirtualAccount();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          _timer.cancel();
          Navigator.pop(context);
        }
      });
    });
  }

  Future<void> _generateVirtualAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/profile/generate-virtual-account'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': widget.amount,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          accountDetails = jsonDecode(response.body)['data'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate account details')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Transfer'),
        backgroundColor: const Color(0xFF383D41),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank Transfer Guidelines',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time Remaining: ${timeLeft ~/ 60}:${(timeLeft % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('• Transfer only the exact amount stated below'),
                    const Text('• Account details expire after 30 minutes'),
                    const Text('• Account name must begin with VTUBIZ'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Account Number'),
                      subtitle: Text(accountDetails['account_number'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(
                            text: accountDetails['account_number'] ?? '',
                          ));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account number copied!'),
                            ),
                          );
                        },
                      ),
                    ),
                    ListTile(
                      title: const Text('Bank Name'),
                      subtitle: Text(accountDetails['bank_name'] ?? ''),
                    ),
                    ListTile(
                      title: const Text('Amount'),
                      subtitle: Text(
                        'NGN ${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
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
    );
  }
}