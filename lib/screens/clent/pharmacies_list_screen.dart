import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PharmaciesListScreen extends StatefulWidget {
  const PharmaciesListScreen({super.key});

  @override
  State<PharmaciesListScreen> createState() => _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  String? selectedCategory;
  final categories = ['Urgence', 'Quartier', 'Spécialisée'];

  Widget _buildPrescriptionBadge(String prescription) {
    Color color;
    IconData icon;

    switch (prescription.toLowerCase()) {
      case 'avec ordonnance':
        color = Colors.red;
        icon = Icons.medical_services;
        break;
      case 'les deux':
        color = Colors.orange;
        icon = Icons.warning_amber_rounded;
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

  Widget _buildMedicamentList(String pharmacieId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: 'pharmacie')
          .where('createdBy', isEqualTo: pharmacieId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final produits = snapshot.data!.docs;

        if (produits.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Aucun médicament disponible.'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: produits.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final String name = data['name'] ?? 'Sans nom';
            final double price = (data['price'] ?? 0).toDouble();
            final String prescription = data['prescriptionRequirement'] ?? 'Sans ordonnance';
            final String imageUrl = data['imageUrl'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover)
                      : Image.asset('assets/images/logo1.png', width: 50, height: 50),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Prix : $price MRU'),
                    _buildPrescriptionBadge(prescription),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = selectedCategory == null
        ? FirebaseFirestore.instance.collection('pharmacies')
        : FirebaseFirestore.instance
        .collection('pharmacies')
        .where('categorie', isEqualTo: selectedCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // 🔎 Filtres catégories
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Toutes'),
                  selected: selectedCategory == null,
                  onSelected: (_) => setState(() => selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: selectedCategory == cat,
                    onSelected: (selected) =>
                        setState(() => selectedCategory = selected ? cat : null),
                  ),
                )),
              ],
            ),
          ),

          const Divider(),

          // 📋 Liste pharmacies
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Aucune pharmacie trouvée.'));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final pharmacieId = doc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.asset(
                              'assets/images/image2.jpg',
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['nom'] ?? 'Pharmacie sans nom',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Adresse : ${data['adresse'] ?? 'N/A'}'),
                                Text('Téléphone : ${data['telephone'] ?? 'N/A'}'),
                                Text('Catégorie : ${data['categorie'] ?? 'N/A'}'),
                                const SizedBox(height: 8),
                                const Text(
                                  '💊 Médicaments disponibles :',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                _buildMedicamentList(pharmacieId),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
