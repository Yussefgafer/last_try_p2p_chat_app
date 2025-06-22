import 'package:flutter/material.dart';
import '../../data/services/language_service.dart';

/// Screen for language settings
class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguageService _languageService = LanguageService();
  String _currentLanguage = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    try {
      final language = await _languageService.getCurrentLanguage();
      setState(() {
        _currentLanguage = language;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _changeLanguage(String languageCode) async {
    if (languageCode == _currentLanguage) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _languageService.setLanguage(languageCode);
      setState(() {
        _currentLanguage = languageCode;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLanguageChangeMessage(languageCode)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Restart app to apply language changes
        _showRestartDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change language: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getLanguageChangeMessage(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return 'تم تغيير اللغة إلى العربية';
      case 'ar_EG':
        return 'اتغيرت اللغة للمصري';
      default:
        return 'Language changed to English';
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_getDialogTitle()),
        content: Text(_getDialogContent()),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text(_getDialogButton()),
          ),
        ],
      ),
    );
  }

  String _getDialogTitle() {
    switch (_currentLanguage) {
      case 'ar':
        return 'إعادة تشغيل مطلوبة';
      case 'ar_EG':
        return 'لازم تعيد تشغيل التطبيق';
      default:
        return 'Restart Required';
    }
  }

  String _getDialogContent() {
    switch (_currentLanguage) {
      case 'ar':
        return 'يرجى إعادة تشغيل التطبيق لتطبيق تغيير اللغة.';
      case 'ar_EG':
        return 'لازم تقفل التطبيق وتفتحه تاني عشان اللغة تتغير.';
      default:
        return 'Please restart the app to apply the language change.';
    }
  }

  String _getDialogButton() {
    switch (_currentLanguage) {
      case 'ar':
        return 'موافق';
      case 'ar_EG':
        return 'تمام';
      default:
        return 'OK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRTL = _currentLanguage.startsWith('ar');

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getScreenTitle()),
          leading: IconButton(
            icon: Icon(isRTL ? Icons.arrow_forward : Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      _getHeaderText(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _getSubHeaderText(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Language Options
                    ...LanguageService.supportedLanguages.map((language) {
                      return _buildLanguageOption(
                        language: language,
                        isSelected: _currentLanguage == language.code,
                        onTap: () => _changeLanguage(language.code),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 32),
                    
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getInfoText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required SupportedLanguage language,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(
          language.flag,
          style: const TextStyle(fontSize: 24),
        ),
        title: Text(
          language.nativeName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          language.name,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
              )
            : null,
        onTap: onTap,
        selected: isSelected,
        selectedTileColor: theme.colorScheme.primary.withOpacity(0.1),
      ),
    );
  }

  String _getScreenTitle() {
    switch (_currentLanguage) {
      case 'ar':
        return 'إعدادات اللغة';
      case 'ar_EG':
        return 'إعدادات اللغة';
      default:
        return 'Language Settings';
    }
  }

  String _getHeaderText() {
    switch (_currentLanguage) {
      case 'ar':
        return 'اختر لغة التطبيق';
      case 'ar_EG':
        return 'اختار لغة التطبيق';
      default:
        return 'Choose App Language';
    }
  }

  String _getSubHeaderText() {
    switch (_currentLanguage) {
      case 'ar':
        return 'يمكنك تغيير لغة واجهة التطبيق من هنا';
      case 'ar_EG':
        return 'تقدر تغير لغة التطبيق من هنا';
      default:
        return 'You can change the app interface language here';
    }
  }

  String _getInfoText() {
    switch (_currentLanguage) {
      case 'ar':
        return 'سيتم إعادة تشغيل التطبيق تلقائياً لتطبيق تغيير اللغة. جميع النصوص والواجهات ستتغير للغة المختارة.';
      case 'ar_EG':
        return 'التطبيق هيتعيد تشغيل لوحده عشان اللغة تتغير. كل الكلام والشاشات هتبقى باللغة اللي اخترتها.';
      default:
        return 'The app will restart automatically to apply the language change. All text and interfaces will change to the selected language.';
    }
  }
}
