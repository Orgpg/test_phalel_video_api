import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../video_provider.dart';

class FolderList extends StatelessWidget {
  const FolderList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VideoProvider>();
    final folders = provider.folders;

    if (folders.isEmpty) {
      return const Center(child: Text('No folders found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        final videoCount = provider.videosByFolder(folder).length;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: const CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.folder, color: Colors.white),
            ),
            title: Text(
              folder,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('$videoCount Videos'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/folder-videos', extra: folder),
          ),
        );
      },
    );
  }
}
