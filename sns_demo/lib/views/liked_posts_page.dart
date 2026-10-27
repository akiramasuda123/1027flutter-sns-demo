import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/firestore_service.dart';

class LikedPostsPage extends StatelessWidget {
  final String userId;
  const LikedPostsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('いいねした投稿')),
      body: StreamBuilder<List<Post>>(
        stream: service.getLikedPostsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data ?? [];
          if (posts.isEmpty) return const Center(child: Text('いいねした投稿はありません'));
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return ListTile(
                leading: CircleAvatar(child: Text(post.author[0])),
                title: Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(post.content),
              );
            },
          );
        },
      ),
    );
  }
}
