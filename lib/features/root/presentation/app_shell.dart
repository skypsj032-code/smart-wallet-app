import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../notifications/presentation/notification_transaction_banner.dart';
import '../../transactions/application/quick_entry_form_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _exitGracePeriod = Duration(seconds: 2);

  late final TextEditingController _amountController;
  late final ScrollController _primaryScrollController;
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _primaryScrollController = ScrollController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _primaryScrollController.dispose();
    super.dispose();
  }

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/timeline')) {
      return 1;
    }
    if (location.startsWith('/tools') ||
        location.startsWith('/calendar') ||
        location.startsWith('/statistics') ||
        location.startsWith('/search') ||
        location.startsWith('/accounts') ||
        location.startsWith('/budgets') ||
        location.startsWith('/ocr') ||
        location.startsWith('/recurring-expenses')) {
      return 2;
    }
    if (location.startsWith('/settings')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _locationToIndex(context);
    final form = ref.watch(quickEntryFormProvider);
    final location = GoRouterState.of(context).uri.toString();
    final hideGlobalQuickPanel =
        location.startsWith('/quick-entry') || location.startsWith('/lock');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _syncController(_amountController, form.amount);

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
              ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  reverseDuration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    );

                    return ColoredBox(
                      color: theme.scaffoldBackgroundColor,
                      child: FadeTransition(
                        opacity: curved,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.025, 0),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(location),
                    child: widget.child,
                  ),
                ),
              ),
              // 알림 감지 배너 — 화면 최상단에 오버레이
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: NotificationTransactionBanner(),
              ),
            ],
          ),
          bottomNavigationBar: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _forwardPointerScroll,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.54),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : const Color(0xFFD4A843).withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hideGlobalQuickPanel)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.white.withValues(alpha: 0.24),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: isDark ? 0.12 : 0.42,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 지출 / 수입 토글 — 타입 선택용, 최대한 작게
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.10 : 0.34,
                                        ),
                                      ),
                                    ),
                                    child: ToggleButtons(
                                      isSelected: [
                                        form.type ==
                                            TransactionEntryType.expense,
                                        form.type ==
                                            TransactionEntryType.income,
                                      ],
                                      onPressed: (index) {
                                        ref
                                            .read(
                                              quickEntryFormProvider.notifier,
                                            )
                                            .setType(
                                              index == 0
                                                  ? TransactionEntryType.expense
                                                  : TransactionEntryType.income,
                                            );
                                      },
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.md,
                                      ),
                                      selectedColor:
                                          theme.colorScheme.onPrimary,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fillColor: theme.colorScheme.primary,
                                      borderColor: Colors.transparent,
                                      selectedBorderColor: Colors.transparent,
                                      constraints: const BoxConstraints(
                                        minHeight: 30,
                                        minWidth: 38,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      children: const [
                                        Text('지출'),
                                        Text('수입'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // 금액 입력 — 주인공, 최대한 넓게 + 세로 가운데 정렬
                                  Expanded(
                                    child: TextField(
                                      controller: _amountController,
                                      onChanged: ref
                                          .read(
                                            quickEntryFormProvider.notifier,
                                          )
                                          .setAmount,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: const InputDecoration(
                                        hintText: '금액',
                                        prefixText: '₩',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // 기록 버튼 — 작게
                                  SizedBox(
                                    width: 48,
                                    height: 34,
                                    child: FilledButton(
                                      onPressed: form.amount.trim().isNotEmpty
                                          ? () => _submit(context, form)
                                          : null,
                                      style: FilledButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.md,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('기록'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        NavigationBar(
                          selectedIndex: currentIndex,
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          onDestinationSelected: (index) {
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
                              icon: Icon(Icons.home_outlined, size: 26),
                              selectedIcon: Icon(Icons.home_rounded, size: 26),
                              label: '홈',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.receipt_long_outlined, size: 26),
                              selectedIcon:
                                  Icon(Icons.receipt_long_rounded, size: 26),
                              label: '내역',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.menu_outlined, size: 26),
                              selectedIcon: Icon(Icons.menu_rounded, size: 26),
                              label: '도구',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.settings_outlined, size: 26),
                              selectedIcon:
                                  Icon(Icons.settings_rounded, size: 26),
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

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _submit(BuildContext context, QuickEntryFormState form) {
    if (!context.mounted) {
      return;
    }

    final notifier = ref.read(quickEntryFormProvider.notifier);
    notifier.reset();
    notifier.setType(form.type);
    notifier.setAmount(form.amount);
    // push: 현재 화면 위에 하단 슬라이드로 진입 (화면 이탈 없음)
    context.push('/quick-entry');
  }

  Future<bool> _handleBackPressed(BuildContext context, String location) async {
    final router = GoRouter.of(context);

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
          content: Text('뒤로가기를 한 번 더 누르�