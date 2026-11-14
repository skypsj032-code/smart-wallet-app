import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_provider.dart';
import '../shared/widgets/app_frame.dart';
import '../shared/widgets/brand_splash_screen.dart';
import 'bootstrap/app_bootstrap_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SmartWalletApp extends ConsumerStatefulWidget {
  const SmartWalletApp({super.key});

  @override
  ConsumerState<SmartWalletApp> createState() => _SmartWalletAppState();
}

class _SmartWalletAppState extends ConsumerState<SmartWalletApp>
    with WidgetsBindingObserver {
  static const _lockAfterBackgroundThreshold = Duration(seconds: 15);

  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isBackgrounded = state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;
    if (isBackgrounded) {
      // Settings can change or become unavailable while the app is away.
      _backgroundedAt ??= DateTime.now();
    }

    final appSettings = ref.read(appSettingsProvider).asData?.value;
    if (appSettings == null) {
      // If the lock policy is unknown when the app leaves the foreground,
      // require authentication again once settings become available.
      if (isBackgrounded ||
          (state == AppLifecycleState.resumed && _backgroundedAt != null)) {
        ref.read(sessionUnlockedProvider.notifier).state = false;
      }
      if (state == AppLifecycleState.resumed) _backgroundedAt = null;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      final backgroundedAt = _backgroundedAt;
      _backgroundedAt = null;

      if (!appSettings.appLockEnabled || backgroundedAt == null) {
        return;
      }

      final awayDuration = DateTime.now().difference(backgroundedAt);
      if (awayDuration >= _lockAfterBackgroundThreshold) {
        ref.read(sessionUnlockedProvider.notifier).state = false;
      }

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(appBootstrapProvider);
    final bootstrapError = bootstrapAsync.asError;

    if (bootstrapAsync.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        builder: (context, child) => AppFrame(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(
          body: BrandSplashScreen(
            trailing: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ),
        ),
      );
    }

    if (bootstrapError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        builder: (context, child) => AppFrame(
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: BrandSplashScreen(
            title: 'Smart Wallet',
            subtitle: '앱을 시작하는 중 문제가 발생했습니다.',
            trailing: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${bootstrapError.error}',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    final router = ref.watch(appRouterProvider);
    final appSettingsAsync = ref.watch(appSettingsProvider);
    final themeMode = switch (appSettingsAsync.asData?.value.themeMode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp.router(
      title: 'Smart Wallet',
      debugShowCheckedModeBanner: false,
      restorationScopeId: 'smart_wallet_app',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        // 시스템 폰트 확대로 인한 레이아웃 파괴 방지 (GlassCard, 대시보드 등)
        minScaleFactor: 1.0,
        maxScaleFactor: 1.2,
        child: AppFrame(
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      routerConfig: router,
    );
  }
}
