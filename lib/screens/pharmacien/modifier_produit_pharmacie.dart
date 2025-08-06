import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ModifierProduitPharmacieScreen extends StatefulWidget {
  final DocumentSnapshot product;

  const ModifierProduitPharmacieScreen({super.key, required this.product});

  @override
  State<ModifierProduitPharmacieScreen> createState() => _ModifierProduitPharmacieScreenState();
}

class _ModifierProduitPharmacieScreenState extends State<ModifierProduitPharmacieScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late double _price;
  late String _type;
  late String _dosage;
  late String _manufacturer;
  late int _stock;
  DateTime? _expirationDate;
  File? _newImageFile;
  bool _isSubmitting = false;

  final picker = ImagePicker();

  final Map<String, List<String>> dosageOptions = {
    'Comprimé': ['250mg', '500mg', '1g'],
    'Sirop': ['100ml', '200ml', '500ml'],
    'Injection': ['1ml', '2ml', '5ml'],
    'Crème': ['15g', '30g', '50g'],
    'Autre': [],
  };

  @override
  void initState() {
    super.initState();
    final data = widget.product.data() as Map<String, dynamic>;

    _name = data['name'] ?? '';
    _description = data['description'] ?? '';
    _price = (data['price'] ?? 0).toDouble();
    _type = data['type'] ?? 'Comprimé';
    _dosage = data['dosage'] ?? '';
    _manufacturer = data['manufacturer'] ?? '';
    _stock = (data['stock'] ?? 0).toInt();
    _expirationDate = (data['expirationDate'] != null)
        ? (data['expirationDate'] as Timestamp).toDate()
        : null;
  }

  Future<void> _pickNewImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked != null) {
      setState(() => _newImageFile = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('products/$fileName.jpg');
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Erreur d'upload image : $e");
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      String? imageUrl = (widget.product.data() as Map<String, dynamic>)['imageUrl'];

      if (_newImageFile != null) {
        imageUrl = await _uploadImage(_newImageFile!);
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.product.id)
          .update({
        'name': _name,
        'description': _description,
        'price': _price,
        'type': _type,
        'dosage': _dosage,
        'manufacturer': _manufacturer,
        'stock': _stock,
        'expirationDate': _expirationDate,
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit mis à jour')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Erreur update : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('products').doc(widget.product.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.product.data() as Map<String, dynamic>;
    final imageUrl = data['imageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le produit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _newImageFile != null
                    ? Image.file(_newImageFile!, height: 180, fit: BoxFit.cover)
                    : imageUrl != null
                    ? Image.network(imageUrl, height: 180, fit: BoxFit.cover)
                    : Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Center(child: Icon(Icons.image, size: 50)),
                ),
              ),
              const SizedBox(height: 12),

              ElevatedButton.icon(
                onPressed: _pickNewImage,
                icon: const Icon(Icons.image),
                label: const Text("Changer l'image"),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom'),
                onSaved: (val) => _name = val!.trim(),
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (val) => _description = val!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _price.toString(),
                decoration: const InputDecoration(labelText: 'Prix (MRU)'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _price = double.tryParse(val ?? '0') ?? 0,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(labelText: 'Type de médicament'),
                items: dosageOptions.keys.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _type = val!;
                    _dosage = '';
                  });
                },
                onSaved: (val) => _type = val!,
              ),
              const SizedBox(height: 16),

              if (dosageOptions[_type]!.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: dosageOptions[_type]!.contains(_dosage) ? _dosage : null,
                  decoration: const InputDecoration(labelText: 'Dosage'),
                  items: dosageOptions[_type]!.map((dose) {
                    return DropdownMenuItem(value: dose, child: Text(dose));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _dosage = val ?? '');
                  },
                  onSaved: (val) => _dosage = val ?? '',
                )
              else
                TextFormField(
                  initialValue: _dosage,
                  decoration: const InputDecoration(labelText: 'Dosage personnalisé'),
                  onSaved: (val) => _dosage = val!.trim(),
                ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _manufacturer,
                decoration: const InputDecoration(labelText: 'Fabricant'),
                onSaved: (val) => _manufacturer = val!.trim(),
              ),
              const SizedBox(height: 16),

              TextFormField(
                initialValue: _stock.toString(),
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                onSaved: (val) => _stock = int.tryParse(val ?? '0') ?? 0,
              ),
              const SizedBox(height: 16),

              Text(
                'Date d\'expiration : ${_expirationDate != null ? _expirationDate!.toLocal().toString().split(' ')[0] : 'Non sélectionnée'}',
              ),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _expirationDate = picked);
                },
                child: const Text('Changer la date'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Enregistrer'),
              ),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: _deleteProduct,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Supprimer le produit',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
