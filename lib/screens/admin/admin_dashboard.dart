import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  bool _isLoggingOut = false;

  int totalUsers = 0;
  int totalPharmacies = 0;
  int totalOnlinePharmacies = 0;

  late final Stream<DocumentSnapshot> _userStatusStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _userStatusStream = _firestore.collection('users').doc(uid).snapshots();

      _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      final statusRef = _database.ref('status/$uid');
      statusRef.set({
        'state': 'online',
        'last_changed': ServerValue.timestamp,
      });
      statusRef.onDisconnect().set({
        'state': 'offline',
        'last_changed': ServerValue.timestamp,
      });
    }
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({
          'isOnline': false,
          'lastLogout': FieldValue.serverTimestamp(),
        });
        await _database.ref('status/$uid').set({
          'state': 'offline',
          'last_changed': ServerValue.timestamp,
        });
      }

      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la déconnexion : $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }


  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '';
    String email = '';
    String password = '';
    String role = 'client';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un utilisateur"),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Nom"),
                    validator: (value) => value!.isEmpty ? "Nom requis" : null,
                    onChanged: (value) => name = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Email"),
                    validator: (value) => value!.isEmpty ? "Email requis" : null,
                    onChanged: (value) => email = value,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: "Mot de passe"),
                    obscureText: true,
                    validator: (value) => value!.length < 6 ? "Min 6 caractères" : null,
                    onChanged: (value) => password = value,
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: "Rôle"),
                    items: const [
                      DropdownMenuItem(value: 'client', child: Text('Client')),
                      DropdownMenuItem(value: 'pharmacien', child: Text('Pharmacien')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) => role = value!,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  Navigator.pop(context); // Fermer le dialog
                  try {
                    final cred = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(email: email, password: password);

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(cred.user!.uid)
                        .set({
                      'name': name,
                      'email': email,
                      'role': role,
                      'isOnline': false,
                      'isBlocked': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Utilisateur ajouté avec succès")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur création : $e")),
                    );
                  }
                }
              },
              child: const Text("Créer"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserRole(String uid, String currentRole, String newRole) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (uid == currentUserId && currentRole == 'admin' && newRole != 'admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez pas retirer votre propre rôle admin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('users').doc(uid).update({'role': newRole});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rôle mis à jour en "$newRole"')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur mise à jour rôle: $e')),
      );
    }
  }

  Future<void> _blockOrUnblockUser(String uid, bool isBlocked) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'isBlocked': !isBlocked,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isBlocked ? 'Utilisateur débloqué' : 'Utilisateur bloqué')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur blocage: $e')),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e')),
      );
    }
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserRow(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final uid = doc.id;
    final role = data['role'] ?? 'client';
    final isBlocked = data['isBlocked'] == true;
    final isOnline = data['isOnline'] == true;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBlocked
              ? Colors.redAccent
              : (isOnline ? Colors.green : Colors.grey),
          child: Icon(
            isBlocked ? Icons.block : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(
          data['name'] ?? 'Sans nom',
          style: TextStyle(
            decoration: isBlocked ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Email: ${data['email'] ?? 'non fourni'}\nRôle: $role',
          style: const TextStyle(fontSize: 13),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'admin':
              case 'pharmacien':
              case 'client':
                _updateUserRole(uid, role, value);
                break;
              case 'bloquer':
                _blockOrUnblockUser(uid, isBlocked);
                break;
              case 'supprimer':
                _deleteUser(uid);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'admin', child: Text('Attribuer admin')),
            const PopupMenuItem(value: 'pharmacien', child: Text('Attribuer pharmacien')),
            const PopupMenuItem(value: 'client', child: Text('Attribuer client')),
            PopupMenuItem(value: 'bloquer', child: Text(isBlocked ? 'Débloquer' : 'Bloquer')),
            const PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Admin"),
              accountEmail: const Text("admin@example.com"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.teal),
              ),
              decoration: const BoxDecoration(color: Colors.teal),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Utilisateurs'),
              onTap: () => Navigator.pushNamed(context, '/admin_users'),
            ),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Produits'),
              onTap: () => Navigator.pushNamed(context, '/admin_products'),
            ),
            ListTile(
              leading: const Icon(Icons.local_pharmacy),
              title: const Text('Pharmacies'),
              onTap: () => Navigator.pushNamed(context, '/admin_pharmacies'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ],
        ),
      ),

      appBar: AppBar(
        title: const Text('Tableau de bord'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Ajouter un utilisateur',
            onPressed: _showAddUserDialog,
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          totalUsers = docs.length;
          totalPharmacies = 0;
          totalOnlinePharmacies = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['role'] == 'pharmacien') {
              totalPharmacies++;
              if (data['isOnline'] == true) totalOnlinePharmacies++;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    buildStatCard("Utilisateurs", "$totalUsers", Icons.person, Colors.teal),
                    const SizedBox(width: 12),
                    buildStatCard("Pharmacies", "$totalPharmacies", Icons.local_pharmacy, Colors.purple),
                    const SizedBox(width: 12),
                    buildStatCard("Connectés", "$totalOnlinePharmacies", Icons.wifi, Colors.blue),
                  ],
                ),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Liste des utilisateurs",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 12),

                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) => buildUserRow(docs[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

}
