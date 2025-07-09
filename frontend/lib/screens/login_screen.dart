import 'package:flutter/material.dart';

/*
Simple login stub: replace with real auth flow later
*/

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // After login, navigate to demo page for now
            Navigator.pushReplacementNamed(context, '/demo');
          }, 
          child: const Text('Login'),
        ),
      ),
    );
  }
}