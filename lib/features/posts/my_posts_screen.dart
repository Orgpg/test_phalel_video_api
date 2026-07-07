import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/services/post_service.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  List<dynamic> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await context.read<PostService>().getMyPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Submissions')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _posts.isEmpty
          ? const Center(child: Text('No submissions yet'))
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostItem(post);
              },
            ),
    );
  }

  Widget _buildPostItem(dynamic post) {
    final status = post['status'] ?? 'PENDING';
    final createdAt = post['createdAt'] != null ? DateTime.parse(post['createdAt']) : DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(status),
                Text(DateFormat('MMM dd, yyyy').format(createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 12),
            Text(post['body'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
            if (post['imageUrl'] != null) ...[
              const SizedBox(height: 12),
              Image.network(post['imageUrl'], height: 100, width: double.infinity, fit: BoxFit.cover),
            ],
            if (status == 'REJECTED' && post['moderationNote'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.shade50,
                child: Text('Note: ${post['moderationNote']}', style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'APPROVED': color = Colors.green; break;
      case 'REJECTED': color = Colors.red; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }
}
