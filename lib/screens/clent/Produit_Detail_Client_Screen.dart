import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProduitDetailClientScreen extends StatelessWidget {
  final DocumentSnapshot product;

  const ProduitDetailClientScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final data = product.data() as Map<String, dynamic>;

    final imageUrl = data['imageUrl'] ?? '';
    final name = data['name'] ?? 'Nom inconnu';
    final price = data['price']?.toString() ?? '0';
    final description = data['description'] ?? 'Pas de description';

    final type = data['type'] ?? '';
    final dosage = data['dosage'] ?? '';
    final manufacturer = data['manufacturer'] ?? '';
    final prescriptionRequirement = data['prescriptionRequirement']?.toString().toLowerCase() ?? '';
    final expiration = data['expirationDate'];

    final prescription = data['prescription'] as Map<String, dynamic>?;

    String expirationDate = '';
    if (expiration != null) {
      if (expiration is Timestamp) {
        final date = expiration.toDate();
        expirationDate = DateFormat('dd/MM/yyyy').format(date);
      } else if (expiration is String) {
        expirationDate = expiration;
      }
    }

    final infoList = [
      if (type.isNotEmpty)
        _infoTile(icon: Icons.category, label: 'Type', value: type, color: Colors.teal),
      if (dosage.isNotEmpty)
        _infoTile(icon: Icons.medication, label: 'Dosage', value: dosage, color: Colors.orange),
      if (manufacturer.isNotEmpty)
        _infoTile(icon: Icons.factory, label: 'Fabricant', value: manufacturer, color: Colors.deepPurple),
      if (expirationDate.isNotEmpty)
        _infoTile(icon: Icons.event, label: 'Expiration', value: expirationDate, color: Colors.redAccent),
      if (prescriptionRequirement == 'oui')
        _infoTile(icon: Icons.receipt, label: 'Ordonnance', value: 'Requise', color: Colors.blue),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.teal,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final crossAxisCount = isWide ? 3 : 2;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, height: 240, width: double.infinity, fit: BoxFit.cover)
                    : Image.asset('assets/images/logo2.png', height: 240, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),

              // Nom + Prix
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      '$price MRU',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Grille des infos
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.3,
                children: infoList,
              ),

              const SizedBox(height: 30),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.5),
                textAlign: TextAlign.justify,
              ),

              const SizedBox(height: 30),

              // Feuille de prescription stylisée
              // Feuille de prescription réaliste
              if (prescription != null && prescription.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 30),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF9F6), // Blanc cassé type papier
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.elliptical(80, 20),
                      bottomLeft: Radius.elliptical(80, 20),
                      bottomRight: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade500.withOpacity(0.2),
                        offset: const Offset(6, 6),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/images/paper_texture.png'), // texture papier
                      fit: BoxFit.cover,
                      opacity: 0.05,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.description, color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Feuille de Prescription Médicale',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.5),
                      _buildPrescriptionSection('Indications', prescription['indications']),
                      _buildPrescriptionSection('Posologie', prescription['posologie']),
                      _buildPrescriptionSection('Contre-indications', prescription['contreIndications']),
                      _buildPrescriptionSection('Effets secondaires', prescription['effetsSecondaires']),
                      _buildPrescriptionSection('Interactions', prescription['interactions']),
                      _buildPrescriptionSection('Mode d’administration', prescription['modeAdministration']),
                      _buildPrescriptionSection('Précautions', prescription['precautions']),
                    ],
                  ),
                ),


              // Bouton commander
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Commande en cours...')),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Commander', style: TextStyle(fontSize: 18)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionSection(String title, dynamic content) {
    if (content == null || content.toString().trim().isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(content.toString(),
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4)),
        ],
      ),
    );
  }
}
