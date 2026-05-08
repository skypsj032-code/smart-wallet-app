# 거래 수정 종료 플로우와 뒤로가기 재검증

## 변경 배경

거래 수정 화면에 설명 문구와 하단 저장 버튼이 동시에 붙어 있어서 흐름이 과했습니다.  
또, 편집 중 뒤로가기를 눌렀을 때 저장 여부를 묻는 분기가 필요했고, 전역 뒤로가기 규칙도 다시 확인할 필요가 있었습니다.

## 이번 변경

- 거래 수정 화면 hero 문구를 `거래 수정`으로 단순화
- 편집 모드에서만 보이던 하단 `거래 수정하기` 버튼 제거
- 캘린더 일별 거래 행의 `눌러서 수정` 보조 문구 제거
- 거래 수정 화면에서 시스템 뒤로가기와 상단 뒤로가기 모두 `저장 / 저장 안 함` 선택 다이얼로그로 통일
- 저장 성공 시에는 기존처럼 수정 완료 스낵바를 보여준 뒤 화면을 닫고, `저장 안 함`은 폼을 초기화한 뒤 바로 이탈

## 뒤로가기 규칙 재확인

전역 `AppShell` 기준 동작은 유지됩니다.

- 홈이 아닌 화면: 뒤로가기 1회면 홈으로 이동
- 홈 화면: 뒤로가기 1회면 종료 안내
- 홈 화면에서 2초 안에 한 번 더 뒤로가기: 앱 종료

거래 수정 화면은 이 전역 규칙보다 먼저 편집 종료 다이얼로그를 처리합니다.

## 검증

- `C:\dev\flutter\bin\dart.bat analyze lib\features\transactions\presentation\quick_entry_screen.dart lib\features\calendar\presentation\calendar_day_detail_section.dart lib\features\root\presentation\app_shell.dart test\features\root\app_shell_back_behavior_test.dart`
- `C:\dev\flutter\bin\flutter.bat test --no-pub test\features\root\app_shell_back_behavior_test.dart`
- `C:\dev\flutter\bin\flutter.bat build windows --debug --no-pub`
