import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_store.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _loading = false;
  String? _error;
  String? _success;

  Future<void> _resendVerification() async {
    if (widget.email == null) return;

    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    try {
      await AuthService.resendVerification(widget.email!);
      setState(() {
        _success = 'Verification email sent! Check your inbox.';
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to send verification email: ${e.toString()}';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    final auth = context.read<AuthStore>();
    if (auth.isLoggedIn) {
      try {
        final me = await AuthService.me();
        final isVerified = me['is_email_verified'] as bool? ?? false;
        if (isVerified) {
          setState(() {
            _success = 'Email verified successfully!';
          });
          // Navigate to home after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Failed to check verification status: ${e.toString()}';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Check verification status when screen loads
    _checkVerificationStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon
            const Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Verify Your Email',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Description
            Text(
              widget.email != null
                  ? 'We\'ve sent a verification link to ${widget.email}'
                  : 'Please check your email for a verification link',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            
            // Success message
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  _success!,
                  style: TextStyle(
                    color: Colors.green[800],
                  ),
                ),
              ),
            
            // Resend button
            ElevatedButton(
              onPressed: _loading ? null : _resendVerification,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resend Verification Email'),
            ),
            const SizedBox(height: 16),
            
            // Check status button
            OutlinedButton(
              onPressed: _loading ? null : _checkVerificationStatus,
              child: const Text('Check Verification Status'),
            ),
            const SizedBox(height: 24),
            
            // Skip for now (temporary)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
              },
              child: const Text('Skip for now'),
            ),
          ],
        ),
      ),
    );
  }
}
