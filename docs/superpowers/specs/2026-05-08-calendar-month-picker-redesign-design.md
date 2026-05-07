# Calendar Month Picker Redesign

Date: 2026-05-08
Branch: `feat/calendar-home-keyboard`

## Summary

Rebuild the calendar detail screen around a single primary monthly calendar experience.

The screen should stop exposing separate `주간 / 일별 / 월별 / 연별` mode chips. Instead, the calendar is primarily a monthly view. The month label in the header, such as `2026.05`, becomes the entrypoint into an inline month-and-year picker that replaces the calendar body temporarily. Users can change year there, choose one of the 12 months, and return to the monthly calendar for that month.

`일별` mode is removed. Day-level inspection remains available by tapping a date and reading the selected-day detail section below the calendar.

## Product Intent

The calendar should feel like a full calendar first, not a screen full of controls.

The current problems are:

- too much vertical space is consumed by mode chips and control UI
- day inspection is split between a dedicated mode and the lower detail section
- month and year navigation are more complicated than they need to be
- the main calendar grid does not own enough of the screen

The new structure makes the monthly calendar the visual center of the screen and moves year/month switching into the header-driven inline picker.

## Scope

This redesign applies to the calendar detail screen only.

Included:

- remove top-level mode chips
- remove `일별` mode
- convert month label into inline month/year picker trigger
- enlarge the monthly calendar body
- keep selected-day detail below the calendar
- preserve transaction sort control in the selected-day detail section

Excluded:

- bringing back quick entry inside calendar
- adding Toss-like `거래 내역 / 소비 분석` tabs inside calendar
- changing home mini-calendar design in this task
- restoring `주간` as a separate always-visible mode selector
- changing recurring suggestions, statistics, or tools/settings IA

## Primary Screen States

The calendar screen has only two main content states.

### 1. Monthly Calendar State

This is the default state.

Structure from top to bottom:

1. Header row
   - month label, for example `2026.05`
   - previous / next month buttons
2. Monthly summary
   - `지출`
   - `수입`
3. Weekday header row
   - `월 화 수 목 금 토 일`
4. Monthly calendar grid
5. Selected-day detail section

The header month label is interactive. Tapping it switches the body into the inline month/year picker state.

### 2. Inline Month/Year Picker State

This temporarily replaces the monthly calendar body in the same screen region.

Structure:

1. Year header
   - active year, for example `2026`
   - previous / next year buttons
2. Month grid
   - `1월` through `12월`
   - arranged as `3 columns x 4 rows`

Behavior:

- changing year refreshes the 12 available months for that year
- tapping a month closes the picker state and returns to monthly calendar state
- the selected month becomes the new displayed month

This is not a popup, not a bottom sheet, and not a separate route.

## Removed Controls

The following are removed from the calendar detail header area:

- `주간`
- `일별`
- `월별`
- `연별`

`일별` is removed completely as a view mode.

`주간` is not retained as a top-level mode in this redesign. The user asked to maximize calendar space and remove controls that compete with the calendar grid. This redesign prioritizes a strong monthly experience with inline year/month switching.

## Monthly Calendar Grid

The monthly grid becomes the dominant visual block.

### Cell structure

Each date cell keeps a stable three-part hierarchy:

- top: date number
- bottom-left: income amount
- bottom-right: expense amount

Rules:

- values are never abbreviated
- use full numeric display, for example `29,000원`
- empty side stays blank but the layout slot remains reserved
- the selected day is highlighted

The layout must prioritize readability and avoid cell-to-cell structural changes.

## Selected-Day Detail Section

This section replaces the need for a separate day mode.

Structure:

1. selected date title
2. small income/expense summary for that date
3. transaction sort toggle
   - `최신순`
   - `오래된순`
4. transaction list

Behavior:

- tapping a day updates this section in place
- default sort remains `최신순`
- switching sort updates only the list order

## State Model

The screen should simplify to a small set of state values.

### Required state

- `displayedMonth`
  - the month currently shown in the main calendar
- `selectedDay`
  - currently selected date inside `displayedMonth`
- `isMonthPickerOpen`
  - whether the inline month/year picker is visible
- `transactionSortOrder`
  - `newestFirst` or `oldestFirst`

### Derived values

- active year comes from `displayedMonth.year`
- monthly income/expense summary comes from `displayedMonth`
- picker month selection uses the same `displayedMonth`

No separate `day mode`, `week mode`, or `year mode` state should remain for this screen.

## Interactions

### Month navigation

- left arrow: previous month
- right arrow: next month
- when month changes, monthly summary and grid refresh

### Month label tap

- tapping `2026.05` opens the inline month/year picker
- picker replaces the calendar body in-place

### Year navigation inside picker

- left arrow: previous year
- right arrow: next year
- month grid remains visible while year changes

### Month selection inside picker

- tapping a month updates `displayedMonth`
- picker closes
- monthly calendar state returns immediately for the selected month

### Day selection

- tapping a date highlights that day
- selected-day detail section updates below the calendar

## Back Behavior Inside Calendar

If the inline month/year picker is open and the user triggers back:

- close the picker first
- do not leave the calendar screen
- do not jump home

Only after the picker is closed should the app-level back rules apply.

## Edge Cases

### Selected day becomes invalid after month change

If the previous `selectedDay` does not exist in the new month:

- reset to the first valid day of the new month

### Selected day has no transactions

- keep the selected-day detail section visible
- show empty transaction state
- do not force navigation or mode changes

### Picker re-entry

- reopening the picker should start from the year and month of `displayedMonth`
- not from current system month unless they are the same

## Visual and Layout Priorities

This redesign is about layout first, not theme restyling.

Priorities:

1. make the calendar body taller and more dominant
2. reduce control chrome above the grid
3. keep the selected-day detail below, not in a separate mode
4. keep the picker inside the same content block

This task should not introduce extra decorative elements.

## Testing

### Widget behavior

- tapping month label opens inline picker
- picker shows current year and 12 months in `3 x 4`
- year arrows change the visible year
- tapping a month returns to monthly calendar for that month
- selected-day detail updates when a day is tapped
- transaction sort toggle still works in selected-day detail
- back closes picker before leaving calendar

### Layout checks

- monthly calendar renders on compact mobile-sized window without overflow
- picker renders on compact mobile-sized window without overflow
- selected-day detail still appears below calendar after month changes

## Implementation Notes

The safest approach is:

1. remove chip-based mode UI
2. introduce `isMonthPickerOpen`
3. convert the calendar body between monthly grid and picker grid
4. preserve selected-day detail and sort behavior
5. add picker-close-on-back behavior

This work should be done incrementally and verified with widget tests before shipping.
