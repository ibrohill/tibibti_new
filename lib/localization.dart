import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'settings_provider.dart';

class Localization {
  static const Map<String, Map<String, String>> _localizedValues = {
    'fr': {
      'settings': 'Paramètres',
      'dark_mode': 'Mode sombre',
      'language': 'Langue',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'العربية',
    },
    'en': {
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'english': 'English',
      'french': 'French',
      'arabic': 'Arabic',
    },
    'ar': {
      'settings': 'الإعدادات',
      'dark_mode': 'الوضع الداكن',
      'language': 'اللغة',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
    },
  };

  static String of(BuildContext context, String key) {
    final lang = Provider.of<SettingsProvider>(context).language;
    final localeCode = lang == 'Français'
        ? 'fr'
        : lang == 'English'
        ? 'en'
        : 'ar';
    return _localizedValues[localeCode]?[key] ?? key;
  }
}
