import 'dart:convert';

import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/services/student_data_source.dart';

class DemoDataSource implements StudentDataSource {
  static const demoYear = '2025/2026';
  static const demoPeriod = '2 четверть';

  @override
  Future<List<String>> academicYears() async => const [demoYear, '2024/2025'];

  @override
  Future<String?> periodId(String periodName) async => 'demo-period';

  @override
  Future<SubjectMarks> marks(String periodId) async => _fixtureMarks();

  @override
  Future<List<dynamic>> homework() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return [
      _homework(
        1,
        'Алгебра',
        start,
        'Решить № 412–418, повторить формулы сокращённого умножения.',
      ),
      _homework(
        2,
        'Русский язык',
        start.add(const Duration(days: 1)),
        'Подготовить упражнение 126 и повторить правописание Н/НН.',
      ),
      _homework(
        3,
        'История',
        start.add(const Duration(days: 1)),
        'Прочитать параграф 18, составить краткий план.',
      ),
      [
        4,
        'Литература',
        start.millisecondsSinceEpoch,
        'Прочитано: главы 1–3. Задание выполнено.',
        true,
      ],
    ];
  }

  @override
  Future<void> reset() async {}

  static SubjectMarks _fixtureMarks() {
    const fixtures = <String, List<(double, double, String)>>{
      'Алгебра': [
        (5, 1, '2026-01-12'),
        (4, 1, '2026-01-16'),
        (3, 2, '2026-01-21'),
        (5, 2, '2026-01-27'),
        (4.2, 1.5, '2026-02-03'),
      ],
      'Геометрия': [
        (5, 2, '2026-01-13'),
        (5, 1, '2026-01-20'),
        (4, 1.5, '2026-02-02'),
      ],
      'Русский язык': [
        (4, 1, '2026-01-11'),
        (5, 2, '2026-01-18'),
        (4.2, 1, '2026-01-25'),
        (5, 1, '2026-02-04'),
      ],
      'Литература': [
        (5, 1, '2026-01-14'),
        (5, 2, '2026-01-28'),
      ],
      'Физика': [
        (3, 1, '2026-01-10'),
        (4, 2, '2026-01-17'),
        (5, 1, '2026-01-24'),
        (3.8, 1.5, '2026-02-01'),
      ],
      'Информатика': [
        (5, 2, '2026-01-09'),
        (5, 1, '2026-01-23'),
        (5, 1.5, '2026-02-05'),
      ],
      'Английский язык (углублённый уровень)': [
        (4, 1, '2026-01-08'),
        (3, 1, '2026-01-15'),
        (4, 2, '2026-01-22'),
        (4.2, 1.5, '2026-01-29'),
        (5, 2, '2026-02-06'),
      ],
      'История': [
        (3, 1, '2026-01-07'),
        (3, 2, '2026-01-19'),
        (3.8, 1, '2026-02-03'),
      ],
    };

    return {
      for (final entry in fixtures.entries)
        entry.key: [
          for (var index = 0; index < entry.value.length; index++)
            StudentMark(
              id: '${entry.key}-$index',
              value: entry.value[index].$1,
              weight: entry.value[index].$2,
              date: entry.value[index].$3,
            ),
        ],
    };
  }

  static List<dynamic> _homework(
    int id,
    String subject,
    DateTime date,
    String text,
  ) {
    return [
      id,
      _legacy(subject),
      date.millisecondsSinceEpoch,
      _legacy(text),
      false,
    ];
  }

  static String _legacy(String value) => latin1.decode(utf8.encode(value));
}
