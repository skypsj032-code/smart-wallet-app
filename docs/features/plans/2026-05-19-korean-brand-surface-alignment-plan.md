# Korean Brand Surface Alignment Plan

작성일: 2026-05-19  
기능 slug: `korean-brand-surface-alignment`  
기능 크기: `medium`

- 바꿀 파일: `lib/app/smart_wallet_app.dart`, `lib/shared/widgets/brand_splash_screen.dart`, `test/bootstrap_settings_test.dart`
- 바꿀 파일: `ios/Runner/Info.plist`, `web/index.html`, `web/manifest.json`
- 바꿀 파일: `windows/runner/main.cpp`, `windows/runner/Runner.rc`, `linux/runner/my_application.cc`
- 바꿀 파일: `lib/features/settings/application/backup_service.dart`, `lib/features/settings/presentation/settings_screen.dart`, `lib/features/transactions/data/transaction_export_service.dart`
- 유지할 것: `smart_wallet_app` 패키지명, `SmartWalletApp` 클래스명, `DajeongLedger` 번들/내부 식별자, 파일명 및 경로
- 단계 1: 루트 `MaterialApp` 타이틀과 브랜드 스플래시 기본 문구를 `다정가계부`로 통일한다.
- 단계 2: 부트스트랩 테스트를 현재 추적 파일 구조(`smart_wallet_app.dart`) 기준으로 정리하고, 앱 타이틀과 스플래시 텍스트를 검증한다.
- 단계 3: iOS/web/desktop에서 실제 표시되는 이름과 메타데이터를 `다정가계부`로 맞춘다.
- 단계 4: 백업/복원/CSV 공유 문구에서 남아 있는 `Smart Wallet` 브랜드 문자열을 `다정가계부`로 교체한다.
- 확인 방법: `flutter test --no-pub test/bootstrap_settings_test.dart`가 통과하는지 확인하고, `rg -n -S "Smart Wallet|Smart Wallet App|Dajeong Ledger App" lib ios web windows linux test` 재검색으로 잔여 노출 문자열을 점검한다.
