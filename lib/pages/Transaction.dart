import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vtubiz/component/dashboard/Footer.dart';
import 'package:vtubiz/component/dashboard/TransactionTable.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/providers/authprovider.dart';

class Transaction extends ConsumerStatefulWidget {
  const Transaction({super.key});

  @override
  _TransactionState createState() => _TransactionState();
}

class _TransactionState extends ConsumerState<Transaction> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Funding', 'Purchases'];
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(getUserProvider);

    return userAsyncValue.when(
      data: (user) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFF001f3e),
          elevation: 0,
          title: const Text(
            'Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: user['pin'] == null
            ? const OtpScreen()
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Transactions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF001f3e),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _filters.map((filter) {
                          bool isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: isSelected,
                              label: Text(filter),
                              onSelected: (_) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              },
                              selectedColor: const Color(0xFF001f3e),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF001f3e),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? const Color(0xFF001f3e)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TransactionTable(
                        selectedFilter: _selectedFilter,
                      )
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: Footer(
          currentIndex: _selectedIndex,
          onNavigate: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF001f3e),
          ),
        ),
      ),
      error: (err, stack) => Scaffold(
        body: Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
