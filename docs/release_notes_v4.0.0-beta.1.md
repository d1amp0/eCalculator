# eCalculator 4.0.0-beta.1

First public beta of the v4 Android line.

## Highlights

- Redesigned the grade calculator around clear, scenario-first interactions.
- Added hypothetical grades, editing of existing grades, and reversible
  exclude/restore operations.
- Recalculate the original and predicted weighted averages immediately after
  every scenario change.
- Updated the eSchool adapter for the August 2026 grades and homework
  endpoints and nested grade schema.
- Added safe remembered-session restoration without an eager `/login`.
- Added account-isolated academic metadata caching, with durable SQLite
  persistence on Windows.
- Made Homework loading lazy, preserved local/remote concurrency behavior, and
  retained local task management.
- Added three application themes.
- Hardened session privacy, cache diagnostics, Android storage, and public
  repository hygiene.
- Added offline synthetic coverage for authentication, parsing, cache privacy,
  persistence, navigation, and duplicate-text homework cleanup.
- Added automated format, analyze, test, and Android debug APK checks for pull
  requests.

## Known limitations

- eSchool integration is unofficial, and upstream changes can break
  compatibility.
- Android is the primary release target; other platform scaffolding is not part
  of the beta support promise.
- CAPTCHA/MFA are not yet fully supported as a user-facing flow.
- Background eMarks notifications are not included yet.
- Existing pre-v4 Android installations use a different application ID and
  cannot be upgraded in place.

No credentials, session material, or real student data are included in the
application, fixtures, CI, or release notes.
