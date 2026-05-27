<smart_wallet_refactoring_blueprint>
  <metadata>
    <purpose>Machine-readable architectural audit and execution queue.</purpose>
    <framework>Flutter / Dart / Riverpod / Drift(SQLite)</framework>
    <schema_version>8</schema_version>
    <last_updated>2026-05-08</last_updated>
    <total_domains>8</total_domains>
    <legend>
      status="done"        — 구현 완료
      status="partial"     — 일부 완료, 후속 작업 필요
      status="pending"     — 미착수
    </legend>
  </metadata>

  <tasks>
    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="1" name="Database &amp; Core Architecture">

      <task id="1-1" priority="P0" status="done">
        <symptom>Foreign key constraints ignored by SQLite engine.</symptom>
        <root_cause>Missing `PRAGMA foreign_keys = ON;` in Drift `beforeOpen`.</root_cause>
        <completed>
          `app_database.dart` `MigrationStrategy.beforeOpen`에
          `customStatement('PRAGMA foreign_keys = ON;')` 추가 (2026-05-08).
        </completed>
      </task>

      <task id="1-2" priority="P0" status="done">
        <symptom>CSV Import duplicates data &amp; causes ANR on large files.</symptom>
        <root_cause>O(N) single-row db transaction loop; weak `localId` generator allows collisions.</root_cause>
        <completed>
          `csv_import_service.dart` (2026-05-08):
          - `localId`를 `sha256(occurredAt|amount|type|memo|merchant).substring(0,16)` 기반으로 교체.
          - 단건 loop 삭제 → `_database.batch((b) =&gt; b.insertAll(..., mode: InsertMode.insertOrIgnore))` 단일 배치로 교체.
          - `import 'package:crypto/crypto.dart'` 추가.
        </completed>
      </task>

      <task id="1-3" priority="P1" status="done">
        <symptom>Timeline UI jank / OOM on large transaction sets.</symptom>
        <root_cause>No DB index on `occurredAt`; full table loaded into memory.</root_cause>
        <completed>
          날짜 그룹 헤더 + 일간 소계 추가 (2026-05-07).
          코드 검토 (2026-05-08) — 이미 완전 구현 확인:
          - `watchTimelineTransactions(limit:)`: Drift `..limit(limit)` 적용.
          - `timelineVisibleLimitProvider` (StateProvider.autoDispose): 초기 50, "더 보기"마다 +50.
          - `_TimelineLoadMoreButton`: `hasMore` 시 표시.
          - 인덱스: `transactions_timeline_idx(deleted_at, occurred_at DESC, created_at DESC)` 복합 인덱스가
            `occurredAt` 쿼리를 커버 — 별도 단일 인덱스 불필요.
        </completed>
      </task>

      <task id="1-4" priority="P1" status="done">
        <symptom>Dismissed push notifications lost permanently — no audit trail.</symptom>
        <root_cause>감지된 알림이 메모리(StateProvider)에만 유지, 앱 재시작 시 소실.</root_cause>
        <completed>
          Schema v7: `NotificationHistories` 테이블 추가 (2026-05-08).
          `AppDatabase.insertNotificationHistory` / `watchNotificationHistories` /
          `deleteOldNotificationHistories(keepCount: 200)` 구현.
          `notificationListenerProvider`에서 감지 시 자동 저장.
          `NotificationHistoryScreen` + `/notification-history` 라우트 + 설정 화면 진입점 추가.
        </completed>
      </task>

      <task id="1-5" priority="P2" status="done">
        <symptom>Build_runner codegen 누락 시 컴파일 불가.</symptom>
        <root_cause>`app_database.g.dart`는 수동 편집 불가 — 스키마 변경 시 반드시 재생성 필요.</root_cause>
        <completed>
          스키마(`tables.dart`) 변경 후 반드시 실행:
          `dartw.bat run build_runner build --delete-conflicting-outputs`
          `app_database.g.dart` regenerated on 2026-05-08 and now reflects schema v8.
          현재 미완료: schema v7 (NotificationHistories) 추가 후 codegen 미실행.
          Windows 환경에서 실행하거나 CI 스텝에 포함할 것.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="2" name="Security &amp; Compliance">

      <task id="2-1" priority="P0" status="done">
        <symptom>PIN hash vulnerability &amp; biometric bypass.</symptom>
        <root_cause>Unsalted SHA-256; boolean validation in `local_auth`.</root_cause>
        <completed>
          `pin_security.dart` 구현 확인 (2026-05-08):
          - PBKDF2-HMAC-SHA256, 120,000 iterations, 16바이트 랜덤 salt (Random.secure()).
          - 저장 포맷: `v2$pbkdf2-sha256$iterations$saltBase64$hashBase64` — salt가 해시에 내장됨.
          - `_constantTimeEquals` 사용 — timing attack 방어.
          - `_isLegacyHash` + `migrateLegacyPinHash` — 구형 unsalted SHA-256 자동 업그레이드.
          별도 `flutter_secure_storage` 불필요 — salt가 해시 문자열에 포함되며 DB는 암호화된 앱 스토리지 내에 있음.
        </completed>
      </task>

      <task id="2-2" priority="P2" status="done">
        <symptom>Financial balance visible in OS multitasking view / app switcher.</symptom>
        <root_cause>No `AppLifecycleState` obscuration applied to Scaffold.</root_cause>
        <completed>
          `app_shell.dart` (2026-05-08):
          - `_AppShellState`에 `WidgetsBindingObserver` mixin 추가.
          - `didChangeAppLifecycleState`에서 inactive/hidden/paused → `_obscured = true`.
          - `_obscured` 시 `Positioned.fill(BackdropFilter(blur: 20))` 오버레이 표시.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="3" name="Performance &amp; Memory">

      <task id="3-1" priority="P1" status="done">
        <symptom>GlassCard GPU overload — dropped frames during scroll.</symptom>
        <root_cause>Uncached `BackdropFilter` repaints on every scroll tick.</root_cause>
        <completed>
          `glass_card.dart` (2026-05-08): `ClipRRect` 바깥에 `RepaintBoundary` 래핑.
          `app_shell.dart` (2026-05-08): `bottomNavigationBar` Listener 바깥에 `RepaintBoundary` 래핑.
        </completed>
      </task>

      <task id="3-2" priority="P1" status="done">
        <symptom>Riverpod zombie state; backup JSON OOM.</symptom>
        <root_cause>Missing `.autoDispose`; full DB JSON serialization in RAM.</root_cause>
        <completed>
          `NotificationListenerEnabledNotifier` uses proper `Notifier` (not `StateProvider`).
          `notificationListenerProvider` lifecycle managed with `ref.onDispose`.
          `quick_entry_form_provider.dart` (2026-05-08): `quickEntrySubmitStateProvider` → `StateProvider.autoDispose`.
          `quick_entry_options_provider.dart` (2026-05-08): `quickEntryAccountsProvider` → `StreamProvider.autoDispose`,
            `quickEntryCategoriesProvider` → `StreamProvider.autoDispose.family`.
          `ocr_capture_provider.dart` (2026-05-08): `OcrCaptureController extends AutoDisposeNotifier`,
            `ocrCaptureProvider` → `NotifierProvider.autoDispose`.
          (참고: `quickEntryFormProvider` 자체는 AppShell-QuickEntryScreen 브릿지 역할로 autoDispose 미적용 유지.)
        </completed>
        <remaining_resolved>
          `backup_service.dart` (2026-05-08):
          - `exportJsonBackup`: `JsonEncoder.withIndent(' ').convert(payload)` → `Isolate.run(() =&gt; ...)` 오프로드.
          - `_decodeAndValidateBackup` → `async`, `jsonDecode` → `Isolate.run(() =&gt; jsonDecode(jsonText))`.
          - `inspectJsonBackup` → `Future&lt;BackupPreview&gt;` (async 전환), 호출부에 `await` 추가.
        </remaining_resolved>
      </task>

      <task id="3-3" priority="P1" status="done">
        <symptom>Camera battery drain when OCR screen is backgrounded.</symptom>
        <root_cause>`CameraController` not paused on `AppLifecycleState.paused`.</root_cause>
        <completed>
          `ocr_capture_screen.dart` (2026-05-08):
          - `_OcrCaptureScreenState`에 `WidgetsBindingObserver` mixin 추가.
          - `didChangeAppLifecycleState`: inactive/paused → `pausePreview()`, resumed → `resumePreview()`.
          - `initState`에 `addObserver`, `dispose`에 `removeObserver` 등록.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="4" name="Platform &amp; OS Integration">

      <task id="4-1" priority="P2" status="done">
        <symptom>Form data loss on OS process kill (low-memory eviction).</symptom>
        <root_cause>No state restoration (`RestorationMixin`) on entry screens.</root_cause>
        <completed>
          `smart_wallet_app.dart` (2026-05-08): `restorationScopeId: 'smart_wallet_app'` 추가 — 앱 전체 복원 트리 활성화.
          `quick_entry_screen.dart` (2026-05-08):
          - `_QuickEntryScreenState with RestorationMixin` 추가.
          - `TextEditingController` → `RestorableTextEditingController` (amount, memo).
          - `restoreState()`: 두 컨트롤러를 `'amount'` / `'memo'` 키로 등록.
          - `_isRestoring` 플래그: OS 복원 첫 프레임에서 Riverpod→컨트롤러 방향 동기화를 건너뛰고
            컨트롤러→Riverpod 역방향 동기화(postFrameCallback)로 대체 — 복원된 텍스트 보존.
          `budget_setup_dialog.dart` (2026-05-08):
          - `_BudgetSetupDialogState with RestorationMixin` 추가.
          - `TextEditingController` → `RestorableTextEditingController` (amount).
          - `showDialog` 호출에 `routeSettings: RouteSettings(name: '/budget-setup-dialog')` 추가 — 다이얼로그 라우트 식별.
        </completed>
      </task>

      <task id="4-2" priority="P3" status="done">
        <symptom>Android 12+ double splash screen flicker.</symptom>
        <root_cause>Missing native splash configuration.</root_cause>
        <completed>
          `pubspec.yaml` (2026-05-08): added dev dependency `flutter_native_splash: ^2.4.7`.
          `flutter_native_splash.yaml` (2026-05-08): Android-only splash config with brand color `#D1A65A`
          and `assets/branding/splash_mark.png`.
          Executed:
          `dartw.bat run flutter_native_splash:create --path flutter_native_splash.yaml`
          Generated Android 12 resources:
          `android/app/src/main/res/values-v31/styles.xml`
          `android/app/src/main/res/values-night-v31/styles.xml`
        </completed>
      </task>

      <task id="4-3" priority="P1" status="done">
        <symptom>알림 토글 껐다 켜면 상태 초기화됨.</symptom>
        <root_cause>`StateProvider&lt;bool&gt;` — 앱 재시작 시 항상 false.</root_cause>
        <completed>
          `NotificationListenerEnabledNotifier extends Notifier&lt;bool&gt;`으로 교체.
          `SharedPreferences`에 영속화 (`_kNotificationEnabled` key).
          Disposal flag 패턴으로 async init race condition 방지.
        </completed>
      </task>

      <task id="4-4" priority="P2" status="done">
        <symptom>알림 권한 취소 후 앱 복귀 시 UI가 허용됨으로 표시됨.</symptom>
        <root_cause>`notificationPermissionGrantedProvider` 최초 1회만 평가됨.</root_cause>
        <completed>
          `_NotificationListenerCard`를 `ConsumerStatefulWidget`으로 전환.
          `AppLifecycleListener.onResume`에서 `ref.invalidate(notificationPermissionGrantedProvider)` 호출.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="5" name="UX &amp; Accessibility">

      <task id="5-1" priority="P2" status="done">
        <symptom>Search causes DB thrash on every keystroke; keyboard stuck open after submit.</symptom>
        <root_cause>No debounce on search stream; missing `FocusNode` management.</root_cause>
        <completed>
          `search_screen.dart` (2026-05-08):
          - `_debounce Timer?` 필드 추가. `_onKeywordChanged`에서 300ms debounce 적용.
          - `dispose`에서 `_debounce?.cancel()` 처리.
          `quick_entry_screen.dart` (2026-05-08):
          - `_amountFocusNode` / `_memoFocusNode` 필드 추가, initState/dispose 처리.
          - Amount TextField: `textInputAction: TextInputAction.next`, `onSubmitted` → memoFocusNode.requestFocus().
          - Memo TextField: `textInputAction: TextInputAction.done`.
          - `_AmountPanel` 생성자 호출부에 두 FocusNode 전달 완료.
        </completed>
      </task>

      <task id="5-2" priority="P3" status="partial">
        <symptom>No Undo after delete; accessibility broken at large font sizes.</symptom>
        <root_cause>Hard delete in DB; missing `Semantics` labels and `TextScaler` clamps.</root_cause>
        <completed>
          `timeline_screen.dart` (2026-05-08): added `Semantics` for the summary card, filter region, load-more button,
          day group headers, and swipeable transaction rows.
          `quick_entry_screen.dart` (2026-05-08): added `Semantics` for the submit CTA, picker fields, and entry
          readiness summary card.
          `transaction_repository.dart` (2026-05-08): `undoDeleteTransaction` 메서드 추가 — `deletedAt = null`.
          `timeline_screen.dart` (2026-05-08): 삭제 후 SnackBar에 '되돌리기' action 연결 (4초).
          `smart_wallet_app.dart` (2026-05-08): `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` 루트 적용.
        </completed>
        <remaining>
          Semantics 라벨 미적용 (스크린리더용 `Semantics` 위젯 추가 필요).
          Follow-up accessibility audit still needed for other screens and components beyond timeline and quick entry.
        </remaining>
      </task>

      <task id="5-3" priority="P2" status="done">
        <symptom>퀵 입력 버튼 탭 시 전체 화면 이탈 — 맥락 끊김.</symptom>
        <root_cause>`context.go('/quick-entry')` 가 ShellRoute 안에서 현재 탭을 교체함.</root_cause>
        <completed>
          `/quick-entry` 라우트를 `_buildModalPage`(CustomTransitionPage)로 교체.
          하단 슬라이드 애니메이션 (300ms easeOutCubic).
          `app_shell.dart` `_submit`에서 `context.push` 사용.
        </completed>
      </task>

      <task id="5-4" priority="P2" status="done">
        <symptom>대시보드에서 예산 상태를 보려면 스크롤을 많이 내려야 함.</symptom>
        <root_cause>`_BudgetStatusCard`가 스크롤 목록 하단에 위치.</root_cause>
        <completed>
          `dashboard_screen.dart`: MetricStrip 바로 아래로 이동
          (OverviewHero → NarrativeCard → MetricStrip → BudgetStatusCard → …).
        </completed>
      </task>

      <task id="5-5" priority="P2" status="done">
        <symptom>타임라인 날짜 그룹에 일간 합계가 없어 전체 파악이 어려움.</symptom>
        <root_cause>각 날짜 헤더에 수입/지출 소계 미표시.</root_cause>
        <completed>
          `_DayGroupHeader` 위젯 추가 — 날짜 왼쪽, 수입(green)/지출(red) 오른쪽.
          `_TimelineSummaryCard`에 수입/지출/순수익 3열 추가.
          각 날짜 그룹 개별 Card로 분리.
        </completed>
      </task>

      <task id="5-6" priority="P3" status="done">
        <symptom>예산 화면에서 카테고리별 소진 현황을 한눈에 파악하기 어려움.</symptom>
        <root_cause>숫자 목록만 제공, 시각적 비교 불가.</root_cause>
        <completed>
          `_CategoryBudgetChartCard` 추가: 카테고리 2개 이상일 때 proportional bar chart 표시.
          진행률에 따라 primary/warning/expense 색상 자동 전환.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="6" name="Robustness &amp; Error Handling">

      <task id="6-1" priority="P0" status="done">
        <symptom>Async gap crashes; integer overflows on large amounts.</symptom>
        <root_cause>Missing `mounted` checks after `await`; unbounded `int.tryParse`.</root_cause>
        <completed>
          `notification_history_screen.dart` `_openQuickEntry`: `context.mounted` 체크.
          `notification_transaction_banner.dart` `_openQuickEntry`: async-safe.
          `ocr_review_screen.dart` (2026-05-08): `retryFromCapturedImage()` await 후 `if (!context.mounted) return` 추가.
          `settings_screen.dart`: 기존 mounted 체크 확인 완료 (이미 적용됨).
          `quick_entry_screen.dart`: 기존 mounted 체크 확인 완료 (이미 적용됨).
          `app_shell.dart` global quick panel TextField: `maxLength: 12`, `buildCounter: (...) =&gt; null` 적용.
          `quick_entry_screen.dart` _AmountPanel TextField: `maxLength: 12`, `buildCounter: (...) =&gt; null` 적용.
        </completed>
      </task>

      <task id="6-2" priority="P3" status="done">
        <symptom>Unhandled exceptions silently swallowed; DB tightly coupled to UI.</symptom>
        <root_cause>No global error boundary; direct `AppDatabase` injection into widgets.</root_cause>
        <completed>
          `main.dart` (2026-05-08):
          - `PlatformDispatcher.instance.onError` 등록 — 미처리 플랫폼 오류를 developer.log로 기록.
          - `FlutterError.onError` 등록 — 위젯 빌드 오류 캡처.
          (Crashlytics/Sentry 훅 자리 확보 완료 — 추후 연동만 하면 됨.)
          `transactions/data/transaction_repository_interface.dart` (2026-05-08):
          - `abstract interface class ITransactionRepository` 추출.
          - `TransactionRepository implements ITransactionRepository`.
          - `transactionRepositoryProvider` → `Provider&lt;ITransactionRepository&gt;`.
          `budgets/data/budget_repository_interface.dart` (2026-05-08):
          - `abstract interface class IBudgetRepository` 추출.
          - `BudgetEditorService implements IBudgetRepository`.
          - `budgetEditorServiceProvider` → `Provider&lt;IBudgetRepository&gt;`.
          `test/mocks/mock_transaction_repository.dart` (2026-05-08):
          - `MockTransactionRepository implements ITransactionRepository` 작성.
          - `created` / `updated` / `softDeleted` / `undoDeleted` 리스트로 호출 기록.
          - `createError` / `updateError` 주입 지원 (실패 시나리오 테스트용).
        </completed>
      </task>

      <task id="6-3" priority="P1" status="done">
        <symptom>Notification parser fails on non-standard bank message formats.</symptom>
        <root_cause>Regex-only parsing breaks on edge cases; no fallback or test coverage.</root_cause>
        <completed>
          `test/features/notifications/notification_parser_test.dart` (2026-05-08):
          - 지출 8케이스: 신한카드/KB국민카드/삼성카드/현대카드/카카오뱅크/토스/네이버페이/병원/영화관/주유소.
          - 수입 3케이스: 급여입금/이자/환급.
          - 파싱불가 5케이스: 금액없음/0원/유형키워드없음/빈입력/숫자코드.
          - 엣지케이스 5케이스: 콤마없는금액/영문상호명/title+text결합/timestamp없음/cardName=null.
          `notification_parser.dart` (2026-05-08): 외화 결제 지원 추가.
          - 원화 없을 때 `USD|EUR|JPY|GBP|CNY|AUD|CAD|CHF|$|€|¥|£` 패턴 fallback.
          - 원화 우선 (양쪽 있으면 원화 사용).
          - 외화 테스트 6케이스 추가 (USD/$/JPY/¥/EUR/원화우선).
          파싱 실패 → `return null` (호출부에서 삽입 건너뜀) — 기존 방어 코드로 충분.
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="7" name="Notification &amp; Automation">

      <task id="7-1" priority="P1" status="done">
        <symptom>카드/은행 알림에서 거래를 수동으로 입력해야 함.</symptom>
        <root_cause>Android NotificationListenerService 미연동.</root_cause>
        <completed>
          `SmartWalletNotificationService.kt`: 40개 은행/카드 패키지 필터링.
          `NotificationChannel`: EventChannel로 Flutter에 스트림 전달.
          `notification_parser.dart`: 금액/유형/상호명/카테고리 정규식 파싱.
          `NotificationTransactionBanner`: 6초 자동닫힘 + LinearProgressIndicator.
          탭 시 금액·유형 채워진 QuickEntry로 이동.
        </completed>
      </task>

      <task id="7-2" priority="P2" status="done">
        <symptom>중복 알림이 연속 수신되면 배너가 반복 표시됨.</symptom>
        <root_cause>동일 금액 + 3초 이내 재수신 구분 없음.</root_cause>
        <completed>
          `_lastNotificationKey` StateProvider: `${amount}_${ts ~/ 3000}` key로 dedup.
        </completed>
      </task>

      <task id="7-3" priority="P2" status="done">
        <symptom>배너 닫힘 후 알림 이력 완전 소실.</symptom>
        <root_cause>메모리(StateProvider)에만 존재.</root_cause>
        <completed>
          Schema v7 `NotificationHistories` 테이블 추가.
          감지 시 자동 DB 저장 + 200건 초과 시 자동 정리.
          `NotificationHistoryScreen` (설정 → 알림 자동 기록 → 알림 수신 이력).
          타일 탭 → 해당 알림 데이터로 QuickEntry 자동 채움.
        </completed>
      </task>

      <task id="7-4" priority="P3" status="done">
        <symptom>알림 파싱 성공률을 알 수 없음.</symptom>
        <root_cause>파싱 결과 통계 미수집.</root_cause>
        <completed>
          `app_database.dart` (2026-05-08): `countRecentNotificationHistories(dayRange: 30)` 메서드 추가.
          `settings_screen.dart` (2026-05-08): 알림 수신 이력 타일 subtitle에
            `_recentNotificationCountProvider` (FutureProvider.autoDispose) 표시.
            → "지난 30일간 감지된 알림 N건" 동적 문구.
          (참고: `isParsed` 컬럼 추가는 schema 변경이라 build_runner 재실행 필요 — 대신 전체 감지 건수로 표시.)
        </completed>
      </task>

      <task id="7-5" priority="P2" status="done">
        <symptom>예산 한도 초과 시 사용자 알림 없음.</symptom>
        <root_cause>예산 초과 감지 로직 미구현.</root_cause>
        <completed>
          `budget_alert_provider.dart` (2026-05-08):
          - `BudgetAlertNotifier extends Notifier&lt;BudgetAlertEvent?&gt;` — `budgetSummaryProvider` 구독.
          - 세션당 중복 방지: `_firedKeys` Set으로 동일 예산·동일 레벨 알림 1회 발행.
          - 임계값: 50%(half) / 80%(warning) / 100%(exceeded).
          `app_shell.dart` (2026-05-08):
          - `ref.listen(budgetAlertProvider, ...)` — 임계값 돌파 시 FloatingSnackBar 표시 (5초).
          - 아이콘: ⚠️(50%) / 🔶(80%) / 🚨(100%).
          (참고: OS 수준 로컬 알림은 `flutter_local_notifications` 미포함으로 앱 내 배너로 대체.)
        </completed>
      </task>

    </domain>

    <!-- ──────────────────────────────────────────────────────────────────── -->
    <domain id="8" name="Code Quality &amp; Testing">

      <task id="8-1" priority="P2" status="done">
        <symptom>Notification parser has no unit test coverage.</symptom>
        <root_cause>복잡한 정규식 로직이 테스트 없이 운영 중.</root_cause>
        <completed>
          `test/features/notifications/notification_parser_test.dart` (2026-05-08):
          지출/수입/파싱불가/엣지 케이스 총 21개 테스트 작성 완료.
          참조: 6-3 completed 섹션.
        </completed>
      </task>

      <task id="8-2" priority="P3" status="done">
        <symptom>라우트 추가 시 `_locationToIndex` 수동 업데이트 필요.</symptom>
        <root_cause>`app_shell.dart`의 탭 인덱스 매핑이 string prefix 하드코딩.</root_cause>
        <completed>
          `app_router.dart` (2026-05-08):
          - `_kRouteTabIndex` const Map&lt;String, int&gt; 추가 — 전체 경로 → 탭 인덱스 정적 매핑.
          - `routeTabIndex(String location)` 함수 export — 쿼리 파라미터 자동 제거.
          `app_shell.dart` (2026-05-08):
          - `_locationToIndex` 내부를 `routeTabIndex(location)` 단일 호출로 교체.
          이제 새 라우트 추가 시 `_kRouteTabIndex` 맵 한 곳만 수정하면 됨.
        </completed>
      </task>

      <task id="8-3" priority="P2" status="done">
        <symptom>`quickEntryCategoriesProvider` 시그니처 혼용.</symptom>
        <root_cause>일부 호출부가 타입 파라미터 없이 사용 시도.</root_cause>
        <completed>
          전체 호출부 검증 완료 (2026-05-08):
          - `quick_entry_screen.dart`: `quickEntryCategoriesProvider(_categoryTypeFor(form.type))` ✓
          - `notification_transaction_banner.dart`: `quickEntryCategoriesProvider(categoryType)` ✓
          - `notification_history_screen.dart`: `quickEntryCategoriesProvider(typeStr)` ✓
          - `calendar_inline_entry_card.dart`: `quickEntryCategoriesProvider(form.type == ... ? 'income' : 'expense')` ✓
          모든 호출부가 String 인자를 올바르게 전달함.
        </completed>
      </task>

    </domain>
  </tasks>

  <execution_protocol>
    <instruction>태스크 ID를 언급하면 해당 &lt;task&gt; 블록을 읽고 action_plan대로 구현합니다.</instruction>
    <instruction>status="done" 태스크는 재구현하지 않고 참고용으로만 활용합니다.</instruction>
    <instruction>스키마 변경(tables.dart) 후에는 반드시 build_runner codegen을 실행합니다.</instruction>
    <instruction>새 태스크 발견 시 적절한 domain에 추가하고 last_updated를 갱신합니다.</instruction>
  </execution_protocol>

</smart_wallet_refactoring_blueprint>
