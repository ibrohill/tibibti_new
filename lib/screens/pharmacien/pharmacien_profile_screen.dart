// pharmacien_profile_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PharmacienProfileScreen extends StatefulWidget {
  const PharmacienProfileScreen({super.key});

  @override
  State<PharmacienProfileScreen> createState() => _PharmacienProfileScreenState();
}

class _PharmacienProfileScreenState extends State<PharmacienProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _categorieController = TextEditingController();
  final _descriptionController = TextEditingController();
  List<String> _services = [];

  final List<String> _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
  final List<String> _joursSelectionnes = [];
  TimeOfDay? _heureOuverture;
  TimeOfDay? _heureFermeture;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _profileImageFile;
  String? _profileImageUrl;

  bool _loading = true;
  bool _showPasswordSection = false;
  bool _savingProfile = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final doc = await _firestore.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null) {
          _nameController.text = data['name'] ?? '';
          _pharmacyNameController.text = data['pharmacyName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _categorieController.text = data['categorie'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _services = List<String>.from(data['services'] ?? []);
          _profileImageUrl = data['profileImageUrl'];

          if (data['schedule'] != null) {
            final schedule = data['schedule'] as Map<String, dynamic>;
            _joursSelectionnes.addAll(List<String>.from(schedule['jours'] ?? []));
            _heureOuverture = _parseTime(schedule['ouverture'] ?? '');
            _heureFermeture = _parseTime(schedule['fermeture'] ?? '');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur chargement profil: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  TimeOfDay? _parseTime(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 600);
      if (picked != null) {
        setState(() => _profileImageFile = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sélection image : $e')));
    }
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _savingProfile = true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'pharmacyName': _pharmacyNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'categorie': _categorieController.text.trim(),
        'description': _descriptionController.text.trim(),
        'services': _services,
        'profileImageUrl': _profileImageUrl,
        'schedule': {
          'jours': _joursSelectionnes,
          'ouverture': _heureOuverture?.format(context) ?? '',
          'fermeture': _heureFermeture?.format(context) ?? '',
        },
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur sauvegarde : $e')));
    } finally {
      setState(() => _savingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pharmacien'), backgroundColor: Colors.teal),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: _profileImageFile != null
                  ? FileImage(_profileImageFile!)
                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                  ? NetworkImage(_profileImageUrl!) as ImageProvider
                  : null,
              child: (_profileImageFile == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            TextButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Changer photo'),
            ),
            _buildInput(label: 'Nom complet', icon: Icons.person, controller: _nameController),
            _buildInput(label: 'Nom de la pharmacie', icon: Icons.local_pharmacy, controller: _pharmacyNameController),
            _buildInput(label: 'Téléphone', icon: Icons.phone, controller: _phoneController),
            _buildInput(label: 'Adresse', icon: Icons.location_on, controller: _addressController),
            _buildInput(label: 'Catégorie', icon: Icons.category, controller: _categorieController),
            _buildInput(label: 'Description', icon: Icons.description, controller: _descriptionController),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Jours d'ouverture", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
            ),
            Column(
              children: _jours.map((jour) {
                return CheckboxListTile(
                  title: Text(jour),
                  value: _joursSelectionnes.contains(jour),
                  onChanged: (val) {
                    setState(() {
                      val!
                          ? _joursSelectionnes.add(jour)
                          : _joursSelectionnes.remove(jour);
                    });
                  },
                );
              }).toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _heureOuverture ?? TimeOfDay(hour: 9, minute: 0),
                      );
                      if (time != null) setState(() => _heureOuverture = time);
                    },
                    child: Text(_heureOuverture != null
                        ? 'Ouvre : ${_heureOuverture!.format(context)}'
                        : 'Choisir heure ouverture'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _heureFermeture ?? TimeOfDay(hour: 18, minute: 0),
                      );
                      if (time != null) setState(() => _heureFermeture = time);
                    },
                    child: Text(_heureFermeture != null
                        ? 'Ferme : ${_heureFermeture!.format(context)}'
                        : 'Choisir heure fermeture'),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput({required String label, required IconData icon, required TextEditingController controller, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pharmacyNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _categorieController.dispose();
    _descriptionController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
