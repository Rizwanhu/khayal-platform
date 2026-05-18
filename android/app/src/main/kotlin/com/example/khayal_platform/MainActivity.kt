package com.example.khayal_platform

import android.media.RingtoneManager
import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "khayal_platform/alarm_sound",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAlarmUri" -> {
                    val alarm =
                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                    val fallback =
                        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    val uri = alarm ?: fallback
                    if (uri != null) {
                        result.success(uri.toString())
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON,
            )
        }
    }
}
