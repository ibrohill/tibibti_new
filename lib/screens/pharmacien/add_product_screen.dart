// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:path/path.dart' as path;

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  String _description = '';
  double _price = 0.0;
  XFile? _imageFile;
  String _type = 'Comprimé';
  String _dosage = '';
  String _manufacturer = '';
  int _stock = 0;
  DateTime? _expirationDate;
  bool _isSubmitting = false;
  String? _prescriptionRequirement = 'Sans ordonnance';
  String _selectedCategory = 'Vitamine';

  // Prescription détaillée
  String _indications = '';
  String _posologie = '';
  String _contreIndications = '';
  String _effetsSecondaires = '';
  String _interactions = '';
  String _modeAdministration = '';
  String _precautions = '';

  final picker = ImagePicker();

  final List<String> _prescriptionOptions = [
    'Sans ordonnance',
    'Avec ordonnance',
    'Les deux',
  ];

  final List<String> _categoryOptions = [
    'Vitamine',
    'Antalgique',
    'Antibiotique',
    'Anti-inflammatoire',
    'Antihistaminique',
    'Antiseptique',
    'Antifongique',
    'Analgésique',
    'Antispasmodique',
    'Antidiarrhéique',
    'Probiotique',
    'Laxatif',
    'Sirop pour la toux',
    'Décongestionnant',
    'Antitussif',
    'Sédatif',
    'Complément alimentaire',
    'Produit dermatologique',
    'Produit ophtalmique',
    'Produit ORL',
    'Autres',
  ];

  final List<String> _typeOptions = ['Comprimé', 'Sirop', 'Gel', 'Pommade', 'Injection'];
  List<String> _dosageOptions = [];

  final Map<String, List<String>> dosageOptionsParType = {
    'Comprimé': ['250mg', '500mg', '1g'],
    'Sirop': ['100ml', '200ml', '500ml', '1L'],
    'Gel': ['30g', '50g', '100g'],
    'Pommade': ['20g', '40g', '80g'],
    'Injection': ['1ml', '2ml', '5ml'],
  };

  @override
  void initState() {
    super.initState();
    _dosageOptions = dosageOptionsParType[_type] ?? [];
    _dosage = _dosageOptions.isNotEmpty ? _dosageOptions.first : '';
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _imageFile = picked);
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Utilisateur non connecté");

      final fileName = path.basename(_imageFile!.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await _imageFile!.readAsBytes();
        uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(_imageFile!.path);
        uploadTask = storageRef.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      }

      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Erreur upload image : $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _expirationDate == null || _prescriptionRequirement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      final imageUrl = await _uploadImage() ?? '';
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("Utilisateur non connecté");

      await FirebaseFirestore.instance.collection('products').add({
        'name': _name,
        'description': _description,
        'price': _price,
        'type': _type,
        'dosage': _dosage,
        'manufacturer': _manufacturer,
        'stock': _stock,
        'expirationDate': Timestamp.fromDate(_expirationDate!),
        'category': _selectedCategory,
        'pharmacieId': userId,
        'createdBy': userId,
        'imageUrl': imageUrl,
        'nbCommandes': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'prescriptionRequirement': _prescriptionRequirement,
        'prescription': {
          'indications': _indications,
          'posologie': _posologie,
          'contreIndications': _contreIndications,
          'effetsSecondaires': _effetsSecondaires,
          'interactions': _interactions,
          'modeAdministration': _modeAdministration,
          'precautions': _precautions,
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médicament ajouté avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un médicament')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Center(child: _buildImage()),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Choisir une image'),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField('Nom du médicament', onSaved: (val) => _name = val!),
              _buildTextField('Prix (UM)', keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ requis';
                  if (double.tryParse(val) == null) return 'Prix invalide';
                  return null;
                },
                onSaved: (val) => _price = double.parse(val!),
              ),
              _buildDropdown('Type', _type, _typeOptions, (val) {
                setState(() {
                  _type = val!;
                  _dosageOptions = dosageOptionsParType[_type] ?? [];
                  _dosage = _dosageOptions.first;
                });
              }),
              _buildDropdown('Dosage', _dosage, _dosageOptions, (val) => setState(() => _dosage = val!)),
              _buildTextField('Fabricant', onSaved: (val) => _manufacturer = val!),
              _buildTextField('Stock', keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Champ requis';
                  if (int.tryParse(val) == null) return 'Stock invalide';
                  return null;
                },
                onSaved: (val) => _stock = int.parse(val!),
              ),
              _buildDropdown('Prescription', _prescriptionRequirement!, _prescriptionOptions,
                      (val) => setState(() => _prescriptionRequirement = val)),
              const SizedBox(height: 10),
              const SizedBox(height: 16),
              const Text("Catégorie", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              DropdownSearch<String>(
                items: _categoryOptions,
                selectedItem: _selectedCategory,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration: const InputDecoration(
                    labelText: "Choisir une catégorie",
                    border: OutlineInputBorder(),
                  ),
                ),
                popupProps: PopupProps.menu(
                  showSearchBox: true,
                  searchFieldProps: const TextFieldProps(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une catégorie',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),
                validator: (val) =>
                val == null || val.isEmpty ? 'Veuillez choisir une catégorie' : null,
              ),
              const SizedBox(height: 16),
              Text("Date d'expiration : ${_expirationDate != null ? DateFormat('dd/MM/yyyy').format(_expirationDate!) : 'Non sélectionnée'}"),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => _expirationDate = pickedDate);
                  }
                },
                child: const Text('Sélectionner une date'),
              ),
              _buildTextField('Description', maxLines: 5, keyboardType: TextInputType.multiline, onSaved: (val) => _description = val!),

              const SizedBox(height: 30),
              const Divider(),
              const Text('Prescription détaillée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              _buildTextField('Indications', maxLines: 3, onSaved: (val) => _indications = val!),
              _buildTextField('Posologie', maxLines: 3, onSaved: (val) => _posologie = val!),
              _buildTextField('Contre-indications', maxLines: 3, onSaved: (val) => _contreIndications = val!),
              _buildTextField('Effets secondaires', maxLines: 3, onSaved: (val) => _effetsSecondaires = val!),
              _buildTextField('Interactions', maxLines: 3, onSaved: (val) => _interactions = val!),
              _buildTextField('Mode d’administration', maxLines: 3, onSaved: (val) => _modeAdministration = val!),
              _buildTextField('Précautions', maxLines: 3, onSaved: (val) => _precautions = val!),

              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Enregistrer le médicament'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        String? Function(String?)? validator,
        required void Function(String?) onSaved,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ?? (val) => val == null || val.isEmpty ? 'Champ requis' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, String currentValue, List<String> options, void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null ? 'Champ requis' : null,
      ),
    );
  }

  Widget _buildImage() {
    if (_imageFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _imageFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
              return Image.memory(snapshot.data!, height: 180, fit: BoxFit.cover);
            } else {
              return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator()));
            }
          },
        );
      } else {
        final file = File(_imageFile!.path);
        return file.existsSync()
            ? Image.file(file, height: 180, fit: BoxFit.cover)
            : Image.asset('assets/images/logo1.png', height: 180);
      }
    } else {
      return Image.asset('assets/images/logo1.png', height: 180);
    }
  }
}
