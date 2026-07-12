import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/comment.dart';
import '../../../core/services/social_service.dart';
import '../../../core/services/post_service.dart';
import '../../../core/providers/feed_provider.dart';
import '../../../core/providers/auth_provider.dart';

class CommentBottomSheet extends StatefulWidget {
  final String videoId; // Also used for postId
  final bool isPost;
  const CommentBottomSheet({super.key, required this.videoId, this.isPost = false});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;
  String? _nextCursor;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments({bool refresh = false}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }
    if (!_hasMore && !refresh) return;

    try {
      CommentResponse response;
      if (widget.isPost) {
        response = await context.read<PostService>().getPostComments(widget.videoId, cursor: _nextCursor);
      } else {
        response = await context.read<SocialService>().getComments(widget.videoId, cursor: _nextCursor);
      }

      setState(() {
        if (refresh) {
          _comments = response.comments;
        } else {
          _comments.addAll(response.comments);
        }
        _nextCursor = response.nextCursor;
        _hasMore = _nextCursor != null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading comments: $e');
    }
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final body = _commentController.text.trim();
    _commentController.clear();

    try {
      Comment newComment;
      if (widget.isPost) {
        newComment = await context.read<PostService>().createPostComment(widget.videoId, body);
      } else {
        newComment = await context.read<SocialService>().createComment(widget.videoId, body);
      }

      setState(() {
        _comments.insert(0, newComment);
      });
      // Update feed stats if on video
      if (!widget.isPost && mounted) {
        context.read<FeedProvider>().updateItemStats(widget.videoId, comments: _comments.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post comment: $e')));
      }
    }
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Delete this comment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      if (widget.isPost) {
        await context.read<PostService>().deletePostComment(widget.videoId, comment.id);
      } else {
        await context.read<SocialService>().deleteComment(widget.videoId, comment.id);
      }
      
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });
      if (!widget.isPost && mounted) {
        context.read<FeedProvider>().updateItemStats(widget.videoId, comments: _comments.length);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().user?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      child: Column(
        children: [
          Container(padding: const EdgeInsets.symmetric(vertical: 16), child: const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          const Divider(height: 1),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _comments.isEmpty
                ? const Center(child: Text('No comments yet'))
                : ListView.builder(
                    itemCount: _comments.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _comments.length) {
                        _loadComments();
                        return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                      }
                      final comment = _comments[index];
                      final isOwner = comment.userId == currentUserId;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: comment.author.avatarUrl != null ? NetworkImage(comment.author.avatarUrl!) : null,
                          child: comment.author.avatarUrl == null ? Text(comment.author.displayName[0]) : null,
                        ),
                        title: Text(comment.author.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(comment.body),
                        trailing: isOwner 
                          ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20), onPressed: () => _deleteComment(comment))
                          : null,
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8, left: 16, right: 8, top: 8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _commentController, decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none))),
                IconButton(icon: const Icon(Icons.send, color: Colors.blue), onPressed: _submitComment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
