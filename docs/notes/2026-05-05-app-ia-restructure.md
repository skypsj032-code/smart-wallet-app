# App IA Restructure

Date: 2026-05-05

## Why this change happened

The previous bottom navigation exposed `홈 / 내역 / 전체`.

The problem was that `전체` had two unrelated responsibilities mixed together:

- money-related execution tools such as search, accounts, budgets, OCR, and recurring expenses
- app-level settings such as backup, restore, app lock, theme, and guide

That made the information architecture feel vague. Users had to learn that
`전체` actually meant both "tools" and "settings".

## New structure

Bottom navigation is now:

- `홈`
- `내역`
- `도구`
- `설정`

### Home

- keeps the summary-first role
- stays focused on balance, monthly flow, and key overview cards
- exposes lightweight entry points to `달력` and `통계`

### Timeline

- remains the transaction history surface
- no role change beyond the new 4-tab shell

### Tools

- becomes the execution hub for money-related actions
- includes:
  - 거래 검색
  - 계좌 관리
  - 예산 관리
  - 고정 지출
  - 영수증 스캔
  - 달력
  - 통계

### Settings

- becomes app-management only
- includes:
  - JSON 백업 만들기
  - CSV 내보내기
  - 백업 복원
  - 앱 잠금
  - 화면 테마
  - 앱 안내

## Implementation notes

- `AppShell` now maps routes to four tabs instead of three
- `/tools` is a new shell route
- routes like `/search`, `/accounts`, `/budgets`, `/ocr-*`, `/calendar`,
  `/statistics`, and `/recurring-expenses` highlight the `도구` tab
- `/settings` highlights the `설정` tab
- home keeps small analysis links instead of promoting calendar/statistics into
  primary tabs

## Home constraint kept on purpose

Home was not turned into a giant feature hub.

The goal was:

- keep home emotionally and visually focused
- let users go deeper when needed
- avoid recreating another ambiguous catch-all surface

The "repeat this often-recorded item" recommendation concept was intentionally
left out of this change and should be handled as a follow-up feature.

## Tests added

- `test/features/root/app_shell_test.dart`
- `test/features/settings/settings_split_test.dart`
- `test/features/dashboard/dashboard_home_links_card_test.dart`

These cover:

- 4-tab shell labels
- `도구` screen content split
- `설정` screen content split
- home-level calendar/statistics shortcut card
