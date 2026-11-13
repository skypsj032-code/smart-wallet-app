package com.example.smart_wallet_app

import android.app.KeyguardManager
import android.content.ActivityNotFoundException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.net.Uri
import android.os.Build
import android.os.CancellationSignal
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        const val METHOD_CHANNEL = "smart_wallet/notification_permission"
        private const val DEVICE_AUTH_CHANNEL = "smart_wallet/device_auth"
    }

    private var deviceAuthResult: MethodChannel.Result? = null
    private var deviceAuthSignal: CancellationSignal? = null
    private var deviceAuthSucceeded = false
    private var isActivityResumed = false
    private var screenReceiverRegistered = false

    private val screenOffReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                finishDeviceAuthentication("cancelled")
            }
        }
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
                "isBatteryOptimizationIgnored" -> {
                    result.success(isIgnoringBatteryOptimizations())
                }
                "openBatteryOptimizationSettings" -> {
                    openBatteryOptimizationSettings()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_AUTH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "authenticateDeviceCredential" -> authenticateDeviceCredential(result)
                "cancelDeviceCredential" -> {
                    finishDeviceAuthentication("cancelled")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun authenticateDeviceCredential(result: MethodChannel.Result) {
        if (deviceAuthResult != null) {
            result.success("busy")
            return
        }
        // DEVICE_CREDENTIAL alone and the reported authentication type are
        // available starting with Android 11. Older versions fail closed.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.success("unsupported")
            return
        }

        val keyguard = getSystemService(KEYGUARD_SERVICE) as? KeyguardManager
        if (keyguard == null) {
            result.success("error")
            return
        }
        if (!keyguard.isDeviceSecure) {
            result.success("notConfigured")
            return
        }

        try {
            val manager = getSystemService(BIOMETRIC_SERVICE) as? BiometricManager
            if (manager == null || manager.canAuthenticate(
                    BiometricManager.Authenticators.DEVICE_CREDENTIAL,
                ) != BiometricManager.BIOMETRIC_SUCCESS
            ) {
                result.success("error")
                return
            }

            deviceAuthResult = result
            deviceAuthSucceeded = false
            val cancellation = CancellationSignal()
            deviceAuthSignal = cancellation
            registerReceiver(screenOffReceiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
            screenReceiverRegistered = true

            BiometricPrompt.Builder(this)
                .setTitle("휴대폰 잠금 확인")
                .setSubtitle("앱 PIN을 복구하려면 휴대폰 잠금을 확인해 주세요.")
                .setAllowedAuthenticators(BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build()
                .authenticate(cancellation, mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(authentication: BiometricPrompt.AuthenticationResult) {
                        if (deviceAuthResult !== result) return
                        if (authentication.authenticationType !=
                            BiometricPrompt.AUTHENTICATION_RESULT_TYPE_DEVICE_CREDENTIAL ||
                            !keyguard.isDeviceSecure
                        ) {
                            finishDeviceAuthentication("error")
                            return
                        }
                        deviceAuthSucceeded = true
                        deliverDeviceAuthenticationWhenActive()
                    }

                    override fun onAuthenticationError(errorCode: Int, errorMessage: CharSequence) {
                        if (deviceAuthResult !== result) return
                        finishDeviceAuthentication(
                            when (errorCode) {
                                BiometricPrompt.BIOMETRIC_ERROR_NO_DEVICE_CREDENTIAL -> "notConfigured"
                                BiometricPrompt.BIOMETRIC_ERROR_CANCELED,
                                BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED -> "cancelled"
                                else -> "error"
                            },
                        )
                    }
                })
        } catch (_: Exception) {
            if (deviceAuthResult === result) {
                finishDeviceAuthentication("error")
            } else {
                result.success("error")
            }
        }
    }

    private fun deliverDeviceAuthenticationWhenActive() {
        if (deviceAuthSucceeded && isActivityResumed && hasWindowFocus()) {
            finishDeviceAuthentication("success")
        }
    }

    private fun finishDeviceAuthentication(outcome: String) {
        val pendingResult = deviceAuthResult ?: return
        deviceAuthResult = null
        deviceAuthSucceeded = false
        val cancellation = deviceAuthSignal
        deviceAuthSignal = null
        if (screenReceiverRegistered) {
            screenReceiverRegistered = false
            unregisterReceiver(screenOffReceiver)
        }
        if (outcome != "success") cancellation?.cancel()
        pendingResult.success(outcome)
    }

    override fun onResume() {
        super.onResume()
        isActivityResumed = true
        deliverDeviceAuthenticationWhenActive()
    }

    override fun onPause() {
        isActivityResumed = false
        super.onPause()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) deliverDeviceAuthenticationWhenActive()
    }

    override fun onUserLeaveHint() {
        // The system credential prompt may itself pause this activity. A
        // user-initiated departure is different and must cancel the request.
        finishDeviceAuthentication("cancelled")
        super.onUserLeaveHint()
    }

    override fun onDestroy() {
        finishDeviceAuthentication("cancelled")
        super.onDestroy()
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
            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val powerManager = getSystemService(POWER_SERVICE) as? PowerManager ?: return false
        return powerManager.isIgnoringBatteryOptimizations(packageName)
    }

    private fun openBatteryOptimizationSettings() {
        val packageUri = Uri.parse("package:$packageName")
        val requestIntent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            .setData(packageUri)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        try {
            startActivity(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    requestIntent
                } else {
                    fallbackIntent
                },
            )
        } catch (_: ActivityNotFoundException) {
            startActivity(fallbackIntent)
        }
    }
}
