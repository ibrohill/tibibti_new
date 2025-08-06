import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("Mes commandes");
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("Paramètres");
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("Support client");
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("À propos & FAQ");
  }
}

class InviteFriendScreen extends StatelessWidget {
  const InviteFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("Inviter un ami");
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildEmptyScreen("Notifications");
  }
}

Widget _buildEmptyScreen(String title) {
  return Scaffold(
    appBar: AppBar(
      title: Text(title),
      backgroundColor: Colors.teal,
    ),
    body: Center(
      child: Text(
        "$title (bientôt disponible)",
        style: const TextStyle(fontSize: 18),
      ),
    ),
  );
}
