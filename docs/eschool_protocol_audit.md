# eSchool protocol audit for eCalculator v4

Status: local source audit and safe instrumentation complete; controlled live
observations are pending. This document contains no account values, response
bodies, credentials, cookie values, grades, homework text, or profile data.

Audit date: 2026-08-30 (Europe/Moscow).

## Scope, evidence, and confidence

Only endpoints already present in the following approved sources were
considered:

- eCalculator at `a40b11aa2358618d87d599aee13f11314ab7c5a2`;
- [d1amp0/eMarks at `8765186`](https://github.com/d1amp0/eMarks/commit/8765186899fe8eae638856890dfa45a35b3f86bf);
- [mikhaillav/eSchool_JS at `0fdd428`](https://github.com/mikhaillav/eSchool_JS/commit/0fdd42844f75630ee525be33a8f5d3ce5524503e);
- [reSchool-org/reSchool-flutter at `bd6399e`](https://github.com/reSchool-org/reSchool-flutter/commit/bd6399e5380232415572fcf9b72f7043a0d0935f).

Confidence labels used below:

- **observed** — one controlled live request succeeded during this audit;
- **strongly corroborated** — present in the current client and/or multiple
  independent approved implementations, but not yet live-observed here;
- **historical** — present only in an approved reference implementation;
- **uncertain** — single-source or structurally ambiguous until the live check.

No endpoint is labelled **observed** yet. The live section must be completed
from metadata-only diagnostic events after the account owner signs in.

## Current eCalculator request inventory

All paths are relative to `https://app.eschool.center/ec-server`. “Cookie” in
the session column means the saved session cookie is sent; its value must never
be logged.

| Operation | Method and path | Query parameter names | Session requirement | Purpose | Volatility | Evidence / confidence |
|---|---|---|---|---|---|---|
| Fresh login | `POST /login` | none | No prior session; form fields are sent by the client | Establish a session cookie | Dynamic | eCalculator, eMarks, eSchool_JS, reSchool / strongly corroborated |
| Login completion | `GET /state` | none | Cookie from `/login` | Obtain the current user identifier and validate the new session | Dynamic session state | all four sources / strongly corroborated |
| Session restoration | `GET /state` | none | Saved cookie | Validate a saved session and refresh the current user identifier | Dynamic session state | all four sources / strongly corroborated |
| Classes / academic years | `GET /usr/getClassByUser` | `userId` | Cookie | Map the account to classes and academic years; obtain `groupId` | Semi-static | all four sources / strongly corroborated |
| Periods | `GET /dict/periods/0` | `groupId` | Cookie | Resolve a named quarter/semester/year to `eiId` | Semi-static | all four sources / strongly corroborated |
| Diary units / subject names | `GET /student/getDiaryUnits` | `userId`, `eiId` | Cookie | Map `unitId` to subject name; response can also contain changing aggregate marks/rating | Mixed: name map semi-static, aggregates dynamic | all four sources / strongly corroborated |
| Grades and lessons | `GET /student/getDiaryPeriod` | `userId`, `eiId` | Cookie | Fetch marks for the selected period | Dynamic | eCalculator, eMarks, eSchool_JS / strongly corroborated |
| Homework / diary | `GET /student/diary` | `userId`, `d1`, `d2` | Cookie | Fetch a bounded lesson window; eCalculator extracts homework variants | Dynamic | eCalculator / uncertain until live observation |

The current app does not call `/student/getPrsDiary`,
`/student/getPupilUnits`, or `/student/getDiaryPeriod_`. They are approved
comparison candidates, not current production dependencies:

| Method and path | Query parameter names | Known purpose | Evidence / confidence |
|---|---|---|---|
| `GET /student/getPrsDiary` | `prsId`, `d1`, `d2` | Diary, lesson parts, homework, and related lesson data for a person | reSchool / historical |
| `GET /student/getPupilUnits` | `prsId`, `yearId` | Subject/unit list for an academic year, used by reSchool analytics | reSchool / historical |
| `GET /student/getDiaryPeriod_` | `userId`, `eiId` | Nested lesson → part → mark representation of period data | reSchool / uncertain until live observation |

## Authentication and restoration behavior

Fresh authentication is two requests: `POST /login`, then `GET /state`.
The client stores the cookie map, user identifier, username, and SHA-256
password derivative in secure storage when “remember me” is enabled. That
password derivative is a reusable authentication secret and must be protected
like a password.

Restoration first sends only `GET /state` with the saved cookie. A 200 response
activates the session without `/login`. A 401 currently causes
`EschoolSession.restore()` to call `/login` automatically using the stored
password derivative. Separately, any ordinary authenticated GET that receives
401 also calls `/login` once and retries the original request.

That foreground convenience must not be reused by a background worker. A
background client needs an explicit “never authenticate” request mode.

`validateSession()` currently collapses 403, 429, timeouts, and other non-200
statuses into `unavailable`. The background design must preserve these statuses
so anti-abuse signals are acted on correctly.

## Request counts

### Code-derived counts before the live run

The `IndexedStack` constructs the calculator and homework pages together, so
opening the main screen starts both remote loads even if the homework tab is
never selected.

| User operation | Requests caused by current code | Count |
|---|---|---:|
| First login | `/login`, `/state` | 2 |
| Initial main-screen data load | `/usr/getClassByUser`, `/dict/periods/0`, `/student/getDiaryUnits`, `/student/getDiaryPeriod`, `/student/diary` | 5 |
| Open one subject after marks loaded | none; the subject view uses the in-memory marks map | 0 |
| Select the homework tab after initial load | normally none; `/student/diary` was already started eagerly | 0 additional |
| Restart with a valid saved session | `/state` plus the same five eager data requests | 6 |
| Restart with a rejected saved session | `/state`, `/login`, `/state`, then five data requests | 8 |
| Open the academic-year selector | one additional `/usr/getClassByUser` | 1 |
| Change year/period | class lookup, periods, units, and grades | 4 |

With the one-shot variant flag enabled, the first calculator load adds exactly
one known request to `/student/getDiaryPeriod_/`. The flag must be disabled for
the restart/session-restoration run so that the variant is not called twice.

### Live counts

Pending metadata-only observation. Fill this table without copying raw console
output into the repository:

| Flow step | Observed paths/statuses | Count |
|---|---|---:|
| First login | pending | pending |
| Load calculator data | pending | pending |
| Open one subject | pending | pending |
| Load/open homework | pending | pending |
| Cold restart and restore | pending | pending |

## Safe temporary diagnostics

`lib/services/eschool/eschool_diagnostics.dart` is compile-time opt-in and
console-only. It accepts no request body, response text, header value, or query
value. Each event contains only:

- method and endpoint path;
- sorted query parameter names;
- status, elapsed milliseconds, and response byte length;
- top-level JSON keys and selected nested field-name/type shapes;
- cookie names;
- `fresh-login` or `restored-session`;
- an in-process sequence number for counting requests.

It is disabled by default with
`--dart-define=ESCHOOL_PROTOCOL_AUDIT=true`. A second explicit flag,
`--dart-define=ESCOOL_COMPARE_DIARY_PERIOD_VARIANT=true`, makes the normal first
calculator load call the already-known underscored variant once. Its decoded
response is discarded and does not affect displayed grades.

Do not redirect diagnostic output to a file, attach it to an issue, or commit
it. Although the mode is designed to exclude private values, review the console
locally and transcribe only the aggregate findings into this document.

Stop the run immediately after any 403, 429, CAPTCHA/blocking indication, or
other anti-abuse signal. Do not retry the comparison.

## `getDiaryPeriod` versus `getDiaryPeriod_`

### Source-level comparison

| Property | `/student/getDiaryPeriod` | `/student/getDiaryPeriod_` |
|---|---|---|
| Current eCalculator use | Yes | No; one-shot audit hook only |
| Other evidence | eMarks and eSchool_JS | reSchool |
| Known top-level shape | map with `result` list | map with `result` list |
| Known result representation | flattened rows containing lesson and optional mark fields | lessons containing `part` lists, whose entries contain `mark` lists |
| Historically documented grade fields | `markId`, `markVal`, `markValId`, `markNum`, `mktWt`, `lessonId`, `partId`, `unitId`, dates | reSchool parses `markValue` and part weight/name; raw identifier fields are not yet confirmed |
| Subject naming | response has `unitId` and may have `subject`; eCalculator joins cached diary units | response has `unitId` and `subject`; reSchool still joins diary units for canonical names and aggregates |
| Companion requests needed for grade change detection after cache warm-up | none | likely none |
| Live status / response bytes | pending | pending |
| Live field shape | pending | pending |

The two implementations appear to expose equivalent grade semantics, but live
value equivalence is not claimed until both endpoints return successfully for
the same period. The underscored response is structurally richer and therefore
may be larger. The non-underscored response historically exposes a direct
`markId`, making it the safer initial candidate for snapshot diffing unless the
live underscored mark objects reveal an equally stable identifier.

## Stable identifiers and grade-change detection

The current domain conversion discards server identifiers and invents
`"<subject>-<list index>"`. That identifier changes when response ordering
changes and can collide conceptually; it cannot reliably detect edits or
deletions.

Preferred identity, in order:

1. server `markId`, if present and stable across successive successful
   snapshots;
2. an underscored mark-object identifier, if the live field shape reveals one;
3. a last-resort composite of `lessonId`, `partId` or part category, and a
   deterministic mark ordinal. This is weaker when multiple marks share a
   lesson part or the server reorders them.

For every successful, complete 200 snapshot, store a local map keyed by the
stable grade identifier. The value should be a local canonical fingerprint of
the change-relevant fields (grade value, weight, assessment/part identity,
subject/unit, and effective date). It does not need to include names, teacher
data, homework, or profile fields.

- **Added grade:** identifier exists only in the new snapshot.
- **Changed grade:** identifier exists in both snapshots but its canonical
  fingerprint differs.
- **Deleted grade:** identifier exists only in the previous snapshot.

Never infer deletions from a timeout, partial parse, non-200 response, a changed
period, or a response that fails completeness validation. Establish the first
successful snapshot silently; otherwise every existing grade would look new.

## Cache recommendations

Cache only the projection the app needs. In particular, a full
`getDiaryUnits` response includes dynamic aggregate marks and must not be given
the same long lifetime as the `unitId → unitName` projection.

| Data | Recommended cache rule | Invalidation |
|---|---|---|
| Account user identifier from state | Store with the secure session | Clear on logout, account change, or 401 |
| Class membership / academic years | 7 days normally; refresh within 24 hours during Aug–Sep | Account change, year-resolution miss, manual refresh |
| Period tree and IDs | 7 days, scoped by `groupId` | Class change, academic-year rollover, missing selected period, manual refresh |
| `unitId → unitName` projection | 7 days, scoped by account and academic year/period | Class/period change, unknown `unitId`, manual refresh |
| Full diary-unit aggregates | At most 5 minutes in foreground, or do not persist | Any grade refresh or period change |
| Profile metadata | Do not fetch for eCalculator; if later needed, 30 days | Account change, explicit refresh |
| Grade snapshot | Always refresh for a user-requested reload; optional 2–5 minute stale-while-revalidate for navigation | Successful new response replaces snapshot atomically |
| Homework for a bounded date window | 5–15 minutes in foreground | Date-window shift, day rollover, explicit refresh |

reSchool caches classes and periods for seven days, pupil units for seven days,
and its combined marks view for one day. The first two are reasonable starting
points. A one-day marks TTL is too stale for notifications and should not be
copied. Its full diary-unit response also mixes static and dynamic fields, so
cache the name projection rather than the whole payload for seven days.

## Minimal background grade-check algorithm

The warm-cache flow can be one eSchool request:

1. Read the saved cookie, saved user identifier, current period `eiId`, cached
   subject map, and last successful grade snapshot from local secure/app
   storage. If any required session/period state is absent, disable/skip the
   worker and wait for foreground setup.
2. Send one `GET /student/getDiaryPeriod` with query names `userId` and `eiId`.
   Use a background-specific request method that cannot call `/login` and cannot
   automatically retry a 401.
3. On 200, validate and canonicalize the complete snapshot, compute added /
   changed / deleted identifiers, atomically replace the snapshot, then issue
   local notifications for real differences. The first snapshot is baseline
   only.
4. On 401, cancel/disable background monitoring and require foreground
   re-authentication.
5. On 403, stop monitoring immediately. Do not alter identity, headers, or
   network route and do not retry.
6. On 429, stop the current run and suspend monitoring for a substantial
   user-visible cooldown; do not create a retry loop.
7. On 5xx, timeout, offline state, parse failure, or cancellation, leave the old
   snapshot unchanged and exit successfully so only a later normal scheduled
   run can try again.

Do not call `/state` before the grade request: it would double steady-state
traffic and the grade endpoint's status already proves whether the session is
usable. Do not call `getDiaryUnits` in the worker; cache the subject projection
in the foreground. Period rollover should also be a foreground refresh rather
than extra background discovery requests.

Android WorkManager is suitable for this deferrable, short network task, but it
is inexact: periodic work has a 15-minute minimum and can be delayed by Doze,
battery optimization, constraints, and standby state. Use unique periodic work,
require network connectivity, avoid expedited work, and offer a conservative
default interval such as 60 minutes rather than treating 15 minutes as a
polling target. See Android's official guidance on
[periodic work and constraints](https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work),
[battery-efficient scheduling](https://developer.android.com/develop/background-work/background-tasks/optimize-battery),
and [background data transfers](https://developer.android.com/develop/background-work/background-tasks/data-transfer-options).

No WorkManager implementation is warranted until the live audit confirms that
a saved session can directly access the chosen grade endpoint and exposes a
stable grade identifier.

## Practices not to copy from eMarks or reSchool

- Do not copy eMarks proxy rotation, randomized User-Agent switching, device
  identity rotation, retries after 403/429, or retry loops around login.
- Do not copy eMarks debug logging of full decoded responses, usernames, error
  response text, or snapshots containing grade values.
- Do not copy eMarks' hard-coded `CURRENT_YEAR = "2025"` or its default period
  identifier.
- Do not copy reSchool's full request-body/response-body logging. Its response
  logger can print private profile, chat, diary, homework, and grade content.
- Do not copy reSchool's automatic re-login after 401 into background work.
- Do not copy reSchool's insecure SharedPreferences fallback for saved account
  credentials or its storage of the plaintext password.
- Do not copy reSchool's device-model/OS randomization.
- Do not copy a one-day grade cache into notification logic.
- Do not copy chat, upload, account mutation, or unrelated report endpoints for
  this audit.

## Current eCalculator inconsistencies and legacy risks

- A fixed login `deviceId` is shared by every installation, while the push token
  is randomized. Device identity semantics should be clarified, not randomized
  in response to blocking.
- Login advertises client version `v.1588`; the unused generic PUT path injects
  `clientVer=v.1587`.
- The generic PUT cookie header contains hard-coded person, user, organisation,
  position, and diary URL values. This path must be removed or rebuilt before
  any mutating feature is considered. It was not invoked in this audit.
- The generic authenticated GET and PUT paths automatically re-authenticate on
  401. They are unsuitable for background monitoring.
- Session restoration stores a reusable password derivative even though a
  successful background design needs only the saved session and must stop on
  expiry.
- `getGroupId()` parses JSON by string slicing and relies on field order and
  punctuation instead of the decoded structure.
- The client repeats class, period, and unit requests and has no protocol-data
  cache.
- The main `IndexedStack` eagerly requests homework even when the user opens
  only the calculator.
- Grade IDs are replaced with subject/list-index IDs, losing `markId` and other
  server identity candidates.
- The client contains legacy Latin-1-to-UTF-8 repair logic, suggesting encoding
  assumptions that should be verified before retaining them.
- Cookie parsing is a small regular expression over the combined `Set-Cookie`
  header and may be fragile for more complex cookie attributes.

## Live audit checklist

Run 1 uses the one-shot comparison flag. The account owner enters credentials
in the app and enables “remember me”; no credentials are supplied to tooling or
chat. Observe the console locally, stop on anti-abuse signals, and perform only:

1. login;
2. wait for calculator data;
3. open one subject;
4. select homework and wait for its already-started load;
5. close the app.

Run 2 keeps only `ESCOOL_PROTOCOL_AUDIT=true` (the variant flag is omitted),
then cold-starts the app and waits for restoration. Confirm that the first
event is `GET /state` with `sessionUse=restored-session`, status 200, and that no
`POST /login` event occurs. Record only counts, statuses, byte lengths, key
names/types, and cookie names in this document.

After the live table and comparison are transcribed, remove the one-shot hook
and diagnostic file, or retain them only if the project explicitly accepts the
compile-time-isolated audit facility. Never commit raw console output.
