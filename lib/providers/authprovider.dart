// import 'dart:ffi';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final authUser = StateProvider<Object>((ref) {
  return '';
});

/// Token Provider: Handles storing and retrieving token
final tokenProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
});

/// State Notifier for token management
final tokenStateProvider = StateNotifierProvider<TokenNotifier, String?>((ref) {
  return TokenNotifier();
});

class TokenNotifier extends StateNotifier<String?> {
  TokenNotifier() : super(null);

  /// Save token to SharedPreferences
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    state = token;
  }
}

/// Clear token from SharedPreferences
Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token');
}

final isLoading = StateProvider<bool>((ref) {
  return false;
});

final isLogin = StateProvider<bool>((ref) {
  return false;
});

final showError = StateProvider<bool>((ref) {
  return false;
});

final errorMessage = StateProvider<String>((ref) {
  return '';
});

// final getUserProvider = FutureProvider<Function>((ref) {
//   return (String token) {
//     return fetchUserData(
//         token);
//   };
// });

Future<Map<String, String>> fetchUserData(String token) async {
  String url = 'https://vtubiz.com/api/profile';
  final user = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (user.statusCode == 200 || user.statusCode == 201) {
    final data = jsonDecode(user.body) as Map<String, dynamic>;

    final userData = data['data'] as Map<String, dynamic>;

    // Transform to Map<String, String>
    return userData.map((key, value) => MapEntry(key, value.toString()));
  } else {
    throw Exception('Failed to fetch user data');
  }
}

Future<List<Map<String, dynamic>>> fetchTransactions(String token) async {
  String url = 'https://vtubiz.com/api/transactions';
  final user = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (user.statusCode == 200 || user.statusCode == 201) {
    final data = jsonDecode(user.body);

    final transactions = data['transactions'] as List<dynamic>;

    return transactions.map((e) => e as Map<String, dynamic>).toList();

    // Transform to Map<String, String>
  } else {
    throw Exception('Failed to fetch user data');
  }
}

Future<List<Map<String, dynamic>>> getLastTransactions(
    String token, String type) async {
  String url = 'https://vtubiz.com/api/transactions/five_transactions/$type';
  final user = await http.get(
    Uri.parse(url),
    headers: {'Authorization': 'Bearer $token'},
  );

  if (user.statusCode == 200 || user.statusCode == 201) {
    final data = jsonDecode(user.body);

    final transactions = data['transactions'] as List<dynamic>;
    print(transactions);

    return transactions.map((e) => e as Map<String, dynamic>).toList();

    // Transform to Map<String, String>
  } else {
    throw Exception('Failed to fetch user data');
  }
}

Future<List<Map<String, dynamic>>> fetchBeneficiaries(
    String token, String type) async {
  try {
    String url = 'https://vtubiz.com/api/beneficiary/$type';
    final user = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (user.statusCode == 200 || user.statusCode == 201) {
      final data = jsonDecode(user.body);

      final beneficiaries = data['data'] as List<dynamic>;
      print(beneficiaries);

      return beneficiaries.map((e) => e as Map<String, dynamic>).toList();

      // Transform to Map<String, String>
    } else {
      throw Exception('Failed to fetch beneficiaries');
    }
  } catch (e) {
    print(e);
    throw Exception('Failed to fetch beneficiaries');
  }
}

final getUserProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    return fetchUserData(token);
  } else {
    throw Exception('Token not found');
  }
});

final getTransactionProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    return fetchTransactions(token);
  } else {
    throw Exception('Token not found');
  }
});

final getLastTransactionProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, type) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    return getLastTransactions(token, type);
  } else {
    throw Exception('Token not found');
  }
});
final fetchBeneficiaryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, type) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token != null) {
    return fetchBeneficiaries(token, type);
  } else {
    throw Exception('Token not found');
  }
});
