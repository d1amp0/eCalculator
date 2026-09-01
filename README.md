# eCalculator

eCalculator is an unofficial Flutter application for students who use
[eSchool](https://app.eschool.center/). It helps students review marks, analyse
weighted averages, explore possible mark scenarios, and view homework.

> [!IMPORTANT]
> eCalculator is not affiliated with, maintained by, or endorsed by eSchool.

## Project status

Version `4.0.0-beta.1` is the first planned public v4 beta. Android is the
primary beta target. The beta focuses on the August 2026 eSchool protocol,
session restoration, privacy-safe local persistence, and deterministic offline
test coverage. Upstream eSchool changes can still affect compatibility.

## Features

- View eSchool marks grouped by subject.
- Calculate simple and weighted grade averages, including supported `+` and
  `-` mark modifiers.
- Explore mark scenarios without changing eSchool data.
- View eSchool homework and manage locally created tasks.
- Store theme, academic-period, and calculation preferences locally.

## Screenshots

Screenshots for the v4 interface will be added before the stable release.

## Supported platforms

Android is the primary supported target. Flutter project scaffolding is also
present for iOS, macOS, Linux, Windows, and web, but those targets are not yet
part of the v4 release validation matrix.

## Install and build

Stable builds will be published on the
[GitHub Releases](https://github.com/d1amp0/eCalculator/releases) page.

To build the current source:

```sh
git clone https://github.com/d1amp0/eCalculator.git
cd eCalculator
flutter pub get
flutter run
```

For an Android debug APK:

```sh
flutter build apk --debug --no-pub
```

### Android release signing

Release builds require an owner-managed upload keystore that is never stored
in this repository:

1. Create and securely back up your own Android upload keystore. Keep it for
   the lifetime of the application because future updates must use the same
   signing identity.
2. Copy `android/key.properties.example` to the local ignored file
   `android/key.properties`.
3. Replace every placeholder with the local keystore path, alias, and
   passwords. Never commit `key.properties`, a keystore, or signing secrets.
4. Build the signed release APK:

```sh
flutter build apk --release --no-pub
```

The output is `build/app/outputs/flutter-apk/app-release.apk`. A release build
fails with a clear configuration error when the local signing file is absent
or incomplete; debug builds do not require it.

## Development

Use Flutter 3.47.0 stable with Dart 3.13.0 or newer. Before opening a pull
request, run:

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

The automated CI workflow runs the same checks without requiring an eSchool
account or repository secrets.

## Security and privacy

Authentication requests are sent directly from the device to eSchool. This
project does not operate a backend that receives eSchool usernames, passwords,
derived credentials, or sessions. Password-derived authentication material is
used only for an explicit foreground login and is discarded after the login
attempt. When Remember Me is enabled, the authenticated session cookies and
required session identity metadata are stored using the operating system's
secure storage. Non-sensitive preferences remain in local app storage.

If Remember Me is disabled, authenticated session state is kept only in memory
for the current app process. Restored-session data never contains the plaintext
password or its derivative, and generic requests do not replay credentials. If
secure storage is unavailable, the app does not fall back to storing session or
credential material in SharedPreferences.

No software can make an absolute security guarantee. Please report suspected
vulnerabilities according to [SECURITY.md](SECURITY.md), and never include
credentials, session cookies, or student data in a public issue.

Android v4 uses the application ID `com.d1amp0.ecalculator` and requires
Android 7.0 (API 24) or newer. Older builds used `com.example.hello`; Android
therefore treats v4 as a different application, so it cannot update those
builds in place. Android Auto Backup is disabled to prevent secure-storage
ciphertext from being restored without its device-bound key.

## eSchool integration disclaimer

eCalculator depends on eSchool services at
`https://app.eschool.center/ec-server`. Availability and compatibility can be
affected by upstream changes. Users and contributors are responsible for
following applicable school policies and eSchool terms.

## Contributing

Practical contribution guidance is available in
[CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and focused pull requests are
welcome, but examples and fixtures must never contain real student data or
authentication material.

## License

eCalculator is available under the [MIT License](LICENSE).
