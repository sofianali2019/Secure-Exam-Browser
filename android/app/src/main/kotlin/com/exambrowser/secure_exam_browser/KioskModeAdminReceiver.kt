package com.exambrowser.secure_exam_browser

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class KioskModeAdminReceiver : DeviceAdminReceiver() {
    override fun onEnabled(context: Context, intent: Intent) {
        Log.i("KioskAdmin", "Device admin enabled")
    }

    override fun onDisabled(context: Context, intent: Intent) {
        Log.w("KioskAdmin", "Device admin disabled — exam security reduced")
    }

    override fun onLockTaskModeEntering(context: Context, intent: Intent, pin: String) {
        Log.i("KioskAdmin", "LockTask mode entered")
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        Log.w("KioskAdmin", "LockTask mode exited")
    }
}
