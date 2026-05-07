# Default Category Seeding

Date: 2026-05-05

## Goal

Expand the built-in categories for both expense and income without turning them
into locked system data.

The required product behavior is:

- new installs should start with a broader, more usable category set
- existing users should receive the newly introduced defaults
- users must still be able to rename, add, and delete default categories
- deleted default categories must not silently reappear on the next app launch

## Core Constraint

The original bootstrap logic only seeded categories when the table was empty.

That created two problems:

1. existing users never received newly added defaults
2. a naive "insert missing defaults on every launch" fix would recreate deleted
   defaults and fight user intent

## Final Design

### 1. Track seed rollout state in settings

`app_settings` now includes `default_category_seed_version`.

- schema version bumped from `4` to `5`
- migration adds the new column with default `0`
- bootstrap upgrades settings to seed version `2` after category seeding runs

This makes category expansion a one-time rollout instead of a permanent repair
loop.

### 2. Separate legacy defaults from newly introduced defaults

Legacy category ids:

- `expense-food`
- `expense-transport`
- `expense-shopping`
- `income-salary`
- `income-other`

For **new installs**:

- seed the full expanded category list

For **existing installs with categories already present**:

- seed only the newly introduced default ids
- do not restore missing legacy ids

This preserves users who may already have deleted an old default such as
`expense-shopping`.

### 3. Keep default categories user-editable

No new restriction was added to category actions.

`QuickEntryCategoryActions` already allows:

- create
- rename
- delete

So defaults remain normal user-facing categories with an `isDefault` marker, not
protected rows.

## Expanded Default Categories

Expense:

- `expense-food` / `식비`
- `expense-cafe-snack` / `카페/간식`
- `expense-groceries` / `장보기`
- `expense-transport` / `교통`
- `expense-housing-utilities` / `주거/통신`
- `expense-shopping` / `쇼핑/패션`
- `expense-household` / `생활용품`
- `expense-health` / `의료/건강`
- `expense-leisure` / `취미/여가`
- `expense-subscriptions` / `구독/디지털`
- `expense-gifts` / `경조사/선물`
- `expense-other` / `기타 지출`

Income:

- `income-salary` / `급여`
- `income-allowance` / `용돈/지원`
- `income-side-income` / `부수입`
- `income-resale` / `중고판매`
- `income-refund` / `환급/캐시백`
- `income-interest-dividend` / `이자/배당`
- `income-other` / `기타 수입`

## Implementation Files

- `lib/app/bootstrap/app_bootstrap_provider.dart`
- `lib/core/database/tables.dart`
- `lib/core/database/app_database.dart`
- `lib/features/settings/application/backup_service.dart`

## Tests Added

`test/app_bootstrap_provider_test.dart`

Coverage:

- full expanded seed on new install
- one-time delta backfill for existing users
- no recreation of a deleted default category after upgrade

## Verification

Passed:

- `dart analyze lib\\app\\bootstrap\\app_bootstrap_provider.dart lib\\core\\database\\app_database.dart lib\\core\\database\\tables.dart lib\\features\\settings\\application\\backup_service.dart test\\app_bootstrap_provider_test.dart test\\bootstrap_settings_test.dart test\\features\\settings\\backup_service_test.dart`
- `flutter test --no-pub test\\app_bootstrap_provider_test.dart test\\features\\settings\\backup_service_test.dart`

Known unrelated failure observed during verification:

- `test\\bootstrap_settings_test.dart` is currently stale against the app's
  present startup and lock-screen behavior. It failed on UI expectations and a
  null check inside `LockScreen`, not on category seeding logic.

## Follow-up

OCR category guesses still use coarse English labels such as `Food & Drink` and
`Shopping`. That mapping is adjacent work and was intentionally left out of this
change.
