import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'modifier_produit_pharmacie.dart';
import 'package:tibibti/screens/pharmacien/produit_detail_screen.dart';

class ListeProduitsPharmacieScreen extends StatelessWidget {
  const ListeProduitsPharmacieScreen({super.key});

  Future<void> _deleteProduct(String id, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('products').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit supprimé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression : $e')),
      );
    }
  }

  Widget _prescriptionBadge(String prescription) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (prescription) {
      case 'Avec ordonnance':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade700;
        icon = Icons.warning_amber_rounded;
        break;
      case 'Les deux':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade700;
        icon = Icons.info_outline;
        break;
      default:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            prescription,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/logo1.png',
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits Pharmacie'),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: 'pharmacie')
            .where('createdBy', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun produit trouvé.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final products = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final product = products[index];
              final data = product.data() as Map<String, dynamic>;

              final imageUrl = data['imageUrl'] as String?;
              final name = data['name'] ?? 'Sans nom';
              final price = data['price'] ?? 0;
              final prescription = data['prescriptionRequirement'] ?? 'Sans ordonnance';
              final description = data['description'] ?? '';

              return Card(
                elevation: 4,
                shadowColor: Colors.teal.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProduitDetailScreen(product: product),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null && imageUrl.isNotEmpty
                              ? Image.network(
                            imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Erreur chargement image: $error');
                              return Image.asset(
                                'assets/images/logo1.png',
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            'assets/images/logo1.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),



                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$price UM',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Colors.teal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _prescriptionBadge(prescription),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.teal, size: 28),
                              tooltip: 'Modifier',
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
                              tooltip: 'Supprimer',
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
                                  await _deleteProduct(product.id, context);
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
    );
  }
}
