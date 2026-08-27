# eCalculator

eCalculator is an unofficial Flutter application for students who use
[eSchool](https://app.eschool.center/). It helps students review marks, analyse
weighted averages, explore possible mark scenarios, and view homework.

> [!IMPORTANT]
> eCalculator is not affiliated with, maintained by, or endorsed by eSchool.

## Project status

Version 4 is in active preparation. This repository currently focuses on a
safer authentication foundation, maintainable project structure, automated
checks, and release readiness while preserving the existing interface.

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

For an Android APK:

```sh
flutter build apk --release
```

Release signing is intentionally not configured in the repository.

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

Authentication requests are sent directly from the application to eSchool.
The project does not intentionally send a user's eSchool password to an
eCalculator-owned backend. eSchool's reusable derived authentication credential
and persistent session information are stored through the operating system's
secure storage. Non-sensitive preferences remain in SharedPreferences.

If “Remember me” is disabled, reusable authentication material is kept only in
memory for the current app process. If secure storage is unavailable, the app
does not fall back to storing credentials in SharedPreferences.

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
