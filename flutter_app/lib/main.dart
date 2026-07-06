import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/parkeasy_theme.dart';

void main() => runApp(const ParkEasy());

class ParkEasy extends StatelessWidget {
  const ParkEasy({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "SRM ParkEasy",
      debugShowCheckedModeBanner: false,
      theme: ParkEasyTheme.lightTheme(),
      home: const LoginScreen(),
    );
  }
}
