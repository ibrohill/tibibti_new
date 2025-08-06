import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String pharmacyId;
  final String userId;
  final String imageUrl;
  final String status; // "envoyée", "reçue", "en cours", "traitée"
  final Timestamp createdAt;

  Prescription({
    required this.id,
    required this.pharmacyId,
    required this.userId,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  factory Prescription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Prescription(
      id: doc.id,
      pharmacyId: data['pharmacyId'] ?? '',
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'envoyée',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'pharmacyId': pharmacyId,
    'userId': userId,
    'imageUrl': imageUrl,
    'status': status,
    'createdAt': createdAt,
  };
}
