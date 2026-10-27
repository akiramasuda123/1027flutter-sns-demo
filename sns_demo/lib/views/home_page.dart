import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/follow_service.dart';
import 'edit_post_page.dart';
import 'liked_posts_page.dart';
import 'post_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showFollowingOnly = false;

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final followService = FollowService();
    final authService = AuthService();
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Row(
            children: [
              _TabButton(label: 'すべて', selected: !_showFollowingOnly, onTap: () => setState(() => _showFollowingOnly = false)),
              _TabButton(label: 'フォロー中', selected: _showFollowingOnly, onTap: () => setState(() => _showFollowingOnly = true)),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'いいねした投稿',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LikedPostsPage(userId: currentUser.uid))),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => authService.logout(),
          ),
        ],
      ),
      body: _showFollowingOnly
          ? StreamBuilder<List<String>>(
              stream: followService.getFollowingIdsStream(currentUser.uid),
              builder: (context, followSnapshot) {
                final followingIds = followSnapshot.data ?? [];
                return StreamBuilder<List<Post>>(
                  stream: firestoreService.getPostsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final posts = (snapshot.data ?? []).where((p) => followingIds.contains(p.userId)).toList();
                    if (posts.isEmpty) return const Center(child: Text('フォロー中のユーザーの投稿がありません'));
                    return _PostList(posts: posts, currentUser: currentUser, firestoreService: firestoreService);
                  },
                );
              },
            )
          : StreamBuilder<List<Post>>(
              stream: firestoreService.getPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return const Center(child: Text('エラーが発生しました'));
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) return const Center(child: Text('まだ投稿がありません。最初のポストをしてみよう！'));
                return _PostList(posts: posts, currentUser: currentUser, firestoreService: firestoreService);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostPage())),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? Colors.blue : Colors.transparent, width: 2)),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.blue : Colors.grey)),
        ),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final List<Post> posts;
  final User currentUser;
  final FirestoreService firestoreService;

  const _PostList({required this.posts, required this.currentUser, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final isLiked = post.likes.contains(currentUser.uid);
        final isMyPost = post.userId == currentUser.uid;

        return ListTile(
          leading: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(uid: post.userId))),
            child: CircleAvatar(child: Text(post.author[0])),
          ),
          title: Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(post.content, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey, size: 20),
                    onPressed: () => firestoreService.toggleLike(post.id, currentUser.uid, isLiked),
                  ),
                  Text('${post.likes.length}'),
                ],
              ),
            ],
          ),
          trailing: isMyPost
              ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditPostPage(post: post)));
                    } else if (value == 'delete') {
                      await firestoreService.deletePost(post.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('編集')),
                    PopupMenuItem(value: 'delete', child: Text('削除')),
                  ],
                )
              : null,
        );
      },
    );
  }
}
