import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/mentor_provider.dart';
import '../../core/models/mentor_listing.dart';

class MentorManagementScreen extends StatefulWidget {
  const MentorManagementScreen({super.key});

  @override
  State<MentorManagementScreen> createState() => _MentorManagementScreenState();
}

class _MentorManagementScreenState extends State<MentorManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MentorProvider>().fetchMyListings();
    });
  }

  void _showListingDialog([MentorListing? listing]) {
    final isEdit = listing != null;
    final titleController = TextEditingController(text: listing?.title);
    final descController = TextEditingController(text: listing?.description);
    final priceController = TextEditingController(text: listing?.coinPrice.toString());
    final durationController = TextEditingController(text: listing?.durationMinutes.toString());
    String category = listing?.category ?? 'Language';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Listing' : 'Create Mentor Listing'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              DropdownButtonFormField<String>(
                value: category,
                items: ['Language', 'Technology', 'Business', 'Arts', 'Music']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => category = v!,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Coin Price'), keyboardType: TextInputType.number),
              TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration (mins)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'description': descController.text,
                'category': category,
                'coinPrice': int.tryParse(priceController.text) ?? 0,
                'durationMinutes': int.tryParse(durationController.text) ?? 0,
              };
              try {
                if (isEdit) {
                  await context.read<MentorProvider>().updateListing(listing.id, data);
                } else {
                  await context.read<MentorProvider>().createListing(data);
                }
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Mentor Listings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<MentorProvider>(
        builder: (context, provider, child) {
          if (provider.myListings.isEmpty) {
            return const Center(child: Text('You have no active mentor listings.'));
          }

          return ListView.builder(
            itemCount: provider.myListings.length,
            itemBuilder: (context, index) {
              final item = provider.myListings[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text('${item.coinPrice} Coins | ${item.durationMinutes} mins'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _showListingDialog(item)),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => provider.deleteListing(item.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showListingDialog(),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
