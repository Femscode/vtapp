import 'package:flutter/material.dart';
import 'package:vtubiz/component/dashboard/TransactionDetails.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TransactionTable extends ConsumerStatefulWidget {
  final String selectedFilter;

  const TransactionTable({
    Key? key,
    this.selectedFilter = 'All',
  }) : super(key: key);

  @override
  _TransactionTableState createState() => _TransactionTableState();
}

class _TransactionTableState extends ConsumerState<TransactionTable> {
  final int _itemsPerPage = 10;
  int _currentPage = 1;
  late ScrollController _scrollController;
  bool _isRedoingTransaction = false;
  String? _redoingTransactionId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final userTransactionValue = ref.read(allTransactionProvider);
      userTransactionValue.whenData((transactions) {
        if (_currentPage * _itemsPerPage < transactions.length) {
          setState(() {
            _currentPage++;
          });
        }
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
                  // Refresh the transaction data after successful redo
                  if (isSuccess) {
                    ref.invalidate(allTransactionProvider);
                  }
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

  Future<void> redoTransaction(String transactionId, String pin) async {
    setState(() {
      _isRedoingTransaction = true;
      _redoingTransactionId = transactionId;
    });

    try {
      final token = await ref.read(tokenProvider.future);
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
        _showResultDialog(
          'Transaction Redone',
          responseData['message'],
          true,
        );
      } else {
        _showResultDialog(
          'Transaction Failed',
          'Failed to redo transaction: ${responseData['message']}',
          false,
        );
      }
    } catch (e) {
      _showResultDialog(
        'Transaction Failed',
        'Failed to redo transaction: ${e.toString()}',
        false,
      );
    } finally {
      setState(() {
        _isRedoingTransaction = false;
        _redoingTransactionId = null;
      });
    }
  }

  bool _canRedoTransaction(Map<String, dynamic> transaction) {
    final description = transaction['description']?.toString().toLowerCase() ?? '';
    final status = transaction['status']?.toString() ?? '';
    
    // Check if transaction is completed (status '1') and is either airtime or data
    return status == '1' && 
           (description.contains('data purchase') || 
            description.contains('airtime purchase'));
  }

  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFF001f3e).withOpacity(0.08);
      case '2':
        return const Color(0xFFF98F29).withOpacity(0.08);
      default:
        return Colors.red.withOpacity(0.08);
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFF001f3e);
      case '2':
        return const Color(0xFFF98F29);
      default:
        return const Color(0xFFD32F2F);
    }
  }

  List<Map<String, dynamic>> filterTransactions(List<dynamic> transactions) {
    if (widget.selectedFilter == 'All') {
      return List<Map<String, dynamic>>.from(transactions);
    }

    return List<Map<String, dynamic>>.from(
      transactions.where((transaction) {
        switch (widget.selectedFilter) {
          case 'Funding':
            return transaction['type'] == 'credit';
          case 'Purchases':
            return transaction['type'] != 'credit';
          default:
            return true;
        }
      }),
    );
  }

  List<Map<String, dynamic>> paginateTransactions(
      List<Map<String, dynamic>> transactions) {
    final startIndex = 0;
    final endIndex = _currentPage * _itemsPerPage;
    if (endIndex >= transactions.length) {
      return transactions;
    }
    return transactions.sublist(startIndex, endIndex);
  }

  bool get hasMoreData => false;

  @override
  Widget build(BuildContext context) {
    final userTransactionValue = ref.watch(allTransactionProvider);

    return userTransactionValue.when(
      data: (transactions) {
        final filteredTransactions = filterTransactions(transactions);
        final paginatedTransactions =
            paginateTransactions(filteredTransactions);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF001f3e).withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF001f3e).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${widget.selectedFilter} Transactions",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF001f3e),
                      ),
                    ),
                    Text(
                      "${paginatedTransactions.length} of ${filteredTransactions.length}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (filteredTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No transactions found',
                      style: TextStyle(
                        color: Color(0xFF001f3e),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: paginatedTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = paginatedTransactions[index];
                        final status = transaction["status"].toString();
                        final canRedo = _canRedoTransaction(transaction);
                        final isCurrentlyRedoing = _isRedoingTransaction && 
                            _redoingTransactionId == transaction['id'].toString();

                        return GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  TransactionDetails(transaction: transaction),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: getStatusColor(status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            transaction["title"] + (transaction['phone_number'] != null ? ' on ' + transaction['phone_number'] : ''),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF001f3e),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          transaction['description'] == 'Data purchase' ||  transaction['description'] == 'Airtime Purchase' ?
                                          Text(
                                            "Phone: ${transaction["phone_number"]}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ) : 
                                          Text(
                                            "Description: ${transaction["description"]}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          )
                                          ,
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "${transaction["type"] == 'debit' ? '-' : '+'}₦${transaction["amount"]}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: transaction["type"] == 'debit'
                                                ? const Color(0xFFC62828)
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                        if (canRedo) 
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: isCurrentlyRedoing ? null : () {
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
                                                      redoTransaction(transaction['id'].toString(), pin);
                                                    },
                                                    onCancel: () {},
                                                  );
                                                },
                                              );
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isCurrentlyRedoing 
                                                    ? Colors.grey[400]
                                                    : const Color(0xFF001f3e),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: isCurrentlyRedoing
                                                  ? Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        SizedBox(
                                                          width: 12,
                                                          height: 12,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Text(
                                                          'Processing...',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : const Text(
                                                      'Redo',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status == '1'
                                            ? 'Completed'
                                            : status == '2'
                                                ? 'Pending'
                                                : 'Failed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: getStatusTextColor(status),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      formatDate(transaction["created_at"]),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (_currentPage * _itemsPerPage <
                        filteredTransactions.length)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _currentPage++;
                              });
                            },
                            child: const Text('Load More'),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF001f3e),
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'Error: $err',
          style: const TextStyle(color: Color(0xFFC62828)),
        ),
      ),
    );
  }
}
