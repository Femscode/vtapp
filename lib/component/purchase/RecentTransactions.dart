import 'package:flutter/material.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecentTransactions extends ConsumerStatefulWidget {
  const RecentTransactions({super.key, required this.recentType});
  final String recentType;
  @override
  _RecentTransactionsState createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends ConsumerState<RecentTransactions> {
  String? pin;

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

  Future<void> redoTransaction(transactionId, String pin) async {
    try {
      final token = await ref.read(tokenProvider.future);
      print(token);
      final response = await http.post(
        Uri.parse('https://vtubiz.com/api/transactions/redo_transaction'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transaction_id': transactionId,
          'pin': pin,
        }),
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Handle success

        _showResultDialog(
          'Transaction Redone',
          responseData['message'],
          true,
        );
      } else {
        // Handle error
        _showResultDialog(
          'Transaction Failed',
          'Failed to redo transaction: ${responseData['message']}',
          false,
        );
      }
    } catch (e) {
      print(e);
      _showResultDialog(
          'Transaction Failed',
          'Failed to redo transaction: ${e.toString()}}}',
          false,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recentTransaction =
        ref.watch(getLastTransactionProvider(widget.recentType));

    return recentTransaction.when(
      data: (transactions) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: transactions.map((transaction) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) {
                            return InputPin(
                              onProceed: (pin) {
                                print('Proceeded with PIN: $pin');
                                redoTransaction(transaction['id'], pin);
                                // Add your logic for proceeding with the PIN
                              },
                              onCancel: () {
                                print('PIN input canceled');
                              },
                            );
                          },
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: 12),
                      ),
                      child: Text('Redo'),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${transaction['description']} | ',
                    ),
                    Text(
                      '${transaction['amount']} | ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
