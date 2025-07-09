import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/*
Simple login stub: replace with real auth flow later
*/

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();


}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await AuthService.login(
      _emailCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    setState(() {
      _loading = false;
    });

    if(ok) {
      Navigator.pushReplacementNamed(context, '/demo');
    } else {
      setState(() => _error = 'Invalid Credentials.');}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login to Tabi'),),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if(_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit, 
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Login'),
                ),
          ],
        ),
        ),
    );
  }
}