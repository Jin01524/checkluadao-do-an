package com.checkluadao.app_checkluadao_ttnt

import org.json.JSONObject
import java.io.File
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
import kotlin.math.roundToInt

internal data class OverlayScanResult(
    val json: String,
    val level: String,
    val score: Int?,
    val isScam: Boolean,
    val isChatScreenshot: Boolean,
    val templateSaveStatus: String?,
    val assessmentStatus: String? = null,
    val suggestedReply: String? = null,
)

internal object OverlayScanClient {
    fun scan(baseUrl: String, image: File, cancellation: ScanCancellation): OverlayScanResult = scanAt(baseUrl, image, "/api/v2/check", cancellation)

    private fun scanAt(baseUrl: String, image: File, path: String, cancellation: ScanCancellation): OverlayScanResult {
        cancellation.check()
        if (!image.isFile || image.length() == 0L || image.length() > 10L * 1024 * 1024) {
            throw IOException("Ảnh chụp không hợp lệ hoặc vượt quá 10 MB.")
        }
        val base = URL(baseUrl)
        if (base.protocol != "https") throw IOException("Máy chủ quét phải dùng HTTPS.")
        val endpoint = URL(base.toString().trimEnd('/') + path)
        val boundary = "CheckLuaDao-${UUID.randomUUID()}"
        val connection = (endpoint.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            doOutput = true
            connectTimeout = 35_000
            readTimeout = 180_000
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
            setRequestProperty("Accept", "application/json")
        }
        try {
            cancellation.attach(connection)
            connection.outputStream.buffered().use { output ->
                fun write(value: String) = output.write(value.toByteArray(Charsets.UTF_8))
                write("--$boundary\r\nContent-Disposition: form-data; name=\"platform\"\r\n\r\nsms\r\n")
                write("--$boundary\r\nContent-Disposition: form-data; name=\"clientRequestId\"\r\n\r\n${UUID.randomUUID()}\r\n")
                write("--$boundary\r\nContent-Disposition: form-data; name=\"images\"; filename=\"screen_scan.jpg\"\r\n")
                write("Content-Type: image/jpeg\r\n\r\n")
                image.inputStream().use { input ->
                    val buffer = ByteArray(64 * 1024)
                    while (true) {
                        cancellation.check()
                        val count = input.read(buffer)
                        if (count < 0) break
                        output.write(buffer, 0, count)
                    }
                }
                write("\r\n--$boundary--\r\n")
            }
            cancellation.check()
            val status = connection.responseCode
            val stream = if (status in 200..299) connection.inputStream else connection.errorStream
            val body = stream?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
                ?: throw IOException("Máy chủ không trả dữ liệu.")
            cancellation.check()
            val data = try { JSONObject(body) } catch (_: Exception) {
                throw IOException("Máy chủ trả dữ liệu không đọc được.")
            }
            if (status == 404 && path == "/api/v2/check") {
                connection.disconnect()
                cancellation.detach(connection)
                cancellation.check()
                return scanAt(baseUrl, image, "/api/check", cancellation)
            }
            if (status !in 200..299) {
                throw IOException(data.optString("error").ifBlank {
                    data.optString("message").ifBlank { "Máy chủ báo lỗi ($status)." }
                }.take(180))
            }
            val assessment = data.optJSONObject("assessment")
            val score = riskScore(if (assessment != null) assessment.opt("riskScore") else data.opt("confidenceScore"))
            val isScam = data.optBoolean("isScam", false)
            val isChatScreenshot = data.optBoolean("isChatScreenshot", true)
            val assessmentStatus = assessment?.optString("status")?.takeIf { it.isNotBlank() }
            val level = when {
                assessmentStatus == "insufficient_context" -> "Chưa đủ ngữ cảnh"
                !isChatScreenshot -> "Cần ảnh hoặc văn bản rõ hơn"
                score == null -> if (isScam) "Có dấu hiệu rủi ro" else "Chưa xác định mức độ"
                !isScam && score < 40 -> "Chưa thấy dấu hiệu lừa đảo"
                score >= 85 -> "Nguy cơ rất cao"
                score >= 70 -> "Nguy cơ cao"
                score >= 40 -> "Cần cảnh giác"
                isScam -> "Có dấu hiệu đáng ngờ"
                else -> "Chưa thấy dấu hiệu lừa đảo"
            }
            val suggestedReply = data.optJSONObject("suggestedReply")?.optString("text")?.takeIf { it.isNotBlank() }
                ?: assessment?.optString("suggestedReply")?.takeIf { it.isNotBlank() }
                ?: data.optString("suggestedReply").takeIf { it.isNotBlank() }
            return OverlayScanResult(
                data.toString(), level, score, isScam, isChatScreenshot,
                data.optString("templateSaveStatus").takeIf { it.isNotBlank() },
                assessmentStatus,
                suggestedReply,
            )
        } finally {
            cancellation.detach(connection)
            connection.disconnect()
        }
    }

    private fun riskScore(value: Any?): Int? {
        val number = when (value) {
            is Number -> value.toDouble()
            is String -> value.toDoubleOrNull()
            else -> null
        } ?: return null
        if (!number.isFinite()) return null
        val scaled = if (number > 0.0 && number < 1.0) number * 100 else number
        return scaled.roundToInt().coerceIn(0, 100)
    }
}
