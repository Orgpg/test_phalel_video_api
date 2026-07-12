import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';
import '../../../core/providers/post_provider.dart';
import '../../../core/providers/user_provider.dart';
import 'comment_bottom_sheet.dart';

class PostFeedItem extends StatelessWidget {
  final FeedItem item;
  const PostFeedItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 80),
      child: Center(
        child: Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorRow(context),
                const SizedBox(height: 20),
                if (item.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.imageUrl!, fit: BoxFit.cover, width: double.infinity),
                  ),
                  const SizedBox(height: 20),
                ],
                Text(
                  item.body ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildPostAction(
                          icon: item.viewerState.liked ? Icons.favorite : Icons.favorite_border,
                          label: '${item.stats.likes}',
                          color: item.viewerState.liked ? Colors.red : Colors.white70,
                          onTap: () => context.read<PostProvider>().toggleLike(item.id),
                        ),
                        const SizedBox(width: 24),
                        _buildPostAction(
                          icon: Icons.comment_outlined,
                          label: '${item.stats.comments}',
                          onTap: () => _showComments(context),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(item.viewerState.saved ? Icons.bookmark : Icons.bookmark_border, color: item.viewerState.saved ? Colors.amber : Colors.white70),
                      onPressed: () => context.read<PostProvider>().toggleSave(item.id, onUnsave: (id) {
                         context.read<UserProvider>().removeSavedItem(id);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _goToProfile(context),
          child: CircleAvatar(
            backgroundImage: item.author.avatarUrl != null ? NetworkImage(item.author.avatarUrl!) : null,
            child: item.author.avatarUrl == null ? Text(item.author.name[0]) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _goToProfile(context),
                child: Text(item.author.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (item.createdAt != null)
                Text(_formatTime(item.createdAt!), style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
        if (item.viewerState.friendStatus != FriendStatus.SELF) ...[
          _buildFollowButton(context),
          const SizedBox(width: 8),
          _buildFriendButton(context),
        ],
      ],
    );
  }

  void _goToProfile(BuildContext context) {
     context.push('/public-profile', extra: item.author.id);
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  Widget _buildFollowButton(BuildContext context) {
    final followed = item.viewerState.followedAuthor;
    return GestureDetector(
      onTap: () => context.read<FeedProvider>().toggleFollow(item.author.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white38),
          borderRadius: BorderRadius.circular(4),
          color: followed ? Colors.transparent : Colors.white10,
        ),
        child: Text(
          followed ? 'Following' : 'Follow',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildFriendButton(BuildContext context) {
    final status = item.viewerState.friendStatus;
    if (status == FriendStatus.FRIENDS) {
      return const Icon(Icons.people, color: Colors.blue, size: 20);
    }
    return GestureDetector(
      onTap: () {
        context.read<FeedProvider>().sendFriendRequest(item.author.id);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent')));
      },
      child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 20),
    );
  }

  Widget _buildPostAction({required IconData icon, required String label, Color color = Colors.white70, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentBottomSheet(videoId: item.id, isPost: true),
    );
  }
}
