import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vtubiz/component/dashboard/Categories.dart';
import 'package:vtubiz/component/dashboard/DiscountBanner.dart';
import 'package:vtubiz/component/dashboard/Footer.dart';
import 'package:vtubiz/component/dashboard/TransactionTable.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/providers/authprovider.dart';
import '../component/dashboard/HomeHeader.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation or page-specific logic here if needed
    switch (index) {
      case 0:
        print('Navigate to Home');
        break;
      case 1:
        print('Navigate to Referral');
        break;
      case 2:
        print('Navigate to Fund Wallet');
        break;
      case 3:
        print('Navigate to Transactions');
        break;
      case 4:
        print('Navigate to Profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(getUserProvider);
    return userAsyncValue.when(
      data: (user) => Scaffold(
        body: user['pin'] == null ? const OtpScreen()
         :
         SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                HomeHeader(auth_user: user),
                DiscountBanner(auth_user: user),
                const Categories(),
                const SizedBox(height: 20),
                const TransactionTable(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const Footer()
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
