import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vtubiz/component/dashboard/TransactionDetails.dart';
import 'package:vtubiz/component/purchase/InputPin.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vtubiz/config.dart';


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
        Uri.parse('${AppConfig.liveUrl}/transactions/redo_transaction'),

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
    return Colors.white;
  }

  Color getStatusBadgeColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFFE2F9EC); // soft green
      case '2':
        return const Color(0xFFFFF4E5); // soft orange
      default:
        return const Color(0xFFFFEBEB); // soft red
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case '1':
        return const Color(0xFF1B8749); // bold green
      case '2':
        return const Color(0xFFD97706); // bold orange/amber
      default:
        return const Color(0xFFE53E3E); // bold red
    }
  }

  Widget getTransactionIcon(Map<String, dynamic> transaction) {
    final description = transaction['description']?.toString().toLowerCase() ?? '';
    final type = transaction['type']?.toString().toLowerCase() ?? '';
    
    IconData iconData = Icons.payment_rounded;
    Color iconColor = const Color(0xFF001F3E);
    Color bgColor = const Color(0xFFF1F5F9);
    
    if (type == 'credit') {
      iconData = Icons.arrow_downward_rounded;
      iconColor = const Color(0xFF1B8749);
      bgColor = const Color(0xFFE2F9EC);
    } else if (description.contains('data')) {
      iconData = Icons.wifi_rounded;
      iconColor = const Color(0xFF0A84FF);
      bgColor = const Color(0xFFE5F1FF);
    } else if (description.contains('airtime')) {
      iconData = Icons.phone_rounded;
      iconColor = const Color(0xFF00D2FF);
      bgColor = const Color(0xFFE0FAFF);
    } else if (description.contains('electric') || description.contains('power')) {
      iconData = Icons.electric_bolt_rounded;
      iconColor = const Color(0xFFFFB300);
      bgColor = const Color(0xFFFFF8E5);
    } else if (description.contains('cable') || description.contains('tv')) {
      iconData = Icons.tv_rounded;
      iconColor = const Color(0xFFBF5AF2);
      bgColor = const Color(0xFFF9EFFF);
    } else if (description.contains('refer')) {
      iconData = Icons.people_rounded;
      iconColor = const Color(0xFF34C759);
      bgColor = const Color(0xFFEAF9EC);
    } else if (description.contains('exam') || description.contains('result')) {
      iconData = Icons.school_rounded;
      iconColor = const Color(0xFF5E5CE6);
      bgColor = const Color(0xFFECECFF);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 18,
      ),
    );
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
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF001f3e).withOpacity(0.04),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF001f3e).withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${widget.selectedFilter} Transactions",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF001f3e),
                      ),
                    ),
                    Text(
                      "${paginatedTransactions.length} of ${filteredTransactions.length}",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (filteredTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No transactions found',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF001f3e),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF001f3e).withOpacity(0.06),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.015),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Category Icon
                                getTransactionIcon(transaction),
                                const SizedBox(width: 12),
                                // Middle section: Title & Time
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction["title"] + (transaction['phone_number'] != null ? ' on ' + transaction['phone_number'] : ''),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF001f3e),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatDate(transaction["created_at"]),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Right section: Amount & Badge / Redo
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "${transaction["type"] == 'debit' ? '-' : '+'}₦${transaction["amount"]}",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: transaction["type"] == 'debit'
                                            ? const Color(0xFFFF2D55)
                                            : const Color(0xFF34C759),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (canRedo) ...[
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
                                              margin: const EdgeInsets.only(right: 6),
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
                                                          width: 10,
                                                          height: 10,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 1.5,
                                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      'Redo',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                        // Badge Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: getStatusBadgeColor(status),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            status == '1'
                                                ? 'Completed'
                                                : status == '2'
                                                    ? 'Pending'
                                                    : 'Failed',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: getStatusTextColor(status),
                                            ),
                                          ),
                                        ),
                                      ],
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
                            child: Text(
                              'Load More',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF001f3e),
                              ),
                            ),
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
