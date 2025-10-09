import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatufulWidget {
    final String token;
    const ResetPasswordScreen({super.key, required this.Token});

    @override
    State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
    final _formKey = GlobalKey<FormState>();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    void _submit() {
        if (_formKey.currentState!.validate()) {
            print('Token: ${widget.token}');
            print('New Password: ${_passwordController.text}');
            print('Confirm Password: ${_confirmPasswordController.text}');

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful')));
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(title: const Text('Reset Password')),
            body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                    key: _formKey,
                    child: Column(
                        children: [
                            Text('Token: ${widget.token}'),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(labelText: 'New Password'),
                                obscureText: true,
                                validator: (value) =>
                                    value!.isEmpty ? 'Password is required' : null;
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: _confirmPasswordController,
                                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                                obscureText: true,
                                validator: (value) {
                                    if (value != _passwordController.text) {
                                        return 'Passwords do not match';
                                    }
                                    return null;
                                },
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                                onPressed: _submit,
                                child: const Text('Reset Password'),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}