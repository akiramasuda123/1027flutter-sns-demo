import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class FollowService {
  final _follows = FirebaseFirestore.instance.collection('follows');
  final _users = FirebaseFirestore.instance.collection('users');

  String _docId(String followerId, String followingId) => '${followerId}_$followingId';

  Future<void> follow(String followerId, String followingId) async {
    await _follows.doc(_docId(followerId, followingId)).set({
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> unfollow(String followerId, String followingId) async {
    await _follows.doc(_docId(followerId, followingId)).delete();
  }

  Stream<bool> isFollowingStream(String followerId, String followingId) {
    return _follows.doc(_docId(followerId, followingId)).snapshots().map((doc) => doc.exists);
  }

  Stream<int> followingCountStream(String uid) {
    return _follows.where('followerId', isEqualTo: uid).snapshots().map((s) => s.size);
  }

  Stream<int> followerCountStream(String uid) {
    return _follows.where('followingId', isEqualTo: uid).snapshots().map((s) => s.size);
  }

  Stream<List<AppUser>> getFollowingUsersStream(String uid) {
    return _follows.where('followerId', isEqualTo: uid).snapshots().asyncMap((snapshot) async {
      final ids = snapshot.docs.map((d) => d['followingId'] as String).toList();
      if (ids.isEmpty) return [];
      final users = await Future.wait(ids.map((id) => _users.doc(id).get()));
      return users.where((d) => d.exists).map((d) => AppUser.fromFirestore(d)).toList();
    });
  }

  Stream<List<AppUser>> getFollowerUsersStream(String uid) {
    return _follows.where('followingId', isEqualTo: uid).snapshots().asyncMap((snapshot) async {
      final ids = snapshot.docs.map((d) => d['followerId'] as String).toList();
      if (ids.isEmpty) return [];
      final users = await Future.wait(ids.map((id) => _users.doc(id).get()));
      return users.where((d) => d.exists).map((d) => AppUser.fromFirestore(d)).toList();
    });
  }

  Stream<List<String>> getFollowingIdsStream(String uid) {
    return _follows.where('followerId', isEqualTo: uid).snapshots().map((s) => s.docs.map((d) => d['followingId'] as String).toList());
  }
}
