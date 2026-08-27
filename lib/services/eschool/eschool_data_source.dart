import 'dart:convert';

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
    final value = await _session.client.getEild(periodName);
    return value.toString() == '400' ? null : value.toString();
  }

  @override
  Future<SubjectMarks> marks(String periodId) async {
    final client = _session.client..period = periodId;
    final response = await client.marksApp();
    final result = <String, List<StudentMark>>{};

    for (var index = 0; index < response.length; index++) {
      final raw = response[index];
      final subject = _decodeLegacyText(raw[2].toString());
      final date = raw[3].toString();
      result.putIfAbsent(subject, () => <StudentMark>[]).add(
            StudentMark(
              id: '$subject-$index',
              value: (raw[0] as num).toDouble(),
              weight: (raw[1] as num).toDouble(),
              date: date.length >= 10 ? date.substring(0, 10) : date,
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

String _decodeLegacyText(String value) {
  try {
    return utf8.decode(latin1.encode(value));
  } on Object {
    return value;
  }
}
