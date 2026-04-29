import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import '../../transactions/application/quick_entry_form_provider.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

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
    if (location.startsWith('/settings') ||
        location.startsWith('/calendar') ||
        location.startsWith('/statistics') ||
        location.startsWith('/search') ||
        location.startsWith('/accounts') ||
        location.startsWith('/budgets') ||
        location.startsWith('/ocr')) {
      return 2;
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
          body: ClipRect(
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
          bottomNavigationBar: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _forwardPointerScroll,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.30)
                        : Colors.white.withValues(alpha: 0.40),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.65),
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
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.12 : 0.04,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    border: Border.all(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                  child: ToggleButtons(
                                    isSelected: [
                                      form.type == TransactionEntryType.expense,
                                      form.type == TransactionEntryType.income,
                                    ],
                                    onPressed: (index) {
                                      ref
                                          .read(quickEntryFormProvider.notifier)
                                          .setType(
                                            index == 0
                                                ? TransactionEntryType.expense
                                                : TransactionEntryType.income,
                                          );
                                    },
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    selectedColor: theme.colorScheme.onPrimary,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fillColor: theme.colorScheme.primary,
                                    borderColor: Colors.transparent,
                                    selectedBorderColor: Colors.transparent,
                                    constraints: const BoxConstraints(
                                      minHeight: 34,
                                      minWidth: 48,
                                    ),
                                    children: const [
                                      Text('지출'),
                                      Text('수입'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  flex: 3,
                                  child: SizedBox(
                                    height: 38,
                                    child: TextField(
                                      controller: _amountController,
                                      onChanged: ref
                                          .read(quickEntryFormProvider.notifier)
                                          .setAmount,
                                      decoration: const InputDecoration(
                                        hintText: '금액',
                                        prefixText: '₩ ',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                SizedBox(
                                  width: 78,
                                  height: 38,
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
                                    ),
                                    child: const Text('기록'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    NavigationBar(
                      selectedIndex: currentIndex,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      onDestinationSelected: (index) {
                        switch (index) {
                          case 0:
                            context.go('/');
                            return;
                          case 1:
                            context.go('/timeline');
                            return;
                          case 2:
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
                          selectedIcon: Icon(Icons.receipt_long_rounded, size: 26),
                          label: '내역',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.menu_outlined, size: 26),
                          selectedIcon: Icon(Icons.menu_rounded, size: 26),
                          label: '전체',
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
    context.go('/quick-entry');
  }

  Future<bool> _handleBackPressed(BuildContext context, String location) async {
    final router = GoRouter.of(context);

    if (router.canPop()) {
      router.pop();
      return false;
    }

    if (location != '/') {
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
          content: Text('뒤로가기를 한 번 더 누르면 종료됩니다.'),
          duration: _exitGracePeriod,
        ),
      );
    return false;
  }
}
