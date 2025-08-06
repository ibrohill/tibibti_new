import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';


class ParametresPharmacienScreen extends StatefulWidget {
  const ParametresPharmacienScreen({Key? key}) : super(key: key);

  @override
  State<ParametresPharmacienScreen> createState() => _ParametresPharmacienScreenState();
}

class _ParametresPharmacienScreenState extends State<ParametresPharmacienScreen> {
  final _auth = FirebaseAuth.instance;

  bool _notificationsEnabled = true;
  bool _isDarkTheme = false;
  String _language = 'fr';
  String _appVersion = '1.0.0';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _isDarkTheme = prefs.getBool('darkTheme') ?? false;
      _language = prefs.getString('language') ?? 'fr';
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('darkTheme', _isDarkTheme);
    await prefs.setString('language', _language);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres enregistrés localement')),
    );
  }

  Future<void> _changePassword() async {
    Navigator.pushNamed(context, '/change_password');
  }

  Future<void> _deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression compte: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Général',
            children: [
              SwitchListTile(
                title: const Text('Notifications'),
                secondary: const Icon(Icons.notifications),
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
              ),
              SwitchListTile(
                title: const Text('Thème sombre'),
                secondary: const Icon(Icons.dark_mode),
                value: Provider.of<ThemeProvider>(context).isDark,
                onChanged: (val) {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme(val);
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Langue'),
                trailing: DropdownButton<String>(
                  value: _language,
                  items: const [
                    DropdownMenuItem(value: 'fr', child: Text('Français')),
                    DropdownMenuItem(value: 'en', child: Text('Anglais')),
                  ],
                  onChanged: (val) => setState(() => _language = val!),
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'Sécurité',
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Changer mot de passe'),
                onTap: _changePassword,
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Authentification 2FA'),
                subtitle: const Text('Bientôt disponible'),
              ),
            ],
          ),
          _sectionCard(
            title: 'Compte',
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Voir mon profil'),
                onTap: () => Navigator.pushNamed(context, '/profil_pharmacien'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Se déconnecter'),
                onTap: () async {
                  await _auth.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Supprimer mon compte'),
                onTap: _deleteAccount,
              ),
            ],
          ),
          _sectionCard(
            title: 'À propos',
            children: [
              ListTile(
                leading: const Icon(Icons.info),
                title: Text('Version $_appVersion'),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Mentions légales / Conditions'),
                onTap: () => Navigator.pushNamed(context, '/mentions_legales'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer les paramètres'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            ListTile(
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...children
          ],
        ),
      ),
    );
  }
}
