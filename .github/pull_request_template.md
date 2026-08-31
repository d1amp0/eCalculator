## Summary

Describe the user-visible change and any protocol compatibility risk.

## Validation

- [ ] `dart format --output=none --set-exit-if-changed .`
- [ ] `flutter analyze --no-pub`
- [ ] `flutter test --no-pub`
- [ ] `flutter build apk --debug --no-pub`
- [ ] Tests use only synthetic fixtures/mocks and make no live eSchool calls.
- [ ] No credentials, cookies, account identifiers, private responses, or
      student data are included.
