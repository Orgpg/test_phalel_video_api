import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/mobile_user.dart';
import '../../core/services/user_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
import '../feed/widgets/post_feed_item.dart';

class PublicProfileScreen extends StatefulWidget {
  final String userId;
  const PublicProfileScreen({super.key, required this.userId});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileUser? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final user = await context.read<UserService>().getUser(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
      // Load user posts
      context.read<PostProvider>().fetchPosts(refresh: true, authorId: widget.userId);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar: AppBar(), body: Center(child: Text('Error: $_error')));
    if (_user == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('User not found')));

    final isSelf = _user!.id == context.read<AuthProvider>().user?.id;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(_user!),
            ),
            actions: [
              if (isSelf)
                IconButton(icon: const Icon(Icons.edit), onPressed: () => context.push('/edit-profile')),
            ],
          ),
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'Posts'), Tab(text: 'Uploads')],
              ),
            ),
            pinned: true,
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            const Center(child: Text('Videos Tab (Coming Soon)')),
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
          if (user.bio != null) Padding(padding: const EdgeInsets.all(8.0), child: Text(user.bio!, style: const TextStyle(color: Colors.white))),
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
