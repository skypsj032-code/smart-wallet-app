import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/budgets/presentation/budget_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/ocr/presentation/ocr_capture_screen.dart';
import '../../features/ocr/presentation/ocr_review_screen.dart';
import '../../features/root/presentation/app_shell.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/application/settings_provider.dart';
import '../../features/settings/presentation/lock_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';
import '../../features/transactions/presentation/quick_entry_screen.dart';

final sessionUnlockedProvider = StateProvider<bool>((ref) => false);

final appRouterProvider = Provider<GoRouter>((ref) {
  final appSettings = ref.watch(appSettingsProvider).asData?.value;
  final isSessionUnlocked = ref.watch(sessionUnlockedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLockRoute = state.matchedLocation == '/lock';

      if (appSettings != null && appSettings.appLockEnabled && !isSessionUnlocked) {
        return isLockRoute ? null : '/lock';
      }

      if (isLockRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/lock',
        name: 'lock',
        pageBuilder: (context, state) =>
            _buildTransitionPage(state: state, child: const LockScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const DashboardScreen()),
          ),
          GoRoute(
            path: '/quick-entry',
            name: 'quick-entry',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const QuickEntryScreen()),
          ),
          GoRoute(
            path: '/calendar',
            name: 'calendar',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const CalendarScreen()),
          ),
          GoRoute(
            path: '/timeline',
            name: 'timeline',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const TimelineScreen()),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const SearchScreen()),
          ),
          GoRoute(
            path: '/accounts',
            name: 'accounts',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const AccountsScreen()),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const SettingsScreen()),
          ),
          GoRoute(
            path: '/statistics',
            name: 'statistics',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const StatisticsScreen()),
          ),
          GoRoute(
            path: '/ocr-capture',
            name: 'ocr-capture',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const OcrCaptureScreen()),
          ),
          GoRoute(
            path: '/ocr-review',
            name: 'ocr-review',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const OcrReviewScreen()),
          ),
          GoRoute(
            path: '/budgets',
            name: 'budgets',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const BudgetScreen()),
          ),
        ],
      ),
    ],
  );
});

NoTransitionPage<void> _buildShellPage({
  required GoRouterState state,
  required Widget child,
}) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}

NoTransitionPage<void> _buildTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  // AppShell의 AnimatedSwitcher가 화면 전환 애니메이션을 담당하므로
  // 라우터 레벨에서는 별도 트랜지션 없이 즉시 교체합니다.
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}
