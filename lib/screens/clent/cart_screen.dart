import 'package:flutter/material.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Panier'),
      //   backgroundColor: Colors.teal[700],
      //   centerTitle: true,
      // ),
      body: const Center(
        child: Text(
          'Votre panier est vide.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
