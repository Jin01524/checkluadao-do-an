package com.checkluadao.app_checkluadao_ttnt

import java.net.HttpURLConnection
import java.util.concurrent.CancellationException

/** One cancellation scope per scan, including a possible legacy endpoint fallback. */
internal class ScanCancellation {
    private val lock = Any()
    @Volatile private var cancelled = false
    private var connection: HttpURLConnection? = null

    fun check() {
        if (cancelled || Thread.currentThread().isInterrupted) {
            throw CancellationException("Screen scan cancelled")
        }
    }

    fun attach(value: HttpURLConnection) {
        val accepted = synchronized(lock) {
            if (cancelled) false else {
                connection = value
                true
            }
        }
        if (!accepted) {
            value.disconnect()
            throw CancellationException("Screen scan cancelled")
        }
        check()
    }

    fun detach(value: HttpURLConnection) {
        synchronized(lock) { if (connection === value) connection = null }
    }

    fun cancel() {
        val active = synchronized(lock) {
            cancelled = true
            connection.also { connection = null }
        }
        // Closing the transport also wakes a thread blocked waiting for the server.
        runCatching { active?.disconnect() }
    }
}
