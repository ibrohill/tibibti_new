import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProduitDetailScreen extends StatelessWidget {
  final DocumentSnapshot product;

  const ProduitDetailScreen({super.key, required this.product});

  Future<void> _deleteProduct(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer ce produit ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produit supprimé')));
        Navigator.pop(context); // Retour à la liste après suppression
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de la suppression: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = product.data() as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(data['name'] ?? 'Détail produit'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/modifier_produit_pharmacie',
                arguments: product,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(context),
            tooltip: 'Supprimer le produit',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (data['imageUrl'] != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  data['imageUrl'],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Nom & Prix
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (data['price'] != null)
                    Text(
                      'Prix : ${data['price']} MRU',
                      style: const TextStyle(fontSize: 18, color: Colors.teal),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (data['type'] != null)
                    _buildInfoRow(Icons.category, 'Type', data['type']),
                  if (data['dosage'] != null)
                    _buildInfoRow(Icons.local_pharmacy, 'Dosage', data['dosage']),
                  if (data['manufacturer'] != null)
                    _buildInfoRow(Icons.business, 'Fabricant', data['manufacturer']),
                  if (data['stock'] != null)
                    _buildInfoRow(Icons.inventory, 'Stock', '${data['stock']} unités'),
                  if (data['expirationDate'] != null)
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Expiration',
                      (data['expirationDate'] as Timestamp)
                          .toDate()
                          .toLocal()
                          .toString()
                          .split(" ")[0],
                    ),
                  if (data['prescriptionRequirement'] != null)
                    _buildPrescriptionRow(data['prescriptionRequirement']),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          if (data['description'] != null)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              elevation: 0.5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  data['description'],
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 10),
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionRow(String prescription) {
    Color badgeColor;
    Color textColor;

    switch (prescription.toLowerCase()) {
      case 'avec ordonnance':
        badgeColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      case 'les deux':
        badgeColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'sans ordonnance':
      default:
        badgeColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.medical_services, color: Colors.teal),
          const SizedBox(width: 10),
          const Text(
            'Ordonnance : ',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              prescription,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
