import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/follow_service.dart';
import 'profile_page.dart';

class FollowListPage extends StatelessWidget {
  final String uid;
  final bool showFollowing;

  const FollowListPage({required this.uid, required this.showFollowing, super.key});

  @override
  Widget build(BuildContext context) {
    final followService = FollowService();
    final stream = showFollowing
        ? followService.getFollowingUsersStream(uid)
        : followService.getFollowerUsersStream(uid);

    return Scaffold(
      appBar: AppBar(title: Text(showFollowing ? 'フォロー中' : 'フォロワー')),
      body: StreamBuilder<List<AppUser>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) return Center(child: Text(showFollowing ? 'フォロー中のユーザーはいません' : 'フォロワーはいません'));
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name[0])),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.bio.isEmpty ? '' : user.bio),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(uid: user.uid))),
              );
            },
          );
        },
      ),
    );
  }
}
