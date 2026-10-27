import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String content;
  final String author;
  final String userId;
  final DateTime createdAt;
  final List<String> likes;

  Post({
    required this.id,
    required this.content,
    required this.author,
    required this.userId,
    required this.createdAt,
    required this.likes,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      content: data['content'] ?? '',
      author: data['author'] ?? '名無し',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
    };
  }
}
