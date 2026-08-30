import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/services/student_data_source.dart';

class EschoolDataSource implements StudentDataSource {
  EschoolDataSource(this._session);

  final EschoolSession _session;

  @override
  Future<List<String>> academicYears() => _session.client.academicYears();

  @override
  Future<String?> periodId(String periodName) async {
    return _session.client.periodId(periodName);
  }

  @override
  Future<SubjectMarks> marks(String periodId) async {
    final response = await _session.client.grades(periodId);
    final result = <String, List<StudentMark>>{};
    final identityOccurrences = <String, int>{};

    for (final grade in response) {
      final value = MarkCalculator.parse(grade.mark.value);
      if (value == null) continue;
      final subject = grade.subject.unitName;
      final protocolKey = grade.identity.provisionalKey;
      final occurrence = identityOccurrences.update(
        protocolKey,
        (value) => value + 1,
        ifAbsent: () => 0,
      );
      final date = grade.mark.markDate ?? grade.lesson.startDate;
      result.putIfAbsent(subject, () => <StudentMark>[]).add(
            StudentMark(
              // The occurrence suffix is UI-local collision protection, not
              // a grade-instance identity contract for notifications.
              id: '$protocolKey#display-$occurrence',
              value: value,
              weight: grade.part.weight ?? 1,
              date: date == null ? '' : date.toIso8601String().substring(0, 10),
            ),
          );
    }
    return result;
  }

  @override
  Future<List<dynamic>> homework() {
    final now = DateTime.now();
    return _session.client.homeworks(
      d1: now.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
      d2: now.add(const Duration(days: 14)).millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> reset() async {}
}
