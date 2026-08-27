import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:ecalculator/domain/student_data.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/services/student_data_source.dart';

Future<LoginResult> loginTry(
  String username,
  String password, {
  required bool rememberMe,
}) {
  return eschoolSession.login(
    username: username,
    password: password,
    rememberMe: rememberMe,
  );
}

Future<SubjectMarks> getMarksMap(String periodId) =>
    studentDataSession.source.marks(periodId);

Future<String> eild(String name) async {
  final value = await studentDataSession.source.periodId(name);
  return value ?? '400';
}

Future<List<String>> academicYears() =>
    studentDataSession.source.academicYears();

String deleteColors(String line) {
  var result = line;
  while (result.contains('background-color')) {
    final first = result.indexOf('background-color');
    final end = result.substring(first).indexOf(';');
    if (end < 0) break;
    result = result.replaceFirst(result.substring(first, first + end + 1), '');
  }
  while (result.contains('color')) {
    final first = result.indexOf('color');
    final end = result.substring(first).indexOf(';');
    if (end < 0) break;
    result = result.replaceFirst(result.substring(first, first + end + 1), '');
  }
  return result;
}

String extractText(String line) {
  var result = line;
  while (result.contains('<')) {
    final first = result.indexOf('<');
    final end = result.substring(first).indexOf('>');
    if (end < 0) break;
    result = result.replaceFirst(result.substring(first, first + end + 1), '');
  }
  result = result.replaceAll('&nbsp;', '');
  return result.length > 200 ? '${result.substring(0, 197)}...' : result;
}

Future<List<dynamic>> homeworkServer() => studentDataSession.source.homework();

Map<String, double> changeMarks(SubjectMarks marksMap) {
  final averages = <String, double>{};
  for (final entry in marksMap.entries) {
    final marks = entry.value.map(
      (mark) => WeightedMark(mark.value, mark.weight),
    );
    final average = MarkCalculator.weightedAverage(marks);
    if (average != null) {
      averages[entry.key] = (average * 100).round() / 100;
    }
  }
  return averages;
}
