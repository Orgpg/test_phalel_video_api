import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/social_service.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<dynamic> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await context.read<SocialService>().getFriends();
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Friends', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _friends.isEmpty
              ? const Center(child: Text('No friends yet', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: _friends.length,
                  itemBuilder: (context, index) {
                    final friend = _friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend['avatarUrl'] != null ? NetworkImage(friend['avatarUrl']) : null,
                        child: friend['avatarUrl'] == null ? Text(friend['name'][0]) : null,
                      ),
                      title: Text(friend['name'], style: const TextStyle(color: Colors.white)),
                      subtitle: Text('@${friend['username'] ?? friend['name']}', style: const TextStyle(color: Colors.white60)),
                      trailing: IconButton(
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        onPressed: () {},
                      ),
                    );
                  },
                ),
    );
  }
}
