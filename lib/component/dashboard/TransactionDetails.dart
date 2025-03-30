import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class TransactionDetails extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetails({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy HH:mm').format(dateTime);
  }

  String getStatusText(String status) {
    switch (status) {
      case '1':
        return 'Completed';
      case '2':
        return 'Pending';
      default:
        return 'Failed';
    }
  }

  void _shareTransaction() {
    final text = '''
Transaction Details:
Description: ${transaction["description"]}
Amount: ₦${transaction["amount"]}
Reference: ${transaction["reference"]}
Status: ${getStatusText(transaction["status"].toString())}
Date: ${formatDate(transaction["created_at"])}
''';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001f3e),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Description', transaction["description"]),
          _buildDetailRow('Amount', 
            "${transaction["type"] == 'debit' ? '-' : '+'}₦${transaction["amount"]}",
            valueColor: transaction["type"] == 'debit' 
              ? const Color(0xFFC62828) 
              : const Color(0xFF2E7D32),
          ),
          _buildDetailRow('Reference', transaction["reference"]),
          _buildDetailRow('Status', getStatusText(transaction["status"].toString())),
          _buildDetailRow('Date', formatDate(transaction["created_at"])),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Add printing functionality here
                  },
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001f3e),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareTransaction,
                  icon: const Icon(Icons.share, color: Color(0xFF001f3e)),
                  label: const Text(
                    'Share',
                    style: TextStyle(color: Color(0xFF001f3e)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF001f3e)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? const Color(0xFF001f3e),
              ),
            ),
          ),
        ],
      ),
    );
  }
}