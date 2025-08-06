import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:tibibti/screens/clent/pharmacies_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/pharmacie_model.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../l10n/app_localizations.dart';

import '../../settings_provider.dart';
import 'cart_screen.dart';
import 'menu_screen.dart';

class HomeClientScreen extends StatefulWidget {
  const HomeClientScreen({super.key});

  @override
  State<HomeClientScreen> createState() => _HomeClientScreenState();
}

class _HomeClientScreenState extends State<HomeClientScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool isDark = false;
  String searchQuery = '';
  String filter = 'Tous';
  Map<String, String> onlineStatusMap = {};
  Position? userPosition;
  bool locationPermissionDenied = false;
  int _selectedIndex = 0;
  List<Widget> get pages => [
    PharmaciesPage(
      onlineStatusMap: onlineStatusMap,
      userPosition: userPosition,
    ),
    const MenuScreen(),
  ];


  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _listenToOnlineStatuses();
  }


  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => locationPermissionDenied = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever ||
        (permission == LocationPermission.denied &&
            await Geolocator.requestPermission() != LocationPermission.whileInUse)) {
      setState(() => locationPermissionDenied = true);
      return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => userPosition = pos);
  }

  void _onMenuItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Exemple de navigation ou action selon l'index
    switch(index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushNamed(context, '/cart');
        break;
      case 2:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigate(String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  void _listenToOnlineStatuses() {
    FirebaseDatabase.instance.ref('status').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        setState(() {
          onlineStatusMap = data.map((key, value) {
            return MapEntry(key.toString(), (value as Map)['state'] ?? 'offline');
          });
        });
      }
    });
  }

  Stream<String> getOnlineStatus(String uid) {
    final ref = FirebaseDatabase.instance.ref('status/$uid/state');
    return ref.onValue.map((event) => event.snapshot.value?.toString() ?? 'offline');
  }



  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Trie une liste de jours selon l’ordre de la semaine
  List<String> trierJours(List<String> jours) {
    const ordreJours = [
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];

    jours = jours.map((j) => j.toLowerCase()).toList();

    jours.sort((a, b) {
      final indexA = ordreJours.indexOf(a);
      final indexB = ordreJours.indexOf(b);
      return indexA.compareTo(indexB);
    });

    return jours;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<SettingsProvider>().isDark;
    final tr = AppLocalizations.of(context)!;
    final appBarBgColor = isDark ? Colors.grey[900] : Colors.white;
    final appBarIconColor = isDark ? Colors.white : Colors.teal[700];
    final appBarTextColor = isDark ? Colors.white : Colors.teal[800];

    final menuBgColor = isDark ? Colors.grey[900] : Colors.white;
    final menuSelectedColor = isDark ? Colors.teal[300] : Colors.teal.shade700;
    final menuUnselectedColor = isDark ? Colors.white70 : Colors.grey.shade600;
    final menuBorderColor = isDark ? Colors.teal.shade300 : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      appBar: AppBar(
        elevation: 4,
        backgroundColor: appBarBgColor,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.capsule_fill,
              color: appBarIconColor,
              size: 26,
            ),
            const SizedBox(width: 8),
            Text(
              tr.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 22,
                color: appBarTextColor,
              ),
            ),

          ],
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/profil');
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: CircleAvatar(
              backgroundColor: isDark ? Colors.teal.shade700 : Colors.teal.shade100,
              child: Icon(
                CupertinoIcons.person_fill,
                color: isDark ? Colors.white : Colors.teal,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              CupertinoIcons.bell_fill,
              color: appBarIconColor,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: pages[_selectedIndex],

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final assets = [
              'assets/icons/home.png',
              'assets/icons/menu.png',
              'assets/icons/ordonance.png',
            ];

            final tr = AppLocalizations.of(context);
            final labels = [tr.home, tr.settings, tr.ordonance];
            final isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(
                  vertical: isSelected ? 14 : 10,
                  horizontal: isSelected ? 20 : 16,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark
                      ? Colors.teal.shade700.withOpacity(0.3)
                      : Colors.teal.shade50)
                      : menuBgColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: (isDark ? Colors.teal.shade700 : Colors.teal)
                            .withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                  ],
                  border: Border.all(
                    color: isSelected ? menuSelectedColor! : menuBorderColor!,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: isSelected ? 1.0 : 0.9,
                        end: isSelected ? 1.2 : 1.0,
                      ),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        final double translateY = isSelected ? -4 : 0;
                        return Transform.translate(
                          offset: Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: assets[index].endsWith('.svg')
                            ? SvgPicture.asset(
                          assets[index],
                          fit: BoxFit.contain,
                          color:
                          isSelected ? menuSelectedColor : menuUnselectedColor,
                        )
                            : Image.asset(
                          assets[index],
                          fit: BoxFit.contain,
                          color:
                          isSelected ? menuSelectedColor : menuUnselectedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? menuSelectedColor : menuUnselectedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }



}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// Widget bouton animé personnalisé
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;

  const _AnimatedButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.gradientColors,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.last.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}