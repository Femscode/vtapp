import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vtubiz/component/dashboard/Categories.dart';
import 'package:vtubiz/component/dashboard/DiscountBanner.dart';
import 'package:vtubiz/component/dashboard/Footer.dart';
import 'package:vtubiz/component/dashboard/TransactionTable.dart';
import 'package:vtubiz/pages/FundWallet.dart';
import 'package:vtubiz/pages/OtpScreen.dart';
import 'package:vtubiz/pages/Profile.dart';
import 'package:vtubiz/pages/Referral.dart';
import 'package:vtubiz/pages/Transaction.dart';
import 'package:vtubiz/providers/authprovider.dart';
import '../component/dashboard/HomeHeader.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> with RouteAware {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Refresh data when dashboard is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardData();
    });
  }

  @override
  void didPopNext() {
    // This is called when returning to this page from another page
    super.didPopNext();
    _refreshDashboardData();
  }

  void _refreshDashboardData() {
    // Invalidate providers to refresh data
    ref.invalidate(getUserProvider);
    ref.invalidate(getTransactionProvider);
    ref.invalidate(allTransactionProvider);
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      // If already on dashboard, refresh the data
      if (_selectedIndex == 0) {
        _refreshDashboardData();
      }
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation to other pages
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Referral()),
        ).then((_) {
          // Refresh when returning from Referral page
          _refreshDashboardData();
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FundWallet()),
        ).then((_) {
          // Refresh when returning from FundWallet page
          _refreshDashboardData();
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Transaction()),
        ).then((_) {
          // Refresh when returning from Transaction page
          _refreshDashboardData();
        });
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        ).then((_) {
          // Refresh when returning from Profile page
          _refreshDashboardData();
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(getUserProvider);
    return userAsyncValue.when(
      data: (user) => Scaffold(
        body: user['pin'] == null
            ? const OtpScreen()
            : RefreshIndicator(
                onRefresh: () async {
                  _refreshDashboardData();
                  // Wait a bit for the providers to refresh
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                color: const Color(0xFF001f3e),
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        HomeHeader(
                          auth_user: user,
                          onRefresh: _refreshDashboardData,
                        ),
                        DiscountBanner(auth_user: user),
                        const Categories(),
                        const SizedBox(height: 20),
                        const TransactionTable(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: Footer(
          currentIndex: _selectedIndex,
          onNavigate: _onItemTapped,
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
