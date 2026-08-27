import 'package:ecalculator/domain/academic_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('academic year rolls over in August', () {
    expect(
      AcademicCalendar.currentYear(now: DateTime(2026, 7, 31)),
      '2025/2026',
    );
    expect(
      AcademicCalendar.currentYear(now: DateTime(2026, 8, 1)),
      '2026/2027',
    );
  });

  test('recent years are derived rather than hardcoded', () {
    expect(AcademicCalendar.recentYears(now: DateTime(2026, 9, 1)), [
      '2026/2027',
      '2025/2026',
      '2024/2025',
    ]);
  });

  test('quarter fallback follows the Russian academic year', () {
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2026, 9, 1)),
      '1 четверть',
    );
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2026, 12, 1)),
      '2 четверть',
    );
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2027, 2, 1)),
      '3 четверть',
    );
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2027, 4, 1)),
      '4 четверть',
    );
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2027, 5, 31)),
      '4 четверть',
    );
  });

  test('summer has no inferred current quarter', () {
    for (final month in [DateTime.june, DateTime.july, DateTime.august]) {
      expect(
        AcademicCalendar.currentQuarter(now: DateTime(2027, month, 1)),
        isNull,
      );
    }
  });

  test('quarter fallback rolls from summer into the next school year', () {
    expect(AcademicCalendar.currentQuarter(now: DateTime(2027, 8, 31)), isNull);
    expect(
      AcademicCalendar.currentQuarter(now: DateTime(2027, 9, 1)),
      '1 четверть',
    );
    expect(
      AcademicCalendar.currentYear(now: DateTime(2027, 8, 31)),
      '2027/2028',
    );
  });
}
