package com.example.smart_wallet_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "smart_wallet/notification_permission"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 알림 이벤트 스트림 채널
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SmartWalletNotificationService.CHANNEL_NAME,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                SmartWalletNotificationService.eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                SmartWalletNotificationService.eventSink = null
            }
        })

        // 알림 접근 권한 확인/요청 메서드 채널
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    result.success(isNotificationListenerEnabled())
                }
                "openPermissionSettings" -> {
                    openNotificationListenerSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val packageName = applicationContext.packageName
        val flat = android.provider.Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        return flat.split(":").any { it.startsWith("$packageName/") }
    }

    private fun openNotificationListenerSettings() {
        startActivity(
            android.content.Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }
}
