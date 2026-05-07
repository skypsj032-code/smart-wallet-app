# Calendar, Home Accordion Preview, and Mobile Frame Plan

**Goal:** Keep the app visually simple by making home calendar/statistics entry collapsible, showing a mini monthly calendar and a mini statistics list on expansion, making calendar open month-first, and keeping the Windows shell in a fixed portrait frame.

## File Structure

- Modify: `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_home_links_card.dart`
  - Replace summary-only folds with a mini calendar preview and a mini statistics preview.
- Modify: `C:\smart wallet\app\lib\features\dashboard\presentation\dashboard_screen.dart`
  - Pass the preview data needed by the home accordion card.
- Modify: `C:\smart wallet\app\lib\features\calendar\application\calendar_provider.dart`
  - Add a home monthly calendar preview provider.
- Modify: `C:\smart wallet\app\lib\features\statistics\application\statistics_provider.dart`
  - Add a home statistics preview provider.
- Modify: `C:\smart wallet\app\lib\features\calendar\presentation\calendar_screen.dart`
  - Keep month-first content visible and exploration tools hidden behind the handle.
- Modify: `C:\smart wallet\app\windows\runner\main.cpp`
  - Keep the shell in a fixed mobile-style portrait frame.
- Verify: `C:\smart wallet\app\test\features\dashboard\dashboard_home_links_card_test.dart`
- Verify: `C:\smart wallet\app\test\features\dashboard\dashboard_screen_navigation_test.dart`
- Verify: `C:\smart wallet\app\test\features\calendar\presentation\calendar_screen_test.dart`

## Task 1: Home foldable previews

- [x] Home calendar/statistics entry stays in the same area.
- [x] Both sections are collapsed by default.
- [x] Expanding `달력` shows a mini monthly calendar and a detail button.
- [x] Expanding `통계` shows the top 3 expense categories and a detail button.
- [x] No search, filter, or heavy interactions are exposed on home.

## Task 2: Month-first calendar screen

- [x] Calendar opens directly into monthly content.
- [x] Search/filter/view controls are hidden by default.
- [x] A handle remains visible so the exploration panel is still discoverable.
- [x] The calendar-to-statistics shortcut is removed.

## Task 3: Fixed portrait Windows frame

- [x] The desktop shell opens in a portrait-sized frame.
- [x] Free-form wide resizing is prevented.
- [x] The size can be tuned without changing the interaction model.

## Task 4: Verification

- [x] Static analysis for the touched Flutter files
- [x] Widget tests for the home foldable card
- [x] Widget tests for home-to-route navigation through the folds
- [x] Widget tests for the month-first calendar screen
- [x] Final Windows rebuild and relaunch after the accordion-preview update

## Verification Commands

```powershell
& 'C:\smart wallet\dartw.bat' analyze `
  lib\features\calendar\application\calendar_provider.dart `
  lib\features\statistics\application\statistics_provider.dart `
  lib\features\dashboard\presentation\dashboard_home_links_card.dart `
  lib\features\dashboard\presentation\dashboard_screen.dart `
  test\features\dashboard\dashboard_home_links_card_test.dart `
  test\features\dashboard\dashboard_screen_navigation_test.dart `
  test\features\calendar\presentation\calendar_screen_test.dart
```

```powershell
& 'C:\smart wallet\flutterw.bat' test --no-pub `
  test\features\dashboard\dashboard_home_links_card_test.dart `
  test\features\dashboard\dashboard_screen_navigation_test.dart `
  test\features\calendar\presentation\calendar_screen_test.dart
```

```powershell
& 'C:\smart wallet\flutterw.bat' build windows --debug --no-pub
Start-Process -FilePath 'C:\smart wallet\app\build\windows\x64\runner\Debug\smart_wallet_app.exe'
```
