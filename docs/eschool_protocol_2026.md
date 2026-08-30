# Current eSchool web protocol audit — August 2026

Audit date: 2026-08-30<br>
Official client: `https://app.eschool.center`<br>
Official build: `1.5.19-ver-4207-g9f651599.0`, built `30.08.2026, 11:34:30`<br>
Mode: read-only; no eSchool data was created, edited, submitted, uploaded, or deleted.

This report contains no credential, password derivative, cookie value, token,
account identifier, profile value, grade value, homework text, or private
response body.

## Evidence boundary

The connected Codex in-app browser allowed normal UI navigation and safe DOM
inspection, but it did **not** expose Chrome DevTools Protocol network capture,
request/response bodies, cookie metadata, WebSocket/SSE frames, transfer sizes,
or cache disposition. Accordingly:

- **OBSERVED OFFICIAL PAGE** means a route or lifecycle result seen in the
  authenticated official UI.
- **PUBLIC FRONTEND CODE** means behavior defined by the exact JavaScript and
  templates publicly delivered by that same production page. It is strong
  current evidence, but not an observed network transaction.
- **LIVE PRODUCTION EVIDENCE (Windows, privacy-safe)** means an authenticated
  request was observed without retaining private values, IDs, account data, or
  response bodies. It establishes endpoint status and field names/types only.

The inspected public artifacts were `env.js` (390 bytes), `scripts.js`
(5,009,358 bytes), `template-cache.js` (4,313,744 bytes), `modulescore.js`
(228,539 bytes), `modulescorea.js` (790,387 bytes), and `modules.js`
(4,015,848 bytes). `env.js`, `scripts.js`, and `template-cache.js` had current
2026 `Last-Modified` and `ETag` headers, but no observed `Cache-Control` header.
No source-map reference was present at the end of the inspected bundles.

## 1. Executive summary

The owner entered credentials in the official page and authorized one click on
**Log in**. Login succeeded without a CAPTCHA or MFA prompt and the client
opened `/Private/student/diary/1`. A normal reload of the authenticated grades
route remained authenticated and did not show the login form.

The current official frontend has not replaced the legacy login with OAuth or a
bearer-token flow. It still defines:

1. client-side SHA-256 of the entered password;
2. `POST /ec-server/login` as form URL encoded data with fields `username`,
   `password`, and optional `device` JSON;
3. cookie credentials (`withCredentials: true`);
4. `GET /ec-server/state` as the authoritative session/bootstrap check.

It has, however, evolved materially: the web-device object is current and
persistent, CAPTCHA logic is integrated, and a `409 MFA_REQUIRED` challenge
flow supports EMAIL and TOTP factors. The production client also uses
`GET /ec-server/student/getDiaryPeriod_`—with the underscore—as its canonical
period-grades endpoint. The non-underscored legacy endpoint is absent from the
current frontend bundle.

Grades are loaded as two dynamic requests: `getDiaryUnits` for subjects and
aggregates, then `getDiaryPeriod_` for nested lessons, assessment parts, and
marks. The UI displays all subjects in one grid, so there is no per-subject
network request in this screen. A period change repeats both requests.

The official client opens an authenticated Server-Sent Events channel at
`/ec-server/events`; when EventSource is unavailable it polls
`/ec-server/eventsList?lastEventId=...` every 30 seconds. The declared events
include `PART_UPDATED`, but no mark/grade-specific event exists in the client
and the handler does not refresh the grades screen. This is therefore useful
future research, not a proven replacement for grade polling.

The best engineering direction is to update parsing and session boundaries
first, not implement background work. A background checker can plausibly be
one `getDiaryPeriod_` request after IDs and subject metadata are cached, but a
fully reliable grade identity still requires confirmation of the exact roles of
the observed mark identifiers against official frontend behavior.

## 2. What changed since legacy eCalculator

| Area | Legacy eCalculator assumption | Current official client evidence |
|---|---|---|
| Login | SHA-256 + form login + device | Core mechanism still exists; device schema/version, CAPTCHA, and MFA have evolved |
| Client version | hard-coded `v.1588` | derived from the deployed build; current value is `v.4207` |
| Device identity | hard-coded device ID, randomized token per login | persistent 32-character device ID and persistent per-login-name 64-character push token |
| MFA | unsupported | `409 MFA_REQUIRED`, factor selection, verification, status, and cancellation |
| Session | saved `JSESSIONID`; `/state` | `/state` remains the private-state gate; authenticated reload succeeded |
| Grades path | `/student/getDiaryPeriod` | `/student/getDiaryPeriod_` is used by `StudentMarks` |
| Grades shape | flat rows with `markVal`/`mktWt` | nested lesson → `part[]` → `mark[]`, normalized by the controller |
| Diary | `/student/diary` with `userId` | `/student/getPrsDiary` with `prsId`, `d1`, `d2` |
| Homework list | derived from the legacy diary response | `/student/getLPartListPupil` for the dedicated Tasks page |
| Live updates | none | authenticated SSE plus a cursor-based fallback event list, but no proven grade event |
| Error handling | app-level retry/re-login | official UI logs out/shows login on 401, shows a 403 dialog, and does not define a 429 retry |

These differences explain multiple likely incompatibilities, but this audit
does not claim that any single one caused the summer outage without observed
network errors from eCalculator itself.

## 3. Current authentication flow

### OBSERVED OFFICIAL PAGE

- Initial navigation ended at `/Main`, titled `eSchool - Вход в систему`.
- The DOM field names were `username` and `inputPassword`.
- The owner filled them manually; their values were never read or exported.
- One authorized click on **Log in** succeeded and navigated to
  `/Private/student/diary/1`.
- No CAPTCHA or MFA prompt appeared for this account in this login.

The HTML form metadata points at `/Main`, but the Angular controller intercepts
the action. It is not evidence of a credential-bearing GET.

### PUBLIC FRONTEND CODE

The current `Auth` factory defines:

```text
POST /ec-server/login
Content-Type: application/x-www-form-urlencoded
withCredentials: true

username=<encoded login>
password=<encoded SHA-256 hex derivative>
device=<encoded JSON, when supplied>
```

The controller computes the SHA-256 hex derivative in the browser and clears
its password model. Plaintext is therefore present only in the local input and
JavaScript memory before hashing; the defined API body contains the derivative,
not plaintext. Transport is HTTPS. The derivative remains reusable credential
material and must be protected like a password.

The current device JSON fields are:

| Field | Current web-client behavior |
|---|---|
| `cliType` | `web` |
| `cliVer` | current derived client version (`v.4207` for this build) |
| `pushToken` | persistent 64-character random value, scoped by normalized login name |
| `deviceId` | persistent 32-character random value |
| `deviceName` | detected browser name |
| `deviceModel` | detected browser major version |
| `cliOs` | detected OS name plus CPU architecture when available |
| `cliOsVer` | detected OS version or null |

CAPTCHA support is current, even though it did not appear here:

- `GET /ec-server/captcha/type`
- `GET /ec-server/showRecaptcha?username`
- `GET /ec-server/captcha/start?lang`
- GOOGLE mode appends the reCAPTCHA response to the SHA-256 hex string.
- IMAGES mode appends the CAPTCHA request and selected response.

MFA is triggered by HTTP 409 with response code `MFA_REQUIRED`. The client
expects `challengeToken`, `factors`, and `expiresAt`, supports EMAIL and TOTP,
and defines:

- `POST /ec-server/mfa/auth/select` — `challengeToken`, `factorId`
- `POST /ec-server/mfa/auth/verify` — `challengeToken`, `code`, `device`
- `POST /ec-server/mfa/auth/status` — `challengeToken`
- `POST /ec-server/mfa/auth/cancel` — `challengeToken`

No explicit CSRF header or token is present in this login definition. Cookie
SameSite behavior may provide protection, but cookie flags were not observable.

The current frontend references cookie names `JSESSIONID`, `route`, and
`es_username` when cleaning login/logout state. It does not prove which names
were issued in this account's response. `document.cookie` exposed no names in
the authenticated page, which is consistent with an HttpOnly session cookie
but does not prove HttpOnly, Secure, SameSite, domain, path, or expiry.

## 4. Current session lifecycle

### OBSERVED OFFICIAL PAGE

Reloading `/Private/studentMarks` kept the same private route and title and did
not show the login form. No credential entry or MFA action was repeated.
Accessible localStorage/sessionStorage and JavaScript-visible cookie name lists
were empty in the safe inspection. No IndexedDB database or service-worker
registration was found before login.

### PUBLIC FRONTEND CODE

The private-state resolver performs:

```text
Browser/private route
→ GET /ec-server/state  (with credentials)
→ authenticated == true
→ install returned user/profile/org/menu/parameter state
→ initialize timers and private route
```

`/state` is authoritative. Local keys `already_authorized` and
`auth_last_login` are UI hints, not a substitute for server validation.
`GET /ec-server/isAuthorized` is also used for explicit checks and before an
SSE reconnect. The login request is not automatically repeated by the official
session-restoration path.

The evidence strongly indicates a cookie-based session rather than a bearer
access/refresh-token flow: all relevant calls use `withCredentials`, the code
manages historical cookie names, no Authorization-token store is present, and
reload restored the session. Actual `Set-Cookie` metadata and any token
rotation remain unobserved.

## 5. Current application bootstrap

The current base URL is `/ec-server`. Relevant PUBLIC FRONTEND CODE sequence:

1. application startup requests `/srv/sysTime` and `/captcha/type`;
2. entry to `Private` resolves `/state`;
3. the `/state` response supplies authentication state plus user, profile,
   organization, menu, and school-parameter structures;
4. the client initializes SSE/timers and loads full group types;
5. route-level resolves load academic years and dictionaries;
6. student initialization may call `/usr/getClassByUser?userId` and group
   detail methods.

Other profile/language/organization calls are role- and feature-dependent.
They are not required for a narrow eCalculator grade reader merely because the
full web UI loads them.

The most relevant bootstrap data classes are:

| Data | Current source | Nature |
|---|---|---|
| session, user, current position, menu, school flags | `GET /state` | session/user-specific |
| server clock | `GET /srv/sysTime` | dynamic but small |
| academic years | `GET /yearplan/academyears` | semi-static, in-memory cached |
| classes for student | `GET /usr/getClassByUser?userId` | semi-static, keyed in-memory cache |
| periods for a class | `GET /dict/periods/0?groupId` | semi-static; no cache in this specific helper |
| mark and attendance dictionaries | dictionary/journal services | static or semi-static, several are memory/local cached |

## 6. Current grades protocol

### OBSERVED OFFICIAL PAGE

- Official route: `/Private/studentMarks`
- Page title: `eSchool - Оценки за период`
- Declared route query names: `yearId`, `eiId`, `groupId`, `userId`
- A normal reload restored the page without login.

### LIVE PRODUCTION EVIDENCE (Windows, privacy-safe)

- `GET /ec-server/student/getDiaryUnits/` returned HTTP 200.
- `GET /ec-server/student/getDiaryPeriod_` returned HTTP 200 with a populated
  result (approximately 219 KB). No values, IDs, or response body were retained.
- The observed field-only response shape was:

```text
lesson: lessonId, unitId, classId, startDt, subject, teacherFio, teacherId, part[]
part:   lesPartId, lptName, lptColor, markSysCode, markSysId, mrkWt, maxpoint,
        isBonus, isDone, isVerified, mark[]
mark:   markId, markValId, markNum, markValue, markDt, isUpdated
```

### PUBLIC FRONTEND CODE

`StudentMarks` resolves the current class, loads periods with
`GET /dict/periods/0?groupId`, chooses the explicit, default, or current period,
then performs:

1. `Journal.getMarksDictionary()` (normally cached);
2. `GET /student/getDiaryUnits/?userId&eiId`;
3. `GET /student/getDiaryPeriod_?userId&eiId`.

Both response wrappers are normalized as `response.result` when present, or
the top-level response otherwise.

`getDiaryUnits` is treated as an array of subject/aggregate rows. Fields used
by the UI include:

```text
unitId, unitName, groupId, groupName, markSysId,
overMark, totalMark, rating, ttlMarkSysId, ttlLackId,
ttlIsSum, ttlEiId, ttlEiName, ttlFactUnitMaxpoint,
ttlPlanUnitMaxpoint, ignoreFactTotalMaxpoint, sugTotalMark
```

`getDiaryPeriod_` is treated as an array of lesson rows. Fields used include:

```text
lesson: startDt, lessonId, unitId, classId, teacherFio, tchrs, part[], pres[]
part:   lesPartId (canonical current identifier), lptName, lptColor, markSysCode, mrkWt, maxpoint,
        teacherComm, mark[]
mark:   markId, markValId, markNum, markDt, markValue, isUpdated, crUseId, crLabel, teacherFio
```

The controller converts `part.mark` into `part.marks` and `part.marksCr` and
then deletes the original property. All subjects are rendered in one grid; a
"subject switch" does not exist in this screen and costs zero API requests.
A period switch re-runs both dynamic grade requests.

The official bundle contains no `/student/getDiaryPeriod` path without the
underscore. It does contain active implementations of `/student/getPrsDiary`,
`/student/getPupilUnits`, and `/student/getDiaryUnits`. It contains no
`/reports/data/get_plan_success` string. Thus:

- `getDiaryPeriod_` is the canonical current period-grades path;
- `getDiaryPeriod` is a legacy eCalculator assumption and was not actively
  probed;
- `getPupilUnits` still exists (`yearId`, `prsId`) but is not used by the
  `StudentMarks` route;
- the old report endpoint has no current frontend corroboration.

## 7. Stable grade identity analysis

The current grid has stable parent identifiers `lessonId`, `lesPartId`, and
`unitId`; `partId` is retained only as a defensive historical parser fallback.
Criteria marks additionally expose `crUseId`. `markNum` is now **LIVE
CONFIRMED** in a populated `getDiaryPeriod_` response. The diary controller's
current mark objects are sorted by `partID`, `markNum`, `crLabel`, and
`crUseId`, which strongly suggests that `markNum` is the disambiguating ordinal
when multiple marks occur in one lesson part.

`markId` and `markValId` are both **LIVE CONFIRMED** in the same mark object.
Neither must automatically be treated as a grade-instance ID: their exact
semantic roles still need verification against official frontend behavior
before finalizing notification diff identity.

Best currently supported composite key:

```text
(lessonId, lesPartId, crUseId-or-null, markNum-if-present)
```

Subject `unitId` and period `eiId` should be included in the snapshot namespace,
not relied on as the mark's unique identity. Mutable state should include the
grade value, `markDt`, assessment weight (`mrkWt`), `maxpoint`, and update flag.

Provisional diff rules while mark-ID semantics remain unverified:

- key only in new snapshot → added grade;
- same key, changed value/weight/maxpoint → changed grade;
- key only in old snapshot → deleted grade.

Until the roles of `markId` and `markValId` are verified, two equal grades in
the same part cannot be matched perfectly in every case. A sorted
multiset/ordinal fallback can detect count changes, but it cannot reliably
distinguish edits from delete-plus-add. That is the most important remaining
schema uncertainty.

## 8. Current homework/diary protocol

### Diary

The official diary route is `/Private/student/diary/1`; the controller supports
previous/current/next-week UI actions. Its current request is:

```text
GET /student/getPrsDiary?prsId&d1&d2
```

The response is consumed as an object containing `lesson[]` and `user[]`.
Lesson fields used include `id`, `date`, `numInDay`, `duration`, `unit`,
`clazz`, `part[]`, and teacher data. The selected user's entry supplies
`mark[]` and `attend[]`; mark fields used include `lessonID`, `partID`,
`markNum`, `value`, `markDt`, `crUseId`, and grading-system metadata. Homework
parts are collected from lesson `part[]` objects with `hasTask`/category,
deadline, variant, attachment, timing, and completion fields.

A week change issues one `getPrsDiary` request. If the accumulating grade
system is active, the controller may additionally request
`getDiaryEstMark(userId, yearId)`.

### Dedicated homework/tasks page

The route is `/Private/homeworks` with query names:

```text
yearId, groupId, parentGroupId, unitId, teacherId, d1, d2
```

For a student/parent/guest, the core list request is:

```text
PUT /student/getLPartListPupil
query: catIds, isOdod, yearId, begDate, endDate, prsId
body: selected unit IDs
```

Despite HTTP PUT, this method is used by the official UI as a read operation.
The response is consumed as an object with `result[]`; list entries include
part/lesson identity, subject/group/teacher metadata, category, due date,
preview, assessment, visibility/time-limit, completion, and attachment-count
fields.

Opening one task uses:

```text
GET /student/getLPartPupil?partId&prsId
```

The detail response is consumed through `result[0]`, `po_files.attach`, and
`po_vars`. Attachment metadata fields used include `fileId`, `fileName`,
`fileType`, `fileSize`, result/owner/variant metadata, and annotations. Public
code constructs download paths under `/files/HOMEWORK_VARIANT/{varId}/{fileId}`
and `/files/LES_PART_RESULT/{partId}/{fileId}`. No attachment was downloaded.
No completion checkbox or other mutating control was invoked.

## 9. Academic years, periods, and subjects

| Concept | Current official source | Important fields/behavior |
|---|---|---|
| academic years | `GET /yearplan/academyears` | `yearId`, names, state, full start/end dates; in-memory cached |
| student classes | `GET /usr/getClassByUser?userId` | `groupId`, `yearId`, dates; cached per user in the service |
| class periods | `GET /dict/periods/0?groupId` | object with `items[]`; item `id`, `name`, `date1`, `date2`, `level`, `study`, `extra` |
| subjects for selected period | `GET /student/getDiaryUnits?userId&eiId` | `unitId`/`unitName` plus dynamic aggregates |
| alternate yearly unit list | `GET /student/getPupilUnits?yearId&prsId` | current service exists; not used by period-grades UI |

The `StudentMarks` screen obtains the class before periods, and periods before
grades. It does not request a subject after clicking a row because the entire
period grid is loaded together.

## 10. Caching behavior

PUBLIC FRONTEND CODE caches some dictionaries and academic/class data in
memory, and stores selected dictionaries in prefixed browser storage. The
specific `getPeriod(0, groupId)`, `getDiaryUnits`, `getDiaryPeriod_`,
`getPrsDiary`, and homework-list helpers do not implement their own response
cache. Authenticated HTTP cache headers were not observable.

Recommended eCalculator policy:

| Data | Suggested policy | Invalidate when | Evidence |
|---|---|---|---|
| `/state` identity/current position | current session only | logout, 401, account/position change | authoritative session bootstrap |
| academic years | persistent, 30 days | session identity/org/protocol change, manual refresh | semi-static; official memory cache |
| classes | persistent, 30 days | session identity/org/year/protocol change, manual refresh | official per-user memory cache |
| periods | persistent, 30 days | class/year/session/protocol change, manual refresh | structurally semi-static |
| subject ID/name projection | persistent, 24 hours | period/class/session/protocol change or unseen `unitId` | names static, but same response has dynamic totals |
| totals/rating from `getDiaryUnits` | do not inherit long subject cache | each foreground grade refresh | dynamic aggregate data |
| marks snapshot | last successful snapshot only | each explicit/background check | dynamic diff source |
| diary/homework | 15–60 minutes plus manual refresh | date range changes, relevant event hint | deadline/completion data changes |
| mark/dictionary metadata | persistent, 7 days | session/protocol/configuration change, manual refresh | official memory/local caching |

eCalculator implements this as a memory-fronted, versioned
`SharedPreferencesAsync` cache with one prefixed preference per typed metadata
record. Independent records avoid whole-cache read-modify-write updates across
foreground and future background isolates. Cache keys include a hashed,
normalized account identity plus user, current position, organization, relevant
year/group/period identifiers, and schema/protocol versions. Corrupt or
version-mismatched entries are discarded. Logout, session identity changes,
and explicit academic-metadata invalidation clear both memory and persistence;
device identity is kept separate.

Dynamic totals, averages, grades, homework, credentials, cookies, MFA tokens,
and raw private responses are never persisted in this cache. Every explicit
grade refresh still calls `getDiaryPeriod_`; once the metadata projection is
warm, that preserves a future one-request grade-check path without adding a
worker or notification behavior here.

The live Windows trace contained three closely spaced
`/usr/getClassByUser` requests before period resolution. The current local
`getOrLoad` cache does not coalesce concurrent cold misses, so this is a
plausible explanation. It is recorded as a later optimization rather than
changing cache concurrency behavior as part of this narrow schema correction.

A later Windows restart audit confirmed correct remembered-session behavior:
`/state` was the first authentication request, used the restored session, and
returned 200 without any `/login`. The same run nevertheless re-requested
academic years, classes, periods, and subjects despite previously warmed TTLs.
The cause is not inferred from that symptom. Fresh-login and restored-session
tests produce and reuse the same account-isolated metadata scope for identical
synthetic `/state` identity, so audit-only cache diagnostics now report safe
hit/miss reasons, initialization accepted/rejected counts, invalidation/clear,
and storage operation failures. They never include scopes, keys, preference
values, identifiers, or exception messages.

Homework is activated lazily at the main navigation layer. Constructing the
initial Calculator tab no longer mounts `HomeworkPage` or calls
`getPrsDiary`; the first Homework navigation mounts it once, and the existing
`IndexedStack` then preserves its state across tab switches.

## 11. Notification/live-update architecture

The official client defines:

```text
EventSource /ec-server/events
withCredentials: true
```

Registered event names are:

```text
MESSAGES_COUNT, TASKS_COUNT, NEW_MESSAGE, DEL_MESSAGE, UPD_MESSAGE,
UPD_THREAD, DEL_THREAD, TASKS_NEW, TASKS_UPDATE, ACTIONS_NEW,
ACTIONS_UPDATE, YOUR_CHANGES, WORKLOAD_CHANGED, REPORT_DONE,
REPORT_PROGRESS, PART_UPDATED, FILE_STATE_CHANGED, SESSION_TERMINATED
```

On an SSE error that is not a normal reconnect state, the client closes the
source, waits five seconds, calls `/isAuthorized`, and reconnects if authorized.
If EventSource is unavailable, it calls:

```text
GET /ec-server/eventsList?lastEventId
```

every 30 seconds and updates `lastEventId` from received events.

There is no `MARK_UPDATED`, `GRADE_UPDATED`, or grades refresh handler in the
current bundle. `PART_UPDATED` merely shows a part/task toast in the inspected
handler. It might be emitted for a grade-related lesson-part mutation, but that
was not observed and must not be assumed. No application-specific WebSocket,
Firebase, Web Push subscription, or grade delta endpoint was established.
Generic WebSocket/SockJS strings in dependency bundles are not counted as
feature evidence.

## 12. Automatic polling behavior

The `StudentMarks` controller contains no timer or auto-refresh loop. A
35-second idle observation left the authenticated grades route/title unchanged;
network traffic could not be counted. The source-defined background mechanisms
are:

- SSE `/events` under normal browser support;
- 30-second `/eventsList` polling only as the EventSource fallback;
- news digest approximately every 200 seconds;
- local 5-second schedulers for task/action due times, which call their digest
  endpoints only initially or when the server-supplied next-update time arrives;
- a one-second local message scheduler that calls the count endpoint only when
  an internal flag requests a check.

None of these repeatedly fetches `getDiaryPeriod_`. Therefore the official
grades screen does not appear to poll the whole grade dataset while idle.

## 13. Error/retry behavior

No errors were deliberately triggered. PUBLIC FRONTEND CODE shows:

- **401:** mark local authorization failed, cancel SSE/timers, remember the
  current private route, and show Login. It does not submit `/login` again.
- **403:** mark authorization failed and show the forbidden dialog; no bypass.
- **429:** login/MFA UI has a “too many attempts, try later” message; the global
  interceptor defines no automatic 429 retry.
- **503 and network status 0:** the global interceptor retries unless
  `skipRetry` is set, with increasing delay and a bounded time/count condition;
  login explicitly sets `skipRetry`.
- **MFA expiry/lock:** challenge state is expired/cleared; the user must restart
  or try later depending on the error.
- **SSE failure:** validate with `/isAuthorized`, then reconnect after five
  seconds; do not re-login.

eCalculator should adopt the safe 401/403/429 behavior, but it should use a
simpler, explicitly bounded background policy rather than copying the web
interceptor's general retry expression.

## 14. Protocol ledger

| Method | Endpoint | Triggering UI action | Auth | Parameters/body names | Response shape used | Cache behavior | Source | Confidence | eCalculator relevance |
|---|---|---|---|---|---|---|---|---|---|
| navigation | `/Main` | open site | public | `orgId`, `esialink`, `session_state`, `code` route params | login HTML/app | public asset cache only | Observed official page | OBSERVED | entry point |
| POST | `/ec-server/login` | Log in | establishes session | form: `username`, `password`, `device` | success or coded login/MFA error | no retry | Official frontend bundle | STRONGLY CORROBORATED | must support current device/CAPTCHA/MFA |
| POST | `/ec-server/mfa/auth/select` | choose factor | challenge | `challengeToken`, `factorId` | expiry/target hint | none | Official frontend bundle | STRONGLY CORROBORATED | foreground login only |
| POST | `/ec-server/mfa/auth/verify` | submit MFA code | challenge | `challengeToken`, `code`, `device` | authenticated login result | none | Official frontend bundle | STRONGLY CORROBORATED | foreground login only |
| GET | `/ec-server/state` | private entry/reload | cookie | none | `authenticated`, user/profile/org/menu/params structures | authoritative, not long cached | Official frontend bundle + restored UI | STRONGLY CORROBORATED | session validation/bootstrap |
| GET | `/ec-server/isAuthorized` | explicit check/SSE reconnect | cookie | none | authorization result | none | Official frontend bundle | STRONGLY CORROBORATED | optional; not needed before every grade check |
| GET | `/ec-server/srv/sysTime` | app startup | cookie/default credentials | none | server time value | none shown | Official frontend bundle | STRONGLY CORROBORATED | usually unnecessary |
| GET | `/ec-server/yearplan/academyears` | route resolve | cookie | none | academic year array | in-memory | Official frontend bundle | STRONGLY CORROBORATED | cacheable metadata |
| GET | `/ec-server/usr/getClassByUser` | initialize student/year | cookie | `userId` | class/year array | in-memory by user | Official frontend bundle | STRONGLY CORROBORATED | obtain `groupId` |
| GET | `/ec-server/dict/periods/0` | initialize/switch class | cookie | `groupId` | object with `items[]` | helper does not cache | Official frontend bundle | STRONGLY CORROBORATED | obtain `eiId` |
| GET | `/ec-server/student/getDiaryUnits/` | open/switch grade period | cookie | `userId`, `eiId` | subject/aggregate array or `result` | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | subject map + dynamic totals |
| GET | `/ec-server/student/getDiaryPeriod_` | open/switch grade period | cookie | `userId`, `eiId` | nested lesson/part/mark array or `result` | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | canonical grades snapshot |
| GET | `/ec-server/student/getPupilUnits` | alternate analytics flows | cookie | `yearId`, `prsId` | not inspected | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | optional, not grade-screen dependency |
| GET | `/ec-server/student/getPrsDiary` | open/change diary week | cookie | `prsId`, `d1`, `d2` | object with `lesson[]`, `user[]` | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | current diary/homework source |
| PUT | `/ec-server/student/getLPartListPupil` | open/filter homework list | cookie | query: `catIds`, `isOdod`, `yearId`, `begDate`, `endDate`, `prsId`; body: unit IDs | object with `result[]` | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | dedicated homework list |
| GET | `/ec-server/student/getLPartPupil` | open homework detail | cookie | `partId`, `prsId` | `result[0]`, `po_files`, `po_vars` | no helper cache | Official frontend bundle | STRONGLY CORROBORATED | detail/attachments |
| SSE | `/ec-server/events` | private session initialization | cookie | EventSource cursor managed by browser | named events | persistent connection | Official frontend bundle | STRONGLY CORROBORATED | possible hint channel, not proven for grades |
| GET | `/ec-server/eventsList` | EventSource unavailable | cookie | `lastEventId` | event array | 30-second fallback poll | Official frontend bundle | STRONGLY CORROBORATED | do not copy unless justified |
| GET | `/ec-server/student/getDiaryPeriod` | legacy eCalculator | cookie | `userId`, `eiId` | legacy flat rows | n/a | Current eCalculator | HISTORICAL | replace; absent from official bundle |
| GET | `/ec-server/student/diary` | legacy eCalculator | cookie | `userId`, `d1`, `d2` | legacy diary expectation | n/a | Current eCalculator | HISTORICAL | replace with current flow |

No row is labelled “Observed official network” because that capture facility
was unavailable.

## 15. Legacy vs current comparison

| Concern | Legacy eCalculator | Current official eSchool | Change required |
|---|---|---|---|
| login | SHA-256 + form login | same core, current device + CAPTCHA + MFA | refresh client identity; model challenge states |
| password handling | stores reusable derivative | derivative still submitted | secure storage; never log; foreground only |
| session | cookie map, auto re-login | cookie session, `/state`, no automatic login on 401 | separate validate from login; remove implicit retry-login |
| state/bootstrap | `/state` | still authoritative | retain with current schema and `authenticated` check |
| user identity | top-level `userId` assumption | state has rich user/current-position structures | parse defensively, bind cache to account/position |
| academic year | infer from class date strings | `/yearplan/academyears` plus class data | use structured year fields |
| period | `/dict/periods/0` | still used | retain; cache by class/year |
| subjects | `getDiaryUnits` | still used, contains dynamic aggregates | separate metadata from totals |
| grades | `getDiaryPeriod` flat shape | `getDiaryPeriod_` nested shape | replace path/parser and add fixtures |
| stable grade ID | lesson/value-oriented | composite lesson/`lesPartId`/criterion/ordinal; `markNum` live-confirmed, mark-ID semantics unconfirmed | verify `markId`/`markValId` roles before final diff contract |
| diary | `/student/diary?userId` | `getPrsDiary?prsId&d1&d2` | replace path, identity, and schema |
| homework | derived from diary | dedicated list/detail methods | decide whether diary or dedicated view fits product needs |
| refresh | eager repeated data loads | route-driven; no grades timer | cache static IDs; explicit refresh/snapshot |
| notification | none | SSE exists, grade signal unproven | research `PART_UPDATED`; retain conservative polling fallback |

## 16. Request-count and bandwidth analysis

Exact counts and response bytes require network capture and are **unknown**.
The following are source-derived lower bounds for relevant API work, excluding
unrelated profile/menu/news/task features and browser asset requests:

| Flow | Core requests implied by current frontend |
|---|---|
| fresh login | 1 `/login` + 1 `/state`; CAPTCHA/MFA add requests only when required |
| private bootstrap | 1 `/state`, then route/role dictionaries and metadata |
| cold open grades | class/period/dictionary resolves as needed + 2 dynamic grade requests |
| warm open grades | 2 dynamic requests: `getDiaryUnits`, `getDiaryPeriod_` |
| switch subject | 0; all subjects are already in the grid |
| switch period | 2 dynamic grade requests |
| change diary week | 1 `getPrsDiary`, optionally 1 `getDiaryEstMark` |
| open homework list | 1 core `getLPartListPupil`, plus cold route dictionaries |
| open one homework | 1 `getLPartPupil`; attachment download only on user action |
| valid session reload | 1 `/state`, followed by the active route's normal loads |

No API response-size estimate is provided. The public JavaScript/template
bundle sizes at the start of this report are not a proxy for API bandwidth.

## 17. Recommended eCalculator architecture

1. Introduce a strict session state machine: `unknown`, `valid`, `expired`,
   `blocked`, `rateLimited`, `mfaRequired`.
2. Make foreground login the only component allowed to use the reusable
   credential derivative or solve CAPTCHA/MFA.
3. Persist only the session cookie jar and current account/position binding in
   secure storage; validate with `/state` when the foreground needs full state.
4. Replace `getDiaryPeriod` parsing with a typed nested
   `getDiaryPeriod_` model and sanitized fixtures.
5. Split subject metadata from dynamic aggregates returned by
   `getDiaryUnits`.
6. Store canonical snapshots keyed by account + position + year + period.
7. Centralize status handling: no auto-login in generic GET/PUT, no 403/429
   retry, bounded transient handling only.
8. Add a protocol version/capability boundary so future eSchool changes do not
   leak throughout UI/domain code.

The next implementation should be the typed current grades/session adapter and
tests—not WorkManager.

## 18. Recommended notification architecture

Do not depend on SSE for grade notifications until a normal teacher-created
grade change demonstrates a sanitized event reason/schema. For the first safe
version, schedule infrequently and use cached IDs:

```text
saved cookie session + cached userId/eiId
→ one GET /student/getDiaryPeriod_?userId&eiId
→ 200: parse, diff, atomically store snapshot, emit local notification
→ 401: mark session expired; disable background monitoring until foreground login
→ 403: stop monitoring; no retry or bypass
→ 429: stop and apply a long user-visible cooldown; no loop
→ 5xx/timeout/offline/parse error: keep old snapshot and exit until a later schedule
```

Do not call `/state` before every background grade request; the grade request
itself tests whether the cookie is accepted. Do not call `getDiaryUnits` in the
steady-state worker after the subject map is cached. Refresh metadata only in
foreground or on an unknown ID/schema/version condition.

This reaches one eSchool request per check. If a future controlled observation
proves that `PART_UPDATED` reliably carries grade identity for students, use it
as a foreground hint or platform-supported push input; do not keep an Android
process alive solely to hold the web SSE connection.

## 19. Things we should explicitly not copy from eMarks/reSchool

- proxy/IP/User-Agent/device/fingerprint rotation;
- a hard-coded browser version, OS, push token, or shared device ID;
- retry loops after 401, 403, 429, CAPTCHA, MFA lock, or blocking;
- automatic background `/login` with a saved password derivative;
- guessing endpoint variants or probing hidden/admin paths;
- treating PUT as safe merely by method name—only the observed official
  read-style homework method is in scope;
- raw HAR, Cookie, Set-Cookie, token, profile, grade, or homework logging;
- response-body persistence for diagnostics;
- `markId` as a grade-instance key without schema proof;
- fixed long cache durations copied without account/year/period invalidation;
- a permanent backend, Firebase, or WorkManager before the protocol adapter is
  correct;
- any action that sends chat, uploads/submits homework, changes settings, or
  attempts to bypass access controls.

## 20. Unknowns requiring further observation

One short follow-up with a real Chrome/CDP network surface is still needed to
close these gaps:

1. actual login/status redirect sequence and `Set-Cookie` names/flags/lifetime;
2. actual `/state` and grades response byte sizes, cache headers, and timing;
3. first authenticated request ordering and exact normal-flow counts;
4. the exact frontend semantics of `markId` and `markValId` in a populated
   `getDiaryPeriod_` mark object, including whether either is an instance ID;
5. whether `PART_UPDATED` is emitted when a grade is added/changed/deleted and
   whether it is visible to the student account;
6. whether normal UI refreshes use conditional requests or browser cache;
7. exact cookie Secure/HttpOnly/SameSite/domain/path/expiry metadata;
8. actual 401/403/429 behavior from normal expiration only—never induced.

Until then, request sizes and a perfect duplicate-grade identity are explicitly
unresolved. Production API code was not changed in this audit.

## Concise answers A–J

**A. How does eSchool authenticate in August 2026?**
The current official frontend computes a SHA-256 hex derivative, sends
`POST /ec-server/login` as form URL encoded `username`, `password`, and current
device JSON over HTTPS with cookie credentials, then validates/bootstraps with
`GET /ec-server/state`. CAPTCHA and `409 MFA_REQUIRED` EMAIL/TOTP challenges
are supported. This is STRONGLY CORROBORATED by current code and a successful
official UI login; exact network headers/status/cookies were not captured.

**B. What replaced the old eCalculator login flow?**
Nothing wholesale. The same core endpoint and SHA-256/form/cookie design
remain, but the device identity/version, CAPTCHA handling, MFA challenge flow,
and session/error state are now richer. eCalculator's stale hard-coded device
metadata and missing challenge handling are incompatible assumptions.

**C. Does `/state` still matter?**
Yes. It is the authoritative private-route session restoration and bootstrap
request. `/isAuthorized` is a lighter auxiliary check, notably for SSE
reconnection.

**D. What is the canonical current endpoint/path for grades?**
`GET /ec-server/student/getDiaryPeriod_?userId&eiId`, paired by the official UI
with `GET /ec-server/student/getDiaryUnits/?userId&eiId`.

**E. What is the best stable identifier for a grade?**
Currently `(lessonId, lesPartId, crUseId-or-null, markNum-if-present)`,
namespaced by account/period. `markNum` is live-confirmed. `markId` and
`markValId` coexist in the live mark object, but neither is proven as a
grade-instance ID; verify their frontend semantics before freezing the diff
contract.

**F. Which data can eCalculator cache aggressively?**
Academic years, classes, periods, mark dictionaries, and the `unitId` → subject
name projection—with account/year/class/version invalidation. Do not cache
marks, homework, averages, totals, or ratings as static data.

**G. Is there an event/delta/push mechanism that avoids grade polling?**
There is authenticated SSE `/events` and a cursor-based `/eventsList` fallback.
No grade-specific event or automatic grades refresh was found. `PART_UPDATED`
is a research lead, not yet a reliable grade signal.

**H. If polling is necessary, what is the minimum safe flow?**
With a saved cookie and cached `userId`/`eiId`, one read-only
`getDiaryPeriod_` request, local diff, and local notification. Never perform
background login; stop on 401/403/429 and defer transient failures.

**I. What should eCalculator change first?**
Replace the legacy flat `getDiaryPeriod` adapter with typed nested
`getDiaryPeriod_` parsing, remove implicit re-login from generic requests, and
replace hard-coded device/client constants with a persistent current device
model. Confirm mark identity with one sanitized CDP capture before implementing
notifications.

**J. What should we absolutely not do?**
Do not probe or mutate, rotate identities, bypass controls, retry 403/429, log
secrets/private bodies, auto-login in background, assume `markId` or
`markValId` semantics, copy stale third-party cache/retry behavior, add
Firebase/backend/WorkManager, or change production protocol endpoints.
