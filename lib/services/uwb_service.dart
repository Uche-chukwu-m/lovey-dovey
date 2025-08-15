import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UwbService {
  // The channel name must be unique and match the native side exactly.
  static const _channel = MethodChannel('com.lovey_dovey/uwb');

  // We use a ValueNotifier to broadcast distance updates to the UI.
  final ValueNotifier<double?> distanceNotifier = ValueNotifier(null);

  UwbService() {
    // Set up a handler to listen for calls FROM the native side.
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // This function will be called by the native code.
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'distance_update':
        final double distance = call.arguments;
        distanceNotifier.value = distance;
        break;
      default:
        // Handle other cases or errors
        break;
    }
  }

  // This function will be called FROM our Flutter UI to start ranging.
  Future<void> startUwbRanging() async {
    try {
      // We will need to exchange discovery tokens via Firebase.
      // For now, let's just trigger the native side.
      // We'll add the Firebase part later.
      await _channel.invokeMethod('startUWB');
      print("UWB Ranging started.");
    } on PlatformException catch (e) {
      print("Failed to start UWB: '${e.message}'.");
    }
  }

  // This function will be called FROM our Flutter UI to stop ranging.
  Future<void> stopUwbRanging() async {
    try {
      await _channel.invokeMethod('stopUWB');
      distanceNotifier.value = null; // Clear the distance
      print("UWB Ranging stopped.");
    } on PlatformException catch (e) {
      print("Failed to stop UWB: '${e.message}'.");
    }
  }
}