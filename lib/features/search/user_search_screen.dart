import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/user_provider.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<UserProvider>().searchUsers(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search users...', border: InputBorder.none),
          onChanged: _onSearchChanged,
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.searchState == UserState.loading) return const Center(child: CircularProgressIndicator());
          if (provider.searchResults.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: provider.searchResults.length,
            itemBuilder: (context, index) {
              final user = provider.searchResults[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!.startsWith('/api') ? 'https://phaleldb.waiphyoaung.dev${user.avatarUrl}' : user.avatarUrl!) : null,
                  child: user.avatarUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(user.name),
                subtitle: Text('@${user.username}'),
                onTap: () => context.push('/public-profile', extra: user.id),
              );
            },
          );
        },
      ),
    );
  }
}
