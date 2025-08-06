import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tibibti/services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _obscurePassword = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        setState(() {
          _error = 'Utilisateur introuvable dans la base.';
          _loading = false;
        });
        await _auth.signOut();
        return;
      }

      final role = userDoc.data()?['role']?.toString().trim().toLowerCase();

      await _firestore.collection('users').doc(uid).update({
        'isOnline': true,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      _setOnlineStatus(uid);

      if (role == 'client') {
        Navigator.pushReplacementNamed(context, '/home_client');
      } else if (role == 'pharmacien') {
        Navigator.pushReplacementNamed(context, '/home_pharmacien');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        setState(() {
          _error = 'Rôle inconnu : $role';
          _loading = false;
        });
        await _auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur inconnue : $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _setOnlineStatus(String uid) {
    final statusRef = FirebaseDatabase.instance.ref('status/$uid');

    // Quand connecté
    statusRef.set({
      'state': 'online',
      'last_changed': ServerValue.timestamp,
    });

    // Quand déconnecté (fermeture brutale, perte réseau)
    statusRef.onDisconnect().set({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
    });
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userCredential = await AuthService().signInWithGoogle();

    if (userCredential != null) {
      final uid = userCredential.user!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      final role = doc.data()?['role']?.toString().trim().toLowerCase();

      if (role == 'client') {
        Navigator.pushReplacementNamed(context, '/home_client');
      } else if (role == 'pharmacien') {
        Navigator.pushReplacementNamed(context, '/home_pharmacien');
      } else if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        setState(() {
          _error = "Rôle inconnu : $role";
        });
      }
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo1.png', height: 260),
              const SizedBox(height: 10),

              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val == null || !val.contains('@') ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,  // <-- contrôle l'affichage du mot de passe
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) => val != null && val.length < 6 ? 'Mot de passe trop court' : null,
                    ),

                    const SizedBox(height: 66),
                    _loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                      ),
                      child: const Text("Se connecter", style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(height: 20),
                    const Text("Ou", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _loginWithGoogle,
                      icon: Image.asset('assets/images/google_logo.png', height: 28),
                      label: const Text('Continuer avec Google'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text("Pas encore de compte ? S'inscrire"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
