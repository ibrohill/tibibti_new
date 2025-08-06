import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/pharmacie_model.dart';
import 'Produit_Detail_Client_Screen.dart';
import 'chat_screen.dart';
import 'prescription_uploader.dart';

class PharmacieDetailsScreen extends StatefulWidget {
  const PharmacieDetailsScreen({super.key});

  @override
  State<PharmacieDetailsScreen> createState() => _PharmacieDetailsScreenState();
}

class _PharmacieDetailsScreenState extends State<PharmacieDetailsScreen> {
  String _searchQuery = '';
  Timer? _debounce;
  final Set<String> _favoriteProductIds = {}; // favoris locaux

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => _searchQuery = query.trim().toLowerCase());
    });
  }

  Stream<String> getOnlineStatus(String uid) {
    final ref = FirebaseDatabase.instance.ref('status/$uid/state');
    return ref.onValue
        .asBroadcastStream()
        .map((event) => event.snapshot.value?.toString() ?? 'offline');
  }


  String formattedDays(List<String> days) {
    if (days.isEmpty) return '—';
    return days.map((d) => d[0].toUpperCase() + d.substring(1)).join(', ');
  }

  void _openOrdonnanceModal(BuildContext context, String pharmacyId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Envoyer une ordonnance',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // On passe bien l'ID ici
              PrescriptionUploader(pharmacyId: pharmacyId),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  void _openInfoDrawer(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _drawerInfoRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(
                    text: '$title: ',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget productImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(color: Colors.grey.shade200);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(color: Colors.grey.shade200),
      errorWidget: (_, __, ___) =>
          Container(color: Colors.grey.shade200, child: const Icon(Icons.medical_services, size: 40)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Pharmacie pharmacie =
    ModalRoute.of(context)!.settings.arguments as Pharmacie;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: _buildInfoDrawer(pharmacie),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: const BackButton(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade200,
              backgroundImage:
              pharmacie.imageUrl.isNotEmpty ? NetworkImage(pharmacie.imageUrl) : null,
              child: pharmacie.imageUrl.isEmpty
                  ? const Icon(Icons.local_pharmacy, color: Colors.teal)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pharmacie.name,
                style: const TextStyle(
                    color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<String>(
            stream: getOnlineStatus(pharmacie.id),
            builder: (context, snapshot) {
              final status = snapshot.data ?? 'offline';
              final isOnline = status == 'online';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _statusBadge(isOnline ? 'En ligne' : 'Hors ligne',
                    isOnline ? Colors.green : Colors.red),
              );
            },
          ),
          if (pharmacie.isOnDuty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _statusBadge('En garde', Colors.orange),
            ),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.teal),
              onPressed: () => _openInfoDrawer(ctx),
              tooltip: 'Détails pharmacie',
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openOrdonnanceModal(context, pharmacie.id),
        label: const Text('Ordonnance'),
        icon: const Icon(Icons.receipt_long),
        backgroundColor: Colors.teal,
      ),

      body: CustomScrollView(
        slivers: [
          // recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un médicament',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),

          // produits
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('createdBy', isEqualTo: pharmacie.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Aucun médicament trouvé')),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final productId = doc.id;
                      final isFav = _favoriteProductIds.contains(productId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    ProduitDetailClientScreen(product: doc)),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                // image
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(14),
                                    bottomLeft: Radius.circular(14),
                                  ),
                                  child: SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: Image.asset(
                                      'assets/images/logo1.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),
                                // info
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['description'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          "${data['price'] ?? ''} MRU",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, color: Colors.teal),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // actions
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isFav ? Icons.favorite : Icons.favorite_border,
                                        color: isFav ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          if (isFav)
                                            _favoriteProductIds.remove(productId);
                                          else
                                            _favoriteProductIds.add(productId);
                                        });
                                      },
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4),
                                      child: Icon(Icons.arrow_forward_ios,
                                          size: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildInfoDrawer(Pharmacie pharmacie) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pharmacie.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (pharmacie.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: pharmacie.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey.shade200),
                    errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StreamBuilder<String>(
                    stream: getOnlineStatus(pharmacie.id),
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? 'offline';
                      final isOnline = status == 'online';
                      return _statusBadge(isOnline ? 'En ligne' : 'Hors ligne',
                          isOnline ? Colors.green : Colors.red);
                    },
                  ),
                  const SizedBox(width: 8),
                  if (pharmacie.isOnDuty) _statusBadge('En garde', Colors.orange),
                ],
              ),
              const SizedBox(height: 16),
              _drawerInfoRow(Icons.location_on, 'Adresse', pharmacie.adresse),
              const SizedBox(height: 8),
              _drawerInfoRow(Icons.phone, 'Téléphone', pharmacie.telephone),
              const SizedBox(height: 8),
              if (pharmacie.openingHours.isNotEmpty)
                _drawerInfoRow(Icons.access_time, 'Horaires', pharmacie.openingHours),
              const SizedBox(height: 8),
              if (pharmacie.openingDays.isNotEmpty)
                _drawerInfoRow(Icons.calendar_today, 'Jours', formattedDays(pharmacie.openingDays)),
              if (pharmacie.categorie.isNotEmpty) ...[
                const SizedBox(height: 12),
                _drawerInfoRow(Icons.category, 'Catégorie', pharmacie.categorie),
              ],
              if (pharmacie.services.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Services proposés', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: pharmacie.services
                      .map((s) => Chip(
                    label: Text(s),
                    backgroundColor: Colors.teal.shade50,
                    labelStyle: const TextStyle(color: Colors.teal),
                  ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 6),
                  Text('${pharmacie.rating.toStringAsFixed(1)} (${pharmacie.reviewsCount} avis)'),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        recipientId: pharmacie.id,
                        recipientName: pharmacie.name,
                      )),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contacter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(44),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
