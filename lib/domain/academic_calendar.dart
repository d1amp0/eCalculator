class AcademicCalendar {
  const AcademicCalendar._();

  static String currentYear({DateTime? now}) {
    final date = now ?? DateTime.now();
    final startYear = date.month >= DateTime.august ? date.year : date.year - 1;
    return '$startYear/${startYear + 1}';
  }

  static List<String> recentYears({DateTime? now, int count = 3}) {
    final current = currentYear(now: now);
    final startYear = int.parse(current.substring(0, 4));
    return List.generate(
      count,
      (index) => '${startYear - index}/${startYear - index + 1}',
    );
  }

  static String? currentQuarter({DateTime? now}) {
    final month = (now ?? DateTime.now()).month;
    if (month == DateTime.september || month == DateTime.october) {
      return '1 четверть';
    }
    if (month == DateTime.november || month == DateTime.december) {
      return '2 четверть';
    }
    if (month >= DateTime.january && month <= DateTime.march) {
      return '3 четверть';
    }
    if (month == DateTime.april || month == DateTime.may) {
      return '4 четверть';
    }
    return null;
  }
}
