import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String pharmacieId;
  final double price;
  final String imageUrl;
  final String dosage;
  final String prescriptionRequirement;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.pharmacieId,
    required this.price,
    required this.imageUrl,
    required this.dosage,
    required this.prescriptionRequirement,
    required this.category,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      pharmacieId: data['pharmacieId'] ?? '',
      price: (data['price'] is int) ? (data['price'] as int).toDouble() : (data['price'] ?? 0.0),
      imageUrl: data['imageUrl'] ?? '',
      dosage: data['dosage'] ?? 'Non précisé',
      prescriptionRequirement: data['prescriptionRequirement'] ?? 'Sans ordonnance',
      category: data['category'] ?? 'Autres',
    );
  }
}
