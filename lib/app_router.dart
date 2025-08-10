import 'package:flutter/material.dart';
import 'package:mitram/screens/auth/login_screen.dart';
import 'package:mitram/screens/auth/signup_screen.dart';
import 'package:mitram/screens/home_screen.dart';
import 'package:mitram/screens/diagnose_screen.dart'; // Import DiagnoseScreen
import 'package:mitram/main.dart'; // Import AuthWrapper

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case SignUpScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case HomeScreen.routeName:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case DiagnoseScreen.routeName: // Add DiagnoseScreen route
        return MaterialPageRoute(builder: (_) => const DiagnoseScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}