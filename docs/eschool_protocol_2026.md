# eSchool integration protocol — August 2026

This document describes the protocol surface used by eCalculator v4. It is a
public integration contract, not a record of account activity. It contains no
credentials, cookie values, account or school identifiers, grades, homework,
profile data, raw responses, or private diagnostic output.

eCalculator is an unofficial client. The upstream service can change without
notice, so every protocol claim is either covered by synthetic tests or marked
as a privacy-safe live confirmation.

## Security boundary

- Authentication and academic requests travel directly between the app and
  `https://app.eschool.center/ec-server` over HTTPS.
- No eCalculator-owned backend receives credentials or session material.
- Reusable authentication material and the session cookie jar use operating
  system secure storage when Remember Me is enabled.
- Academic metadata persistence never stores credentials, cookies, MFA data,
  device secrets, raw `/state` data, grades, homework, or raw HTTP bodies.
- CI and automated tests use only synthetic fixtures, fakes, mocks, and local
  storage abstractions. They never call production eSchool.

## Current request surface

All paths below are relative to `/ec-server`.

| Method and path | Purpose | Parameters/body used by eCalculator |
|---|---|---|
| `POST /login` | Start a foreground session | form fields required by the current login flow |
| `GET /state` | Validate/bootstrap a fresh or restored session | session cookies |
| `GET /yearplan/academyears` | Resolve academic years | none |
| `GET /usr/getClassByUser` | Resolve classes | `userId` |
| `GET /dict/periods/0` | Resolve periods | `groupId` |
| `GET /student/getDiaryUnits/` | Resolve subject metadata | `userId`, `eiId` |
| `GET /student/getDiaryPeriod_` | Load the selected period's grades | `userId`, `eiId` |
| `GET /student/getPrsDiary` | Load the compact homework/diary projection | `prsId`, `d1`, `d2` |

The underscore in `getDiaryPeriod_` and the trailing slash in
`getDiaryUnits/` are intentional current protocol details. The legacy
`getDiaryPeriod` and `/student/diary` paths are not used by the v4 adapter.

## Authentication and session restoration

Fresh login is a foreground-only operation. After a successful `/login`, the
client validates and bootstraps the session through `/state`. Restoration uses
the saved cookie jar and calls `/state` directly; it does not submit `/login`
first. A rejected or unavailable restored session is surfaced to the app and
does not trigger an implicit credential replay from a generic request.

A privacy-safe Windows restart audit confirmed the intended remembered-session
path: `/state` returned HTTP 200 as a restored session and no `/login` request
occurred. Only method/path/status/session-use metadata was retained.

## Grades response contract

`getDiaryUnits/` provides the static subject projection used to name units.
Dynamic totals and ratings from that response are not placed in the long-lived
subject metadata cache.

`getDiaryPeriod_` returns nested lessons, assessment parts, and marks. A
non-empty production response and `getDiaryUnits/` were both privacy-safely
confirmed with HTTP 200. The field-only shape observed was:

```text
lesson: lessonId, unitId, classId, startDt, subject, teacherFio, teacherId, part[]
part:   lesPartId, lptName, lptColor, markSysCode, markSysId, mrkWt, maxpoint,
        isBonus, isDone, isVerified, mark[]
mark:   markId, markValId, markNum, markValue, markDt, isUpdated
```

The canonical current part identifier is `lesPartId`. The parser retains
`partId` only as a defensive historical compatibility fallback and never
fabricates an identifier.

`markNum` is **LIVE CONFIRMED** in a populated response. `markId` and
`markValId` are also **LIVE CONFIRMED** in the same mark object. Their exact
semantic roles have not been established against the official UI, so neither
is declared to be the permanent grade-instance identity. `isUpdated` is
optional and is parsed defensively from a boolean or the current integer 0/1
representation.

The current provisional structural identity is:

```text
(lessonId, lesPartId, crUseId-or-null, markNum-if-present)
```

It is suitable for preserving parsed structure, but notification diff identity
must not be finalized until the roles and stability of `markId` and
`markValId` are verified. Notifications are not implemented in this beta.

## Metadata cache

The cache stores independently versioned, typed projections. Current TTLs are:

| Kind | TTL | Persistent contents |
|---|---:|---|
| academic years | 30 days | parsed academic-year metadata |
| classes | 30 days | parsed class metadata |
| periods | 30 days | parsed period metadata |
| subjects | 24 hours | unit ID/name and mark-system projection only |

Records are scoped by a one-way account fingerprint plus the necessary
synthetic protocol identity dimensions. Account isolation is not weakened for
restored sessions. Logout, identity changes, protocol/schema changes, and
explicit invalidation clear or reject the relevant records.

Windows uses a dedicated SQLite database in the normal application-support
location (`eschool_metadata.db`, table `metadata_records`). Other supported
platforms use `SharedPreferencesAsync`. The SQLite table stores only a record
key and the existing versioned JSON envelope. It does not contain session or
student content.

Automated file-backed tests close one SQLite store instance, reopen the same
database through another instance, and cover multiple records, update, remove,
clear, and privacy-safe diagnostics. A later real Windows full-process restart
confirmed durable reuse after the SQLite change:

- cache initialization discovered 4 records, accepted 4, and rejected 0;
- academic years, classes, periods, and subjects were cache hits;
- the explicit dynamic grade load still requested `getDiaryPeriod_`, as
  designed.

Together with the restored `/state` result above, this confirms the Windows
metadata cache across an actual process restart for the controlled build. It
does not replace future release-build/device regression testing.

Cold concurrent misses are not currently coalesced. A trace once showed several
closely spaced class requests before period resolution; this remains a bounded
optimization opportunity rather than a protocol correctness change.

## Privacy-safe protocol diagnostics

Diagnostics are disabled by default and can be enabled at compile time with
`--dart-define=ESCHOOL_PROTOCOL_AUDIT=true`. Allowed cache output is limited to:

- event and cache kind;
- a fixed safe reason category;
- a verification boolean;
- discovered/accepted/rejected counts;
- visible prefixed-record count.

The diagnostic layer must never receive or print usernames, credentials,
cookies, session IDs, MFA material, raw cache keys/scopes, account or school
identifiers, stored values, exception text, preference values, HTTP bodies, or
grades/homework. Tests assert that representative sensitive synthetic values
cannot appear in audit output.

## Homework loading

The initial Calculator tab does not mount the Homework page or request remote
homework. The first navigation to Homework mounts it once and loads
`getPrsDiary`; subsequent tab changes preserve its state. Local task cleanup is
performed by SQLite row ID so duplicate task text cannot delete a newer row.
Demo mode remains memory-only.

## Known limitations before stable v4

- Upstream endpoint and schema compatibility cannot be guaranteed.
- CAPTCHA and MFA variants still require real-device release validation when a
  suitable account flow is available.
- The exact long-term semantics of `markId` and `markValId` are unresolved.
- No grade notification or background polling feature is included.
- Android release signing is intentionally external to this repository.

Any future live protocol check must be user-driven, read-only, minimal, and
transcribed only as aggregate metadata. Raw logs, HAR files, credentials,
session values, account identifiers, and private response bodies must never be
committed or attached to a public issue.
