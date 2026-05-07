# Statistics Category Interpretation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 통계 화면을 `숫자/차트 우선` 구조에서 `지출 카테고리 해석 우선` 구조로 바꿔, 이번 기간에 돈이 어디에 가장 많이 갔는지 상단에서 바로 읽을 수 있게 만든다.

**Architecture:** 지출 카테고리 해석 문구 생성 로직은 presentation 밖의 application 레이어로 분리한다. `StatisticsSnapshot`는 해석에 필요한 최소 데이터만 더 제공하고, `StatisticsScreen`은 상단 해석 카드와 상위 카테고리 목록을 우선 배치한 뒤 기존 숫자 요약과 차트를 보조 영역으로 재배치한다.

**Tech Stack:** Flutter, Riverpod, Drift, flutter_test

---

## File Map

- Create: `lib/features/statistics/application/statistics_interpretation.dart`
  - 통계 상단 해석 문구와 근거 문구를 만드는 순수 로직
- Modify: `lib/features/statistics/application/statistics_provider.dart`
  - 해석에 필요한 지출 건수 데이터를 `StatisticsSnapshot`에 추가
- Modify: `lib/features/statistics/presentation/statistics_screen.dart`
  - 상단 해석 카드 적용, 섹션 순서 재배치, 카테고리 목록 역할 강화
- Create: `test/features/statistics/application/statistics_interpretation_test.dart`
  - 해석 빌더 단위 테스트
- Create: `test/features/statistics/presentation/statistics_screen_test.dart`
  - 상단 해석 카드와 상위 카테고리 목록 위젯 테스트

### Task 1: Add failing interpretation tests

**Files:**
- Create: `test/features/statistics/application/statistics_interpretation_test.dart`
- Read: `lib/features/statistics/application/statistics_provider.dart`

- [ ] **Step 1: Write the failing test file**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_interpretation.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';

void main() {
  test('returns empty-data interpretation when there is no expense', () {
    const snapshot = StatisticsSnapshot(
      totalExpense: 0,
      totalIncome: 0,
      balance: 0,
      transactionCount: 0,
      expenseTransactionCount: 0,
      periodLabel: '2026.05',
      categories: <CategoryStat>[],
    );

    final interpretation = buildStatisticsCategoryInterpretation(snapshot);

    expect(interpretation.headline, contains('지출 흐름'));
    expect(interpretation.evidence, contains('카테고리별'));
  });

  test('returns focused interpretation when top category share is high', () {
    const snapshot = StatisticsSnapshot(
      totalExpense: 100000,
      totalIncome: 0,
      balance: -100000,
      transactionCount: 5,
      expenseTransactionCount: 5,
      periodLabel: '2026.05',
      categories: <CategoryStat>[
        CategoryStat(label: '식비', amount: 42000, share: 0.42),
        CategoryStat(label: '교통', amount: 18000, share: 0.18),
      ],
    );

    final interpretation = buildStatisticsCategoryInterpretation(snapshot);

    expect(interpretation.headline, contains('식비'));
    expect(interpretation.evidence, contains('42%'));
    expect(interpretation.evidence, contains('5건'));
  });

  test('returns general interpretation when top category exists but is not dominant', () {
    const snapshot = StatisticsSnapshot(
      totalExpense: 100000,
      totalIncome: 0,
      balance: -100000,
      transactionCount: 8,
      expenseTransactionCount: 8,
      periodLabel: '최근 3개월',
      categories: <CategoryStat>[
        CategoryStat(label: '식비', amount: 24000, share: 0.24),
        CategoryStat(label: '장보기', amount: 22000, share: 0.22),
        CategoryStat(label: '교통', amount: 18000, share: 0.18),
      ],
    );

    final interpretation = buildStatisticsCategoryInterpretation(snapshot);

    expect(interpretation.headline, contains('먼저'));
    expect(interpretation.evidence, contains('식비'));
    expect(interpretation.evidence, contains('장보기'));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\statistics\application\statistics_interpretation_test.dart
```

Expected: FAIL because `statistics_interpretation.dart` and `expenseTransactionCount` do not exist yet.

- [ ] **Step 3: Commit the failing test**

```bash
git -C "C:\smart wallet\app" add test/features/statistics/application/statistics_interpretation_test.dart
git -C "C:\smart wallet\app" commit -m "test: add statistics interpretation cases"
```

### Task 2: Implement interpretation builder and snapshot support

**Files:**
- Create: `lib/features/statistics/application/statistics_interpretation.dart`
- Modify: `lib/features/statistics/application/statistics_provider.dart`
- Test: `test/features/statistics/application/statistics_interpretation_test.dart`

- [ ] **Step 1: Add the new interpretation types and builder**

```dart
class StatisticsCategoryInterpretation {
  const StatisticsCategoryInterpretation({
    required this.headline,
    required this.evidence,
  });

  final String headline;
  final String evidence;
}

StatisticsCategoryInterpretation buildStatisticsCategoryInterpretation(
  StatisticsSnapshot snapshot,
) {
  if (snapshot.totalExpense <= 0 ||
      snapshot.expenseTransactionCount <= 0 ||
      snapshot.categories.isEmpty) {
    return const StatisticsCategoryInterpretation(
      headline: '아직 이 기간의 지출 흐름은 조금 더 쌓여야 보여요.',
      evidence: '지금은 카테고리별로 읽을 만큼 지출 기록이 많지 않아요.',
    );
  }

  final topCategory = snapshot.categories.first;
  final topSharePercent = (topCategory.share * 100).round();

  if (topCategory.share >= 0.35) {
    return StatisticsCategoryInterpretation(
      headline: '이번 기간엔 ${topCategory.label} 쪽 지출이 가장 크게 모였어요.',
      evidence: '지출의 $topSharePercent%가 ${topCategory.label}에 모였고, 총 ${snapshot.expenseTransactionCount}건이 기록됐어요.',
    );
  }

  final secondCategory =
      snapshot.categories.length > 1 ? snapshot.categories[1].label : null;
  final nextPhrase =
      secondCategory == null ? '' : ' ${secondCategory} 비중도 크게 보이고 있어요.';

  return StatisticsCategoryInterpretation(
    headline: '이번 기간엔 ${topCategory.label} 쪽 지출이 먼저 보이고 있어요.',
    evidence: '${topCategory.label} 비중이 가장 크고,$nextPhrase',
  );
}
```

- [ ] **Step 2: Extend `StatisticsSnapshot` with expense count**

```dart
class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.totalExpense,
    required this.totalIncome,
    required this.balance,
    required this.transactionCount,
    required this.expenseTransactionCount,
    required this.periodLabel,
    required this.categories,
  });

  final int expenseTransactionCount;
}
```

- [ ] **Step 3: Populate the expense count in the provider**

```dart
final expenseRows = rows.where((transaction) => transaction.type == 'expense').toList();

return StatisticsSnapshot(
  totalExpense: totalExpense,
  totalIncome: totalIncome,
  balance: totalIncome - totalExpense,
  transactionCount: rows.length,
  expenseTransactionCount: expenseRows.length,
  periodLabel: periodLabel,
  categories: categoriesList,
);
```

- [ ] **Step 4: Run the new test and analyze the two files**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\statistics\application\statistics_provider.dart lib\features\statistics\application\statistics_interpretation.dart test\features\statistics\application\statistics_interpretation_test.dart
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\statistics\application\statistics_interpretation_test.dart
```

Expected: `No issues found!` and `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git -C "C:\smart wallet\app" add lib/features/statistics/application/statistics_provider.dart lib/features/statistics/application/statistics_interpretation.dart test/features/statistics/application/statistics_interpretation_test.dart
git -C "C:\smart wallet\app" commit -m "feat: add statistics category interpretation logic"
```

### Task 3: Refactor statistics screen to lead with interpretation

**Files:**
- Modify: `lib/features/statistics/presentation/statistics_screen.dart`
- Read: `lib/features/statistics/application/statistics_interpretation.dart`

- [ ] **Step 1: Import the interpretation builder**

```dart
import '../application/statistics_interpretation.dart';
```

- [ ] **Step 2: Replace the current insight panel body with interpretation-first content**

```dart
class _InsightPanel extends StatelessWidget {
  const _InsightPanel({required this.snapshot});

  final StatisticsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final interpretation = buildStatisticsCategoryInterpretation(snapshot);
    final highlightColor =
        snapshot.balance >= 0 ? AppColors.income : AppColors.expense;

    return Card(
      elevation: 0,
      color: highlightColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이번 기간 소비 해석',
              style: theme.textTheme.labelLarge?.copyWith(
                color: highlightColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              interpretation.headline,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              interpretation.evidence,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MiniHighlightChip(
                  label: '기간',
                  value: snapshot.periodLabel,
                  accent: highlightColor,
                ),
                if (snapshot.topCategory != null)
                  _MiniHighlightChip(
                    label: '1위 지출',
                    value: snapshot.topCategory!.label,
                    accent: AppColors.warning,
                  ),
                _MiniHighlightChip(
                  label: '지출 건수',
                  value: '${snapshot.expenseTransactionCount}건',
                  accent: AppColors.primaryDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Move section order to interpretation first, category reading second**

```dart
AppSection(
  title: '이번 기간 소비 해석',
  child: _InsightPanel(snapshot: snapshot),
),
const SizedBox(height: AppSpacing.lg),
AppSection(
  title: '상위 지출 카테고리',
  child: _CategoryInsightPanel(snapshot: snapshot),
),
const SizedBox(height: AppSpacing.lg),
AppSection(
  title: '핵심 숫자',
  child: _OverviewPanel(snapshot: snapshot),
),
```

- [ ] **Step 4: Keep charts as reference, not the main voice**

```dart
AppSection(
  title: '차트로 다시 보기',
  child: _ChartsPanel(snapshot: snapshot),
),
```

- [ ] **Step 5: Run analyze for the screen**

Run:

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\statistics\presentation\statistics_screen.dart lib\features\statistics\application\statistics_interpretation.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git -C "C:\smart wallet\app" add lib/features/statistics/presentation/statistics_screen.dart
git -C "C:\smart wallet\app" commit -m "feat: make statistics interpretation-first"
```

### Task 4: Add widget coverage for the statistics screen

**Files:**
- Create: `test/features/statistics/presentation/statistics_screen_test.dart`
- Modify if needed: `lib/features/statistics/presentation/statistics_screen.dart`

- [ ] **Step 1: Write a focused screen test with provider overrides**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/statistics/application/statistics_provider.dart';
import 'package:smart_wallet_app/features/statistics/presentation/statistics_screen.dart';

void main() {
  testWidgets('shows interpretation card before category and chart sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statisticsProvider.overrideWith(
            (ref) => Stream.value(
              const StatisticsSnapshot(
                totalExpense: 100000,
                totalIncome: 300000,
                balance: 200000,
                transactionCount: 8,
                expenseTransactionCount: 5,
                periodLabel: '2026.05',
                categories: <CategoryStat>[
                  CategoryStat(label: '식비', amount: 42000, share: 0.42),
                  CategoryStat(label: '교통', amount: 18000, share: 0.18),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: StatisticsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('이번 기간 소비 해석'), findsOneWidget);
    expect(find.textContaining('식비'), findsWidgets);
    expect(find.text('상위 지출 카테고리'), findsOneWidget);
    expect(find.text('차트로 다시 보기'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the new widget test**

Run:

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\statistics\presentation\statistics_screen_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3: Commit**

```bash
git -C "C:\smart wallet\app" add test/features/statistics/presentation/statistics_screen_test.dart
git -C "C:\smart wallet\app" commit -m "test: cover statistics interpretation screen"
```

### Task 5: Final targeted verification

**Files:**
- Verify: `lib/features/statistics/application/statistics_provider.dart`
- Verify: `lib/features/statistics/application/statistics_interpretation.dart`
- Verify: `lib/features/statistics/presentation/statistics_screen.dart`
- Verify: `test/features/statistics/application/statistics_interpretation_test.dart`
- Verify: `test/features/statistics/presentation/statistics_screen_test.dart`

- [ ] **Step 1: Run targeted analyze**

```powershell
& 'C:\smart wallet\dartw.bat' analyze lib\features\statistics\application\statistics_provider.dart lib\features\statistics\application\statistics_interpretation.dart lib\features\statistics\presentation\statistics_screen.dart test\features\statistics\application\statistics_interpretation_test.dart test\features\statistics\presentation\statistics_screen_test.dart
```

Expected: `No issues found!`

- [ ] **Step 2: Run targeted tests**

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub test\features\statistics\application\statistics_interpretation_test.dart test\features\statistics\presentation\statistics_screen_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 3: Commit final verification-ready state**

```bash
git -C "C:\smart wallet\app" add lib/features/statistics/application/statistics_provider.dart lib/features/statistics/application/statistics_interpretation.dart lib/features/statistics/presentation/statistics_screen.dart test/features/statistics/application/statistics_interpretation_test.dart test/features/statistics/presentation/statistics_screen_test.dart
git -C "C:\smart wallet\app" commit -m "feat: redesign statistics around category interpretation"
```
