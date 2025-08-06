import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../settings_provider.dart';
import '../../localization.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(Localization.of(context, 'settings')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(Localization.of(context, 'dark_mode')),
              value: settings.isDark,
              onChanged: (value) {
                settings.toggleTheme(value);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(Localization.of(context, 'language') + ': ',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: settings.language,
                  items: [
                    DropdownMenuItem(
                      value: 'Français',
                      child: Text(Localization.of(context, 'french')),
                    ),
                    DropdownMenuItem(
                      value: 'English',
                      child: Text(Localization.of(context, 'english')),
                    ),
                    DropdownMenuItem(
                      value: 'العربية',
                      child: Text(Localization.of(context, 'arabic')),
                    ),
                  ],
                  onChanged: (lang) {
                    if (lang != null) {
                      settings.changeLanguage(lang);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
