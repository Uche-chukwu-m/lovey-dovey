// import Flutter
// import UIKit

// @main
// @objc class AppDelegate: FlutterAppDelegate {
//   override func application(
//     _ application: UIApplication,
//     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//   ) -> Bool {
//     GeneratedPluginRegistrant.register(with: self)
//     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
//   }
// }

import UIKit
import Flutter
import NearbyInteraction
import MultipeerConnectivity // Used for token exchange

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, NISessionDelegate {
    
    private var niSession: NISession?
    private var flutterChannel: FlutterMethodChannel!
    
    // We'll use a placeholder for the discovery token for now
    // In a real implementation, this would be exchanged via Firebase
    private var partnerDiscoveryToken: NIDiscoveryToken?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        // The channel name must match the one in Dart
        flutterChannel = FlutterMethodChannel(name: "com.lovey_dovey/uwb",
                                              binaryMessenger: controller.binaryMessenger)
        
        flutterChannel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if call.method == "startUWB" {
                self.startUWB()
                result(nil) // Acknowledge the call
            } else if call.method == "stopUWB" {
                self.stopUWB()
                result(nil) // Acknowledge the call
            } else {
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func startUWB() {
        // Create a new session
        niSession = NISession()
        niSession?.delegate = self
        
        // For this example, we'll hardcode a token. In a real app,
        // you would get your token, send it to your partner via Firebase,
        // and receive their token from Firebase.
        
        // This is a placeholder. Without a real partner token, ranging won't start.
        // We'll wire this to Firebase in a later step.
        guard let token = niSession?.discoveryToken else {
            print("Failed to get discovery token.")
            return
        }
        
        print("My discovery token is: \(token)")
        
        // Let's assume we received a partner's token and stored it.
        // If 'partnerDiscoveryToken' is nil, the session will just wait.
        if let partnerToken = partnerDiscoveryToken {
            let config = NINearbyPeerConfiguration(peerToken: partnerToken)
            niSession?.run(config)
            print("UWB Session started.")
        } else {
            print("Waiting for partner's token to start the session...")
        }
    }
    
    func stopUWB() {
        niSession?.invalidate()
        niSession = nil
        print("UWB Session stopped.")
    }
    
    // MARK: - NISessionDelegate
    
    // This delegate method is called when the distance to the other device is updated.
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let nearbyObject = nearbyObjects.first else { return }
        
        if let distance = nearbyObject.distance {
            // Send the distance back to Flutter!
            flutterChannel.invokeMethod("distance_update", arguments: distance)
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // Handle when the partner goes out of range
        flutterChannel.invokeMethod("distance_update", arguments: nil)
    }
    
    func sessionWasSuspended(_ session: NISession) {
        print("UWB Session was suspended.")
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        print("UWB Session suspension ended.")
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        print("UWB Session invalidated with error: \(error)")
    }
}