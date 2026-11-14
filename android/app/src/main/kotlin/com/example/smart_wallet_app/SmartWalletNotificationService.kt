package com.example.smart_wallet_app

import android.content.Context
import android.content.SharedPreferences
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject
import java.security.MessageDigest

class SmartWalletNotificationService : NotificationListenerService() {

    companion object {
        const val CHANNEL_NAME = "smart_wallet/notifications"
        @Volatile
        var eventSink: EventChannel.EventSink? = null

        // App-private, bounded staging area. The existing manifest disables
        // Android backup; raw texts are deleted after Dart confirms handling.
        private const val QUEUE_PREFERENCES = "smart_wallet_notification_queue"
        private const val ENABLED_KEY = "capture_enabled"
        private const val PENDING_KEY = "pending"
        private const val DROPPED_KEY = "dropped"
        private const val MAX_PENDING = 200
        private const val MAX_TITLE_LENGTH = 512
        private const val MAX_TEXT_LENGTH = 2048
        private val queueLock = Any()

        private fun preferences(context: Context): SharedPreferences =
            context.applicationContext.getSharedPreferences(QUEUE_PREFERENCES, Context.MODE_PRIVATE)

        private fun pendingArray(prefs: SharedPreferences): JSONArray =
            JSONArray(prefs.getString(PENDING_KEY, "[]") ?: "[]")

        private fun requireCommitted(success: Boolean) {
            check(success) { "Could not persist notification queue" }
        }

        fun configureCaptureEnabled(context: Context, enabled: Boolean) {
            synchronized(queueLock) {
                val editor = preferences(context).edit().putBoolean(ENABLED_KEY, enabled)
                if (!enabled) {
                    // Revoking consent stops collection and removes staged raw text.
                    editor.remove(PENDING_KEY).remove(DROPPED_KEY)
                }
                requireCommitted(editor.commit())
            }
        }

        private fun isCaptureEnabled(context: Context): Boolean =
            synchronized(queueLock) { preferences(context).getBoolean(ENABLED_KEY, false) }

        fun getPendingNotifications(context: Context): List<Map<String, Any>> =
            synchronized(queueLock) {
                val prefs = preferences(context)
                if (!prefs.getBoolean(ENABLED_KEY, false)) return@synchronized emptyList()
                val pending = pendingArray(prefs)
                (0 until pending.length()).map { index ->
                    val item = pending.getJSONObject(index)
                    mapOf<String, Any>(
                        "eventId" to item.getString("eventId"),
                        "packageName" to item.getString("packageName"),
                        "title" to item.getString("title"),
                        "text" to item.getString("text"),
                        "timestamp" to item.getLong("timestamp"),
                    )
                }
            }

        fun acknowledgeNotifications(context: Context, ids: List<String>) {
            if (ids.isEmpty()) return
            synchronized(queueLock) {
                val prefs = preferences(context)
                if (!prefs.getBoolean(ENABLED_KEY, false)) return@synchronized
                val pending = pendingArray(prefs)
                val acknowledged = ids.toSet()
                val retained = JSONArray()
                for (index in 0 until pending.length()) {
                    val item = pending.getJSONObject(index)
                    if (item.getString("eventId") !in acknowledged) retained.put(item)
                }
                requireCommitted(prefs.edit().putString(PENDING_KEY, retained.toString()).commit())
            }
        }

        fun getDroppedNotificationCount(context: Context): Int =
            synchronized(queueLock) { preferences(context).getInt(DROPPED_KEY, 0) }

        private fun enqueue(context: Context, event: Map<String, Any>): Boolean =
            synchronized(queueLock) {
                val prefs = preferences(context)
                if (!prefs.getBoolean(ENABLED_KEY, false)) return@synchronized false
                val pending = pendingArray(prefs)
                val id = event.getValue("eventId") as String
                for (index in 0 until pending.length()) {
                    if (pending.getJSONObject(index).getString("eventId") == id) {
                        // Still notify an active listener; DB ingestion must be idempotent.
                        return@synchronized true
                    }
                }
                if (pending.length() >= MAX_PENDING) {
                    // Keep already staged entries. Make overflow observable;
                    // never pretend the incoming event was preserved.
                    val dropped = prefs.getInt(DROPPED_KEY, 0)
                    val next = if (dropped == Int.MAX_VALUE) dropped else dropped + 1
                    requireCommitted(prefs.edit().putInt(DROPPED_KEY, next).commit())
                    return@synchronized false
                }
                pending.put(JSONObject(event))
                requireCommitted(prefs.edit().putString(PENDING_KEY, pending.toString()).commit())
                true
            }

        private fun eventId(
            packageName: String,
            notificationKey: String,
            timestamp: Long,
            title: String,
            text: String,
        ): String {
            val signature = listOf(packageName, notificationKey, timestamp.toString(), title, text)
                .joinToString("\u0000")
            return MessageDigest.getInstance("SHA-256")
                .digest(signature.toByteArray(Charsets.UTF_8))
                .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
        }

        // 알림을 필터링할 카드/은행 패키지명 목록
        private val bankingPackages = setOf(
            // 신한
            "com.shinhancard.smartsalad",
            "com.shinhancard.shinhaneasycardapp",
            "com.shinhan.sbanking",
            // KB국민
            "com.kbcard.kbkookmincard",
            "com.kbcard.cxh.payapp",
            "com.kbstar.kbbank",
            // 삼성
            "com.samsung.android.spay",
            // 현대
            "com.hyundaicard.appcard",
            // 롯데
            "com.lottecard.app",
            // 카카오
            "com.kakaobank.channel",
            "com.kakao.pay",
            // 토스 / 토스뱅크
            "viva.republica.toss",
            "com.viva.republica.tossbank",
            // 하나
            "com.hanacard.myhanacard",
            "com.hana.onebank",
            // 우리
            "com.wooribank.smart.wcmw",
            "com.wooricard.smart",
            "com.wooribank.pib.smart",
            // 농협
            "com.ibk.nhb",
            "nh.smart",
            "com.nhcard.nhsmartpay",
            "nh.smart.banking",
            // IBK기업
            "com.ibk.neobanking",
            // 우체국
            "com.epost.dspay",
            // BC카드
            "com.bccard.app",
            // 씨티
            "com.citi.citimobileapp",
            // 페이코
            "com.nhnent.payapp",
            "com.nhn.android.npay",
            // SSG페이
            "com.ssgpay",
            // 네이버페이
            "com.naver.android.pay",
            // 케이뱅크
            "com.kbankwith.smartbank",
            // 카카오페이 증권 (이체 알림)
            "com.kakaopaycorp.banking",
        )

        // 알림 내용에 금융 키워드가 2개 이상이면 필터 통과
        private fun containsBankingKeywords(combined: String): Boolean {
            val keywords = listOf("카드", "승인", "사용", "출금", "입금", "결제", "이체", "원", "페이", "bank", "pay")
            return keywords.count { combined.contains(it, ignoreCase = true) } >= 2
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Avoid reading any notification content at all until capture is enabled.
        // enqueue() checks again under the same lock in case consent changes.
        if (!isCaptureEnabled(applicationContext)) return
        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return
        val title = (extras.getCharSequence("android.title")?.toString() ?: "")
            .take(MAX_TITLE_LENGTH)
        val text = (extras.getCharSequence("android.text")?.toString() ?: "")
            .take(MAX_TEXT_LENGTH)
        val packageName = sbn.packageName ?: ""

        val combined = "$title $text"
        val isRelevant = packageName in bankingPackages || containsBankingKeywords(combined)
        if (!isRelevant) return

        try {
            val data = HashMap<String, Any>()
            data["eventId"] = eventId(packageName, sbn.key, sbn.postTime, title, text)
            data["packageName"] = packageName
            data["title"] = title
            data["text"] = text
            data["timestamp"] = sbn.postTime
            if (enqueue(applicationContext, data)) {
                // A running Flutter app can ingest immediately. If its sink is
                // unavailable, the private queue remains for the next launch.
                eventSink?.success(data)
            }
        } catch (_: Exception) {
            // Do not log notification contents or overwrite a damaged queue.
        }
    }
}
