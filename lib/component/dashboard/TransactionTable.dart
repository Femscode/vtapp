import 'package:flutter/material.dart';
import 'package:vtubiz/component/dashboard/TransactionDetails.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      setState(() {
        _currentPage++;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final userTransactionValue = ref.watch(getTransactionProvider);

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
                SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paginatedTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = paginatedTransactions[index];
                          final status = transaction["status"].toString();

                          return GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => TransactionDetails(
                                    transaction: transaction),
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
                                              transaction["description"],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF001f3e),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Ref: ${transaction["reference"]}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                      if (paginatedTransactions.length <
                          filteredTransactions.length)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFF001f3e).withOpacity(0.5),
                            ),
                          ),
                        ),
                    ],
                  ),
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
