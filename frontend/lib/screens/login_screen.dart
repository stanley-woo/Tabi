import 'package:flutter/material.dart';
import 'package:frontend/state/auth_store.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;


/*
Simple login stub: replace with real auth flow later
*/

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();


}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true; // controls password visibility
  bool _loading = false; // shows loading spinner on the primary button
  String? _error; // form-level error banner (optional)

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if(!isValid) return;

    setState(() {_loading = true; _error = null;});

    try {
      await context.read<AuthStore>().loginWithCredentials(_emailCtrl.text.trim(), _passCtrl.text.trim());
      if(!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = 'Invalid credentials');
    } finally {
      if(mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Future<void> _submit() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //   final ok = await AuthService.login(
  //     _emailCtrl.text.trim(),
  //     _passCtrl.text.trim(),
  //   );
  //   setState(() {
  //     _loading = false;
  //   });

  //   if(ok) {
  //     // ignore: use_build_context_synchronously
  //     Navigator.pushReplacementNamed(context, '/home');
  //   } else {
  //     setState(() => _error = 'Invalid Credentials.');}
  // }

  void _onRegisterPressed() {
    // TODO: Navigate to your Register screen (or open a sheet)
    // Navigator.pushNamed(context, '/register');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Register pressed (stub)')),
    );
  }

  Future<void> _onGooglePressed() async {
    // TODO: Hook up google_sign_in and your backend exchange
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continue with Google (stub)')),
    );
  }

  Future<void> _onApplePressed() async {
    // TODO: Hook up Sign in with Apple (sign_in_with_apple package) on iOS
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continue with Apple (stub)')),
    );
  }

  // ---Widgets--------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(title: const Text('Welcome to Tabi'), centerTitle: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text('Sign in to continue', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
                  const SizedBox(height: 24),

                  if(_error != null) ...[
                    _ErrorBanner(message: _error!),
                    const SizedBox(height: 12)
                  ],

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.username, AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com', prefixIcon: Icon(Icons.alternate_email)),
                          validator: (val) {
                            final v = val?.trim() ?? '';
                            if(v.isEmpty) return 'Email is required';
                            final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
                            if(!ok) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Your password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              onPressed:() => setState(() => _obscure = !_obscure), 
                              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off)
                            ),
                          ),
                          validator: (val) {
                            final v = val ?? '';
                            if(v.isEmpty) return 'Password is required';
                            if(v.length < 8) return 'Password must be at least 8 characters';
                            return null;
                          },
                          onFieldSubmitted: (_) => _onLoginPressed(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Primary CTA
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _loading ? null : _onLoginPressed,
                      child: _loading ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Secondary CTA (Register)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(onPressed: _loading ? null : _onRegisterPressed, child: const Text('Create an account')),
                  ),

                  const SizedBox(height: 24),

                  // Divider with "or"
                  Row(
                    children: [
                      Expanded(child:Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or continue with', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant))
                    ],
                  ),

                  const SizedBox(height: 16),

                 // Social sign-in buttons (stubs)
                  Row(
                    children: [
                      Expanded(
                        child: _SocialButton(
                          label: 'Google',
                          icon: const _GoogleIcon(),    // simple “G” mark (no extra deps)
                          onPressed: _loading ? null : _onGooglePressed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (Platform.isIOS)
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: const Icon(Icons.apple, size: 20),
                            onPressed: _loading ? null : _onApplePressed,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Center(
                    child: TextButton(
                        onPressed: _loading ? null : () async {
                          setState(() => _loading = true);
                          try {
                            await context
                                .read<AuthStore>()
                                .loginWithCredentials('demo@tabi.app', 'password');
                            if (!mounted) return;
                            // (Optional) view as a specific profile while staying admin:
                            await context.read<AuthStore>().devQuickSwitchProfile('pikachu');

                            Navigator.pushReplacementNamed(context, '/home');
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login failed: $e')),
                            );
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                      child: const Text('Use demo account'),
                    ),
                  ),

                  Text('By continuing you agree to Tabi’s Terms & Privacy.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12)
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: cs.onErrorContainer))),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  const _SocialButton({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext content) {
    final cs = Theme.of(content).colorScheme;
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: icon,
        label: Text(label),
        onPressed: onPressed,
      )
    );
  }
}

/// Minimal Google "G" glyph without extra packages.
/// For production, prefer using brand assets or `flutter_svg` with Google's logo.
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    // A simple circle with a 'G'—placeholder only.
    final cs = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 10,
      backgroundColor: cs.surfaceContainerHighest,
      child: Text(
        'G',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: cs.onSurfaceVariant,
          fontSize: 12,
          height: 1,
        ),
      ),
    );
    // Swap with a proper Google logo when you add branding.
  }
}