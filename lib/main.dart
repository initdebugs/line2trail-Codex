import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/language_notifier.dart';
import 'features/navigation/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageNotifier().init();
  runApp(const PathifyApp());
}

class PathifyApp extends StatelessWidget {
  const PathifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageNotifier(),
      child: Consumer<LanguageNotifier>(
        builder: (context, languageNotifier, child) {
          return MaterialApp(
            title: 'Pathify',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            home: const MainNavigation(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
