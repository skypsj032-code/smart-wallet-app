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
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/timeline')) return 1;
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
    final hideGlobalQuickPanel = location.startsWith('/quick-entry');
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    _syncController(_amountController, form.amount);

    return PopScope(
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
        body: Padding(
          padding: EdgeInsets.only(bottom: hideGlobalQuickPanel ? 0 : 80),
          child: ClipRect(
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
        ),
        bottomSheet: hideGlobalQuickPanel
            ? null
            : AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: ToggleButtons(
                              isSelected: [
                                form.type == TransactionEntryType.expense,
                                form.type == TransactionEntryType.income,
                              ],
                              onPressed: (index) {
                                ref.read(quickEntryFormProvider.notifier).setType(
                                      index == 0
                                          ? TransactionEntryType.expense
                                          : TransactionEntryType.income,
                                    );
                              },
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              selectedColor: theme.colorScheme.onPrimary,
                              color: theme.colorScheme.onSurfaceVariant,
                              fillColor: theme.colorScheme.primary,
                              borderColor: Colors.transparent,
                              selectedBorderColor: Colors.transparent,
                              constraints: const BoxConstraints(
                                minHeight: 36,
                                minWidth: 54,
                              ),
                              children: const [
                                Text('지출'),
                                Text('수입'),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SizedBox(
                              height: 36,
                              child: TextField(
                                controller: _amountController,
                                onChanged:
                                    ref.read(quickEntryFormProvider.notifier).setAmount,
                                decoration: const InputDecoration(
                                  hintText: '금액 입력',
                                  prefixText: '₩ ',
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
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
                            height: 36,
                            child: FilledButton(
                              onPressed: form.amount.trim().isNotEmpty
                                  ? () => _submit(context, form)
                                  : null,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                              child: const Text('입력'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                context.go('/');
              case 1:
                context.go('/timeline');
              case 2:
                context.go('/settings');
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
      ),
    );
  }

  void _syncController(TextEditingController controller, String value) {
    if (controller.text == value) return;
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
