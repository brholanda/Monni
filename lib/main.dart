import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/accessibility_settings.dart';
import 'data/category_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_PT');
  await CategoryStore.instance.load();
  await AccessibilitySettings.instance.load();
  runApp(const MonniApp());
}

class MonniApp extends StatelessWidget {
  const MonniApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettings.instance;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) => MaterialApp(
        title: 'Monni',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: const Locale('pt', 'PT'),
        supportedLocales: const [Locale('pt', 'PT'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
