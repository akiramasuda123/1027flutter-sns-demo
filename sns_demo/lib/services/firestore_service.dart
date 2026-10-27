import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

class FirestoreService {
  final _posts = FirebaseFirestore.instance.collection('posts');

  Future<void> addPost(String content, String author, String userId) async {
    await _posts.add({
      'content': content,
      'author': author,
      'userId': userId,
      'createdAt': Timestamp.now(),
      'likes': [],
    });
  }

  Stream<List<Post>> getPostsStream() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  Stream<List<Post>> getMyPostsStream(String userId) {
    return _posts
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  Stream<List<Post>> getLikedPostsStream(String userId) {
    return _posts
        .where('likes', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) => Post.fromFirestore(doc)).toList());
  }

  Future<void> updatePost(String postId, String content) async {
    await _posts.doc(postId).update({'content': content});
  }

  Future<void> deletePost(String postId) async {
    await _posts.doc(postId).delete();
  }

  Future<void> toggleLike(String postId, String userId, bool isLiked) async {
    await _posts.doc(postId).update({
      'likes': isLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }
}
