package com.checkluadao.app_checkluadao_ttnt

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

class MainActivity : FlutterActivity() {
    private var captureChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (!ScreenBubbleService.running) clearLegacyScanCache(this)
        captureChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        activeActivity = WeakReference(this)
        captureChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "state" -> result.success(mapOf(
                    "supported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O),
                    "overlayGranted" to Settings.canDrawOverlays(this),
                    "running" to ScreenBubbleService.running,
                ))
                "requestOverlayPermission" -> {
                    startActivity(Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")))
                    result.success(null)
                }
                "startBubble" -> {
                    val apiBaseUrl = call.argument<String>("apiBaseUrl")
                    val allowLiveScan = call.argument<Boolean>("allowLiveScan") == true
                    if (!Settings.canDrawOverlays(this)) {
                        result.error("overlay_permission", "Cần cấp quyền hiển thị trên ứng dụng khác.", null)
                    } else if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                        result.error("unsupported", "Tính năng cần Android 8 trở lên.", null)
                    } else if (!allowLiveScan) {
                        result.error("privacy_gate", "Quét tự động chưa mở vì backend cần hoàn tất kiểm tra quyền riêng tư.", null)
                    } else if (apiBaseUrl == null || Uri.parse(apiBaseUrl).scheme != "https" ||
                        Uri.parse(apiBaseUrl).host.isNullOrBlank()) {
                        result.error("api_url", "Địa chỉ máy chủ quét phải dùng HTTPS.", null)
                    } else {
                        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
                            .putString(API_BASE_URL, apiBaseUrl.trimEnd('/')).apply()
                        val intent = Intent(this, ScreenBubbleService::class.java).setAction(ScreenBubbleService.ACTION_START)
                        startForegroundService(intent)
                        result.success(null)
                    }
                }
                "stopBubble" -> {
                    startService(Intent(this, ScreenBubbleService::class.java).setAction(ScreenBubbleService.ACTION_STOP))
                    result.success(null)
                }
                "consumeOverlayResult" -> {
                    val resultJson = ScreenBubbleService.consumeResult()
                    if (ScreenBubbleService.running) {
                        startService(Intent(this, ScreenBubbleService::class.java)
                            .setAction(ScreenBubbleService.ACTION_REFRESH))
                    }
                    result.success(resultJson)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_OPEN_HOME, false)) {
            captureChannel?.invokeMethod("openHome", null)
        }
        if (intent.getBooleanExtra(EXTRA_OVERLAY_RESULT_READY, false)) {
            captureChannel?.invokeMethod("overlayResultReady", null)
        }
    }

    override fun onDestroy() {
        if (activeActivity?.get() === this) activeActivity = null
        super.onDestroy()
    }

    companion object {
        const val CHANNEL = "checkluadao/screen_bubble"
        const val PREFS = "screen_bubble"
        const val API_BASE_URL = "api_base_url"
        const val EXTRA_OVERLAY_RESULT_READY = "overlay_result_ready"
        const val EXTRA_OPEN_HOME = "open_home"
        private var activeActivity: WeakReference<MainActivity>? = null

        fun notifyBubbleStateChanged() {
            activeActivity?.get()?.captureChannel?.invokeMethod("bubbleStateChanged", null)
        }
    }
}
