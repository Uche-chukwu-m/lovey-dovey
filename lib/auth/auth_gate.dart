import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lovey_dovey/auth/login_screen.dart';
import 'package:lovey_dovey/auth/pairing_check_wrapper.dart'; // We'll create this next

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not logged in
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // User is logged in, now we need to check if they are paired
        return const PairingCheckWrapper();
      },
    );
  }
}