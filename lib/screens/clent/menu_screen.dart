import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _navigate(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Menu', style: TextStyle(fontWeight: FontWeight.bold)),
      //   centerTitle: true,
      //   backgroundColor: Colors.teal[700],
      // ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.person_crop_circle,
            title: 'Profil',
            route: '/profil',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.bag_fill,
            title: 'Mes commandes',
            route: '/orders',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.settings,
            title: 'Paramètres',
            route: '/settings',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.chat_bubble_text,
            title: 'Support client',
            route: '/support',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.info_circle,
            title: 'À propos & FAQ',
            route: '/about',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.gift_fill,
            title: 'Inviter un ami',
            route: '/invite',
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.bell_solid,
            title: 'Notifications',
            route: '/notifications',
          ),
          const Divider(height: 30),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.arrow_right_circle_fill,
            title: 'Déconnexion',
            action: () => _logout(context),
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        String? route,
        VoidCallback? action,
        Color? iconColor,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.teal.shade700),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(CupertinoIcons.chevron_forward, size: 18),
      onTap: () {
        if (action != null) {
          action();
        } else if (route != null) {
          _navigate(context, route);
        }
      },
    );
  }
}
