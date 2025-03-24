
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding


class AuthUserNotifier extends StateNotifier<Object> {
  AuthUserNotifier() : super('') {
    _loadAuthUser();
  }

  Future<void> _loadAuthUser() async {
    final prefs = await SharedPreferences.getInstance();
    final authUserString = prefs.getString('authUser');
    if (authUserString != null) {
      state = jsonDecode(authUserString);
    }
  }

  Future<void> updateAuthUser(Object user) async {
    state = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authUser', jsonEncode(user));
  }

  Future<void> clearAuthUser() async {
    state = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authUser');
  }
}
