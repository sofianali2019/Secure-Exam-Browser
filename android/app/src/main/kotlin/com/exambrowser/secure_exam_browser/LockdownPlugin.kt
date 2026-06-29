package com.exambrowser.secure_exam_browser

import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class LockdownPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, EventChannel.StreamHandler,
    View.OnKeyListener {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var activity: Activity? = null
    private var eventSink: EventChannel.EventSink? = null
    private var isLocked = false
    private var dpm: DevicePolicyManager? = null
    private var adminComponent: ComponentName? = null
    private var isAdminActive = false

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.exambrowser/lockdown")
        channel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "com.exambrowser/lockdown_events")
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "startLockdown" -> startLockdown(call, result)
            "stopLockdown" -> stopLockdown(result)
            "isInLockdown" -> result.success(isLocked)
            else -> result.notImplemented()
        }
    }

    private fun startLockdown(call: MethodCall, result: Result) {
        val args = call.arguments as? Map<String, Any> ?: run {
            result.error("INVALID_ARGS", "Missing config", null)
            return
        }
        val act = activity
        if (act == null) {
            result.error("NO_ACTIVITY", "Activity not available", null)
            return
        }
        // Execute lockdown on UI thread and return result only after completion
        act.runOnUiThread {
            try {
                applyLockdown(act, args)
                isLocked = true
                result.success(true)
            } catch (e: Exception) {
                isLocked = false
                result.error("LOCKDOWN_FAILED", "Lockdown failed: ${e.message}", null)
            }
        }
    }

    private fun stopLockdown(result: Result) {
        val act = activity
        if (act == null) {
            isLocked = false
            result.success(true)
            return
        }
        act.runOnUiThread {
            try {
                removeLockdown(act)
            } catch (_: Exception) {
                // Best-effort cleanup; report success anyway
            }
            isLocked = false
            result.success(true)
        }
    }

    private fun applyLockdown(activity: Activity, args: Map<String, Any>) {
        // Register key listener to intercept back, volume, and other hardware keys
        activity.window.decorView.setOnKeyListener(this)
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        if (args["fullscreenOnly"] as? Boolean ?: true) {
            activity.window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }

        if (args["blockNotifications"] as? Boolean ?: true) {
            try {
                val audioManager = activity.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                audioManager.setStreamVolume(AudioManager.STREAM_ALARM, 0, 0)
                audioManager.setStreamVolume(AudioManager.STREAM_SYSTEM, 0, 0)
            } catch (_: Exception) {}
        }

        // LockTask: Prevent app switching and keep this app as the active foreground task.
        // Requires the device admin receiver to be enabled and the app to be whitelisted.
        if (isAdminActive && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                if (dpm?.isLockTaskPermitted(activity.packageName) == true) {
                    activity.startLockTask()
                } else {
                    eventSink?.success(mapOf(
                        "type" to "locktask_error",
                        "detail" to "App not whitelisted for LockTask. Ensure device admin is enabled in Settings."
                    ))
                }
            } catch (e: Exception) {
                eventSink?.success(mapOf(
                    "type" to "locktask_error",
                    "detail" to "Failed to start LockTask: ${e.message}"
                ))
            }
        }
    }

    private fun removeLockdown(activity: Activity) {
        // Remove key listener
        activity.window.decorView.setOnKeyListener(null)

        // Stop LockTask mode so user can exit the kiosk
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            try {
                activity.stopLockTask()
            } catch (_: Exception) {
                // LockTask was not active; safe to ignore
            }
        }

        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        activity.window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
    }

    // Intercept hardware keys during lockdown to prevent exam escape.
    override fun onKey(v: View?, keyCode: Int, event: KeyEvent): Boolean {
        if (!isLocked) return false

        // Block back button
        if (keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_DOWN) {
            eventSink?.success(mapOf(
                "type" to "app_switch",
                "detail" to "Back button blocked"
            ))
            return true
        }

        // Block volume keys (prevents student from changing volume which could affect proctoring audio)
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                eventSink?.success(mapOf(
                    "type" to "keyboard_shortcut",
                    "detail" to "Volume key blocked"
                ))
            }
            return true
        }

        // Block camera button
        if (keyCode == KeyEvent.KEYCODE_CAMERA) {
            return true
        }

        // Block notification access via hardware keys
        if (keyCode == KeyEvent.KEYCODE_NOTIFICATION) {
            return true
        }

        return false
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        dpm = activity?.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
        adminComponent = ComponentName(activity!!, KioskModeAdminReceiver::class.java)
        // Check if the device admin is already active
        isAdminActive = dpm?.isAdminActive(adminComponent!!) == true
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
