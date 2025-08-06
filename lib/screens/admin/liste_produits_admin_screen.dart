import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tibibti/screens/pharmacien/produit_detail_screen.dart';

import '../pharmacien/modifier_produit_pharmacie.dart';

class ListeProduitsAdminScreen extends StatefulWidget {
  const ListeProduitsAdminScreen({super.key});

  @override
  State<ListeProduitsAdminScreen> createState() => _ListeProduitsAdminScreenState();
}

class _ListeProduitsAdminScreenState extends State<ListeProduitsAdminScreen> {
  String? selectedPharmacyId;
  String? selectedPharmacyName;

  Future<void> _deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion Produits par Pharmacie'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Dropdown pour choisir une pharmacie
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'pharmacien')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final pharmacies = snapshot.data!.docs;
                if (pharmacies.isEmpty) {
                  return const Text('Aucune pharmacie trouvée.');
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner une pharmacie',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  value: selectedPharmacyId,
                  items: pharmacies.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Sans nom';
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedPharmacyId = value;
                      selectedPharmacyName = pharmacies.firstWhere((doc) => doc.id == value).get('name');
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // Message si aucun produit trouvé
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedPharmacyId == null
                    ? FirebaseFirestore.instance.collection('products').snapshots()
                    : FirebaseFirestore.instance
                    .collection('products')
                    .where('pharmacyId', isEqualTo: selectedPharmacyId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final products = snapshot.data!.docs;
                  if (products.isEmpty) {
                    return Center(
                      child: Text(
                        selectedPharmacyId == null
                            ? 'Aucun produit trouvé.'
                            : 'Aucun produit trouvé pour cette pharmacie.',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final data = product.data() as Map<String, dynamic>;

                      final imageUrl = data['imageUrl'] as String?;
                      final name = data['name'] ?? 'Sans nom';
                      final price = data['price'] ?? 0;

                      return Material(
                        elevation: 3,
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProduitDetailScreen(product: product),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? Image.network(
                                    imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholderImage(),
                                  )
                                      : _placeholderImage(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (data['description'] != null && data['description'].toString().isNotEmpty)
                                        Text(
                                          data['description'],
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$price UM',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.teal, size: 28),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ModifierProduitPharmacieScreen(product: product),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 28),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmer la suppression'),
                                            content: Text('Supprimer "$name" ? Cette action est irréversible.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, false),
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true),
                                                child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirmed == true) {
                                          await _deleteProduct(product.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.teal.shade50,
      child: const Icon(Icons.medical_services, size: 40, color: Colors.teal),
    );
  }
}
