// lib/screens/user_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'admin_panel.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  String? _username;
  bool _isAdmin = false;

  Future<void> _load() async {
    final u = await AuthService.currentUser();
    String? name = u;
    bool admin = false;
    if (u != null) {
      try {
        final me = await AdminService.me();
        name = (me['username'] as String?) ?? u;
        admin = (me['is_admin'] == true);
      } catch (_) {}
    }
    if (mounted) setState(() { _username = name; _isAdmin = admin; });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _goLogin() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    _load();
  }

  Future<void> _goRegister() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
    _load();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = _username != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loggedIn
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xin chào, ${_username!}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_isAdmin ? 'Quyền: Admin' : 'Quyền: User'),
                  const SizedBox(height: 16),
                  if (_isAdmin)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AdminPanelScreen())),
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Mở Bảng điều khiển Admin'),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  const Text('Bạn chưa đăng nhập.'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _goLogin,
                      icon: const Icon(Icons.login),
                      label: const Text('Đăng nhập'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _goRegister,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Đăng ký'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
