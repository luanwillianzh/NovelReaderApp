package com.thefool.novelreader

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.thefool.novelreader/deep_linking"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            // This method channel is primarily for sending data from Kotlin to Dart.
            // No methods are expected to be called from Dart to Kotlin via this channel.
            result.notImplemented()
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            uri?.let {
                if (it.host == "novel") {
                    val novelId = it.getQueryParameter("novel_id")

                    val deepLinkData = mutableMapOf<String, String?>()
                    deepLinkData["novel_id"] = novelId

                    // Send data to Flutter
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("handleDeepLink", deepLinkData)
                }
            }
        }
    }
}
