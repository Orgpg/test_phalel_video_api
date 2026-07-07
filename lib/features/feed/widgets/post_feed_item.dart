import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/feed_item.dart';
import '../../../core/providers/feed_provider.dart';

class PostFeedItem extends StatelessWidget {
  final FeedItem item;
  const PostFeedItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(child: Text(item.author.name[0])),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.author.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (item.viewerState.friendStatus != FriendStatus.SELF) ...[
                      _buildFollowButton(context),
                      const SizedBox(width: 8),
                      _buildFriendButton(context),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                if (item.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(item.imageUrl!, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  item.body ?? '',
                  style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPostAction(
                      icon: item.viewerState.liked ? Icons.favorite : Icons.favorite_border,
                      label: '${item.stats.likes}',
                      color: item.viewerState.liked ? Colors.red : Colors.white70,
                      onTap: () => context.read<FeedProvider>().toggleLike(item.id),
                    ),
                    _buildPostAction(
                      icon: Icons.comment_outlined,
                      label: '${item.stats.comments}',
                      onTap: () {},
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

  Widget _buildFollowButton(BuildContext context) {
    final followed = item.viewerState.followedAuthor;
    return GestureDetector(
      onTap: () => context.read<FeedProvider>().toggleFollow(item.author.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
          color: followed ? Colors.transparent : Colors.white.withOpacity(0.2),
        ),
        child: Text(
          followed ? 'Following' : 'Follow',
          style: const TextStyle(color: Colors.white, fontSize: 12),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
