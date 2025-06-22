import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/services/gemini_service.dart';
import 'data/services/language_service.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  GeminiService().initialize();
  LanguageService().initialize();

  runApp(const P2PChatApp());
}

class P2PChatApp extends StatefulWidget {
  const P2PChatApp({super.key});

  @override
  State<P2PChatApp> createState() => _P2PChatAppState();
}

class _P2PChatAppState extends State<P2PChatApp> {
  final LanguageService _languageService = LanguageService();
  Locale? _currentLocale;

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final locale = await _languageService.getCurrentLocale();
    setState(() {
      _currentLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      locale: _currentLocale,
      supportedLocales: _languageService.getSupportedLocales(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
