import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/user_screen.dart';
import 'screens/pest_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DurianPestApp());
}

class DurianPestApp extends StatelessWidget {
  const DurianPestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Durian Pest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootNav(),
      onGenerateRoute: (settings) {
        if (settings.name == "/detail") {
          final code = settings.arguments as String;
          return MaterialPageRoute(builder: (_) => PestDetailScreen(code: code));
        }
        return null;
      },
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _current = 0;
  final _pages = const [
    HomeScreen(),
    DetectScreen(),
    ChatScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _current, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E9D6F), // xanh lá
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _current,
        onTap: (i) => setState(() => _current = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chính'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Quét AI'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat tư vấn'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'User'),
        ],
      ),
    );
  }
}
