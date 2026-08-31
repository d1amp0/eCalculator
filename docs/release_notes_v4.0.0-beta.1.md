# eCalculator 4.0.0-beta.1

First public beta of the v4 Android line.

## Highlights

- Updated the eSchool adapter for the August 2026 grades and homework
  endpoints and nested grade schema.
- Added safe remembered-session restoration without an eager `/login`.
- Added account-isolated academic metadata caching, with durable SQLite
  persistence on Windows.
- Made Homework loading lazy and preserved local/remote concurrency behavior.
- Added offline synthetic coverage for authentication, parsing, cache privacy,
  persistence, navigation, and duplicate-text homework cleanup.
- Added automated format, analyze, test, and Android debug APK checks for pull
  requests.

## Known limitations

- This is an unofficial beta and can be affected by upstream eSchool changes.
- Android is the primary release target; other platform scaffolding is not part
  of the beta support promise.
- CAPTCHA/MFA variations and final release signing require separate real-device
  validation.
- Grade notifications and background polling are not included.
- Existing pre-v4 Android installations use a different application ID and
  cannot be upgraded in place.

No credentials, session material, or real student data are included in the
application, fixtures, CI, or release notes.
