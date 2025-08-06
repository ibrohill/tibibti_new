import 'package:cloud_firestore/cloud_firestore.dart';

class Pharmacie {
  final String id;
  final String name;
  final String adresse;
  final String telephone;
  final String categorie;
  final String description;
  final String imageUrl;
  final String openingHours;
  final List<String> openingDays;
  final List<String> services;
  final double rating;
  final int reviewsCount;
  final bool isOnDuty;  // <-- Ajout

  Pharmacie({
    required this.id,
    required this.name,
    required this.adresse,
    required this.telephone,
    required this.categorie,
    required this.description,
    required this.imageUrl,
    required this.openingHours,
    required this.openingDays,
    required this.services,
    required this.rating,
    required this.reviewsCount,
    this.isOnDuty = false,  // Valeur par défaut
  });

  factory Pharmacie.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final schedule = data['schedule'] ?? {};

    final rawJours = schedule['jours'];
    List<String> joursList = [];
    if (rawJours is Iterable) {
      joursList = rawJours.map((e) => e.toString()).toList();
    }

    return Pharmacie(
      id: doc.id,
      name: data['nom'] ?? data['pharmacyName'] ?? '',
      adresse: data['adresse'] ?? data['address'] ?? '',
      telephone: data['telephone'] ?? data['phone'] ?? '',
      categorie: data['categorie'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      openingHours: '${schedule['ouverture'] ?? ''} - ${schedule['fermeture'] ?? ''}',
      openingDays: joursList,
      services: List<String>.from(data['services'] ?? []),
      rating: (data['rating'] ?? 0).toDouble(),
      reviewsCount: (data['reviewsCount'] ?? 0).toInt(),
      isOnDuty: data['isOnDuty'] ?? false,  // <-- Extraction
    );
  }
}
