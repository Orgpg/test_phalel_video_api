import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'feed/feed_screen.dart';
import 'friends/friends_screen.dart';
import 'friends/friend_requests_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const FriendsScreen(),
    const Placeholder(), // Placeholder for Create
    const FriendRequestsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _showCreateMenu();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Upload Video'),
              onTap: () {
                Navigator.pop(context);
                context.push('/upload');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Create Post'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-post');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box, size: 32), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
