import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:tibibti/screens/pharmacien/produit_detail_screen.dart';

class HomePharmacienScreen extends StatefulWidget {
  const HomePharmacienScreen({super.key});

  @override
  State<HomePharmacienScreen> createState() => _HomePharmacienScreenState();
}

class _HomePharmacienScreenState extends State<HomePharmacienScreen>
    with SingleTickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _setPharmacienOnline() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final uid = user.uid;

      // Firestore : marquer en ligne
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': true,
      });

      // Realtime Database : pour détecter la déconnexion
      final DatabaseReference statusRef =
      FirebaseDatabase.instance.ref('status/$uid');

      // Définir valeur en ligne
      await statusRef.set({'state': 'online', 'timestamp': ServerValue.timestamp});

      // Définir comportement lors de déconnexion brutale
      await statusRef.onDisconnect().set({
        'state': 'offline',
        'timestamp': ServerValue.timestamp,
      });
    }
  }

  // Pour gérer notifications locales
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String _pharmacyName = '';
  String _lastNotification = 'Aucune notification reçue';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _loadPharmacienName();
    _setPharmacienOnline();

    // --- Initialisation notifications ---
    _initFirebaseMessaging();
  }

  Future<void> _initFirebaseMessaging() async {
    // Initialisation notifications locales Android
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          // Action sur tap notification (optionnel)
          debugPrint('Notification tap: ${response.payload}');
        });

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Demande permission (utile sur iOS, neutre sur Android)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification autorisée');

      // Récupérer token FCM
      String? token = await messaging.getToken();
      debugPrint('Token FCM: $token');

      // Écouter notifications reçues en foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Notification foreground reçue: ${message.notification?.title}');

        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          // Affiche notification locale
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                'default_channel',
                'Notifications',
                channelDescription: 'Canal de notifications par défaut',
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }

        // Mise à jour UI
        setState(() {
          _lastNotification = notification?.body ?? 'Notification sans contenu';
        });

        // Affiche Snackbar temporaire
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification: ${notification?.title ?? ""}')),
        );
      });
    } else {
      debugPrint('Notification non autorisée');
    }
  }

  Future<void> _loadPharmacienName() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _pharmacyName = data['pharmacyName'] ?? '';
          });

          // Initialise isOnDuty à false si absent
          if (!data.containsKey('isOnDuty')) {
            await _firestore.collection('users').doc(uid).update({
              'isOnDuty': false,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur récupération nom pharmacie : $e');
    }
  }



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;

        // Firestore : marquer hors ligne
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isOnline': false,
        });

        // Realtime Database : supprimer le statut
        await FirebaseDatabase.instance.ref('status/$uid').remove();
      }

      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de déconnexion : $e')),
      );
    }
  }


  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 22, color: Colors.teal)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _prescriptionWidget(String prescription) {
    Icon icon;
    Color color;

    switch (prescription.toLowerCase()) {
      case 'avec ordonnance':
        icon = const Icon(Icons.medical_services, color: Colors.red, size: 18);
        color = Colors.red;
        break;
      case 'les deux':
        icon = const Icon(Icons.help_outline, color: Colors.orange, size: 18);
        color = Colors.orange;
        break;
      default:
        icon = const Icon(Icons.check_circle_outline, color: Colors.green, size: 18);
        color = Colors.green;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        icon,
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            prescription,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }


  Widget _medicamentList(Stream<QuerySnapshot> stream) {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Aucun médicament trouvé.'));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final product = doc.data() as Map<String, dynamic>;
              final prescription = product['prescriptionRequirement'] ?? 'Sans ordonnance';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProduitDetailScreen(product: doc),
                    ),
                  );
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product['imageUrl'] != null && product['imageUrl'].toString().isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              product['imageUrl'],
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/logo1.png',
                                  height: 90,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          )
                        else
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.asset(
                              'assets/images/logo1.png',
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            product['name'] ?? 'Sans nom',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Prix: ${product['price']} MRU",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _prescriptionWidget(prescription),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final userEmail = _auth.currentUser?.email ?? 'Pharmacien';
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(_pharmacyName.isNotEmpty ? _pharmacyName : 'Tableau de bord Pharmacien'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
              final isOnDuty = (data['isOnDuty'] ?? false) as bool;

              if (!isOnDuty) return const SizedBox.shrink();

              return Container(
                color: Colors.orange,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: const Center(
                  child: Text(
                    'Votre pharmacie est en garde',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          if (_auth.currentUser?.uid != null)
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final isOnDuty = (data['isOnDuty'] ?? false) as bool;

                return TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  icon: Icon(isOnDuty ? Icons.local_hospital : Icons.local_hospital_outlined),
                  label: Text(isOnDuty ? 'Garde' : 'Hors garde'),
                  onPressed: () async {
                    final newValue = !isOnDuty;
                    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
                      'isOnDuty': newValue,
                    });
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(newValue ? 'Mode garde activé' : 'Mode garde désactivé')),
                    );
                  },
                );
              },
            ),
        ],
      ),


      drawer: Drawer(
        child: ListView(
          padding: const EdgeInsets.only(top: 40),
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'P',
                      style: const TextStyle(fontSize: 32, color: Colors.teal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userEmail,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Mon Profil'),
              onTap: () async {
                await Navigator.pushNamed(context, '/profil_pharmacien');
                _loadPharmacienName();
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Nos médicaments'),
              onTap: () => Navigator.pushNamed(context, '/liste_produits_pharmacie'),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Ajouter un médicament'),
              onTap: () => Navigator.pushNamed(context, '/ajout_produit_pharmacie'),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Ordonnances'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/pharmacien/ordonnances',
                  arguments: userId, // userId = uid du pharmacien / pharmacie
                );
              },
            ),


            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Contacter l'administration"),
              onTap: () => Navigator.pushNamed(context, '/support'),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(context); // ferme le drawer
                Navigator.pushNamed(context, '/parametres_pharmacien');
              },
            ),

            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Se déconnecter'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('assets/images/image2.jpg',
                  height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text(
              "Bienvenue, ${_pharmacyName.isNotEmpty ? _pharmacyName : 'Pharmacien'} 👋",
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),



            // Affiche le dernier message reçu en notification
            Text(
              'Dernière notification reçue :\n$_lastNotification',
              style: const TextStyle(fontSize: 16, color: Colors.teal),
            ),

            const SizedBox(height: 12),

            Card(
              color: Colors.teal.shade50,
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('products')
                          .where('createdBy', isEqualTo: userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Erreur: ${snapshot.error}');
                        }
                        final count = snapshot.data?.docs.length ?? 0;
                        return _statItem('Produits', count.toString());
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('orders')
                          .where('pharmacienId', isEqualTo: userId)
                          .where('status', isEqualTo: 'en_attente')
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statItem('Commandes', count.toString());
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('messages')
                          .where('toUid', isEqualTo: userId)
                          .where('read', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                        return _statItem('Messages', count.toString());
                      },
                    ),
                  ],
                ),
              ),
            ),
            _sectionTitle('Tous mes médicaments'),
            Expanded(
              child: _medicamentList(
                _firestore
                    .collection('products')
                    .where('category', isEqualTo: 'pharmacie')
                    .where('createdBy', isEqualTo: userId)
                    .snapshots(),
              ),
            ),

            _sectionTitle('Médicaments les plus demandés'),
            SizedBox(
              height: 180,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('products')
                    .where('category', isEqualTo: 'pharmacie')
                    .where('createdBy', isEqualTo: userId)
                    .orderBy('nbCommandes', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur : ${snapshot.error}'));
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucun médicament populaire pour l’instant.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final product = doc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProduitDetailScreen(product: doc),
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.only(right: 12),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (product['imageUrl'] != null)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: Image.network(
                                      product['imageUrl'],
                                      height: 90,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    product['name'] ?? 'Sans nom',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    "Prix: ${product['price']} MRU",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
