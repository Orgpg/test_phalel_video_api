import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/providers/wallet_provider.dart';

class TopupBottomSheet extends StatefulWidget {
  const TopupBottomSheet({super.key});

  @override
  State<TopupBottomSheet> createState() => _TopupBottomSheetState();
}

class _TopupBottomSheetState extends State<TopupBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _coinsController = TextEditingController();
  final _mmkController = TextEditingController();
  XFile? _screenshot;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (img != null) setState(() => _screenshot = img);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _screenshot == null) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<WalletProvider>().submitTopupRequest(
        screenshot: _screenshot!,
        requestedCoins: _coinsController.text.trim(),
        mmkAmount: _mmkController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Topup request submitted for review'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Top Up Skill Coins', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _coinsController,
                decoration: const InputDecoration(labelText: 'Amount of Coins', border: OutlineInputBorder(), prefixIcon: Icon(Icons.stars)),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mmkController,
                decoration: const InputDecoration(labelText: 'MMK Amount Paid', border: OutlineInputBorder(), prefixIcon: Icon(Icons.money)),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Payment Screenshot', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12), color: Colors.grey.shade50),
                  child: _screenshot != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildImagePreview(),
                        )
                      : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.grey), SizedBox(height: 8), Text('Select Screenshot', style: TextStyle(color: Colors.grey))])),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      return Image.network(_screenshot!.path, fit: BoxFit.cover, width: double.infinity);
    } else {
      return Image.file(File(_screenshot!.path), fit: BoxFit.cover, width: double.infinity);
    }
  }
}
