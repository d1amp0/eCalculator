# Contributing to eCalculator

Thank you for helping improve eCalculator.

1. Open an issue for substantial behavior or protocol changes before coding.
2. Create a focused branch from `master` and keep unrelated refactors out of
   the same pull request.
3. Never commit real credentials, cookies, student data, private school data,
   signing files, or production account fixtures.
4. Add or update offline tests for changed logic. Tests must not require a live
   eSchool account.
5. Run formatting, analysis, tests, and an Android debug build before opening
   the pull request.

Never add live eSchool integration tests. Protocol tests must use synthetic
fixtures, fakes, mocks, or local HTTP abstractions. Diagnostic output must be
reduced to documented metadata-only fields before it is shared or committed.

Keep eSchool protocol changes conservative and explain compatibility risks in
the pull request. By contributing, you agree that your contribution is licensed
under the MIT License.
