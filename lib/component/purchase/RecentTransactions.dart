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

      if (response.statusCode == 200) {
        // Handle success
        print('Transaction redone successfully : ${response.body}');
      } else {
        // Handle error
        print('Failed to redo transaction: ${response.body}');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final recentTransaction = ref.watch(getLastTransactionProvider(widget.recentType));

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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(20)),
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

