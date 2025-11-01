import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/detect_screen.dart';
import 'screens/advice_screen.dart';
import 'screens/pest_detail_screen.dart';

class AppRouter {
  static const home = '/';
  static const detect = '/detect';
  static const advice = '/advice';
  static const detail = '/detail';

  static Route<dynamic> onGenerateRoute(RouteSettings s) {
    switch (s.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case detect:
        return MaterialPageRoute(builder: (_) => const DetectScreen());
      case advice:
        return MaterialPageRoute(builder: (_) => const AdviceScreen());
      case detail:
        final code = s.arguments as String;
        return MaterialPageRoute(builder: (_) => PestDetailScreen(code: code));
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(body: Center(child: Text('Not found'))),
        );
    }
  }
}
