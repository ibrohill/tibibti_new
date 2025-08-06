import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProduitsPharmacieScreen extends StatelessWidget {
  final String pharmacienId;

  const ProduitsPharmacieScreen({super.key, required this.pharmacienId});

  // Badge ordonnance
  Widget _buildPrescriptionBadge(String prescription) {
    Color color;
    IconData icon;

    switch (prescription.toLowerCase()) {
      case 'avec ordonnance':
        color = Colors.red;
        icon = Icons.medical_information;
        break;
      case 'les deux':
        color = Colors.orange;
        icon = Icons.warning_amber_outlined;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle_outline;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 4),
        Text(
          prescription,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produits disponibles'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('createdBy', isEqualTo: pharmacienId)
            .where('category', isEqualTo: 'pharmacie')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun produit trouvé."));
          }

          final produits = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: produits.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = produits[index].data()! as Map<String, dynamic>;
              final String name = data['name'] ?? 'Nom inconnu';
              final double? price = (data['price'] ?? 0).toDouble();
              final String prescription = data['prescriptionRequirement'] ?? 'Sans ordonnance';
              final String imageUrl = data['imageUrl'] ?? '';
              final String? description = data['description'];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: 56, height: 56, fit: BoxFit.cover)
                        : Image.asset('assets/images/image2.jpg', width: 56, height: 56),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Prix : ${price?.toStringAsFixed(0)} MRU"),
                      const SizedBox(height: 4),
                      _buildPrescriptionBadge(prescription),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    // TODO : Naviguer vers un écran de détail si tu veux
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
