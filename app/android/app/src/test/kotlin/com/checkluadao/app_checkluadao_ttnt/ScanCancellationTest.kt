package com.checkluadao.app_checkluadao_ttnt

import org.junit.Assert.*
import org.junit.Test
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.CancellationException
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

class ScanCancellationTest {
    private class WaitingConnection : HttpURLConnection(URL("https://example.invalid")) {
        val started = CountDownLatch(1)
        val disconnected = CountDownLatch(1)
        val closeCount = AtomicInteger()
        override fun connect() {}
        override fun usingProxy() = false
        override fun disconnect() {
            closeCount.incrementAndGet()
            disconnected.countDown()
        }
        override fun getResponseCode(): Int {
            started.countDown()
            check(disconnected.await(2, TimeUnit.SECONDS))
            return 200
        }
    }

    @Test fun cancelWakesBlockedRequestAndRejectsLateResult() {
        val scope = ScanCancellation()
        val connection = WaitingConnection()
        val executor = Executors.newSingleThreadExecutor()
        try {
            val task = executor.submit<Boolean> {
                scope.attach(connection)
                connection.responseCode
                try { scope.check(); false } catch (_: CancellationException) { true }
            }
            assertTrue(connection.started.await(1, TimeUnit.SECONDS))
            scope.cancel()
            assertTrue(task.get(1, TimeUnit.SECONDS))
            scope.cancel()
            assertEquals(1, connection.closeCount.get())
        } finally { executor.shutdownNow() }
    }

    @Test fun cancelledScopeNeverStartsUploadOrLegacyFallback() {
        val scope = ScanCancellation()
        val connection = WaitingConnection()
        scope.cancel()
        assertThrows(CancellationException::class.java) { scope.attach(connection) }
        assertEquals(1, connection.closeCount.get())
        assertEquals(1L, connection.started.count)
    }

    @Test fun newScanCanProceedAfterPreviousScanWasCancelled() {
        val old = ScanCancellation()
        old.cancel()
        val fresh = ScanCancellation()
        val connection = WaitingConnection()
        fresh.attach(connection)
        fresh.check()
        fresh.detach(connection)
        fresh.cancel()
        assertEquals(0, connection.closeCount.get())
    }
}
