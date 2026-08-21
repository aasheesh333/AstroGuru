package com.dhanuk.astroprerna

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.ConnectionResult

class MainActivity: FlutterActivity() {

    private val channelName = "com.dhanuk.astroprerna/gms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isGmsAvailable" -> {
                        try {
                            val availability = GoogleApiAvailability.getInstance()
                            val code = availability.isGooglePlayServicesAvailable(this)
                            result.success(code == ConnectionResult.SUCCESS)
                        } catch (e: Exception) {
                            // If the check itself fails, report success so we
                            // don't disable features on Google devices.
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
