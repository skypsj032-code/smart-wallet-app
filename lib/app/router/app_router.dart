import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/budgets/presentation/budget_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/notifications/presentation/notification_history_screen.dart';
import '../../features/ocr/presentation/ocr_capture_screen.dart';
import '../../features/ocr/presentation/ocr_review_screen.dart';
import '../../features/recurring_expenses/presentation/recurring_expenses_screen.dart';
import '../../features/root/presentation/app_shell.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/application/settings_provider.dart';
import '../../features/settings/presentation/lock_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';
import '../../features/timeline/presentation/timeline_screen.dart';
import '../../features/transactions/presentation/quick_entry_screen.dart';
import '../../features/tools/presentation/tools_screen.dart';

final sessionUnlockedProvider = StateProvider<bool>((ref) => false);

/// 경로 → 탭 인덱스 정적 매핑.
/// 새 라우트를 추가할 때 이 맵만 업데이트하면 AppShell이 자동 반영된다.
const _kRouteTabIndex = <String, int>{
  '/': 0,
  '/quick-entry': 0, // 모달 — 탭 변경 없음
  '/timeline': 1,
  '/tools': 2,
  '/calendar': 2,
  '/statistics': 2,
  '/search': 2,
  '/accounts': 2,
  '/budgets': 2,
  '/ocr-capture': 2,
  '/ocr-review': 2,
  '/recurring-expenses': 2,
  '/notification-history': 2,
  '/settings': 3,
  '/lock': 0, // 잠금화면 — 탭 무관
};

/// 현재 경로 문자열로부터 BottomNavigationBar 탭 인덱스를 반환한다.
/// 쿼리 파라미터는 무시한다.
int routeTabIndex(String location) {
  final path = location.split('?').first;
  return _kRouteTabIndex[path] ?? 0;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final appSettings = ref.watch(appSettingsProvider).asData?.value;
  final isSessionUnlocked = ref.watch(sessionUnlockedProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLockRoute = state.matchedLocation == '/lock';

      if (appSettings != null &&
          appSettings.appLockEnabled &&
          !isSessionUnlocked) {
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
                _buildModalPage(state: state, child: const QuickEntryScreen()),
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
            path: '/tools',
            name: 'tools',
            pageBuilder: (context, state) =>
                _buildShellPage(state: state, child: const ToolsScreen()),
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
          GoRoute(
            path: '/recurring-expenses',
            name: 'recurring-expenses',
            pageBuilder: (context, state) => _buildShellPage(
              state: state,
              child: const RecurringExpensesScreen(),
            ),
          ),
          GoRoute(
            path: '/notification-history',
            name: 'notification-history',
            pageBuilder: (context, state) => _buildShellPage(
              state: state,
              child: const NotificationHistoryScreen(),
            ),
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

/// 하단에서 슬라이드 올라오는 모�