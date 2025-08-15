import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lovey_dovey/auth/pairing_screen.dart';
import 'package:lovey_dovey/screens/dashboard_screen.dart';

class PairingCheckWrapper extends StatelessWidget {
  const PairingCheckWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // This should not happen if called from AuthGate, but it's a safe fallback.
      return const Scaffold(body: Center(child: Text('Error: No user found.')));
    }

    // Listen to changes in the current user's document in Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // If the document doesn't exist or has no partnerUid, they are not paired
        if (!snapshot.hasData || snapshot.data!.data() == null) {
          return const PairingScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // Check if the 'partnerUid' field exists and is not null
        if (userData.containsKey('partnerUid') && userData['partnerUid'] != null) {
          // User is paired, go to the dashboard
          return const DashboardScreen();
        } else {
          // User is not paired, show the pairing screen
          return const PairingScreen();
        }
      },
    );
  }
}