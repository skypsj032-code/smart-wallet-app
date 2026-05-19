# Korean Brand Surface Alignment Result

작성일: 2026-05-19  
기능 slug: `korean-brand-surface-alignment`  
기능 크기: `medium`

- 실제 변경: Flutter 앱 타이틀, 브랜드 스플래시 기본 문구, iOS 표시 이름, 웹 title/manifest, Windows/Linux 창 제목, Windows 버전 리소스, 백업/CSV 공유 문구를 `다정가계부` 기준으로 맞췄다.
- 계획과 차이: 메인 워크트리에서 복사한 `dajeong_ledger_app.dart`는 추적 파일 구조와 맞지 않아 제거하고, 원격 기준 추적 파일인 `smart_wallet_app.dart` 쪽에 변경을 다시 반영했다.
- 검증 결과: `flutter test --no-pub test/bootstrap_settings_test.dart` 통과, `rg` 재검색으로 `Smart Wallet`, `Smart Wallet App`, `Dajeong Ledger App` 잔여 문자열을 점검했다.
- Figma 메모: 외부 Figma 파일에는 아직 `korean-brand-surface-alignment` 섹션을 직접 추가하지 못했다. 이후 `Before / After / Note`를 같은 slug로 남기면 된다.
- 다음 할 일: 내부 식별자(`smart_wallet_app`, `DajeongLedger`)와 국가별 현지화 전략은 별도 기능으로 분리한다.
