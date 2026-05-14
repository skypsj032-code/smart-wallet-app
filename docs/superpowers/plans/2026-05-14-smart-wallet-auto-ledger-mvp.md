# Smart Wallet Auto Ledger MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an Android-first automatic ledger MVP that ingests notification/SMS transaction signals, converts them into trustworthy ledger candidates, and surfaces a read-first dashboard without requiring routine manual entry.

**Architecture:** Extend the existing local-first Drift database and `notifications` feature into a full ingestion pipeline. Keep raw signal capture, normalization, verification, and ledger publication as separate units so the app can ingest noisy signals without polluting the canonical `transactions` table. Reuse the existing dashboard and account surfaces, but shift them from quick-entry-first to auto-ledger-first summaries.

**Tech Stack:** Flutter, Riverpod, Drift/SQLite, existing Android notification channel integration, widget tests, repository tests

---

## Summary

### In scope

- ingest Android notification and SMS signals into a raw signal store
- normalize signals into ledger candidates
- verify, dedupe, and publish only trustworthy candidates
- expose a read-first dashboard with review visibility
- add provenance, trust, and backup controls needed for MVP

### Out of scope

- full bank or card API integrations
- advanced budgeting and complex installment UX
- exhaustive power-user filtering and customization
- iOS capture parity

### Execution order

1. schema and domain models
2. ingestion pipeline
3. verification and publication
4. dashboard and review UI
5. trust controls and backup hooks

### Definition of done

- raw signals can be captured without mutating the canonical ledger
- trustworthy candidates auto-publish into `transactions`
- uncertain candidates remain reviewable without polluting the ledger
- the home/dashboard experience reads as auto-ledger-first
- provenance and backup surfaces exist for user trust

## Risks And Dependencies

- Android signal formats are noisy and vary across apps, so parser and verification boundaries must stay explicit.
- Drift migration work is the critical path because every later task depends on new tables and columns.
- Dashboard changes should not regress existing manual entry flows during MVP transition.
- Backup and provenance UI matter early because automatic ingestion without trust cues will feel unsafe.

## File Structure

### Existing files to modify

- `app/lib/core/database/tables.dart`
  Responsibility: extend schema for raw signals, ledger candidates, verification metadata, and richer published transactions.
- `app/lib/core/database/app_database.dart`
  Responsibility: migrations, typed queries, candidate promotion helpers, dashboard summary reads.
- `app/lib/features/notifications/application/notification_parser.dart`
  Responsibility: parse raw Android signals into normalized transaction signal parts.
- `app/lib/features/notifications/application/notification_provider.dart`
  Responsibility: feed parsed signals into the new ingestion pipeline instead of only writing banner/history rows.
- `app/lib/features/transactions/data/transaction_repository.dart`
  Responsibility: publish verified candidates into canonical transactions and support provenance metadata.
- `app/lib/features/dashboard/presentation/dashboard_screen.dart`
  Responsibility: replace manual-entry-first emphasis with auto-ledger summary, review count, and read-first signals.
- `app/lib/features/settings/presentation/settings_screen.dart`
  Responsibility: expose backup/export plus auto-ledger trust controls and source-health state.

### New files to create

- `app/lib/features/auto_ledger/domain/ledger_signal.dart`
  Responsibility: normalized ingestion model for raw external transaction signals.
- `app/lib/features/auto_ledger/domain/ledger_candidate.dart`
  Responsibility: candidate ledger state, certainty, review status, provenance, and location/category context.
- `app/lib/features/auto_ledger/application/auto_ledger_ingestion_service.dart`
  Responsibility: convert parsed notification/SMS events into raw signal rows and candidate rows.
- `app/lib/features/auto_ledger/application/auto_ledger_verification_service.dart`
  Responsibility: dedupe candidates, assign certainty, and decide publish vs review state.
- `app/lib/features/auto_ledger/application/auto_ledger_provider.dart`
  Responsibility: Riverpod providers for review queue, published summary, and health counts.
- `app/lib/features/auto_ledger/presentation/review_queue_card.dart`
  Responsibility: dashboard/home widget that surfaces held-back candidates without polluting the main ledger.
- `app/lib/features/auto_ledger/presentation/auto_ledger_detail_sheet.dart`
  Responsibility: explain source, verification reason, and publication status for a candidate or published ledger row.
- `app/test/features/auto_ledger/auto_ledger_ingestion_service_test.dart`
  Responsibility: ingestion and candidate generation tests.
- `app/test/features/auto_ledger/auto_ledger_verification_service_test.dart`
  Responsibility: certainty, dedupe, and publish/hold logic tests.
- `app/test/core/database/auto_ledger_schema_test.dart`
  Responsibility: schema and migration coverage for the new tables/columns.
- `app/test/features/dashboard/auto_ledger_dashboard_test.dart`
  Responsibility: read-first dashboard behavior and review count visibility.

## Task 1: Add Auto-Ledger Schema And Domain Models

**Files:**
- Create: `app/lib/features/auto_ledger/domain/ledger_signal.dart`
- Create: `app/lib/features/auto_ledger/domain/ledger_candidate.dart`
- Create: `app/test/core/database/auto_ledger_schema_test.dart`
- Modify: `app/lib/core/database/tables.dart`
- Modify: `app/lib/core/database/app_database.dart`

- [ ] **Step 1: Write the failing schema test**

```dart
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/core/database/app_database.dart';

void main() {
  test('auto-ledger tables and provenance columns exist', () async {
    final database = AppDatabase.test();

    final rawTables = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name IN ('raw_transaction_signals', 'ledger_candidates')",
    ).get();

    expect(rawTables.map((row) => row.read<String>('name')), containsAll([
      'raw_transaction_signals',
      'ledger_candidates',
    ]));

    final transactionColumns = await database.customSelect("PRAGMA table_info(transactions)").get();
    final names = transactionColumns.map((row) => row.read<String>('name')).toList();

    expect(names, containsAll([
      'source_kind',
      'source_ref_id',
      'review_status',
      'location_label',
      'verification_summary',
    ]));

    await database.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\flutterw.bat test -r expanded test\core\database\auto_ledger_schema_test.dart`

Expected: FAIL because the new tables and transaction columns do not exist yet.

- [ ] **Step 3: Add the schema and domain model skeletons**

```dart
// app/lib/features/auto_ledger/domain/ledger_signal.dart
class LedgerSignal {
  const LedgerSignal({
    required this.sourceKind,
    required this.sourceApp,
    required this.rawTitle,
    required this.rawBody,
    required this.detectedAt,
    required this.amount,
    required this.flowType,
    this.merchantName,
    this.accountHint,
    this.categoryHint,
  });

  final String sourceKind;
  final String sourceApp;
  final String rawTitle;
  final String rawBody;
  final DateTime detectedAt;
  final int amount;
  final String flowType;
  final String? merchantName;
  final String? accountHint;
  final String? categoryHint;
}

// app/lib/features/auto_ledger/domain/ledger_candidate.dart
class LedgerCandidate {
  const LedgerCandidate({
    required this.localId,
    required this.amount,
    required this.flowType,
    required this.occurredAt,
    required this.candidateStatus,
    required this.certaintyScore,
    this.merchantName,
    this.categoryId,
    this.accountId,
    this.locationLabel,
    this.verificationSummary,
  });

  final String localId;
  final int amount;
  final String flowType;
  final DateTime occurredAt;
  final String candidateStatus;
  final double certaintyScore;
  final String? merchantName;
  final String? categoryId;
  final String? accountId;
  final String? locationLabel;
  final String? verificationSummary;
}
```

```dart
// app/lib/core/database/tables.dart
class RawTransactionSignals extends Table {
  TextColumn get localId => text()();
  TextColumn get sourceKind => text()();
  TextColumn get sourceApp => text()();
  TextColumn get rawTitle => text()();
  TextColumn get rawBody => text()();
  IntColumn get amount => integer()();
  TextColumn get flowType => text()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get accountHint => text().nullable()();
  TextColumn get categoryHint => text().nullable()();
  DateTimeColumn get detectedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class LedgerCandidates extends Table {
  TextColumn get localId => text()();
  TextColumn get signalId => text()();
  IntColumn get amount => integer()();
  TextColumn get flowType => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get candidateStatus => text()();
  RealColumn get certaintyScore => real()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get locationLabel => text().nullable()();
  TextColumn get verificationSummary => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastModifiedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

// add to Transactions
TextColumn get sourceKind => text().nullable()();
TextColumn get sourceRefId => text().nullable()();
TextColumn get reviewStatus => text().withDefault(const Constant('published'))();
TextColumn get locationLabel => text().nullable()();
TextColumn get verificationSummary => text().nullable()();
```

- [ ] **Step 4: Wire the migration and rerun the schema test**

```dart
// app/lib/core/database/app_database.dart
@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    Budgets,
    RecurringExpenses,
    Accounts,
    AppSettings,
    BackupMetadata,
    NotificationHistories,
    OcrDrafts,
    RawTransactionSignals,
    LedgerCandidates,
  ],
)
class AppDatabase extends _$AppDatabase {
  // ...

  static AppDatabase test() => AppDatabase.forTesting();

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(transactions, transactions.sourceKind);
            await m.addColumn(transactions, transactions.sourceRefId);
            await m.addColumn(transactions, transactions.reviewStatus);
            await m.addColumn(transactions, transactions.locationLabel);
            await m.addColumn(transactions, transactions.verificationSummary);
            await m.createTable(rawTransactionSignals);
            await m.createTable(ledgerCandidates);
          }
        },
      );
}
```

Run: `.\flutterw.bat test -r expanded test\core\database\auto_ledger_schema_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/core/database/tables.dart app/lib/core/database/app_database.dart app/lib/features/auto_ledger/domain/ledger_signal.dart app/lib/features/auto_ledger/domain/ledger_candidate.dart app/test/core/database/auto_ledger_schema_test.dart
git commit -m "feat: add auto-ledger schema foundation"
```

## Task 2: Build Ingestion And Candidate Creation

**Files:**
- Create: `app/lib/features/auto_ledger/application/auto_ledger_ingestion_service.dart`
- Create: `app/test/features/auto_ledger/auto_ledger_ingestion_service_test.dart`
- Modify: `app/lib/features/notifications/application/notification_parser.dart`
- Modify: `app/lib/features/notifications/application/notification_provider.dart`

- [ ] **Step 1: Write the failing ingestion test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wallet_app/features/auto_ledger/application/auto_ledger_ingestion_service.dart';
import 'package:smart_wallet_app/features/notifications/application/notification_parser.dart';

void main() {
  test('ingestParsedNotification stores a raw signal and candidate', () async {
    final database = AppDatabase.test();
    final service = AutoLedgerIngestionService(database);

    final parsed = ParsedNotificationTransaction(
      amount: 6300,
      type: 'expense',
      merchant: '스타벅스 강남점',
      rawTitle: '[신한카드]',
      rawText: '6,300원 승인 스타벅스 강남점',
      detectedAt: DateTime(2026, 5, 14, 8, 42),
      cardName: '신한카드',
      suggestedCategoryKeyword: '카페',
    );

    await service.ingestParsedNotification(
      packageName: 'com.shcard.smartpay',
      parsed: parsed,
    );

    final signals = await database.select(database.rawTransactionSignals).get();
    final candidates = await database.select(database.ledgerCandidates).get();

    expect(signals, hasLength(1));
    expect(candidates, hasLength(1));
    expect(candidates.single.candidateStatus, 'pending_verification');
    expect(candidates.single.merchantName, '스타벅스 강남점');

    await database.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\flutterw.bat test -r expanded test\features\auto_ledger\auto_ledger_ingestion_service_test.dart`

Expected: FAIL because the service does not exist yet.

- [ ] **Step 3: Implement ingestion service and parser bridge**

```dart
// app/lib/features/auto_ledger/application/auto_ledger_ingestion_service.dart
class AutoLedgerIngestionService {
  AutoLedgerIngestionService(this._database);

  final AppDatabase _database;

  Future<void> ingestParsedNotification({
    required String packageName,
    required ParsedNotificationTransaction parsed,
  }) async {
    final now = DateTime.now();
    final signalId = 'sig_${const Uuid().v4()}';
    final candidateId = 'cand_${const Uuid().v4()}';

    await _database.batch((batch) {
      batch.insert(
        _database.rawTransactionSignals,
        RawTransactionSignalsCompanion.insert(
          localId: signalId,
          sourceKind: 'notification',
          sourceApp: packageName,
          rawTitle: parsed.rawTitle,
          rawBody: parsed.rawText,
          amount: parsed.amount,
          flowType: parsed.type,
          merchantName: Value(parsed.merchant),
          accountHint: Value(parsed.cardName),
          categoryHint: Value(parsed.suggestedCategoryKeyword),
          detectedAt: parsed.detectedAt,
          createdAt: now,
        ),
      );

      batch.insert(
        _database.ledgerCandidates,
        LedgerCandidatesCompanion.insert(
          localId: candidateId,
          signalId: signalId,
          amount: parsed.amount,
          flowType: parsed.type,
          occurredAt: parsed.detectedAt,
          candidateStatus: 'pending_verification',
          certaintyScore: 0.55,
          merchantName: Value(parsed.merchant),
          locationLabel: const Value(null),
          verificationSummary: const Value('Single-source notification candidate'),
          createdAt: now,
          lastModifiedAt: now,
        ),
      );
    });
  }
}
```

```dart
// app/lib/features/notifications/application/notification_provider.dart
final autoLedgerIngestionServiceProvider = Provider<AutoLedgerIngestionService>(
  (ref) => AutoLedgerIngestionService(ref.watch(appDatabaseProvider)),
);

// inside listener
await ref.read(autoLedgerIngestionServiceProvider).ingestParsedNotification(
  packageName: event['package'] as String? ?? '',
  parsed: parsed,
);
```

- [ ] **Step 4: Run the ingestion and existing parser tests**

Run: `.\flutterw.bat test -r expanded test\features\auto_ledger\auto_ledger_ingestion_service_test.dart test\features\notifications\notification_parser_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/auto_ledger/application/auto_ledger_ingestion_service.dart app/lib/features/notifications/application/notification_provider.dart app/lib/features/notifications/application/notification_parser.dart app/test/features/auto_ledger/auto_ledger_ingestion_service_test.dart app/test/features/notifications/notification_parser_test.dart
git commit -m "feat: ingest notification signals into auto-ledger candidates"
```

## Task 3: Add Verification, Dedupe, And Ledger Publication

**Files:**
- Create: `app/lib/features/auto_ledger/application/auto_ledger_verification_service.dart`
- Create: `app/test/features/auto_ledger/auto_ledger_verification_service_test.dart`
- Modify: `app/lib/features/transactions/data/transaction_repository.dart`
- Modify: `app/lib/core/database/app_database.dart`

- [ ] **Step 1: Write the failing verification test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('high-certainty candidate is published and low-certainty candidate is held', () async {
    final database = AppDatabase.test();
    final service = AutoLedgerVerificationService(database);

    await seedCandidate(database, id: 'cand_hi', amount: 6300, merchant: '스타벅스 강남점', certainty: 0.92);
    await seedCandidate(database, id: 'cand_lo', amount: 6310, merchant: '스타벅스?', certainty: 0.41);

    await service.runVerificationPass();

    final published = await (database.select(database.transactions)
          ..where((t) => t.sourceRefId.isNotNull()))
        .get();
    final candidates = await database.select(database.ledgerCandidates).get();

    expect(published, hasLength(1));
    expect(candidates.singleWhere((row) => row.localId == 'cand_hi').candidateStatus, 'published');
    expect(candidates.singleWhere((row) => row.localId == 'cand_lo').candidateStatus, 'review_required');

    await database.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\flutterw.bat test -r expanded test\features\auto_ledger\auto_ledger_verification_service_test.dart`

Expected: FAIL because verification and publication services do not exist yet.

- [ ] **Step 3: Implement verification rules and publication path**

```dart
// app/lib/features/auto_ledger/application/auto_ledger_verification_service.dart
class AutoLedgerVerificationService {
  AutoLedgerVerificationService(this._database);

  final AppDatabase _database;

  Future<void> runVerificationPass() async {
    final rows = await _database.select(_database.ledgerCandidates).get();

    for (final row in rows) {
      if (row.candidateStatus != 'pending_verification') continue;

      if (row.certaintyScore >= 0.85) {
        await _publish(row);
      } else {
        await (_database.update(_database.ledgerCandidates)
              ..where((tbl) => tbl.localId.equals(row.localId)))
            .write(
          LedgerCandidatesCompanion(
            candidateStatus: const Value('review_required'),
            verificationSummary: const Value('Held back for user review'),
            lastModifiedAt: Value(DateTime.now()),
          ),
        );
      }
    }
  }

  Future<void> _publish(LedgerCandidate row) async {
    final now = DateTime.now();
    await _database.into(_database.transactions).insert(
          TransactionsCompanion.insert(
            localId: 'tx_${const Uuid().v4()}',
            type: row.flowType,
            amount: row.amount,
            occurredAt: row.occurredAt,
            merchantName: Value(row.merchantName),
            categoryId: Value(row.categoryId),
            accountId: Value(row.accountId),
            sourceKind: const Value('auto_ledger'),
            sourceRefId: Value(row.localId),
            reviewStatus: const Value('published'),
            locationLabel: Value(row.locationLabel),
            verificationSummary: Value(row.verificationSummary),
            createdAt: now,
            lastModifiedAt: now,
          ),
        );

    await (_database.update(_database.ledgerCandidates)
          ..where((tbl) => tbl.localId.equals(row.localId)))
        .write(
      LedgerCandidatesCompanion(
        candidateStatus: const Value('published'),
        lastModifiedAt: Value(now),
      ),
    );
  }
}
```

- [ ] **Step 4: Run verification and repository tests**

Run: `.\flutterw.bat test -r expanded test\features\auto_ledger\auto_ledger_verification_service_test.dart test\features\transactions\transaction_repository_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/auto_ledger/application/auto_ledger_verification_service.dart app/lib/features/transactions/data/transaction_repository.dart app/lib/core/database/app_database.dart app/test/features/auto_ledger/auto_ledger_verification_service_test.dart app/test/features/transactions/transaction_repository_test.dart
git commit -m "feat: verify and publish auto-ledger candidates"
```

## Task 4: Build Read-First Dashboard And Review Surfaces

**Files:**
- Create: `app/lib/features/auto_ledger/application/auto_ledger_provider.dart`
- Create: `app/lib/features/auto_ledger/presentation/review_queue_card.dart`
- Create: `app/lib/features/auto_ledger/presentation/auto_ledger_detail_sheet.dart`
- Create: `app/test/features/dashboard/auto_ledger_dashboard_test.dart`
- Modify: `app/lib/features/dashboard/presentation/dashboard_screen.dart`

- [ ] **Step 1: Write the failing dashboard test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dashboard shows auto-ledger review count and read-first summary', (tester) async {
    await tester.pumpWidget(buildDashboardWithAutoLedger(
      publishedToday: 6,
      reviewRequired: 2,
      topCategoryLabel: '식비',
      topLocationLabel: '회사 근처',
    ));

    expect(find.text('오늘 자동 반영 6건'), findsOneWidget);
    expect(find.text('검토 필요 2건'), findsOneWidget);
    expect(find.textContaining('회사 근처'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\flutterw.bat test -r expanded test\features\dashboard\auto_ledger_dashboard_test.dart`

Expected: FAIL because the dashboard does not expose auto-ledger summary or review counts yet.

- [ ] **Step 3: Add providers and update the dashboard**

```dart
// app/lib/features/auto_ledger/application/auto_ledger_provider.dart
final autoLedgerReviewCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final rows = await (db.select(db.ledgerCandidates)
        ..where((tbl) => tbl.candidateStatus.equals('review_required')))
      .get();
  return rows.length;
});

final autoLedgerPublishedTodayProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(appDatabaseProvider);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);
  final end = start.add(const Duration(days: 1));
  final rows = await (db.select(db.transactions)
        ..where((tbl) =>
            tbl.sourceKind.equals('auto_ledger') &
            tbl.occurredAt.isBiggerOrEqualValue(start) &
            tbl.occurredAt.isSmallerThanValue(end)))
      .get();
  return rows.length;
});
```

```dart
// app/lib/features/dashboard/presentation/dashboard_screen.dart
final reviewCountAsync = ref.watch(autoLedgerReviewCountProvider);
final publishedTodayAsync = ref.watch(autoLedgerPublishedTodayProvider);

// add a top summary card
Text('오늘 자동 반영 ${publishedTodayAsync.valueOrNull ?? 0}건');
Text('검토 필요 ${reviewCountAsync.valueOrNull ?? 0}건');
```

- [ ] **Step 4: Run dashboard tests**

Run: `.\flutterw.bat test -r expanded test\features\dashboard\auto_ledger_dashboard_test.dart test\features\dashboard\dashboard_screen_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/auto_ledger/application/auto_ledger_provider.dart app/lib/features/auto_ledger/presentation/review_queue_card.dart app/lib/features/auto_ledger/presentation/auto_ledger_detail_sheet.dart app/lib/features/dashboard/presentation/dashboard_screen.dart app/test/features/dashboard/auto_ledger_dashboard_test.dart app/test/features/dashboard/dashboard_screen_test.dart
git commit -m "feat: add read-first auto-ledger dashboard surfaces"
```

## Task 5: Add Trust Controls, Backup Hooks, And MVP Hardening

**Files:**
- Modify: `app/lib/features/settings/presentation/settings_screen.dart`
- Modify: `app/lib/features/settings/application/backup_service.dart`
- Modify: `app/test/features/settings/backup_service_test.dart`
- Modify: `app/test/features/settings/settings_split_test.dart`

- [ ] **Step 1: Write the failing trust and backup test**

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup export includes raw signals and ledger candidates', () async {
    final database = AppDatabase.test();
    final service = BackupService(database);

    await seedRawSignal(database, id: 'sig_1');
    await seedCandidate(database, id: 'cand_1', amount: 6300);

    final backup = await service.exportJsonString();

    expect(backup, contains('"rawTransactionSignals"'));
    expect(backup, contains('"ledgerCandidates"'));

    await database.close();
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `.\flutterw.bat test -r expanded test\features\settings\backup_service_test.dart`

Expected: FAIL because backup export does not include the new auto-ledger tables yet.

- [ ] **Step 3: Extend backup/export and settings trust UI**

```dart
// app/lib/features/settings/application/backup_service.dart
final rawSignals = await select(database.rawTransactionSignals).get();
final candidates = await select(database.ledgerCandidates).get();

return jsonEncode({
  'transactions': transactions.map(_transactionToJson).toList(),
  'rawTransactionSignals': rawSignals.map(_rawSignalToJson).toList(),
  'ledgerCandidates': candidates.map(_candidateToJson).toList(),
});
```

```dart
// app/lib/features/settings/presentation/settings_screen.dart
ListTile(
  title: const Text('자동 장부화 출처 보기'),
  subtitle: const Text('알림, 문자, 검토 대기 거래를 확인합니다.'),
  onTap: () => context.push('/notification-history'),
),
ListTile(
  title: const Text('데이터 내보내기'),
  subtitle: const Text('원문 신호와 후보 거래까지 백업합니다.'),
  onTap: () => _openBackupDialog(context),
),
```

- [ ] **Step 4: Run settings and backup tests**

Run: `.\flutterw.bat test -r expanded test\features\settings\backup_service_test.dart test\features\settings\settings_split_test.dart`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/settings/presentation/settings_screen.dart app/lib/features/settings/application/backup_service.dart app/test/features/settings/backup_service_test.dart app/test/features/settings/settings_split_test.dart
git commit -m "feat: add auto-ledger trust and backup support"
```

## Self-Review

### Spec coverage

- Auto collection foundation: covered by Task 1 and Task 2
- Automatic ledger publication with safe hold-back: covered by Task 3
- Read-first home experience: covered by Task 4
- Asset-linked published ledger: covered by Task 3 and Task 4
- Trust, backup, provenance visibility: covered by Task 5

### Placeholder scan

- No `TODO`, `TBD`, or "implement later" markers remain.
- Every task includes exact file paths and commands.
- Each task includes concrete code skeletons rather than abstract instructions.

### Type consistency

- Raw signal table name: `raw_transaction_signals`
- Candidate table name: `ledger_candidates`
- Candidate states: `pending_verification`, `review_required`, `published`
- Published transaction provenance: `sourceKind`, `sourceRefId`, `reviewStatus`, `locationLabel`, `verificationSummary`

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-14-smart-wallet-auto-ledger-mvp.md`.

Recommended execution modes:

- `Subagent-Driven`: one task per worker, review after each task, lower integration risk
- `Inline Execution`: single-session execution when tighter serial control is preferred
