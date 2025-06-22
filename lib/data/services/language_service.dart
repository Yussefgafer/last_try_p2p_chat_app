import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

/// Service for managing app language and localization
class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  final Logger _logger = Logger();
  
  Box? _settingsBox;
  bool _isInitialized = false;
  
  static const String _languageKey = 'app_language';
  static const String _rtlKey = 'is_rtl';

  /// Supported languages
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇺🇸',
      isRTL: false,
    ),
    SupportedLanguage(
      code: 'ar',
      name: 'Arabic',
      nativeName: 'العربية',
      flag: '🇸🇦',
      isRTL: true,
    ),
    SupportedLanguage(
      code: 'ar_EG',
      name: 'Egyptian Arabic',
      nativeName: 'مصري',
      flag: '🇪🇬',
      isRTL: true,
    ),
  ];

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _settingsBox = await Hive.openBox('language_settings');
      _isInitialized = true;
      _logger.i('Language service initialized');
    } catch (e) {
      _logger.e('Failed to initialize language service: $e');
      throw Exception('Language service initialization failed: $e');
    }
  }

  /// Get current language
  Future<String> getCurrentLanguage() async {
    if (!_isInitialized) await initialize();

    try {
      return _settingsBox?.get(_languageKey, defaultValue: 'en') ?? 'en';
    } catch (e) {
      _logger.e('Failed to get current language: $e');
      return 'en';
    }
  }

  /// Set current language
  Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();

    try {
      await _settingsBox?.put(_languageKey, languageCode);
      
      // Update RTL setting
      final language = getSupportedLanguage(languageCode);
      await _settingsBox?.put(_rtlKey, language?.isRTL ?? false);
      
      _logger.i('Language set to: $languageCode');
    } catch (e) {
      _logger.e('Failed to set language: $e');
      throw Exception('Failed to set language: $e');
    }
  }

  /// Get current locale
  Future<Locale> getCurrentLocale() async {
    final languageCode = await getCurrentLanguage();
    return _parseLocale(languageCode);
  }

  /// Check if current language is RTL
  Future<bool> isRTL() async {
    if (!_isInitialized) await initialize();

    try {
      return _settingsBox?.get(_rtlKey, defaultValue: false) ?? false;
    } catch (e) {
      _logger.e('Failed to get RTL setting: $e');
      return false;
    }
  }

  /// Get supported language by code
  SupportedLanguage? getSupportedLanguage(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get all supported locales
  List<Locale> getSupportedLocales() {
    return supportedLanguages.map((lang) => _parseLocale(lang.code)).toList();
  }

  /// Parse language code to Locale
  Locale _parseLocale(String languageCode) {
    if (languageCode.contains('_')) {
      final parts = languageCode.split('_');
      return Locale(parts[0], parts[1]);
    }
    return Locale(languageCode);
  }

  /// Get language name in current language
  String getLanguageName(String languageCode, String currentLanguage) {
    final language = getSupportedLanguage(languageCode);
    if (language == null) return languageCode;

    // Return native name for better UX
    return language.nativeName;
  }

  /// Get text direction for language
  TextDirection getTextDirection(String languageCode) {
    final language = getSupportedLanguage(languageCode);
    return (language?.isRTL ?? false) ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Check if language is supported
  bool isLanguageSupported(String languageCode) {
    return supportedLanguages.any((lang) => lang.code == languageCode);
  }

  /// Get device language if supported
  String getDeviceLanguage() {
    try {
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final deviceLanguageCode = '${deviceLocale.languageCode}_${deviceLocale.countryCode}';
      
      // Check for exact match first (e.g., ar_EG)
      if (isLanguageSupported(deviceLanguageCode)) {
        return deviceLanguageCode;
      }
      
      // Check for language only (e.g., ar)
      if (isLanguageSupported(deviceLocale.languageCode)) {
        return deviceLocale.languageCode;
      }
      
      // Default to English
      return 'en';
    } catch (e) {
      _logger.w('Failed to get device language: $e');
      return 'en';
    }
  }

  /// Auto-detect and set language based on device
  Future<void> autoDetectLanguage() async {
    try {
      final deviceLanguage = getDeviceLanguage();
      await setLanguage(deviceLanguage);
      _logger.i('Auto-detected language: $deviceLanguage');
    } catch (e) {
      _logger.e('Failed to auto-detect language: $e');
      // Fallback to English
      await setLanguage('en');
    }
  }

  /// Get language statistics
  Map<String, dynamic> getLanguageStats() {
    return {
      'supportedLanguages': supportedLanguages.length,
      'rtlLanguages': supportedLanguages.where((lang) => lang.isRTL).length,
      'ltrLanguages': supportedLanguages.where((lang) => !lang.isRTL).length,
      'currentLanguage': getCurrentLanguage(),
      'deviceLanguage': getDeviceLanguage(),
    };
  }

  /// Reset to default language
  Future<void> resetToDefault() async {
    await setLanguage('en');
    _logger.i('Language reset to default (English)');
  }

  /// Dispose service
  Future<void> dispose() async {
    try {
      await _settingsBox?.close();
      _isInitialized = false;
      _logger.i('Language service disposed');
    } catch (e) {
      _logger.e('Error disposing language service: $e');
    }
  }
}

/// Model for supported language
class SupportedLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String flag;
  final bool isRTL;

  const SupportedLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.isRTL,
  });

  @override
  String toString() {
    return 'SupportedLanguage(code: $code, name: $name, nativeName: $nativeName, isRTL: $isRTL)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is SupportedLanguage &&
        other.code == code &&
        other.name == name &&
        other.nativeName == nativeName &&
        other.flag == flag &&
        other.isRTL == isRTL;
  }

  @override
  int get hashCode {
    return code.hashCode ^
        name.hashCode ^
        nativeName.hashCode ^
        flag.hashCode ^
        isRTL.hashCode;
  }
}
