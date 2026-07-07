import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/social_service.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await context.read<SocialService>().getFriendRequests();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequest(String requestId, bool accept) async {
    try {
      if (accept) {
        await context.read<SocialService>().acceptFriendRequest(requestId);
      } else {
        await context.read<SocialService>().rejectFriendRequest(requestId);
      }
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Friend Requests', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(child: Text('No pending requests', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final request = _requests[index];
                    final sender = request['sender'] ?? {};
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: sender['avatarUrl'] != null ? NetworkImage(sender['avatarUrl']) : null,
                        child: sender['avatarUrl'] == null ? Text(sender['name']?[0] ?? '?') : null,
                      ),
                      title: Text(sender['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('wants to be your friend', style: TextStyle(color: Colors.white60)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _handleRequest(request['id'], true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _handleRequest(request['id'], false),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
