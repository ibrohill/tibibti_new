import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/prescription_model.dart';

class PharmacienPrescriptionsScreen extends StatefulWidget {
  final String pharmacieId;
  const PharmacienPrescriptionsScreen({required this.pharmacieId, super.key});

  @override
  State<PharmacienPrescriptionsScreen> createState() => _PharmacienPrescriptionsScreenState();
}

class _PharmacienPrescriptionsScreenState extends State<PharmacienPrescriptionsScreen> {
  Stream<List<Prescription>> getPrescriptions() {
    return FirebaseFirestore.instance
        .collection('prescriptions')
        .where('pharmacyId', isEqualTo: widget.pharmacieId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Prescription.fromFirestore(d)).toList());
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance.collection('prescriptions').doc(id).update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordonnances reçues'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<List<Prescription>>(
        stream: getPrescriptions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('Aucune ordonnance reçue'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final presc = list[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Envoyée par : ${presc.userId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Statut : ${presc.status}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 6),
                      if (presc.imageUrl.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(presc.imageUrl),
                                ),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              presc.imageUrl,
                              height: 140,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: presc.status,
                            items: const [
                              DropdownMenuItem(value: 'envoyée', child: Text('Envoyée')),
                              DropdownMenuItem(value: 'reçue', child: Text('Reçue')),
                              DropdownMenuItem(value: 'en cours', child: Text('En cours')),
                              DropdownMenuItem(value: 'traitée', child: Text('Traitée')),
                            ],
                            onChanged: (val) {
                              if (val != null) _updateStatus(presc.id, val);
                            },
                          ),
                          const Spacer(),
                          Text(
                            'Le ${DateFormat('dd/MM/yyyy HH:mm').format(presc.createdAt.toDate())}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
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
