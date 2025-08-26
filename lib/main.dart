import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/navigation/screens/main_navigation.dart';

void main() {
  runApp(const Line2TrailApp());
}

class Line2TrailApp extends StatelessWidget {
  const Line2TrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Line2Trail',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}
