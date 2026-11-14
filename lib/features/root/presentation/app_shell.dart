import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_opacity.dart';
import '../../../app/theme/app_sizes.dart';
import '../../budgets/application/budget_alert_provider.dart';
import '../../notifications/presentation/notification_transaction_banner.dart';
import '../../settings/application/settings_provider.dart';
import '../../transactions/application/quick_entry_exit_coordinator.dart';
import '../../transactions/application/quick_entry_form_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.child,
    this.showNotificationFeatures = true,
  });

  final Widget child;
  final bool showNotificationFeatures;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  static const _exitGracePeriod = Duration(seconds: 2);

  late final ScrollController _primaryScrollController;
  DateTime? _lastBackPressedAt;
  bool _obscured = false; // 멀티태스킹/스위처 노출 방지

  @override
  void initState() {
    super.initState();
    _primaryScrollController = ScrollController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _primaryScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldObscure = state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused;
    if (shouldObscure != _obscured) {
      setState(() => _obscured = shouldObscure);
    }
  }

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return routeTabIndex(location);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    final form = ref.watch(quickEntryFormProvider);
    final isSubmitting = ref.watch(quickEntrySubmitStateProvider);
    final pendingNotice = ref.watch(quickEntrySaveNoticeProvider);
    if (pendingNotice != null) {
      // Rebuild when lock settings or session state resolve; never consume a
      // save result on an old shell that is about to be hidden by the lock.
      ref.watch(appSettingsProvider);
      ref.watch(sessionUnlockedProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final settings = ref.read(appSettingsProvider).asData?.value;
        if (settings == null ||
            (settings.appLockEnabled && !ref.read(sessionUnlockedProvider)) ||
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path == '/lock') {
          return;
        }
        final notices = ref.read(quickEntrySaveNoticeProvider.notifier);
        if (!identical(notices.state, pendingNotice)) return;
        notices.state = null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(pendingNotice.message)),
        );
        final currentForm = ref.read(quickEntryFormProvider);
        if (pendingNotice.closeEditor &&
            currentForm.amount.isEmpty &&
            currentForm.editingId == null &&
            GoRouterState.of(context).uri.path == '/quick-entry') {
          context.go('/');
        }
      });
    }

    // 예산 임계값 초과 감지 → 앱 내 SnackBar 알림
    ref.listen<BudgetAlertEvent?>(budgetAlertProvider, (_, event) {
      if (event == null || !context.mounted) return;
      final (icon, label) = switch (event.level) {
        BudgetAlertLevel.half => ('⚠️', '${event.label} 예산 50% 소진됐어요.'),
        BudgetAlertLevel.warning => ('🔶', '${event.label} 예산 80% 소진됐어요.'),
        BudgetAlertLevel.exceeded => ('🚨', '${event.label} 예산을 초과했어요!'),
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$icon $label'),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
    });
    final location = GoRouterState.of(context).uri.toString();
    final hideGlobalQuickPanel =
        location.startsWith('/quick-entry') ||
        location.startsWith('/lock') ||
        form.editingId != null ||
        isSubmitting;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PrimaryScrollController(
      controller: _primaryScrollController,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }

          final shouldExit = await _handleBackPressed(context, location);
          if (shouldExit && mounted) {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              // ShellRoute supplies one Navigator; keeping two copies during
              // an AnimatedSwitcher transition duplicates its GlobalKey.
              ClipRect(child: widget.child),
              // 알림 감지 배너 — 화면 최상단에 오버레이
              if (widget.showNotificationFeatures)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: NotificationTransactionBanner(),
                ),
              // 멀티태스킹/앱 스위처 금융정보 노출 방지
              // Offstage: 보안 모드 활성 시 하위 트리 렌더링 중단 → GPU Overdraw 방지
              if (_obscured)
                Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        size: AppSizes.touchTarget,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: !hideGlobalQuickPanel &&
                  (location == '/' || location.startsWith('/?') || location == '/timeline')
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (!ref.read(quickEntrySubmitStateProvider)) {
                      // Keep an unfinished new entry so it can be resumed.
                      context.push('/quick-entry');
                    }
                  },
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('기록하기'),
                )
              : null,
          bottomNavigationBar: RepaintBoundary(
            child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _forwardPointerScroll,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: AppOpacity.overlayHighlightDark)
                        : Colors.white.withValues(alpha: AppOpacity.overlayUtilityLight),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: AppOpacity.borderGlass)
                            : AppColors.primary.withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NavigationBar(
                          selectedIndex: currentIndex,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          onDestinationSelected: (index) async {
                            if (ref.read(quickEntrySubmitStateProvider)) return;
                            if (ref.read(quickEntryFormProvider).editingId != null &&
                                !await ref.read(quickEntryExitCoordinatorProvider).confirmExit()) {
                              return;
                            }
                            if (!context.mounted) return;
                            if (ref.read(quickEntryFormProvider).editingId == null) {
                              ref.read(quickEntryFormProvider.notifier).abandonFailedSaveRestoration();
                            }
                            switch (index) {
                              case 0:
                                context.go('/');
                                return;
                              case 1:
                                context.go('/timeline');
                                return;
                              case 2:
                                context.go('/tools');
                                return;
                              case 3:
                                context.go('/settings');
                                return;
                            }
                          },
                          destinations: const [
                            NavigationDestination(
                              icon: Icon(Icons.home_outlined, size: AppSizes.iconMD),
                              selectedIcon: Icon(Icons.home_rounded, size: AppSizes.iconMD),
                              label: '홈',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.receipt_long_outlined, size: AppSizes.iconMD),
                              selectedIcon:
                                  Icon(Icons.receipt_long_rounded, size: AppSizes.iconMD),
                              label: '내역',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.menu_outlined, size: AppSizes.iconMD),
                              selectedIcon: Icon(Icons.menu_rounded, size: AppSizes.iconMD),
                              label: '도구',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.settings_outlined, size: AppSizes.iconMD),
                              selectedIcon:
                                  Icon(Icons.settings_rounded, size: AppSizes.iconMD),
                              label: '설정',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ), // RepaintBoundary
      ),
    );
  }

  void _forwardPointerScroll(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_primaryScrollController.hasClients) {
      return;
    }

    final position = _primaryScrollController.position;
    final targetOffset = (position.pixels + event.scrollDelta.dy).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (targetOffset == position.pixels) {
      return;
    }

    _primaryScrollController.jumpTo(targetOffset);
  }

  Future<bool> _handleBackPressed(BuildContext context, String location) async {
    if (ref.read(quickEntrySubmitStateProvider)) return false;
    final router = GoRouter.of(context);

    if (location.startsWith('/quick-entry') &&
        ref.read(quickEntryFormProvider).editingId != null) {
      final allowed = await ref.read(quickEntryExitCoordinatorProvider).confirmExit();
      if (!allowed || !context.mounted) return false;
    }

    if (location.startsWith('/quick-entry') &&
        ref.read(quickEntryFormProvider).editingId == null) {
      ref.read(quickEntryFormProvider.notifier).abandonFailedSaveRestoration();
    }

    if (router.canPop()) {
      router.pop();
      return false;
    }

    if (!_isHomeLocation(location)) {
      _lastBackPressedAt = null;
      context.go('/');
      return false;
    }

    final now = DateTime.now();
    final lastBackPressedAt = _lastBackPressedAt;
    final shouldExit = lastBackPressedAt != null &&
        now.difference(lastBackPressedAt) <= _exitGracePeriod;

    if (shouldExit) {
      return true;
    }

    _lastBackPressedAt = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('뒤로가기를 한 번 더 누르면 앱이 종료됩니다.'),
          duration: _exitGracePeriod,
          behavior: SnackBarBehavior.floating,
        ),
      );
    return false;
  }

  bool _isHomeLocation(String location) {
    return location == '/' || location.startsWith('/?');
  }
}
