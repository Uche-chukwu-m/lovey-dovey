// package com.example.lovey_dovey
//
// import io.flutter.embedding.android.FlutterActivity
//
// class MainActivity : FlutterActivity()

package com.example.lovey_dovey // Make sure this matches your package name!

import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.uwb.RangingParameters
import androidx.core.uwb.RangingResult
import androidx.core.uwb.UwbManager
import androidx.core.uwb.UwbDevice
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

@RequiresApi(Build.VERSION_CODES.S) // UWB requires Android 12 (API 31) or higher
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.lovey_dovey/uwb" // Must match the channel name in Dart
    private lateinit var flutterChannel: MethodChannel

    private var uwbManager: UwbManager? = null
    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    // The ranging session is a Flow in the modern Android UWB library
    private var rangingJob: kotlinx.coroutines.Job? = null

    // This is the Android equivalent of Apple's NIDiscoveryToken.
    // We will need to get this from our partner via Firebase.
    private var partnerDevice: UwbDevice? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize UWB Manager
        uwbManager = UwbManager.createInstance(this)

        // Set up the Method Channel
        flutterChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        flutterChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "startUWB" -> {
                    startUwbRanging()
                    result.success(null) // Acknowledge the call
                }
                "stopUWB" -> {
                    stopUwbRanging()
                    result.success(null) // Acknowledge the call
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startUwbRanging() {
        // Stop any previous ranging sessions
        stopUwbRanging()

        // Get our own local UWB address. We would send this to our partner via Firebase.
        val localAddress = uwbManager?.adapterState?.value?.address
        if (localAddress == null) {
            Log.e("UWB", "Could not get local UWB address.")
            return
        }
        Log.d("UWB", "My local UWB address: $localAddress")
        
        // TODO: This is the critical missing piece.
        // We need to receive the partner's UWB address from Firebase and create a UwbDevice.
        // For now, this will prevent ranging from starting.
        // partnerDevice = UwbDevice.createForAddress("PARTNER_ADDRESS_FROM_FIREBASE")

        if (partnerDevice == null) {
            Log.d("UWB", "Partner device not set. Waiting for partner address.")
            // Send a status update to Flutter
            flutterChannel.invokeMethod("distance_update", null)
            return
        }

        // Configure the ranging parameters
        val rangingParameters = RangingParameters(
            uwbConfigType = RangingParameters.UWB_CONFIG_ID_1,
            // The session ID can be any unique integer
            sessionId = (0..65535).random(),
            subSessionId = 0,
            sessionKeyInfo = null,
            complexChannel = null,
            peerDevices = listOf(partnerDevice!!),
            updateRateType = RangingParameters.UWB_UPDATE_RATE_AUTOMATIC
        )

        // Start a new ranging session as a coroutine Flow
        rangingJob = uwbManager!!.rangingSessions
            .onEach {
                // This block is called for each result from the flow
                when (it) {
                    is RangingResult.RangingResultPosition -> {
                        val distance = it.position.distance.value
                        Log.d("UWB", "Distance: $distance m")
                        // Send the distance back to Flutter!
                        runOnUiThread {
                            flutterChannel.invokeMethod("distance_update", distance)
                        }
                    }
                    is RangingResult.RangingResultPeerDisconnected -> {
                        Log.d("UWB", "Peer disconnected.")
                        runOnUiThread {
                            flutterChannel.invokeMethod("distance_update", null)
                        }
                    }
                }
            }
            .catch { e -> Log.e("UWB", "Ranging failed: $e") }
            .launchIn(coroutineScope)

        Log.d("UWB", "UWB Ranging started.")
    }

    private fun stopUwbRanging() {
        // Cancel the coroutine job, which closes the UWB session
        rangingJob?.cancel()
        rangingJob = null
        Log.d("UWB", "UWB Ranging stopped.")
    }

    override fun onDestroy() {
        // Clean up the coroutine scope when the activity is destroyed
        super.onDestroy()
        coroutineScope.cancel()
    }
}