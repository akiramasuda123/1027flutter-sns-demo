import 'package:flutter/material.dart';

import '../models/post.dart';
import '../services/firestore_service.dart';

class EditPostPage extends StatefulWidget {
  final Post post;
  const EditPostPage({required this.post, super.key});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  late final _controller = TextEditingController(text: widget.post.content);
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _firestoreService.updatePost(widget.post.id, _controller.text.trim());
      Navigator.pop(context);
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
        title: const Text('投稿を編集'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: const Text('保存', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: 5,
          maxLength: 140,
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }
}
