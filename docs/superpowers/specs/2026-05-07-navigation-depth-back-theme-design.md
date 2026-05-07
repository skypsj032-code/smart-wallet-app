# Navigation Depth, Back Behavior, Theme Picker, and Calendar Sort Design

Created: 2026-05-07

## 1. Summary

This design defines four app-wide interaction rules:

- Back behavior is consistent everywhere.
- All navigation depth, including pages and popups, is capped at 3 levels.
- Calendar day transactions stay newest-first by default, with a manual sort toggle.
- Theme mode selection is rebuilt as a clear 3-way segmented control.

The goal is not to add new product surface area. The goal is to remove ambiguity, stop accidental exits, and make the app feel predictable.

## 2. Problems

### 2.1 Back behavior is inconsistent

The current app can exit too easily. Users expect:

- if they are already at home, back should require two presses to exit
- if they are not at home, one back press should take them home

Instead, the current behavior feels mixed and fragile.

### 2.2 Entry depth is uncontrolled

The user wants a hard rule:

- page
- popup
- dialog
- bottom sheet

all count toward a single maximum depth of 3.

Right now this rule is not enforced globally.

### 2.3 Calendar day sorting is rigid

The user wants:

- default sort: newest first
- optional toggle: oldest first

The current behavior should not permanently switch to oldest-first.

### 2.4 Theme mode selection feels wrong

The existing theme picker is visually weak and does not read like a strong stateful control. This is a long-standing settings UX issue, not a data issue.

## 3. Goals

- Make back behavior fully predictable.
- Enforce a single global depth rule of 3.
- Keep calendar day transactions newest-first by default.
- Add an explicit sort toggle for the selected-day transaction list.
- Replace the theme picker with a clearer segmented control.

## 4. Non-goals

- No redesign of the entire settings screen.
- No redesign of routing architecture beyond what is needed for the depth and back policy.
- No persistence of a per-user custom sort preference unless the app already has a suitable settings slot.
- No local notification work.

## 5. Approaches considered

### Approach A: Global navigation policy

Use a shared app-level policy for:

- root/home detection
- back interception
- depth counting
- popup gating

Pros:

- one rule for the whole app
- easier to reason about
- future screens inherit the same behavior

Cons:

- requires touching the root shell and popup entry points

### Approach B: Screen-by-screen fixes

Patch calendar, settings, and a few popups individually.

Pros:

- quicker short term

Cons:

- rules drift immediately
- easy to miss edge cases
- future regressions are likely

## 6. Chosen approach

Approach A is required.

The user requested absolute consistency, especially for:

- leaving the app
- returning to home
- limiting how many layers can be opened

That cannot be solved reliably with screen-local patches.

## 7. Final design

### 7.1 Back behavior

#### At home

When the app is already at home:

- first back press shows a short message that one more back press will exit the app
- second back press within the allowed window exits the app

#### Outside home

When the user is not at home:

- one back press always returns to home
- it does not exit the app directly

#### When overlays are open

If a dialog, popup, or bottom sheet is open:

- back closes the topmost open layer first
- only after overlays are closed does the home/non-home rule apply

### 7.2 Depth model

The app uses one shared depth model.

#### Level 1

Root surfaces:

- home
- timeline/history
- tools
- settings

#### Level 2

A detail screen entered from a root surface.

Examples:

- calendar detail
- statistics detail
- recurring transaction management

#### Level 3

An overlay or nested action entered from a detail screen.

Examples:

- edit dialog
- selection popup
- bottom sheet

#### Hard rule

No flow may exceed level 3.

If a new action would create level 4:

- do not open another nested overlay
- either reuse the current screen
- or close/replace the current overlay
- or route the user back to a shallower surface before continuing

### 7.3 Calendar selected-day sorting

For selected-day transactions in the calendar detail:

- default order is newest first
- user can switch to oldest first

This is a view concern, not a data mutation.

The toggle is local to the selected-day transaction list.

Expected states:

- Newest first
- Oldest first

The list updates immediately when toggled.

### 7.4 Theme picker

The current theme picker is replaced with a stronger 3-way segmented control:

- System
- Light
- Dark

Design requirements:

- icon + text for each option
- selected state is visually obvious
- the control reads as one grouped decision, not three unrelated buttons
- it lives inside the settings card as a clear self-contained control block

### 7.5 Interaction boundary

This policy applies to:

- routed pages
- dialogs
- popups
- bottom sheets

This policy does not try to infer user intent from content. It only governs structural entry depth and back behavior.

## 8. Edge cases

### 8.1 Non-home back with pending overlays

If the user is on a detail screen and an overlay is open:

1. back closes overlay
2. next back returns home

It must not jump straight to app exit.

### 8.2 Home tab vs home route

The home exit rule applies only when the app is structurally at home, not just when a nested page happens to visually resemble home.

### 8.3 Repeated overlay entry from level 3

If the user is already at level 3 and tries to open another nested popup:

- the app should block the extra nested entry
- no silent crash
- no invisible no-op without feedback if a visible action was requested

### 8.4 Calendar sort and date switching

Changing the selected date should keep the current sort mode unless the implementation cost is disproportionate or conflicts with existing list state patterns. If persistence across date changes is expensive, session-local retention inside the screen is sufficient.

## 9. Testing requirements

### Back behavior

- back once from home does not exit
- back twice from home exits
- back once from a non-home detail returns home
- back with open dialog closes dialog before applying page-level back behavior

### Depth limit

- opening a third level succeeds
- attempting a fourth level is blocked or replaced safely

### Calendar sorting

- default selected-day order is newest first
- toggling changes to oldest first
- toggling back restores newest first

### Theme picker

- system, light, and dark all render in one grouped control
- selecting one clearly updates the visual selected state
- the current stored theme mode still maps correctly to app theme

## 10. Success criteria

This work is complete when:

- users can predict back behavior without trial and error
- the app never exits from non-home with a single back press
- no flow exceeds 3 total levels
- calendar day sorting is controllable without changing the default expectation
- theme mode selection looks intentional and reads instantly
