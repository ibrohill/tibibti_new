import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrdonnancesPharmacienScreen extends StatefulWidget {
  @override
  _OrdonnancesPharmacienScreenState createState() => _OrdonnancesPharmacienScreenState();
}

class _OrdonnancesPharmacienScreenState extends State<OrdonnancesPharmacienScreen> {
  String? pharmacyId;

  @override
  void initState() {
    super.initState();
    fetchPharmacyId();
  }

  Future<void> fetchPharmacyId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      setState(() {
        pharmacyId = userDoc.data()?['pharmacyId'];
      });
    }
  }

  Future<void> updateStatus(String ordonnanceId, String status, {String? motifRefus}) async {
    await FirebaseFirestore.instance.collection('ordonnances').doc(ordonnanceId).update({
      'status': status,
      if (motifRefus != null) 'motifRefus': motifRefus,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (pharmacyId == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Ordonnances reçues')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ordonnances')
            .where('pharmacyId', isEqualTo: pharmacyId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return Center(child: Text("Aucune ordonnance reçue."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(data['imageUrl'], width: 60, height: 60, fit: BoxFit.cover),
                  title: Text("Ordonnance de ${data['userId']}"),
                  subtitle: Text("Statut: ${data['status']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () => updateStatus(doc.id, 'acceptée'),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          final motif = await showDialog<String>(
                            context: context,
                            builder: (context) => MotifRefusDialog(),
                          );
                          if (motif != null && motif.isNotEmpty) {
                            updateStatus(doc.id, 'refusée', motifRefus: motif);
                          }
                        },
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

class MotifRefusDialog extends StatefulWidget {
  @override
  _MotifRefusDialogState createState() => _MotifRefusDialogState();
}

class _MotifRefusDialogState extends State<MotifRefusDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Motif du refus'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(hintText: "Ex: Ordonnance illisible"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Annuler")),
        ElevatedButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text("Envoyer")),
      ],
    );
  }
}
