import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tibibti/models/pharmacie_model.dart';

class PharmaciesPage extends StatefulWidget {
  final Map<String, String> onlineStatusMap;
  final Position? userPosition;

  const PharmaciesPage({
    Key? key,
    required this.onlineStatusMap,
    required this.userPosition,
  }) : super(key: key);

  @override
  State<PharmaciesPage> createState() => _PharmaciesPageState();
}

class _PharmaciesPageState extends State<PharmaciesPage> {
  String searchQuery = '';
  String filter = 'Tous';

  final TextEditingController _searchController = TextEditingController();

  bool locationPermissionDenied = false;

  Position? userPosition;

  Map<String, String> onlineStatusMap = {}; // Remplacer par ta source réelle

  // Formatage des jours d’ouverture (ex: Du Lundi au Vendredi ou Le Dimanche)
  String _formatOpeningDays(List<String> jours) {
    const ordre = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    List<String> joursLower = jours.map((j) => j.toLowerCase()).toList();
    joursLower.sort((a, b) => ordre.indexOf(a).compareTo(ordre.indexOf(b)));

    if (joursLower.length == 1) {
      return 'Le ${_capitalize(joursLower.first)}';
    } else if (joursLower.isNotEmpty) {
      return 'Du ${_capitalize(joursLower.first)} au ${_capitalize(joursLower.last)}';
    }
    return '';
  }

  String _capitalize(String s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : s;

  // Widget pour afficher la note en étoiles (sur 5)
  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    List<Widget> stars = [];

    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }
    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }

    return Row(children: stars);
  }

  @override
  void initState() {
    super.initState();
    onlineStatusMap = widget.onlineStatusMap;
    userPosition = widget.userPosition;
  }

  @override
  void didUpdateWidget(covariant PharmaciesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onlineStatusMap != widget.onlineStatusMap) {
      setState(() => onlineStatusMap = widget.onlineStatusMap);
    }
    if (oldWidget.userPosition != widget.userPosition) {
      setState(() => userPosition = widget.userPosition);
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => locationPermissionDenied = true);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => locationPermissionDenied = true);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => locationPermissionDenied = true);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        userPosition = position;
        locationPermissionDenied = false;
      });
    } catch (_) {
      setState(() => locationPermissionDenied = true);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  List<String> trierJours(List<String> jours) {
    const ordre = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    jours.sort((a, b) => ordre.indexOf(a.toLowerCase()).compareTo(ordre.indexOf(b.toLowerCase())));
    return jours;
  }

  Stream<String> getOnlineStatus(String userId) async* {
    yield onlineStatusMap[userId] ?? 'offline';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une pharmacie...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: ['Tous', 'Ouverts', 'De garde'].map((item) {
                final isSelected = filter == item;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: isSelected,
                    onSelected: (_) => setState(() => filter = item),
                    selectedColor: Colors.teal,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.teal[900],
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 4,
                    shadowColor: Colors.teal.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),


            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'pharmacien')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Aucune pharmacie trouvée.'));
                  }

                  List<Pharmacie> toutesPharmacies = [];
                  List<Pharmacie> pharmaciesProches = [];

                  for (var doc in snapshot.data!.docs) {
                    final pharmacie = Pharmacie.fromFirestore(doc);
                    final nameLower = pharmacie.name.toLowerCase();
                    final matchesQuery = nameLower.contains(searchQuery);
                    final isOpen = onlineStatusMap[doc.id] == 'online';
                    final isFavoris = false; // À gérer dans ton modèle ou Firestore

                    final isOnDuty = pharmacie.isOnDuty;

                    bool matchesFilter = false;
                    switch (filter) {
                      case 'Ouverts':
                        matchesFilter = matchesQuery && (onlineStatusMap[pharmacie.id] == 'online');
                        break;
                      case 'De garde':
                        matchesFilter = matchesQuery && isOnDuty;
                        break;
                      default:
                        matchesFilter = matchesQuery;
                    }

                    if (!matchesFilter) continue;

                    if (userPosition != null && pharmacie.adresse.isNotEmpty) {
                      final lat = (doc.data()! as Map<String, dynamic>)['latitude'] ?? 0.0;
                      final lng = (doc.data()! as Map<String, dynamic>)['longitude'] ?? 0.0;
                      if (lat != 0 && lng != 0) {
                        final distance = _calculateDistance(userPosition!.latitude, userPosition!.longitude, lat, lng);
                        if (distance < 10) {
                          pharmaciesProches.add(pharmacie);
                        } else {
                          toutesPharmacies.add(pharmacie);
                        }
                      } else {
                        toutesPharmacies.add(pharmacie);
                      }
                    } else {
                      toutesPharmacies.add(pharmacie);
                    }
                  }

                  final toDisplay = pharmaciesProches.isNotEmpty ? pharmaciesProches : toutesPharmacies;

                  if (userPosition != null) {
                    toDisplay.sort((a, b) {
                      final latA = (snapshot.data!.docs.firstWhere((doc) => doc.id == a.id).data()! as Map<String, dynamic>)['latitude'] ?? 0.0;
                      final lngA = (snapshot.data!.docs.firstWhere((doc) => doc.id == b.id).data()! as Map<String, dynamic>)['longitude'] ?? 0.0;
                      final latB = (snapshot.data!.docs.firstWhere((doc) => doc.id == b.id).data()! as Map<String, dynamic>)['latitude'] ?? 0.0;
                      final lngB = (snapshot.data!.docs.firstWhere((doc) => doc.id == b.id).data()! as Map<String, dynamic>)['longitude'] ?? 0.0;

                      final distA = _calculateDistance(userPosition!.latitude, userPosition!.longitude, latA, lngA);
                      final distB = _calculateDistance(userPosition!.latitude, userPosition!.longitude, latB, lngB);

                      return distA.compareTo(distB);
                    });
                  }

                  if (toDisplay.isEmpty) {
                    return const Center(child: Text('Aucune pharmacie correspondante.'));
                  }

                  return ListView.builder(
                    itemCount: toDisplay.length,
                    itemBuilder: (context, index) {
                      final pharmacie = toDisplay[index];

                      final joursTries = trierJours(pharmacie.openingDays);
                      String joursAffiches = '';
                      if (joursTries.isEmpty) {
                        joursAffiches = '';
                      } else if (joursTries.length == 1) {
                        joursAffiches = 'Le ${joursTries.first[0].toUpperCase()}${joursTries.first.substring(1)}';
                      } else {
                        joursAffiches = 'Du ${joursTries.first[0].toUpperCase()}${joursTries.first.substring(1)} au ${joursTries.last[0].toUpperCase()}${joursTries.last.substring(1)}';
                      }

                      double? distanceKm;
                      if (userPosition != null) {
                        final docData = snapshot.data!.docs.firstWhere((doc) => doc.id == pharmacie.id).data()! as Map<String, dynamic>;
                        final lat = docData['latitude'] ?? 0.0;
                        final lng = docData['longitude'] ?? 0.0;
                        if (lat != 0 && lng != 0) {
                          distanceKm = _calculateDistance(userPosition!.latitude, userPosition!.longitude, lat, lng);
                        }
                      }

                      return Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.only(bottom: 20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.pushNamed(context, '/pharmacie_detail', arguments: pharmacie);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    child: pharmacie.imageUrl.isNotEmpty
                                        ? Image.network(
                                      pharmacie.imageUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Image.asset(
                                        'assets/images/default_pharmacy.png',
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                        : Image.asset(
                                      'assets/images/image2.jpg',
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 50,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                        gradient: LinearGradient(
                                          colors: [Colors.transparent, Colors.black54],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 16,
                                    right: 16,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            pharmacie.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(blurRadius: 5, color: Colors.black87, offset: Offset(0, 1)),
                                              ],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        StreamBuilder<String>(
                                          stream: getOnlineStatus(pharmacie.id),
                                          builder: (context, snapshot) {
                                            final status = onlineStatusMap[pharmacie.id] ?? 'offline';
                                            final isOnline = status == 'online';

                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isOnline ? Colors.greenAccent[700] : Colors.redAccent[700],
                                                borderRadius: BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (isOnline ? Colors.greenAccent : Colors.redAccent).withOpacity(0.6),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.circle, size: 12, color: Colors.white),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isOnline ? 'En ligne' : 'Hors ligne',
                                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (joursTries.isNotEmpty && pharmacie.openingHours.isNotEmpty) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.calendar_today, color: Colors.teal, size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '$joursAffiches • ${pharmacie.openingHours}',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.grey.shade900,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                                letterSpacing: 0.2,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    if (distanceKm != null) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.directions_walk, color: Colors.teal, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${distanceKm.toStringAsFixed(1)} km de distance',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    if (pharmacie.services.isNotEmpty) ...[
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.medical_services, color: Colors.teal, size: 22),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Wrap(
                                              spacing: 10,
                                              runSpacing: 8,
                                              children: pharmacie.services.map((service) {
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade100.withOpacity(0.4),
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.teal.withOpacity(0.15),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    service,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.teal.shade900,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                    ],

                                    // Ligne avec les deux boutons alignés côte à côte
                                    Row(
                                      children: [
                                        if (pharmacie.adresse.isNotEmpty)
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.teal[700],
                                                side: BorderSide(color: Colors.teal.shade300),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              ),
                                              icon: const Icon(Icons.location_on_outlined, size: 20),
                                              label: const Text('Voir sur la carte', style: TextStyle(fontWeight: FontWeight.w600)),
                                              onPressed: () async {
                                                final docData = snapshot.data!.docs.firstWhere((doc) => doc.id == pharmacie.id).data()! as Map<String, dynamic>;
                                                final lat = docData['latitude'] ?? 0.0;
                                                final lng = docData['longitude'] ?? 0.0;

                                                Uri mapUri;
                                                if (lat != 0 && lng != 0) {
                                                  mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                                } else {
                                                  final query = Uri.encodeComponent(pharmacie.adresse);
                                                  mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
                                                }

                                                if (await canLaunchUrl(mapUri)) {
                                                  await launchUrl(mapUri);
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Impossible d’ouvrir la localisation')),
                                                  );
                                                }
                                              },
                                            ),
                                          ),

                                        const SizedBox(width: 12),

                                        _AnimatedButton(
                                          onTap: () => launchUrl(Uri(scheme: 'tel', path: pharmacie.telephone)),
                                          icon: Icons.call,
                                          label: 'Appeler',
                                          gradientColors: [Colors.teal.shade700, Colors.teal.shade400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;

  const _AnimatedButton({
    Key? key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.gradientColors,
  }) : super(key: key);

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: widget.gradientColors),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.last.withOpacity(0.6),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
