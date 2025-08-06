import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      'title': 'Tibibti',
      'home': 'Home',
      'settings': 'Settings',
      'ordonance': 'Ordonance',
    },
    'fr': {
      'title': 'Tibibti',
      'home': 'Accueil',
      'settings': 'Paramètres',
      'ordonance': 'Ordonance',
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get ordonance => _localizedValues[locale.languageCode]!['ordonance']!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
