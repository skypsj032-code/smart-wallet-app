# Calendar Reference Layout Redesign

Date: 2026-05-08
Branch: `feat/calendar-home-keyboard`

## Summary

Rebuild the calendar detail screen so it visually follows the provided Toss-style spending calendar reference while preserving the current Smart Wallet behavior.

This is a presentation-layer redesign, not a feature rewrite. The existing month navigation, inline month/year picker, selected-day detail, and transaction sorting remain. The visual structure changes so the screen reads as a large monthly calendar first, with the selected day's detail naturally continuing below it.

## Product Intent

The calendar detail screen should feel like a dedicated money calendar page, not a stack of cards and controls.

The reference succeeds because:

- the page itself is the canvas
- the monthly calendar is the primary object on screen
- controls are minimal and quiet
- monthly totals are readable before the user studies daily data
- daily values stay compact and structured
- the selected day is emphasized subtly, not with heavy card chrome

Smart Wallet should keep its current capabilities, but the screen should visually read closer to that model.

## Scope

This redesign applies to the calendar detail screen only.

Included:

- convert calendar detail into a white full-page surface
- keep the month label, month arrows, inline month/year picker, and selected-day detail behavior
- add a top tab row for `Calendar / Transactions / Spending Analysis`
- reorganize the vertical rhythm to match the reference
- flatten the monthly calendar so cells feel like text slots, not mini cards
- make the selected-day detail feel like the daily section that lives below the monthly calendar

Excluded:

- redesigning the home mini-calendar to match the same density
- changing statistics screen layout in this task
- changing the timeline screen layout in this task
- changing route structure
- changing transaction models, sorting logic, or provider data shape unless needed to support the presentation

## Design Principle: Preserve Function, Replace Chrome

The guiding rule for this task is:

- keep functional state and interactions where they already work
- replace visual chrome, spacing, hierarchy, and grouping

Preserved behaviors:

- `2026.05` month header remains the trigger for the inline month/year picker
- previous / next arrows keep moving by month
- tapping a date updates the selected day
- the selected-day detail remains below the monthly calendar
- transaction sorting remains `Newest first / Oldest first`
- the tab labels navigate to existing screens rather than becoming fake decoration

Replaced presentation:

- yellow immersive background inside the calendar detail screen
- floating card look around the monthly calendar
- strong cell borders and chip-like mode controls
- stacked control chrome that competes with the calendar body

## Screen Structure

The screen is a single white page with five visual bands.

### 1. Title band

Top of page:

- large month title, for example `2026.05`
- month navigation arrows on the right

The title should be visually dominant and left-aligned. It is both a label and an interaction target. Tapping it still opens the inline month/year picker in the calendar area below.

### 2. Tab band

Directly below the title:

- `Calendar`
- `Transactions`
- `Spending Analysis`

Visual behavior:

- `Calendar` is active on this screen
- active tab uses a thin underline
- tabs are quiet and light compared to the title
- no heavy pills, chips, or segmented controls

Functional behavior:

- `Transactions` navigates to the existing timeline screen
- `Spending Analysis` navigates to the existing statistics screen
- `Calendar` stays on the current screen

### 3. Monthly totals band

Directly below the tabs:

- `Expense 1,625,560 won`
- `Income 2,746,059 won`

Rules:

- render as two simple text rows, not a card
- amounts stay full-length, never abbreviated
- `Income` amount uses the stronger accent color
- `Expense` amount uses strong neutral emphasis
- this band should feel like a compact summary block, not a hero card

### 4. Monthly calendar band

This is the main visual block of the screen.

Structure:

- weekday header row
- monthly grid

Layout rules:

- the monthly calendar owns the majority of the first screen
- the grid should be wider and taller than it is today
- cells should read as part of one flat surface, not as nested rounded cards
- ordinary days should be quiet
- the selected day should be highlighted with a subtle circular or softly rounded emphasis behind the date

Cell structure:

- top: date number
- bottom-left: income amount
- bottom-right: expense amount

Cell behavior rules:

- full numeric values only
- empty slots remain visually reserved, but blank
- alignment is fixed and consistent across every cell
- the design must avoid moving the location of income or expense between cells

### 5. Daily detail band

Below the monthly calendar, reached naturally by scrolling:

- selected date heading
- that day's income / expense summary
- sort control
- transaction list

This is the replacement for a dedicated day view. The user stays in the monthly calendar context and scrolls down to inspect the selected day.

## Visual Hierarchy

The hierarchy should be:

1. month title
2. monthly totals
3. date numbers
4. daily income / expense values inside cells
5. daily detail list content

Important consequence:

- the calendar should not be wrapped in a stronger card than its own content
- section chrome should be weaker than the numbers themselves

## Surface and Background Rules

Home remains the emotional yellow entry screen.

Calendar detail does not.

Rules:

- calendar detail uses a white page surface
- large decorative yellow background treatment stops at the home experience
- entering calendar should feel like moving into a clean financial workspace
- any transition from home to calendar can suggest continuity, but the calendar page itself should be predominantly white

## Spacing Rules

The reference uses generous spacing between sections, but tight spacing inside the calendar cells.

Apply the same principle:

- larger gaps between title, tabs, totals, and grid
- smaller internal spacing inside each date cell
- no oversized padding that makes the calendar feel trapped inside a card

The current calendar has too much visual padding around the main content block. This redesign reduces container padding so the monthly grid gets more room.

## Inline Month/Year Picker

The inline picker stays functionally the same.

Rules:

- it replaces the calendar body in place
- it uses the same white page language
- it should feel like a natural alternate state of the monthly calendar area
- year title and month grid should be clean and quiet
- picker chrome should not look like a separate popup

The picker must visually belong to the same surface as the monthly calendar.

## Selected-Day Default

The selected day defaults to today.

When the user first enters the calendar detail screen:

- the monthly calendar is shown
- today is the selected date when possible
- scrolling down reveals today's daily detail

When the user taps another date, only the selected-day detail updates.

## What Must Be Removed

The redesigned screen should not contain:

- mode chips such as `Week / Day / Month / Year`
- a floating calendar card sitting on another colored surface
- heavy borders around each date cell
- extra explanation copy above the calendar
- decorative background competing with the calendar data

## Testing Focus

This redesign is visual, but it still needs verification that functional behavior remains intact.

Must verify:

- month title still opens inline picker
- month arrows still navigate month to month
- date tap still updates the selected-day section
- tab buttons still route to timeline and statistics
- selected-day detail still defaults to today
- compact app width still renders without overflow

## Success Criteria

The redesign is successful when:

- the calendar page feels like one clean white financial surface
- the monthly calendar is visibly the main object on screen
- the selected-day detail feels like the natural continuation of the calendar, not a separate mode
- the screen looks much closer to the provided reference in layout and hierarchy
- Smart Wallet functionality remains intact
