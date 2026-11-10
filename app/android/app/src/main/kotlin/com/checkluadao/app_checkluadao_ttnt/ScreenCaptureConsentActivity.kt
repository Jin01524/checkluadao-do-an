package com.checkluadao.app_checkluadao_ttnt

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Bundle

class ScreenCaptureConsentActivity : Activity() {
    private var capturePermissionRequested = false
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        capturePermissionRequested = savedInstanceState?.getBoolean(STATE_CAPTURE_REQUESTED) == true
    }

    override fun onResume() {
        super.onResume()
        requestCapturePermission()
    }

    private fun requestCapturePermission() {
        if (capturePermissionRequested) return
        capturePermissionRequested = true
        val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        startActivityForResult(manager.createScreenCaptureIntent(), REQUEST_CAPTURE)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        outState.putBoolean(STATE_CAPTURE_REQUESTED, capturePermissionRequested)
        super.onSaveInstanceState(outState)
    }

    @Deprecated("Android result callback for the system capture dialog")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_CAPTURE) return
        if (!ScreenBubbleService.running) { finish(); return }
        val action = if (resultCode == RESULT_OK && data != null) {
            ScreenBubbleService.ACTION_CAPTURE
        } else {
            ScreenBubbleService.ACTION_SHOW
        }
        val service = Intent(this, ScreenBubbleService::class.java).setAction(action)
        if (action == ScreenBubbleService.ACTION_CAPTURE) {
            service.putExtra(ScreenBubbleService.EXTRA_RESULT_CODE, resultCode)
            service.putExtra(ScreenBubbleService.EXTRA_RESULT_DATA, data)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(service)
        else startService(service)
        finish()
    }

    companion object {
        private const val REQUEST_CAPTURE = 5102
        private const val STATE_CAPTURE_REQUESTED = "capture_permission_requested"
    }
}