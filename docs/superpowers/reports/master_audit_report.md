# 🚀 Smart Wallet 마스터 오딧 리포트 (Phase 1 ~ 5 종합)

**"보이는 버그를 잡는 것은 아마추어지만, 보이지 않는 아키텍처의 붕괴를 막는 것은 마스터의 영역입니다."**

본 리포트는 Smart Wallet 앱이 프로덕션(실무) 환경에서 직면할 수 있는 상태 관리, 동시성, 렌더링, OS 생명주기, 보안 관점의 치명적 잠복 결함 15가지를 총망라한 딥 다이브 정밀 스캔 결과입니다.

---

## 📌 현재 집행 현황 (2026-05-08)

### 커밋까지 완료된 작업
*   **Phase 1 / Task 1~3 완료:** `65b7ef0`, `53999df`
*   **Phase 2 / Task 4~6 완료:** `41bf720`
*   **Phase 3 / Task 7~9 완료:** `0b83b5c`

### 작업 트리에 반영되었지만 아직 커밋되지 않은 작업
*   **Task 11:** `AndroidManifest.xml` 권한 추가 + 설정 화면에서 배터리 최적화 예외 유도 UX 반영
*   **Task 12:** `settings_screen.dart`에 iOS 안내 Fallback UI 추가
*   **Task 13:** `backup_service.dart`에 기존 파일 보존형 원자적 교체 저장 반영
*   **Task 14:** `AndroidManifest.xml`에 `allowBackup="false"`, `fullBackupContent="false"` 반영
*   **Task 15:** `ocr_capture_provider.dart` 종료/리셋 시 OCR 임시 파일 삭제 반영

### 아직 남은 핵심 작업
*   **Task 10 미착수:** 네이티브 알림 Queue/Headless 처리
*   **Task 14 잔여:** 로컬 JSON 백업 암호화(AES 계열) 미구현
*   **Task 15 잔여:** 프로젝트 전역 `catch (_)` 정리와 Crashlytics 연동은 아직 남음

---

## 🌊 Phase 1: Riverpod 상태 관리 심연 (State Management Audit)

앱을 오래 켜둘수록 폰이 느려지고 데이터가 꼬이는 아키텍처 수준의 버그입니다.

### 1. 전역 폼(Form) 좀비 상태화 (Memory Leak & State Contamination) ✅ 커밋 완료
*   **문제 파일:** `quick_entry_form_provider.dart`, `calendar_inline_entry_controller.dart`
*   **문제 현상:** 사용자가 50,000원을 입력하다 화면을 끄고 나간 뒤, 한참 뒤에 다시 화면을 켜도 50,000원이 그대로 남아있으며 폼 객체가 앱을 강제 종료할 때까지 메모리(RAM)를 갉아먹습니다.
*   **원인:** 상태를 관리하는 `QuickEntryFormController`와 `CalendarInlineEntryController`가 `AutoDisposeNotifier`가 아닌 일반 `Notifier`를 상속받고 있습니다.
*   **해결책:** `NotifierProvider.autoDispose`로 변경하여 화면 파괴 시 GC가 폼 데이터를 메모리에서 즉시 해제하도록 수정해야 합니다.

### 2. Riverpod 1급 발암 물질 (`ref.watch` 콜백 오용) ✅ 커밋 완료
*   **문제 파일:** `calendar_inline_entry_controller.dart` (L172)
*   **문제 현상:** 캘린더 화면에서 날짜를 바꿀 때마다 구독 트리가 꼬이며, 최악의 경우 앱이 크래시되거나 무한 렌더링 루프에 빠질 수 있습니다.
*   **원인:** `_selectedDate()` 라는 일반 콜백 메서드 내부에서 `ref.watch(selectedCalendarDateProvider)`를 호출하고 있습니다. (일반 메서드에서 watch 사용 불가).
*   **해결책:** `_selectedDate()` 내부의 `ref.watch`를 전부 `ref.read`로 치환해야 합니다.

### 3. UI 객체(`WidgetRef`)의 도메인 레이어 침범 (Spaghetti Coupling) ✅ 커밋 완료
*   **문제 파일:** `timeline_provider.dart` (L44, L50)
*   **원인:** `loadMoreTimelineItems(WidgetRef ref)` 처럼 글로벌 함수에 플러터 UI 객체인 `WidgetRef`를 매개변수로 던지고 있어 UI와 비즈니스 로직이 강하게 결합됩니다.
*   **해결책:** `TimelineController extends AutoDisposeNotifier` 클래스를 새로 만들어 캡슐화해야 합니다.

---

## 💾 Phase 2: Drift SQLite & 데이터 동시성 (Concurrency Audit)

데이터가 수천 건 단위로 쌓이거나 백그라운드 로직이 겹치는 순간 앱이 영구적으로 멈추는 시한폭탄입니다.

### 4. `for` 루프 단건 Insert에 의한 I/O 폭발 (Bulk Insert Loop of Death) ✅ 커밋 완료
*   **문제 파일:** `backup_service.dart` (L197 ~ L212)
*   **문제 현상:** 5년 치 가계부를 JSON 백업으로 복원할 때, 폰이 엄청나게 뜨거워지며 1~2분 이상 앱이 완전히 굳어버립니다(ANR).
*   **원인:** `for (final raw in ...)` 루프를 돌며 `insert`를 수천 번 개별 호출하여 매번 디스크 I/O를 발생시킵니다.
*   **해결책:** `await _database.batch((batch) => batch.insertAll(...))` 구문으로 단 1번의 Transaction에 처리해야 합니다.

### 5. 비결정론적 Primary Key 붕괴 (동시성 충돌) ✅ 커밋 완료
*   **문제 파일:** `transaction_repository.dart` (L71), `recurring_expense_service.dart` (L140)
*   **문제 현상:** 정기 지출이 여러 개 동시 생성되거나 연속 클릭 시 Primary Key 중복 위반 크래시가 발생합니다.
*   **원인:** 고유 식별자(`localId`)를 `tx_${now.microsecondsSinceEpoch}`로 하드코딩해서 생성 중입니다.
*   **해결책:** 시간 의존형 ID 생성을 버리고 `uuid.v4()` 패키지로 전면 교체해야 합니다.

### 6. 동시성 락(Lock) 마비 (WAL 모드 누락) ✅ 커밋 완료
*   **문제 파일:** `app_database.dart` (L34)
*   **원인:** `PRAGMA journal_mode=WAL;` (Write-Ahead Logging) 셋팅이 누락되어, 유저가 스크롤(Read)하는 동시에 백그라운드 작업(Write)이 돌면 DB 락이 걸리며 크래시가 발생합니다.
*   **해결책:** SQLite 연결 직후 해당 PRAGMA를 주입하여 락 컨텐션을 해소해야 합니다.

---

## ⚡ Phase 3: 플러터 엔진 & 렌더링 최적화 (Rendering Audit)

보이지 않는 곳에서 배터리를 갉아먹고, 레이아웃 화면을 파괴하는 주범입니다.

### 7. 배터리 광탈 60FPS 무한 루프 애니메이션 (Infinite CPU/GPU Drain) ✅ 커밋 완료
*   **문제 파일:** `app_frame.dart` (L27)
*   **문제 현상:** 앱이 홈 화면 뒤에 가려져 백그라운드에 있는 상태에서도 배터리가 줄줄 샙니다.
*   **원인:** `_AtmospherePainter`를 렌더링하는 `_controller`가 앱 라이프사이클과 무관하게 `..repeat()`으로 무한 반복되고 있습니다.
*   **해결책:** `WidgetsBindingObserver`를 연동하여 `AppLifecycleState.paused` 시점에 `_controller.stop()`을 호출해야 합니다.

### 8. 시각 접근성 무방비에 의한 레이아웃 파괴 (Unbounded Text Scaling) ✅ 커밋 완료
*   **문제 파일:** `main.dart` 또는 `app_shell.dart` (설정 누락)
*   **문제 현상:** 기기 시스템 설정에서 글자 크기를 최대로 키우면 GlassCard 등의 UI가 산산조각 납니다.
*   **원인:** 폰트 스케일링을 제어하는 `TextScaler.clamp` 로직이 앱 전체에 단 하나도 없습니다.
*   **해결책:** `MaterialApp` 최상단에서 최대 폰트 배율을 `TextScaler.linear().clamp(minScaleFactor: 1.0, maxScaleFactor: 1.2)`로 제한해야 합니다.

### 9. 무한 연쇄 블러(Blur) 오버드로우 (Exponential GPU Overdraw) ✅ 커밋 완료
*   **문제 파일:** `app_shell.dart` (L168)
*   **원인:** 멀티태스킹 뷰 진입 시 `BackdropFilter`를 씌우는데, 밑바탕 배경이 무한 애니메이션 중이라 매 프레임마다 블러 연산을 처음부터 재계산합니다.
*   **해결책:** 화면이 가려질 때 렌더링을 중단시키는 `Offstage` 또는 정적 이미지 스냅샷 방식을 도입해야 합니다.

---

## 🤖 Phase 4: 네이티브 OS 생명주기 (Native Background Audit)

운영체제가 강제로 앱의 숨통을 끊거나 기능을 무력화시키는 네이티브 결함입니다.

### 10. 백그라운드 알림 영구 유실 (The EventSink Black Hole) ❌ 미착수
*   **문제 파일:** `SmartWalletNotificationService.kt` (L76)
*   **문제 현상:** 앱이 백그라운드 상태일 때 수신된 결제 내역 알림이 가계부에 등록되지 않고 영원히 사라집니다.
*   **원인:** `val sink = eventSink ?: return` 구문 때문에, 플러터 엔진이 멈춰 싱크가 닫혀 있으면 알림을 버립니다.
*   **해결책:** 네이티브(Kotlin) 단에 Room DB 큐(Queue)를 구축해 데이터를 쌓아두고 앱이 켜질 때 일괄 방출해야 합니다.

### 11. 배터리 최적화 강제 종료 (Aggressive Doze Mode Kill) ✅ 구현 완료
*   **문제 파일:** `AndroidManifest.xml`
*   **원인:** `<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />` 누락으로 인해, 며칠 뒤 OS가 알림 서비스를 강제로 영원히 죽여버립니다.
*   **해결책:** 매니페스트에 해당 권한을 추가하고, 유저를 배터리 최적화 예외 설정 화면으로 유도해야 합니다.
*   **현재 상태:** 권한 선언과 설정 화면 유도 버튼, 상태 확인용 네이티브 채널까지 반영되었습니다.

### 12. iOS 유저 사각지대 및 방어 로직 부재 (Platform Discrepancy) ✅ 구현 완료
*   **문제 파일:** `notification_channel.dart`, `settings_screen.dart`
*   **원인:** 애플은 시스템 알림 읽기를 차단하나, iOS 유저를 위한 안내 화면이나 플랫폼 예외 처리 분기 로직(`if (Platform.isIOS)`)이 없습니다.
*   **해결책:** 플랫폼 분기를 추가해 iOS 유저에게 알맞은 수동 입력 가이드 화면(Fallback UI)을 제공해야 합니다.
*   **현재 상태:** `settings_screen.dart`에 iOS 전용 안내 카드가 추가되어 자동 감지 미지원 사실과 대체 입력 경로를 명시합니다.

---

## 🛡️ Phase 5: 보안 무결성 & 파일 I/O (Security & I/O Audit)

데이터 파괴 및 보안 정보 유출을 유발하는 가장 치명적인 잠재 리스크입니다.

### 13. 백업 파일 오염 (I/O Atomicity / 원자적 쓰기 누락) ✅ 구현 완료
*   **문제 파일:** `backup_service.dart` (L140)
*   **문제 현상:** 백업 JSON을 쓰는 도중 배터리가 방전되면 기존 백업 파일마저 0바이트로 깡통이 됩니다.
*   **원인:** `file.writeAsString`을 통해 원본 파일에 덮어쓰기 방식으로 직접 I/O를 실행하고 있습니다.
*   **해결책:** 임시 파일(`.tmp`)에 전체 데이터를 쓰고 난 뒤 안전하게 `rename`하는 원자적 저장 처리가 필요합니다.
*   **현재 상태:** `.tmp` 저장 후 기존 파일을 `.bak`으로 대피시켜 교체 실패 시 복구하는 보존형 교체 로직과 테스트가 반영되었습니다.

### 14. 금융 데이터 평문 자동 유출 (Unencrypted Auto-Backup Leak) 🟡 부분 반영
*   **문제 파일:** `AndroidManifest.xml`
*   **원인:** `<application>` 태그에 `android:allowBackup="false"`가 없어, 평문 상태의 민감한 결제 내역 파일들이 구글 드라이브 클라우드로 무단 무차별 자동 백업됩니다.
*   **해결책:** 매니페스트에 `allowBackup="false"`를 선언하고, 로컬 JSON 백업 기능에도 자체 암호화(AES-256 등)를 도입해야 합니다.
*   **현재 상태:** `allowBackup="false"`와 `fullBackupContent="false"`는 작업 트리에 반영되었습니다. 하지만 백업 파일 자체 암호화는 아직 미구현입니다.

### 15. 고해상도 영수증 및 스택트레이스 무한 누수 (Cache/Log Bloat) 🟡 부분 반영
*   **문제 파일:** `ocr_service.dart`, `app_database.dart`
*   **원인:** OCR 처리 후 `captureReceipt()`가 생성한 수십 MB 단위의 영수증 원본 사진 파일을 절대 삭제하지 않습니다. 또한, 시스템 곳곳의 `catch (_)` 블록이 `StackTrace`를 먹어버려 Crashlytics 로그 추적이 불가능합니다.
*   **해결책:** 임시 이미지 `File.delete()` 강제 호출 로직을 추가하고, 모든 예외 처리 블록에 `catch (error, stackTrace)`를 명시해야 합니다.
*   **현재 상태:** OCR 캡처 Provider의 `reset()` 및 `dispose` 경로에서 임시 이미지 삭제가 적용되었고, `ocr_service.dart`, `notification_channel.dart`, `app_database.dart`의 일부 swallow catch는 스택트레이스 로깅으로 전환되었습니다.

---

## 🎯 다음 집도 우선순위

1. `Task 10` 네이티브 알림 유실 방지 큐 설계 및 구현
2. `Task 14` 로컬 JSON 백업 암호화 설계 및 구현
3. `Task 15` 프로젝트 전역 swallow catch 정리와 Crashlytics 연동
4. Phase 4/5 변경의 디바이스 실기 검증
