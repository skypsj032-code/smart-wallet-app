# Korean Brand Surface Alignment Spec

작성일: 2026-05-19  
기능 slug: `korean-brand-surface-alignment`  
기능 크기: `medium`

- 왜: 한국 1차 출시 기준으로 사용자에게 보이는 앱 이름이 `Smart Wallet`, `Smart Wallet App`, `Dajeong Ledger`로 섞여 있어 브랜드 인지가 흔들린다.
- 사용자 변화: 사용자는 앱 실행, 오류 상태, 백업/내보내기 공유 문구, 웹/데스크톱 메타데이터에서 제품 이름을 일관되게 `다정가계부`로 보게 된다.
- 범위: Flutter 앱 타이틀, 브랜드 스플래시 기본 문구, iOS 표시 이름, 웹 title/manifest, Windows/Linux 창 제목, Windows 버전 리소스, 백업/CSV 공유 문구를 정리한다.
- 비범위: 패키지명 `smart_wallet_app`, 파일 경로, Dart 클래스명, 앱 내부 식별자, 백업 파일명 slug, 번들 식별자는 이번에 바꾸지 않는다.
- 리스크: 사용자 노출 문자열과 내부 식별자를 구분하지 않으면 빌드/의존 경로까지 흔들릴 수 있으므로, 이번 기능은 노출면만 바꾼다.
- 관련 Figma: `korean-brand-surface-alignment` 섹션에 `Before / After / Note`를 남긴다.
