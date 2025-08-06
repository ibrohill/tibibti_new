import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isDark = false;
  String _language = 'Français';

  bool get isDark => _isDark;
  String get language => _language;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('darkTheme') ?? false;
    _language = prefs.getString('language') ?? 'Français';
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', value);
    notifyListeners();
  }

  Future<void> changeLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    notifyListeners();
  }
}

// Le thème sombre personnalisé pour AppBar et BottomNavigationBar
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.deepPurple[700],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.deepPurple[900],
    foregroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.white),
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Colors.deepPurple[900],
    selectedItemColor: Colors.deepPurple[300],
    unselectedItemColor: Colors.white70,
  ),
);

final ThemeData lightTheme = ThemeData.light();

class TibibtiApp extends StatelessWidget {
  const TibibtiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Tibibti',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.isDark ? ThemeMode.dark : ThemeMode.light,
      // Ajoute ici la localisation selon settings.language (à intégrer)
      // ...
      home: const Placeholder(), // remplace par ton écran d'accueil
    );
  }
}
