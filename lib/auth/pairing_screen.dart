import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  String? _userRole; // "Receiver", "Clinger", or null
  String? _pairingCode;
  bool _isLoading = false;
  final _codeController = TextEditingController();
  
  // Generate a unique 6-digit code for the Receiver
  void _generatePairingCode() async {
    setState(() { _isLoading = true; });
    final userRef = _firestore.collection('users').doc(_auth.currentUser!.uid);
    String code;
    // Loop to ensure the code is unique (highly unlikely to collide, but good practice)
    do {
      code = (100000 + Random().nextInt(900000)).toString();
    } while ((await _firestore.collection('users').where('pairingCode', isEqualTo: code).get()).docs.isNotEmpty);

    await userRef.set({
      'email': _auth.currentUser!.email,
      'uid': _auth.currentUser!.uid,
      'role': 'Receiver',
      'pairingCode': code,
      'partnerUid': null,
    });

    setState(() {
      _userRole = 'Receiver';
      _pairingCode = code;
      _isLoading = false;
    });
  }

  // Clinger attempts to pair using a code
  void _attemptToPair() async {
    setState(() { _isLoading = true; });
    final enteredCode = _codeController.text.trim();
    if (enteredCode.length != 6) {
      // Show an error
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a 6-digit code.')));
      setState(() { _isLoading = false; });
      return;
    }

    final query = await _firestore.collection('users').where('pairingCode', isEqualTo: enteredCode).limit(1).get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code. Please try again.')));
      setState(() { _isLoading = false; });
    } else {
      final receiverDoc = query.docs.first;
      final receiverUid = receiverDoc.id;
      final clingerUid = _auth.currentUser!.uid;

      // Use a batch write to update both users at once (atomic operation)
      WriteBatch batch = _firestore.batch();

      // Update the Receiver
      batch.update(receiverDoc.reference, {
        'partnerUid': clingerUid,
        'pairingCode': FieldValue.delete(), // Remove the code once used
      });

      // Set the Clinger's data
      batch.set(_firestore.collection('users').doc(clingerUid), {
        'email': _auth.currentUser!.email,
        'uid': clingerUid,
        'role': 'Clinger',
        'partnerUid': receiverUid,
      });

      await batch.commit();
      // AuthGate will now automatically navigate to the dashboard
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    // Initial choice screen
    if (_userRole == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Your Role')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Are you the Receiver or the Clinger?', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _generatePairingCode,
                child: const Text('I am the Receiver'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setState(() => _userRole = 'Clinger'),
                child: const Text('I am the Clinger'),
              ),
            ],
          ),
        ),
      );
    }

    // Receiver's View
    if (_userRole == 'Receiver') {
      return Scaffold(
        appBar: AppBar(title: const Text('Share Your Code')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Share this code with your partner:', textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                Text(_pairingCode ?? 'Generating...', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 8)),
                const SizedBox(height: 20),
                const Text('Waiting for partner to connect...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }
    
    // Clinger's View
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Pairing Code')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Enter the 6-digit code from your partner:', style: TextStyle(fontSize: 18)),
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 8),
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _attemptToPair, child: const Text('Pair Up!')),
            ],
          ),
        ),
      ),
    );
  }
}