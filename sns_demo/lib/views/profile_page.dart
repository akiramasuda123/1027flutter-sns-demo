import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import 'follow_list_page.dart';

class ProfilePage extends StatefulWidget {
  final String uid;
  const ProfilePage({required this.uid, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _userService = UserService();
  final _followService = FollowService();
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;

  bool get _isMe => FirebaseAuth.instance.currentUser?.uid == widget.uid;
  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _userService.updateUser(widget.uid, name: _nameController.text.trim(), bio: _bioController.text.trim());
      await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          if (_isMe)
            TextButton(
              onPressed: _isEditing ? (_isLoading ? null : _save) : () => setState(() => _isEditing = true),
              child: Text(_isEditing ? '保存' : '編集',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: StreamBuilder<AppUser?>(
        stream: _userService.getUserStream(widget.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = snapshot.data;
          if (user == null) return const Center(child: Text('ユーザーが見つかりません'));

          if (_isEditing && _nameController.text.isEmpty) {
            _nameController.text = user.name;
            _bioController.text = user.bio;
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    child: Text(user.name[0], style: const TextStyle(fontSize: 32)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: _isEditing
                      ? TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ユーザー名'))
                      : Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Center(child: Text(user.email, style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 12),
                // フォロー・フォロワー数
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FollowCount(
                      stream: _followService.followingCountStream(widget.uid),
                      label: 'フォロー',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FollowListPage(uid: widget.uid, showFollowing: true))),
                    ),
                    const SizedBox(width: 32),
                    _FollowCount(
                      stream: _followService.followerCountStream(widget.uid),
                      label: 'フォロワー',
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => FollowListPage(uid: widget.uid, showFollowing: false))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // フォローボタン（他人のプロフィールのみ）
                if (!_isMe)
                  StreamBuilder<bool>(
                    stream: _followService.isFollowingStream(_currentUid, widget.uid),
                    builder: (context, snapshot) {
                      final isFollowing = snapshot.data ?? false;
                      return Center(
                        child: ElevatedButton(
                          onPressed: () => isFollowing
                              ? _followService.unfollow(_currentUid, widget.uid)
                              : _followService.follow(_currentUid, widget.uid),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey[200] : Colors.blue,
                            foregroundColor: isFollowing ? Colors.black : Colors.white,
                          ),
                          child: Text(isFollowing ? 'フォロー中' : 'フォローする'),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 16),
                _isEditing
                    ? TextField(controller: _bioController, decoration: const InputDecoration(labelText: '自己紹介'), maxLines: 3)
                    : Text(user.bio.isEmpty ? '自己紹介がありません' : user.bio, style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FollowCount extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final VoidCallback onTap;

  const _FollowCount({required this.stream, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          return Column(
            children: [
              Text('${snapshot.data ?? 0}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          );
        },
      ),
    );
  }
}
