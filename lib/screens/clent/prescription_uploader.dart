import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Simule l'envoi d'une ordonnance vers une pharmacie donnée (localement).
class PrescriptionUploader extends StatefulWidget {
  final String pharmacyId;
  final void Function()? onSent;

  const PrescriptionUploader({
    required this.pharmacyId,
    this.onSent,
    super.key,
  });

  @override
  State<PrescriptionUploader> createState() => _PrescriptionUploaderState();
}

class _PrescriptionUploaderState extends State<PrescriptionUploader> {
  XFile? _pickedFile;
  bool _uploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromCamera() async {
    try {
      final picked =
      await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (picked != null) {
        setState(() => _pickedFile = picked);
      }
    } catch (e) {
      _showMessage('Erreur lors de la prise de photo : $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() => _pickedFile = picked);
      }
    } catch (e) {
      _showMessage('Erreur lors de la sélection : $e');
    }
  }

  Future<void> _sendPrescription() async {
    if (_pickedFile == null || _uploading) return;
    setState(() => _uploading = true);

    // Simulation d’envoi local (tu peux remplacer par logique réelle plus tard)
    await Future.delayed(const Duration(seconds: 2));

    // Ici tu peux par exemple stocker en local une trace avec widget.pharmacyId
    // ou préparer un objet pour envoyer à Firestore / backend quand prêt.

    setState(() {
      _uploading = false;
      _pickedFile = null;
    });

    _showMessage('Ordonnance envoyée à la pharmacie ${widget.pharmacyId} (simulation)');

    if (widget.onSent != null) widget.onSent!();
  }

  void _showMessage(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Widget _buildPreview() {
    if (_pickedFile != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedFile!.readAsBytes(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.done && snap.hasData) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(snap.data!, fit: BoxFit.cover),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(_pickedFile!.path), fit: BoxFit.cover),
        );
      }
    } else {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Icon(Icons.receipt_long, size: 48, color: Colors.teal),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aperçu
        SizedBox(height: 160, width: double.infinity, child: _buildPreview()),
        const SizedBox(height: 12),
        Text(
          'Ordonnance pour pharmacie : ${widget.pharmacyId}',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scanner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_pickedFile != null && !_uploading) ? _sendPrescription : null,
            icon: _uploading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.send),
            label: Text(_uploading ? 'Envoi...' : 'Envoyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
