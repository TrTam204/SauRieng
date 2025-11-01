// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static Future<bool> login(String username, String password) async {
    final uri = Uri.parse('${ApiService.base}/auth/login');
    final res = await http.post(uri, body: {
      'username': username,
      'password': password,
    }).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Login failed ${res.statusCode}');
    final ok = (jsonDecode(res.body)['ok'] == true);
    if (ok) {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('username', username);
    }
    return ok;
  }

  static Future<bool> register(String username, String password) async {
    final uri = Uri.parse('${ApiService.base}/auth/register');
    final res = await http.post(uri, body: {
      'username': username,
      'password': password,
    }).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Register failed ${res.statusCode}');
    final ok = (jsonDecode(res.body)['ok'] == true);
    return ok;
  }

  static Future<String?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('username');
  }

  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('username');
  }
}
