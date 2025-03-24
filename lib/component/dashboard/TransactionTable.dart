import 'package:flutter/material.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionTable extends ConsumerStatefulWidget {
  const TransactionTable({super.key});

  @override
  _TransactionTableState createState() => _TransactionTableState();
}

class _TransactionTableState extends ConsumerState<TransactionTable> {
  // Helper function to format the date
  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }
  // Update the status color function for better visual feedback
    Color getStatusColor(String status) {
    switch (status) {
      case '1': // Completed
        return const Color(0xFF001f3e).withOpacity(0.08);  // Very light navy
      case '2': // Pending
        return const Color(0xFFF98F29).withOpacity(0.08);  // Very light orange
      default: // Failed
        return Colors.red.withOpacity(0.08);  // Very light red
    }
  }

  Color getStatusTextColor(String status) {
    switch (status) {
      case '1': // Completed
        return const Color(0xFF001f3e);  // Navy blue
      case '2': // Pending
        return const Color(0xFFF98F29);  // Orange
      default: // Failed
        return const Color(0xFFD32F2F);  // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final userTransactionValue = ref.watch(getTransactionProvider);
    return userTransactionValue.when(
      data: (transactions) => Container(
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
        // ... rest of the code remains the same ...
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transaction History",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF001f3e),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Handle view more
                    },
                    child: const Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF001f3e),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final status = transaction["status"].toString();
                return Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                );
              },
            ),
          ],
        ),
      ),
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
