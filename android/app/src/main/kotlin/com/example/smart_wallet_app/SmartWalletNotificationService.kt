package com.example.smart_wallet_app

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

class SmartWalletNotificationService : NotificationListenerService() {

    companion object {
        const val CHANNEL_NAME = "smart_wallet/notifications"
        var eventSink: EventChannel.EventSink? = null

        // 알림을 필터링할 카드/은행 패키지명 목록
        private val bankingPackages = setOf(
            "com.shinhancard.smartsalad",
            "com.shinhancard.shinhaneasycardapp",
            "com.samsung.android.spay",
            "com.kbcard.kbkookmincard",
            "com.kbcard.cxh.payapp",
            "com.hyundaicard.appcard",
            "com.lottecard.app",
            "com.kakaobank.channel",
            "viva.republica.toss",
            "com.hanacard.myhanacard",
            "com.wooribank.smart.wcmw",
            "com.wooricard.smart",
            "com.ibk.nhb",
            "nh.smart",
            "com.nhcard.nhsmartpay",
            "com.shinhan.sbanking",
            "com.kbstar.kbbank",
            "com.ibk.neobanking",
            "com.epost.dspay",
            "com.citi.citimobileapp",
            "com.bccard.app",
            "com.ssgpay",
            "com.nhn.android.npay",
            "com.kakao.pay",
        )

        // 알림 내용에 금융 키워드가 2개 이상이면 필터 통과
        private fun containsBankingKeywords(combined: String): Boolean {
            val keywords = listOf("카드", "승인", "사용", "출금", "입금", "결제", "이체", "원", "페이", "bank", "pay")
            return keywords.count { combined.contains(it, ignoreCase = true) } >= 2
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val sink = eventSink ?: return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return
        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val packageName = sbn.packageName ?: ""

        val combined = "$title $text"
        val isRelevant = packageName in bankingPackages || containsBankingKeywords(combined)
        if (!isRelevant) return

        try {
            val data = HashMap<String, Any>()
            data["packageName"] = packageName
            data["title"] = title
            data["text"] = text
            data["timestamp"] = sbn.postTime
            sink.success(data)
        } catch (e: Exception) {
            // 싱크가 닫혀있으면 무시
        }
    }
}
