// lib/screens/splash/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));

    final user = _auth.currentUser;
    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final role = doc['role'];
      if (role == 'client') {
        Navigator.pushReplacementNamed(context, '/home_client');
      } else if (role == 'pharmacien') {
        Navigator.pushReplacementNamed(context, '/home_pharmacien');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/logo1.png', width: 500),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Colors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
