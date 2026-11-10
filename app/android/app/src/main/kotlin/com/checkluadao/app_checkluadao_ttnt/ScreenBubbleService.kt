package com.checkluadao.app_checkluadao_ttnt

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executors
import java.util.concurrent.Future

class ScreenBubbleService : Service() {
    private lateinit var windowManager: WindowManager
    private var bubble: FrameLayout? = null
    private var statusBadge: TextView? = null
    private var bubbleParams: WindowManager.LayoutParams? = null
    private var actionMenu: LinearLayout? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var projection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var capturing = false
    private var projectionPending = false
    private var analysisInFlight = false
    private var analysisGeneration = 0
    private var scanOverlay: ScreenScanOverlay? = null
    private var activeScanFile: File? = null
    private var activeScanCall: ScanCancellation? = null
    private var analysisTask: Future<*>? = null
    private var destroyed = false
    private val analysisExecutor = Executors.newSingleThreadExecutor()

    override fun onCreate() {
        super.onCreate()
        clearLegacyScanCache(this)
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(
            CHANNEL_ID, "Bong bóng quét màn hình", NotificationManager.IMPORTANCE_LOW))
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> { cancelCurrentScan(false); stopSelf(); return START_NOT_STICKY }
            ACTION_REFRESH -> {
                promote(projectionPending || capturing)
                updateBubble()
            }
            ACTION_CAPTURE -> {
                val code = intent.getIntExtra(EXTRA_RESULT_CODE, 0)
                @Suppress("DEPRECATION")
                val data = intent.getParcelableExtra<Intent>(EXTRA_RESULT_DATA)
                if (code == 0 || data == null) {
                    projectionPending = false
                    promote(false)
                    showBubble()
                } else {
                    projectionPending = true
                    promote(true)
                    hideBubble()
                    val generation = analysisGeneration
                    mainHandler.postDelayed({
                        if (!destroyed && generation == analysisGeneration) {
                            capture(code, data)
                        }
                    }, 650)
                }
            }
            ACTION_SHOW -> {
                promote(projectionPending || capturing)
                showBubble()
            }
            else -> {
                promote(projectionPending || capturing)
                showBubble()
            }
        }
        running = true
        MainActivity.notifyBubbleStateChanged()
        return START_NOT_STICKY
    }

    private fun promote(projectionActive: Boolean) {
        val notification = notification(when {
            analysisInFlight -> "Đang phân tích nội dung đã quét."
            hasPendingResult() -> "Đã có kết quả. Mở CheckLuaDao để xem chi tiết."
            else -> "Chạm bong bóng để chọn quét hoặc mở ứng dụng."
        })
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val type = if (projectionActive) ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                else ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            startForeground(NOTIFICATION_ID, notification, type)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun notification(message: String): Notification {
        val open = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_OPEN_HOME, true)
            if (hasPendingResult()) putExtra(MainActivity.EXTRA_OVERLAY_RESULT_READY, true)
        }
        val pending = PendingIntent.getActivity(this, 0, open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return Notification.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_camera)
            .setContentTitle("CheckLuaDao • Quét màn hình")
            .setContentText(message)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()
    }

    private fun hasPendingResult(): Boolean = pendingResultJson != null

    private fun showBubble() {
        if (destroyed) return
        if (!Settings.canDrawOverlays(this)) { stopSelf(); return }
        bubble?.let { it.visibility = View.VISIBLE; updateBubble(); return }
        val size = dp(64)
        val container = FrameLayout(this).apply {
            elevation = dp(12).toFloat()
            isClickable = true
            isFocusable = true
        }
        val logo = ImageView(this).apply {
            setImageBitmap(logoMark())
            scaleType = ImageView.ScaleType.FIT_CENTER
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        container.addView(logo, FrameLayout.LayoutParams(dp(50), dp(50), Gravity.CENTER))
        statusBadge = TextView(this).apply {
            gravity = Gravity.CENTER
            text = "✓"
            textSize = 14f
            setTextColor(Color.WHITE)
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            elevation = dp(2).toFloat()
        }
        container.addView(statusBadge, FrameLayout.LayoutParams(dp(22), dp(22),
            Gravity.END or Gravity.BOTTOM).apply {
            rightMargin = dp(1)
            bottomMargin = dp(1)
        })
        bubble = container
        updateBubble()
        val params = WindowManager.LayoutParams(size, size,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.START
            x = resources.displayMetrics.widthPixels - size - 16
            y = resources.displayMetrics.heightPixels / 3
        }
        bubbleParams = params
        var downX = 0f
        var downY = 0f
        var originX = 0
        var originY = 0
        var dragged = false
        container.setOnClickListener { onBubbleTap() }
        container.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    downX = event.rawX; downY = event.rawY
                    originX = params.x; originY = params.y
                    dragged = false
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - downX
                    val dy = event.rawY - downY
                    if (kotlin.math.abs(dx) + kotlin.math.abs(dy) > 12 * resources.displayMetrics.density) dragged = true
                    if (dragged) {
                        hideMenu()
                        params.x = (originX + dx.toInt()).coerceIn(0, resources.displayMetrics.widthPixels - size)
                        params.y = (originY + dy.toInt()).coerceIn(0, resources.displayMetrics.heightPixels - size)
                        windowManager.updateViewLayout(container, params)
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (!dragged) container.performClick()
                    true
                }
                else -> true
            }
        }
        windowManager.addView(container, params)
    }

    private fun updateBubble() {
        val pending = hasPendingResult()
        bubble?.contentDescription = if (pending)
            "CheckLuaDao: có kết quả hiện tại, chạm để mở lựa chọn"
            else "CheckLuaDao: chạm để mở lựa chọn quét màn hình hoặc quay lại ứng dụng"
        bubble?.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.WHITE)
            setStroke(dp(2), if (pending) Color.rgb(4, 120, 87) else Color.rgb(14, 99, 216))
        }
        statusBadge?.visibility = if (pending) View.VISIBLE else View.GONE
        statusBadge?.background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.rgb(4, 120, 87))
            setStroke(dp(2), Color.WHITE)
        }
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density + 0.5f).toInt()

    // Keep the existing brand asset intact; the native overlay displays its icon area.
    private fun logoMark(): Bitmap {
        val source = BitmapFactory.decodeResource(resources, R.drawable.logo_checkluadao)
        val left = (source.width * 0.10f).toInt()
        val top = 0
        val width = (source.width * 0.88f).toInt().coerceAtMost(source.width - left)
        val height = (source.height * 0.84f).toInt().coerceAtMost(source.height)
        return Bitmap.createBitmap(source, left, top, width, height).also {
            if (it !== source) source.recycle()
        }
    }

    private fun onBubbleTap() {
        if (actionMenu != null) hideMenu() else showMenu()
        if (actionMenu != null) bubble?.contentDescription =
            "CheckLuaDao: chạm để thu menu lựa chọn"
    }

    private fun showMenu() {
        if (capturing || analysisInFlight || actionMenu != null) return
        val anchor = bubbleParams ?: return
        val menuWidth = dp(208)
        val menuHeight = dp(200)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(4), dp(4), dp(4), dp(4))
            clipChildren = false
            clipToPadding = false
        }
        root.addView(menuCard("Quét màn hình", "Chụp nội dung đang xem",
            android.R.drawable.ic_menu_camera, true) {
            cancelCurrentScan(false)
            pendingResultJson = null
            hideMenu()
            hideBubble()
            startActivity(Intent(this, ScreenCaptureConsentActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            })
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(56)))
        root.addView(menuCard("Quay lại", "Mở CheckLuaDao",
            android.R.drawable.ic_menu_revert, false) {
            hideMenu()
            startActivity(Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_OPEN_HOME, true)
                if (hasPendingResult()) putExtra(MainActivity.EXTRA_OVERLAY_RESULT_READY, true)
            })
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(56)).apply {
            topMargin = dp(8)
        })
        root.addView(menuCard("Đóng", "Tắt bong bóng quét",
            android.R.drawable.ic_menu_close_clear_cancel, false, danger = true) {
            hideMenu()
            stopSelf()
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, dp(56)).apply {
            topMargin = dp(8)
        })
        root.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE) {
                val bubbleWindow = bubbleParams
                val touchedBubble = bubbleWindow != null &&
                    event.rawX >= bubbleWindow.x && event.rawX < bubbleWindow.x + dp(64) &&
                    event.rawY >= bubbleWindow.y && event.rawY < bubbleWindow.y + dp(64)
                if (!touchedBubble) hideMenu()
                true
            } else false
        }
        val screenWidth = resources.displayMetrics.widthPixels
        val screenHeight = resources.displayMetrics.heightPixels
        val x = if (anchor.x >= screenWidth / 2)
            anchor.x - menuWidth - dp(8) else anchor.x + dp(64) + dp(8)
        val params = WindowManager.LayoutParams(menuWidth, menuHeight,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT).apply {
            gravity = Gravity.TOP or Gravity.START
            this.x = x.coerceIn(0, (screenWidth - menuWidth).coerceAtLeast(0))
            y = (anchor.y + dp(32) - menuHeight / 2).coerceIn(
                dp(32), (screenHeight - menuHeight - dp(24)).coerceAtLeast(dp(32)))
        }
        windowManager.addView(root, params)
        actionMenu = root
    }

    private fun menuCard(title: String, detail: String, iconRes: Int,
                         primary: Boolean, danger: Boolean = false, onClick: () -> Unit): View {
        val accent = if (danger) Color.rgb(185, 28, 28) else Color.rgb(0, 55, 176)
        val foreground = if (primary) Color.WHITE else if (danger) accent else Color.rgb(11, 28, 48)
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(12), 0, dp(10), 0)
            elevation = dp(4).toFloat()
            background = GradientDrawable().apply {
                cornerRadius = 0f
                setColor(if (primary) Color.rgb(0, 55, 176) else Color.WHITE)
                if (!primary) setStroke(dp(1),
                    if (danger) Color.rgb(248, 205, 205) else Color.rgb(205, 219, 244))
            }
            isClickable = true
            isFocusable = true
            contentDescription = "$title. $detail"
            setOnClickListener { onClick() }
            addView(ImageView(this@ScreenBubbleService).apply {
                setImageResource(iconRes)
                setColorFilter(if (primary) Color.WHITE else accent)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(dp(24), dp(24)).apply { rightMargin = dp(12) })
            addView(LinearLayout(this@ScreenBubbleService).apply {
                orientation = LinearLayout.VERTICAL
                addView(TextView(this@ScreenBubbleService).apply {
                    text = title
                    textSize = 14f
                    setTextColor(foreground)
                    setTypeface(null, android.graphics.Typeface.BOLD)
                })
                addView(TextView(this@ScreenBubbleService).apply {
                    text = detail
                    textSize = 10f
                    setTextColor(if (primary) Color.rgb(218, 232, 255) else Color.rgb(82, 98, 122))
                })
            })
        }
    }

    private fun hideMenu() {
        val menu = actionMenu ?: return
        windowManager.removeView(menu)
        actionMenu = null
        updateBubble()
    }

    private fun hideBubble() {
        hideMenu()
        bubble?.visibility = View.GONE
    }

    private fun capture(resultCode: Int, data: Intent) {
        if (destroyed || capturing) return
        capturing = true
        try {
            val metrics = resources.displayMetrics
            val width = metrics.widthPixels
            val height = metrics.heightPixels
            val reader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
            imageReader = reader
            val manager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
            val mediaProjection = manager.getMediaProjection(resultCode, data)
                ?: throw IllegalStateException("Android did not provide a capture session")
            projection = mediaProjection
            mediaProjection.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() {
                    if (capturing) Log.w(TAG, "MediaProjection stopped before capture completed")
                    mainHandler.post {
                        if (!destroyed && projection === mediaProjection) finishCapture()
                    }
                }
            }, mainHandler)
            reader.setOnImageAvailableListener({ source ->
                if (destroyed || !capturing || imageReader !== source) return@setOnImageAvailableListener
                val image = source.acquireLatestImage() ?: return@setOnImageAvailableListener
                Log.d(TAG, "Screenshot frame received")
                var savedFile: File? = null
                try {
                    val plane = image.planes[0]
                    val rowPixels = plane.rowStride / plane.pixelStride
                    val raw = Bitmap.createBitmap(rowPixels, height, Bitmap.Config.ARGB_8888)
                    raw.copyPixelsFromBuffer(plane.buffer)
                    val cropped = Bitmap.createBitmap(raw, 0, 0, width, height)
                    val file = File(cacheDir, "screen_scan_${System.currentTimeMillis()}.jpg")
                    savedFile = file
                    FileOutputStream(file).use { cropped.compress(Bitmap.CompressFormat.JPEG, 88, it) }
                    cropped.recycle(); raw.recycle()
                    savedFile = file
                    analysisInFlight = true
                } catch (error: Exception) {
                    Log.w(TAG, "Could not save screenshot", error)
                    savedFile?.delete()
                    savedFile = null
                } finally {
                    image.close()
                    finishCapture()
                    savedFile?.let { beginAnalysis(it) }
                }
            }, mainHandler)
            virtualDisplay = mediaProjection.createVirtualDisplay("CheckLuaDaoScreenScan",
                width, height, metrics.densityDpi, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                reader.surface, null, mainHandler)
            val generation = analysisGeneration
            mainHandler.postDelayed({
                if (!destroyed && generation == analysisGeneration && capturing) {
                    Log.w(TAG, "Screenshot capture timed out")
                    finishCapture()
                }
            }, 7000)
        } catch (error: Exception) {
            Log.w(TAG, "Could not start screenshot capture", error)
            finishCapture()
        }
    }

    private fun finishCapture(restoreBubble: Boolean = true) {
        capturing = false
        projectionPending = false
        virtualDisplay?.release(); virtualDisplay = null
        imageReader?.close(); imageReader = null
        projection?.stop(); projection = null
        if (!destroyed) promote(false)
        if (!destroyed && restoreBubble && !analysisInFlight) showBubble()
    }

    private fun beginAnalysis(file: File) {
        activeScanFile = file
        analysisGeneration++
        val generation = analysisGeneration
        pendingResultJson = null
        val overlay = ScreenScanOverlay(this, windowManager,
            onDetails = { openDetails() },
            onDismiss = { cancelCurrentScan() })
        scanOverlay = overlay
        overlay.showScanning()
        mainHandler.postDelayed({
            if (analysisInFlight && generation == analysisGeneration) scanOverlay?.showAnalyzing()
        }, 950)
        val apiBaseUrl = getSharedPreferences(MainActivity.PREFS, MODE_PRIVATE)
            .getString(MainActivity.API_BASE_URL, null)
        val cancellation = ScanCancellation()
        activeScanCall = cancellation
        analysisTask = analysisExecutor.submit {
            var failureMessage: String? = null
            val outcome = try {
                if (apiBaseUrl == null) throw IllegalStateException("Máy chủ quét chưa được cấu hình.")
                OverlayScanClient.scan(apiBaseUrl, file, cancellation)
            } catch (error: Exception) {
                failureMessage = error.message
                null
            } finally {
                file.delete()
            }
            mainHandler.post {
                if (destroyed || generation != analysisGeneration) return@post
                activeScanCall = null
                analysisTask = null
                analysisInFlight = false
                activeScanFile = null
                if (outcome != null) {
                    // Only keep the current report in memory for transfer to Flutter.
                    pendingResultJson = outcome.json
                    scanOverlay?.showResult(outcome)
                } else {
                    scanOverlay?.showError(failureMessage?.take(160)
                        ?: "Không nhận được kết quả. Hãy chọn Quét màn hình để bắt đầu lượt mới.")
                }
                promote(false)
                if (scanOverlay == null) showBubble()
            }
        }
    }

    private fun cancelCurrentScan(restoreBubble: Boolean = true) {
        val wasActive = analysisInFlight || capturing || projectionPending
        // Invalidate callbacks before closing I/O: a late response can never revive this scan.
        analysisGeneration++
        mainHandler.removeCallbacksAndMessages(null)
        analysisInFlight = false
        projectionPending = false
        pendingResultJson = null
        scanOverlay?.dismiss()
        scanOverlay = null
        analysisTask?.cancel(true)
        analysisTask = null
        activeScanCall?.cancel()
        activeScanCall = null
        activeScanFile?.delete()
        activeScanFile = null
        finishCapture(false)
        if (!destroyed) {
            promote(false)
            if (restoreBubble) showBubble()
        }
        if (wasActive) Log.d(TAG, "Screen scan cancelled: transport closed, callbacks invalidated")
    }

    private fun openDetails() {
        scanOverlay?.dismiss()
        scanOverlay = null
        showBubble()
        startActivity(Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_OPEN_HOME, true)
            if (hasPendingResult()) putExtra(MainActivity.EXTRA_OVERLAY_RESULT_READY, true)
        })
    }

    override fun onDestroy() {
        destroyed = true
        cancelCurrentScan(false)
        analysisExecutor.shutdownNow()
        hideMenu()
        bubble?.let { windowManager.removeView(it) }
        bubble = null
        statusBadge = null
        running = false
        MainActivity.notifyBubbleStateChanged()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    companion object {
        private const val TAG = "CheckLuaDaoBubble"
        const val ACTION_START = "checkluadao.bubble.START"
        const val ACTION_STOP = "checkluadao.bubble.STOP"
        const val ACTION_SHOW = "checkluadao.bubble.SHOW"
        const val ACTION_REFRESH = "checkluadao.bubble.REFRESH"
        const val ACTION_CAPTURE = "checkluadao.bubble.CAPTURE"
        const val EXTRA_RESULT_CODE = "result_code"
        const val EXTRA_RESULT_DATA = "result_data"
        private const val CHANNEL_ID = "checkluadao_screen_bubble"
        private const val NOTIFICATION_ID = 4101
        var running = false
            private set
        private var pendingResultJson: String? = null

        fun consumeResult(): String? = pendingResultJson.also { pendingResultJson = null }
    }
}
