import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import '../../core/models/feed_item.dart';
import '../../core/models/user_verification.dart';
import '../../core/models/mobile_user.dart';
import '../../core/models/video_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../core/services/verification_service.dart';
import '../../core/network/dio_client.dart';
import '../feed/widgets/post_feed_item.dart';
import '../home/widgets/video_list.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _resetPasswordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isResettingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  void _loadInitialData() {
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      context.read<PostProvider>().fetchPosts(refresh: true, authorId: user.id);
      context.read<UserProvider>().fetchMyUploads(refresh: true);
      context.read<UserProvider>().fetchMySaved(refresh: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_resetPasswordFormKey.currentState!.validate()) return;
    setState(() => _isResettingPassword = true);
    try {
      await context.read<AuthProvider>().resetPassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated'), backgroundColor: Colors.green));
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isResettingPassword = false);
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await context.read<AuthProvider>().deleteAccount();
        if (mounted) context.go('/login');
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(user),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: () => context.push('/search-users')),
              IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/edit-profile')),
              IconButton(icon: const Icon(Icons.settings), onPressed: () => _showSettings(context)),
            ],
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Posts'), Tab(text: 'Uploads'), Tab(text: 'Saved')],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildUploadsTab(),
            _buildSavedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MobileUser user) {
    return Container(
      color: Colors.deepPurple,
      padding: const EdgeInsets.only(top: 80, bottom: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!.startsWith('/api') ? 'https://phaleldb.waiphyoaung.dev${user.avatarUrl}' : user.avatarUrl!) : null,
            child: user.avatarUrl == null ? const Icon(Icons.person, size: 50) : null,
          ),
          const SizedBox(height: 12),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text('@${user.username}', style: const TextStyle(color: Colors.white70)),
          if (user.bio != null && user.bio!.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Text(user.bio!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Followers', user.stats?.followers ?? 0),
              _buildStat('Following', user.stats?.following ?? 0),
              _buildStat('Posts', user.stats?.authoredPosts ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int count) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildPostsTab() {
    return Consumer<PostProvider>(
      builder: (context, provider, child) {
        if (provider.state == PostState.loading && provider.posts.isEmpty) return const Center(child: CircularProgressIndicator());
        if (provider.posts.isEmpty) return const Center(child: Text('No posts yet'));
        return ListView.builder(
          itemCount: provider.posts.length,
          itemBuilder: (context, index) => PostFeedItem(item: provider.posts[index]),
        );
      },
    );
  }

  Widget _buildUploadsTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.uploadsState == UserState.loading && provider.myUploads.isEmpty) return const Center(child: CircularProgressIndicator());
        if (provider.myUploads.isEmpty) return const Center(child: Text('No uploads yet'));
        // Mapping FeedItem to VideoModel for existing VideoList
        final videos = provider.myUploads.map((e) => VideoModel.fromFeedItem(e)).toList();
        return VideoList(videos: videos, onRefresh: () => provider.fetchMyUploads(refresh: true));
      },
    );
  }

  Widget _buildSavedTab() {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        if (provider.savedState == UserState.loading && provider.mySaved.isEmpty) return const Center(child: CircularProgressIndicator());
        if (provider.mySaved.isEmpty) return const Center(child: Text('No saved items yet'));
        return ListView.builder(
          itemCount: provider.mySaved.length,
          itemBuilder: (context, index) {
            final item = provider.mySaved[index];
            if (item.type == FeedItemType.VIDEO) return PostFeedItem(item: item); // Simplified for mixed
            return PostFeedItem(item: item);
          },
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.lock_outline), title: const Text('Reset Password'), onTap: () { Navigator.pop(context); _showResetPasswordDialog(); }),
            ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete Account', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); _handleDeleteAccount(); }),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () { Navigator.pop(context); context.read<AuthProvider>().logout(); }),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Form(
          key: _resetPasswordFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: _currentPasswordController, decoration: const InputDecoration(labelText: 'Current Password'), obscureText: true),
              const SizedBox(height: 8),
              TextFormField(controller: _newPasswordController, decoration: const InputDecoration(labelText: 'New Password'), obscureText: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: _handleResetPassword, child: const Text('Update')),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

