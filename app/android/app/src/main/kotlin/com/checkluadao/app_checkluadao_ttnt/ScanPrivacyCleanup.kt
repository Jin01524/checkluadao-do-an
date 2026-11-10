package com.checkluadao.app_checkluadao_ttnt

import android.content.Context

/** Delete only files and preference keys owned by the removed scan-history flow. */
internal fun clearLegacyScanCache(context: Context) {
    context.cacheDir.listFiles { file ->
        file.isFile && (file.name.startsWith("screen_scan_") || file.name.startsWith("conversation_"))
    }?.forEach { it.delete() }
    context.getSharedPreferences(MainActivity.PREFS, Context.MODE_PRIVATE).edit()
        .remove("pending_capture_path")
        .remove("pending_result_path")
        .remove("pending_result_image_path")
        .apply()
}
