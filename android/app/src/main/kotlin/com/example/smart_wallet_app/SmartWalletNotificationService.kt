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
