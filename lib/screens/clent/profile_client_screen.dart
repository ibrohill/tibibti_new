import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileClientScreen extends StatefulWidget {
  const ProfileClientScreen({super.key});

  @override
  State<ProfileClientScreen> createState() => _ProfileClientScreenState();
}

class _ProfileClientScreenState extends State<ProfileClientScreen> {
  final _formKey = GlobalKey<FormState>();

  User? user;
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
      }
    } catch (e) {
      // Gestion erreur si besoin
    }

    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': user!.email,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Profil')),
        body: const Center(child: Text('Aucun utilisateur connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mon Profil')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.teal.shade400,
                child: const Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),

              // Email affiché (non modifiable)
              TextFormField(
                initialValue: user!.email ?? '',
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Nom modifiable
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              const SizedBox(height: 20),

              // Téléphone modifiable
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'Veuillez entrer un téléphone' : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
