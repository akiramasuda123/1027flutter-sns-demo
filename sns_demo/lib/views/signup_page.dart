import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onToggle;
  const SignupPage({required this.onToggle, super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;

  Future<void> _signup() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signUp(_emailController.text.trim(), _passwordController.text.trim());
      final user = _auth.currentUser!;
      await user.updateDisplayName(_nameController.text.trim());
      await UserService().createUser(AppUser(
        uid: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'ユーザー名')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'メールアドレス')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'パスワード'), obscureText: true),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _signup, child: const Text('登録')),
            TextButton(onPressed: widget.onToggle, child: const Text('ログインはこちら')),
          ],
        ),
      ),
    );
  }
}
