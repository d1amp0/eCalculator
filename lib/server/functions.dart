import 'dart:convert';

import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';

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

Future<Map<String, List<List<dynamic>>>> getMarksMap(String eild) async {
  final client = eschoolSession.client..period = eild;
  final marks = await client.marksApp();
  final changedMarks = <String, List<List<dynamic>>>{};

  for (final mark in marks) {
    final subject = _decodeLegacyText(mark[2].toString());
    changedMarks.putIfAbsent(subject, () => <List<dynamic>>[]).add([
      mark[0],
      mark[1],
      mark[3].toString().substring(0, 10),
    ]);
  }
  return changedMarks;
}

Future<String> eild(String name) async {
  final value = await eschoolSession.client.getEild(name);
  return value.toString();
}

Future<List<String>> academicYears() => eschoolSession.client.academicYears();

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

Future<List<dynamic>> homeworkServer() {
  final now = DateTime.now();
  return eschoolSession.client.homeworks(
    d1: now.subtract(const Duration(days: 7)).millisecondsSinceEpoch,
    d2: now.add(const Duration(days: 14)).millisecondsSinceEpoch,
  );
}

Map<String, double> changeMarks(
  Map<String, List<List<dynamic>>> marksMap,
) {
  final averages = <String, double>{};
  for (final entry in marksMap.entries) {
    final marks = entry.value.map(
      (mark) => WeightedMark(
        (mark[0] as num).toDouble(),
        (mark[1] as num).toDouble(),
      ),
    );
    final average = MarkCalculator.weightedAverage(marks);
    if (average != null) {
      averages[entry.key] = (average * 100).round() / 100;
    }
  }
  return averages;
}

double getScore(List<List<dynamic>>? markList) {
  if (markList == null) return 0;
  return markList.fold<double>(
    0,
    (sum, mark) =>
        sum + (mark[0] as num).toDouble() * (mark[1] as num).toDouble(),
  );
}

double getCoefficient(List<List<dynamic>>? markList) {
  if (markList == null) return 0;
  return markList.fold<double>(
    0,
    (sum, mark) => sum + (mark[1] as num).toDouble(),
  );
}

String _decodeLegacyText(String value) {
  try {
    return utf8.decode(latin1.encode(value));
  } on Object {
    return value;
  }
}
