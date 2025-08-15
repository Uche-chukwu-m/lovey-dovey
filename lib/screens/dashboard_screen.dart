import 'package:flutter/material.dart';
import 'package:lovey_dovey/services/uwb_service.dart'; // Import our service

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Create an instance of our service
  final UwbService _uwbService = UwbService();
  
  // These will now be dynamic
  String _status = "Not Ranging";
  String _distanceDisplay = "---";

  @override
  void initState() {
    super.initState();
    // Listen for distance updates from the service
    _uwbService.distanceNotifier.addListener(_onDistanceChanged);
  }

  @override
  void dispose() {
    // Clean up the listener and stop ranging when the screen is closed
    _uwbService.distanceNotifier.removeListener(_onDistanceChanged);
    _uwbService.stopUwbRanging();
    super.dispose();
  }

  void _onDistanceChanged() {
    final distance = _uwbService.distanceNotifier.value;
    setState(() {
      if (distance == null) {
        _status = "Partner Not Found";
        _distanceDisplay = "---";
      } else {
        // Format the distance to 2 decimal places
        _distanceDisplay = "${distance.toStringAsFixed(2)} m";
        if (distance < 0.30) { // Our 30cm rule!
          _status = "Cling Alert! 😜";
          // We will add the timer logic here in the next phase!
        } else {
          _status = "Safe Distance 😊";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // We'll reuse most of the previous UI
    return Scaffold(
      appBar: AppBar(
        title: const Text("LoveyDovey Dashboard"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'Distance: $_distanceDisplay',
                style: const TextStyle(fontSize: 32, color: Colors.blueGrey),
              ),
              // We'll replace these placeholders with real data soon
              const SizedBox(height: 40),
              const Text('Total Cling Time: 0h 0m 0s', style: TextStyle(fontSize: 20)),
              const Text('Cuddle Charge: \$0.00', style: TextStyle(fontSize: 20)),
              const SizedBox(height: 40),
              // Add buttons to control UWB for testing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _uwbService.startUwbRanging,
                    child: const Text('Start Ranging'),
                  ),
                  ElevatedButton(
                    onPressed: _uwbService.stopUwbRanging,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop Ranging'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}