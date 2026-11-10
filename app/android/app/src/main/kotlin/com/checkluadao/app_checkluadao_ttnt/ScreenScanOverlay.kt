package com.checkluadao.app_checkluadao_ttnt

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.TextView

internal class ScreenScanOverlay(
    private val context: Context,
    private val windowManager: WindowManager,
    private val onDetails: () -> Unit,
    private val onDismiss: () -> Unit,
) {
    private var root: FrameLayout? = null
    private var card: LinearLayout? = null
    private var scanAnimator: ObjectAnimator? = null

    fun showScanning() {
        val panel = prepare()
        panel.addView(label("CHECKLUADAO • QUÉT MÀN HÌNH", 11f, BLUE, true))
        panel.addView(label("Đang quét ảnh màn hình", 20f, INK, true).apply {
            setPadding(0, dp(12), 0, dp(4))
        })
        panel.addView(label("Ảnh đang được chuẩn bị để phân tích dấu hiệu lừa đảo.", 13f, MUTED))
        val scanBox = FrameLayout(context).apply {
            background = rectangle(Color.rgb(239, 245, 255))
            clipChildren = true
        }
        panel.addView(scanBox, LinearLayout.LayoutParams(-1, dp(100)).apply {
            topMargin = dp(18)
        })
        val scanContent = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            addView(ImageView(context).apply {
                setImageResource(R.drawable.ic_scan_content)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(dp(20), dp(20)).apply {
                rightMargin = dp(8)
            })
            addView(label("KIỂM TRA NỘI DUNG", 14f, BLUE, true))
        }
        scanBox.addView(scanContent, FrameLayout.LayoutParams(-1, -1))
        val line = View(context).apply { setBackgroundColor(Color.rgb(14, 99, 216)) }
        scanBox.addView(line, FrameLayout.LayoutParams(-1, dp(3), Gravity.TOP))
        scanAnimator = ObjectAnimator.ofFloat(line, "translationY", 0f, dp(97).toFloat()).apply {
            duration = 1100
            repeatCount = ValueAnimator.INFINITE
            repeatMode = ValueAnimator.REVERSE
            start()
        }
        addHideButton(panel)
    }

    fun showAnalyzing() {
        val panel = prepare()
        panel.addView(label("CHECKLUADAO • PHÂN TÍCH AI", 11f, BLUE, true))
        panel.addView(label("Đang phân tích", 20f, INK, true).apply {
            setPadding(0, dp(12), 0, dp(4))
        })
        panel.addView(label("Đang đối chiếu nội dung và dấu hiệu rủi ro. Việc này có thể mất một lúc.", 13f, MUTED))
        addProgressSpinner(panel)
        addHideButton(panel)
    }

    private fun addProgressSpinner(panel: LinearLayout) {
        val spinner = ImageView(context).apply {
            setImageResource(android.R.drawable.ic_popup_sync)
            setColorFilter(BLUE)
            contentDescription = "Đang xử lý"
        }
        panel.addView(spinner, LinearLayout.LayoutParams(dp(48), dp(48)).apply {
            gravity = Gravity.CENTER_HORIZONTAL
            topMargin = dp(18)
        })
        scanAnimator = ObjectAnimator.ofFloat(spinner, "rotation", 0f, 360f).apply {
            duration = 1300
            repeatCount = ValueAnimator.INFINITE
            start()
        }
    }

    fun showResult(result: OverlayScanResult) {
        val panel = prepare()
        if (result.assessmentStatus == "insufficient_context") {
            panel.addView(label("CHECKLUADAO • CẦN THÊM NGỮ CẢNH", 11f, AMBER, true))
            panel.addView(label("Chưa đủ ngữ cảnh", 21f, INK, true).apply {
                setPadding(0, dp(12), 0, dp(6))
            })
            panel.addView(label("Lượt này không được lưu. Khi có phản hồi mới, chọn Quét màn hình để kiểm tra lại toàn bộ đoạn chat như một lượt mới.", 13f, MUTED))
            result.suggestedReply?.let { reply ->
                val suggestion = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(dp(12), dp(12), dp(12), dp(12))
                    background = GradientDrawable().apply {
                        setColor(Color.rgb(239, 245, 255))
                        setStroke(dp(2), BLUE)
                    }
                    addView(label("TIN NHẮN AI GỢI Ý ĐỂ HỎI LẠI", 11f, BLUE, true))
                    addView(label(reply, 17f, INK, true).apply {
                        setPadding(0, dp(8), 0, 0)
                    })
                }
                panel.addView(suggestion, LinearLayout.LayoutParams(-1, -2).apply { topMargin = dp(14) })
                panel.addView(label("Với số lạ, việc trả lời có thể xác nhận bạn đang hoạt động.", 12f, AMBER))
                panel.addView(action("Sao chép câu hỏi", BLUE, Color.WHITE) {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    clipboard.setPrimaryClip(ClipData.newPlainText("Câu hỏi CheckLuaDao", reply))
                }, LinearLayout.LayoutParams(-1, dp(44)).apply { topMargin = dp(14) })
            }
            panel.addView(action("Mở CheckLuaDao", Color.rgb(238, 243, 252), INK) { onDetails() },
                LinearLayout.LayoutParams(-1, dp(44)).apply { topMargin = dp(10) })
            addHideButton(panel)
            return
        }
        val riskColor = when {
            !result.isChatScreenshot -> AMBER
            result.score == null -> AMBER
            !result.isScam && result.score < 40 -> GREEN
            result.score >= 70 -> RED
            result.score >= 40 -> AMBER
            result.isScam -> AMBER
            else -> GREEN
        }
        panel.addView(label("KẾT QUẢ QUÉT MÀN HÌNH", 11f, BLUE, true))
        panel.addView(label(result.level, 21f, riskColor, true).apply {
            setPadding(0, dp(12), 0, dp(6))
        })
        panel.addView(label(
            result.score?.let { "$it/100 điểm rủi ro AI" } ?: "Chưa có điểm rủi ro",
            15f, INK, true,
        ))
        if (result.score != null) {
            panel.addView(ProgressBar(context, null, android.R.attr.progressBarStyleHorizontal).apply {
                max = 100
                progress = result.score
                progressTintList = android.content.res.ColorStateList.valueOf(riskColor)
                progressBackgroundTintList = android.content.res.ColorStateList.valueOf(Color.rgb(228, 235, 247))
            }, LinearLayout.LayoutParams(-1, dp(9)).apply { topMargin = dp(12) })
        }
        if (result.isChatScreenshot && !result.isScam && result.score != null && result.score < 40) {
            val recheckNotice = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(12), dp(12), dp(12), dp(12))
                background = GradientDrawable().apply {
                    setColor(Color.rgb(239, 245, 255))
                    setStroke(dp(1), Color.rgb(190, 212, 255))
                }
                addView(label("LƯU Ý KHI CÓ TIN NHẮN MỚI", 11f, BLUE, true))
                addView(label("Đánh giá này dựa trên nội dung hiện có. Nếu xuất hiện tin nhắn mới có dấu hiệu đáng nghi, bạn có thể quét lại toàn bộ cuộc trò chuyện để kiểm tra.", 13f, INK).apply {
                    setPadding(0, dp(6), 0, 0)
                })
            }
            panel.addView(recheckNotice, LinearLayout.LayoutParams(-1, -2).apply {
                topMargin = dp(14)
            })
        }
        panel.addView(label("Kết quả chỉ hỗ trợ nhận diện rủi ro. Xem báo cáo trước khi quyết định.",
            12f, MUTED).apply { setPadding(0, dp(13), 0, 0) })
        val saveMessage = when (result.templateSaveStatus) {
            "saved" -> if (result.isScam || (result.score ?: 0) >= 40) "Đã lưu mẫu cảnh báo (chưa kiểm duyệt)." else "Đã lưu mẫu an toàn để đối chiếu."
            "incomplete_analysis" -> "Chưa lưu mẫu: AI thiếu một phần phân tích."
            "deferred_review" -> "Có dấu hiệu nhạy cảm; tạm hoãn lưu mẫu để tránh kết luận sai."
            "deferred_insufficient_context" -> "Chưa đủ ngữ cảnh; mẫu chưa được lưu."
            "database_error" -> "Chưa lưu được mẫu. Xem chi tiết trong app."
            else -> null
        }
        if (saveMessage != null) {
            panel.addView(label(saveMessage, 12f, MUTED).apply {
                setPadding(0, dp(8), 0, 0)
            })
        }
        panel.addView(action("Xem chi tiết", BLUE, Color.WHITE) { onDetails() },
            LinearLayout.LayoutParams(-1, dp(48)).apply { topMargin = dp(18) })
        addHideButton(panel)
    }

    fun showError(message: String, actionLabel: String = "Mở CheckLuaDao") {
        val panel = prepare()
        panel.addView(label("CHƯA THỂ PHÂN TÍCH", 11f, AMBER, true))
        panel.addView(label("Không có kết quả quét", 20f, INK, true).apply {
            setPadding(0, dp(12), 0, dp(6))
        })
        panel.addView(label(message, 13f, MUTED))
        panel.addView(action(actionLabel, BLUE, Color.WHITE) { onDetails() },
            LinearLayout.LayoutParams(-1, dp(48)).apply { topMargin = dp(18) })
        addHideButton(panel)
    }

    fun dismiss() {
        scanAnimator?.cancel()
        scanAnimator = null
        root?.let { windowManager.removeView(it) }
        root = null
        card = null
    }

    private fun prepare(): LinearLayout {
        scanAnimator?.cancel()
        scanAnimator = null
        if (root == null) {
            val layer = FrameLayout(context).apply {
                setBackgroundColor(Color.argb(160, 7, 21, 42))
                isClickable = true
            }
            val panel = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(dp(18), dp(18), dp(18), dp(16))
                background = rectangle(Color.WHITE)
                elevation = dp(16).toFloat()
            }
            val scroll = ScrollView(context).apply {
                isFillViewport = false
                clipToPadding = false
                addView(panel, ViewGroup.LayoutParams(-1, -2))
            }
            layer.addView(scroll, FrameLayout.LayoutParams(-1, -1, Gravity.TOP).apply {
                leftMargin = dp(18)
                rightMargin = dp(18)
                topMargin = dp(56)
                bottomMargin = dp(24)
            })
            windowManager.addView(layer, WindowManager.LayoutParams(-1, -1,
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT).apply { gravity = Gravity.TOP or Gravity.START })
            root = layer
            card = panel
        }
        return card!!.apply { removeAllViews() }
    }

    private fun addHideButton(panel: LinearLayout) {
        panel.addView(action("Đóng", Color.rgb(238, 243, 252), INK) { onDismiss() },
            LinearLayout.LayoutParams(-1, dp(42)).apply { topMargin = dp(10) })
    }

    private fun action(text: String, backgroundColor: Int, textColor: Int,
                       onClick: () -> Unit) = TextView(context).apply {
        this.text = text
        textSize = 14f
        setTypeface(null, Typeface.BOLD)
        setTextColor(textColor)
        gravity = Gravity.CENTER
        background = rectangle(backgroundColor)
        isClickable = true
        isFocusable = true
        setOnClickListener { onClick() }
    }

    private fun label(text: String, size: Float, color: Int, bold: Boolean = false) =
        TextView(context).apply {
            this.text = text
            textSize = size
            setTextColor(color)
            if (bold) setTypeface(null, Typeface.BOLD)
        }

    private fun rectangle(color: Int) = GradientDrawable().apply {
        setColor(color)
    }

    private fun dp(value: Int): Int = (value * context.resources.displayMetrics.density + 0.5f).toInt()

    companion object {
        private val BLUE = Color.rgb(0, 55, 176)
        private val INK = Color.rgb(11, 28, 48)
        private val MUTED = Color.rgb(82, 98, 122)
        private val GREEN = Color.rgb(4, 120, 87)
        private val AMBER = Color.rgb(146, 64, 14)
        private val RED = Color.rgb(180, 35, 24)
    }
}
