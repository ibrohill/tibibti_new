import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdonnanceUploadScreen extends StatefulWidget {
  const OrdonnanceUploadScreen({Key? key}) : super(key: key);

  @override
  State<OrdonnanceUploadScreen> createState() => _OrdonnanceUploadScreenState();
}

class _OrdonnanceUploadScreenState extends State<OrdonnanceUploadScreen> {
  File? _image;
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  String? _selectedPharmacyId;
  List<Map<String, dynamic>> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pharmacies').get();
      setState(() {
        _pharmacies = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Pharmacie sans nom',
          };
        }).toList();

        if (_pharmacies.isNotEmpty) {
          _selectedPharmacyId = _pharmacies.first['id'];
        }
      });
    } catch (e) {
      // En cas d'erreur, on peut afficher un message ou gérer autrement
      debugPrint("Erreur chargement pharmacies: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 85);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadOrdonnance() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une image")),
      );
      return;
    }

    if (_selectedPharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une pharmacie")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      String imageUrl;

      // Si pas de Storage configuré, on met une image exemple fixe (URL publique)
      imageUrl = 'https://via.placeholder.com/150.png?text=Ordonnance+exemple';

      // --- Upload Storage à décommenter si configuré ---
      /*
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('ordonnances').child('$fileName.jpg');
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
      */

      await FirebaseFirestore.instance.collection('ordonnances').add({
        'userId': user?.uid,
        'imageUrl': imageUrl,
        'note': _noteController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'en_attente',
        'pharmacyId': _selectedPharmacyId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordonnance envoyée avec succès')),
      );

      setState(() {
        _image = null;
        _noteController.clear();
        _isLoading = false;
        _selectedPharmacyId = _pharmacies.isNotEmpty ? _pharmacies.first['id'] : null;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Envoyer une ordonnance"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 12),

            // Sélecteur pharmacie
            DropdownButtonFormField<String>(
              value: _selectedPharmacyId,
              decoration: const InputDecoration(
                labelText: 'Choisissez une pharmacie',
                border: OutlineInputBorder(),
              ),
              items: _pharmacies.map((pharma) {
                return DropdownMenuItem<String>(
                  value: pharma['id'],
                  child: Text(pharma['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPharmacyId = value;
                });
              },
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo),
                  label: const Text("Galerie"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Caméra"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Remarques (facultatif)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _uploadOrdonnance,
              child: const Text("Envoyer l’ordonnance"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
