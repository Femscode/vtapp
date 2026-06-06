import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vtubiz/pages/AuthScreen.dart';
import 'package:vtubiz/pages/Dashboard.dart';
import 'package:vtubiz/providers/authprovider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsyncValue = ref.watch(tokenProvider);
    return MaterialApp(
      title: 'VTUBIZ',
      theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFFAFBFD),
          primarySwatch: const MaterialColor(0xFFFFECDF, {
            50: Color(0xFFFFECDF),
            100: Color(0xFFFFD8BF),
            200: Color(0xFFFFC39F),
            300: Color(0xFFFFAE7F),
            400: Color(0xFFFF9A5F),
            500: Color(0xFFFFECDF),
            600: Color(0xFFFFD8BF),
            700: Color(0xFFFFC39F),
            800: Color(0xFFFFAE7F),
            900: Color(0xFFFF9A5F),
          }),
          textTheme: GoogleFonts.plusJakartaSansTextTheme()),
      home: tokenAsyncValue.when(
        data: (token) => token != null ? const Dashboard() : AuthScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          body: Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}
