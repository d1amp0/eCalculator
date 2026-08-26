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
    expect(
      AcademicCalendar.recentYears(now: DateTime(2026, 9, 1)),
      ['2026/2027', '2025/2026', '2024/2025'],
    );
  });
}
