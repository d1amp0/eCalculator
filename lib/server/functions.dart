import 'dart:convert';

import 'eschool_base.dart';

Future<bool> loginTry(String username, String password) async {
  try {
    final client = await EschoolBase.login(username, password: password);
    client.save(filename: 'eschool_account');
  } on Exception {
    return false;
  }
  return true;
}

Future<Map<String, List<List>>> getMarksMap(String eild) async {
  final client = await EschoolBase.fromFile('eschool_account');
  client.period = eild;
  List marks = await client.marksApp();
  //List<List> marks = [
  //  [4.0, 1.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [3.0, 1.0, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [4.2, 1.5, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [5.0, 0.5, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [1.0, 1.0, "Ð¥Ð¸Ð¼Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [4.0, 1.25, "Ð¥Ð¸Ð¼Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [3.0, 1.0, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 2.0, "ÐÐµÐ¾Ð¼ÐµÑÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [1.0, 2.0, "ÐÐµÐ¾Ð¼ÐµÑÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [4.0, 0.5, "ÐÐ¸ÑÐµÑÐ°ÑÑÑÐ°", "2020-09-03T00:00:00"],
  //  [1.0, 0.5, "Ð ÑÑÑÐºÐ¸Ð¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [3.0, 1.25, "Ð¥Ð¸Ð¼Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [2.0, 2.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 2.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [4.0, 1.75, "ÐÐµÐ¾Ð³ÑÐ°ÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [3.0, 1.25, "Ð ÑÑÑÐºÐ¸Ð¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [4.0, 1.0, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [4.0, 0.5, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 1.25, "Ð ÑÑÑÐºÐ¸Ð¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [2.0, 0.5, "Ð¥Ð¸Ð¼Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [3.0, 0.5, "ÐÐµÐ¾Ð¼ÐµÑÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [1.0, 0.5, "ÐÐ½ÑÐ¾ÑÐ¼Ð°ÑÐ¸ÐºÐ° Ð¸ ÐÐÐ¢", "2020-09-03T00:00:00"],
  //  [5.0, 0.5, "ÐÐÐ", "2020-09-03T00:00:00"],
  //  [1.0, 0.5, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [4.0, 1.25, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [3.0, 1.0, "ÐÐ¸ÑÐµÑÐ°ÑÑÑÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 0.5, "ÐÐµÐ¾Ð³ÑÐ°ÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [1.0, 1.0, "Ð¤Ð¸Ð·Ð¸ÑÐµÑÐºÐ°Ñ ÐºÑÐ»ÑÑÑÑÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 0.5, "ÐÐ¸Ð¾Ð»Ð¾Ð³Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [5.0, 0.75, "ÐÐ¸Ð¾Ð»Ð¾Ð³Ð¸Ñ", "2020-09-03T00:00:00"],
  //  [5.0, 1.25, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 1.25, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [3.0, 0.5, "ÐÐµÐ¾Ð¼ÐµÑÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [5.0, 2.0, "Ð ÑÑÑÐºÐ¸Ð¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [5.0, 0.5, "ÐÐ½ÑÐ¾ÑÐ¼Ð°ÑÐ¸ÐºÐ° Ð¸ ÐÐÐ¢", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "ÐÐ½ÑÐ¾ÑÐ¼Ð°ÑÐ¸ÐºÐ° Ð¸ ÐÐÐ¢", "2020-09-03T00:00:00"],
  //  [1.0, 1.25, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [2.0, 2.0, "ÐÐ»Ð³ÐµÐ±ÑÐ°", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [4.0, 1.75, "ÐÑÑÐ¾ÑÐ¸Ñ", "2020-09-03T00:00:00"],
  //  [1.0, 1.0, "Ð¤Ð¸Ð·Ð¸ÐºÐ°", "2020-09-03T00:00:00"],
  //  [4.0, 1.0, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [5.0, 1.0, "ÐÐ½Ð¾ÑÑÑÐ°Ð½Ð½ÑÐ¹ ÑÐ·ÑÐº", "2020-09-03T00:00:00"],
  //  [
  //    4.0,
  //    1.25,
  //    "ÐÑÐ½Ð¾Ð²Ñ Ð±ÐµÐ·Ð¾Ð¿Ð°ÑÐ½Ð¾ÑÑÐ¸ Ð¸ Ð·Ð°ÑÐ¸ÑÑ Ð Ð¾Ð´Ð¸Ð½Ñ",
  //    "2020-09-03T00:00:00"
  //  ]
  //];
  Map<String, List<List>> changedMarks = {};
  for (var elem in marks) {
    elem[2] = utf8.decode(latin1.encode(elem[2]));
    if (!changedMarks.containsKey(elem[2])) {
      changedMarks.addAll({
        elem[2]: [
          [elem[0], elem[1], elem[3].substring(0, 10)]
        ]
      });
    } else {
      changedMarks[elem[2]]?.add([elem[0], elem[1], elem[3].substring(0, 10)]);
    }
  }
  return changedMarks;
}

Future<String> eild(name) async {
  final client = await EschoolBase.fromFile('eschool_account');
  int eild = await client.getEild(name);
  return eild.toString();
  return "000000";
}

String deleteColors(String line) {
  int first;
  String substring;
  while (line.contains('background-color')) {
    first = line.indexOf('background-color');
    substring =
        line.substring(first, first + line.substring(first).indexOf(';') + 1);
    line = line.replaceFirst(substring, "");
  }
  while (line.contains('color')) {
    first = line.indexOf('color');
    substring =
        line.substring(first, first + line.substring(first).indexOf(';') + 1);
    line = line.replaceFirst(substring, "");
  }
  return line;
}

String extractText(String line) {
  int first;
  String substring;
  while (line.contains("<")) {
    first = line.indexOf("<");
    substring =
        line.substring(first, first + line.substring(first).indexOf('>') + 1);
    line = line.replaceFirst(substring, "");
  }
  line = line.replaceAll("&nbsp;", "");
  if (line.length > 200) {
    line = "${line.substring(0, 197)}...";
  }
  return line;
}

Future<List> homeworkServer() async {
  final client = await EschoolBase.fromFile('eschool_account');
  return await client.homeworks(d1: DateTime.now().add(const Duration(days: -7)).millisecondsSinceEpoch, d2: DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch);
  //return [
  //  [
  //    3812780,
  //    "ÐÐ¸Ð¾Ð»Ð¾Ð³Ð¸Ñ",
  //    1735246800000,
  //    "<p>ÑÐ²Ð¾Ð»ÑÑÐ¸Ñ</p>",
  //    false,
  //    []
  //  ],
  //  [
  //    3827621,
  //    "ÐÑÐ½Ð¾Ð²Ñ Ð±ÐµÐ·Ð¾Ð¿Ð°ÑÐ½Ð¾ÑÑÐ¸ Ð¸ Ð·Ð°ÑÐ¸ÑÑ Ð Ð¾Ð´Ð¸Ð½Ñ",
  //    1735246800000,
  //    '<p><strong>Ð¢ÐµÐ¼Ð°:</strong><span style="background-color: rgb(251, 251, 252);">&nbsp;&nbsp;</span><strong style="background-color: rgb(251, 251, 252);">ÐÐ±ÑÐµÐ½Ð¸Ðµ Ð² Ð¶Ð¸Ð·Ð½Ð¸ ÑÐµÐ»Ð¾Ð²ÐµÐºÐ°. ÐÐµÐ¶Ð»Ð¸ÑÐ½Ð¾ÑÑÐ½Ð¾Ðµ Ð¾Ð±ÑÐµÐ½Ð¸Ðµ, Ð¾Ð±ÑÐµÐ½Ð¸Ðµ Ð² Ð³ÑÑÐ¿Ð¿Ðµ,ÐºÐ¾Ð½ÑÐ¿ÐµÐºÑ,Ð¸Ð½ÑÐµÑÐ½ÐµÑ,ÑÐ¸ÑÐ°ÑÑ Ð¸ ÑÐ¼ÐµÑÑ Ð¾ÑÐ²ÐµÑÐ°ÑÑ Ð½Ð° Ð²Ð¾Ð¿ÑÐ¾ÑÑ:</strong></p><p><strong style="color: rgb(194, 133, 255);"> </strong><strong style="color: rgb(0, 138, 0);">ÐÑÐ¾Ð²ÐµÑÑÐµÐ¼ Ð·Ð½Ð°Ð½Ð¸Ñ.</strong></p><p><strong style="color: rgb(194, 133, 255);">Ð£ÑÑÐ½Ð¾:</strong></p><p><span style="color: rgb(34, 34, 34); background-color: white;">1.Ð§ÑÐ¾ Ð´Ð»Ñ Ð²Ð°Ñ Ð·Ð½Ð°ÑÐ¸Ñ Ð¾Ð±ÑÐµÐ½Ð¸Ðµ?Ð­ÑÐ¾ Ð¿ÑÐ¾ÑÑÐ¾Ð¹ Ð¾Ð±Ð¼ÐµÐ½ ÑÐ»Ð¾Ð²Ð°Ð¼Ð¸ Ð¸Ð»Ð¸ ÑÐµÐ»Ð°Ñ ÑÐ¸ÑÑÐµÐ¼Ð° ÑÐ»Ð¾Ð¶Ð½ÑÑ ÑÐ¾ÑÐ¸Ð°Ð»ÑÐ½ÑÑ Ð²Ð·Ð°Ð¸Ð¼Ð¾Ð´ÐµÐ¹ÑÑÐ²Ð¸Ð¹?</span></p><p><span style="background-color: white; color: rgb(34, 34, 34);">2.Ð§ÑÐ¾ ÑÐ°ÐºÐ¾Ðµ Ð½Ð°ÑÑÐ¾ÑÑÐµÐµ Ð¾Ð±ÑÐµÐ½Ð¸Ðµ?</span></p><p><span style="background-color: white; color: rgb(34, 34, 34);">3.&nbsp;ÐÐ°Ðº ÑÐ°Ð±Ð¾ÑÐ°ÑÑ ÑÐ¾ÑÐ¸Ð°Ð»ÑÐ½ÑÐµ Ð³ÑÑÐ¿Ð¿Ñ?</span></p><p><span style="background-color: white; color: rgb(34, 34, 34);">4.&nbsp;ÐÐ°ÐºÐ¸Ðµ ÑÑÑÐµÑÑÐ²ÑÑÑ Ð¼ÐµÑÐ°Ð½Ð¸Ð·Ð¼Ñ Ð²Ð·Ð°Ð¸Ð¼Ð¾Ð´ÐµÐ¹ÑÑÐ²Ð¸Ñ Ð¼ÐµÐ¶Ð´Ñ Ð»ÑÐ´ÑÐ¼Ð¸ ?</span></p><p><span style="background-color: white; color: rgb(34, 34, 34);">5.ÐÐ°Ðº Ð¿ÑÐµÐ¾Ð´Ð¾Ð»ÐµÐ²Ð°ÑÑ ÐºÐ¾Ð¼Ð¼ÑÐ½Ð¸ÐºÐ°ÑÐ¸Ð²Ð½ÑÐµ Ð±Ð°ÑÑÐµÑÑ</span>?</p><p><span style="color: rgb(230, 0, 0);">ÐÐ¸ÑÑÐ¼ÐµÐ½Ð½Ð¾</span>:ÑÐ°Ð·Ð³Ð°Ð´Ð°ÑÑ ÐÑÐ¾ÑÑÐ²Ð¾ÑÐ´</p><p><br></p><p><br></p>',
  //    false,
  //    [
  //      [3983959, "ÐÑÐ¾ÑÑÐ²Ð¾ÑÐ´.docx"]
  //    ]
  //  ],
  //  [
  //    3835640,
  //    "ÐÐ»Ð³ÐµÐ±ÑÐ° Ð¸ Ð½Ð°ÑÐ°Ð»Ð° Ð°Ð½Ð°Ð»Ð¸Ð·Ð°",
  //    1736456400000,
  //    "<p>ÐÐµÐ¹Ð±ÑÐ¾Ð½: â764(Ð±), 805, 813, 816, 818, 821, 827, 829(Ð°), 832(Ð±), 836, 838.</p>",
  //    false,
  //    []
  //  ]
  //];
}

Map<String, double> changeMarks(Map<String, List<List<dynamic>>> marksMap) {
  Map<String, double> marksChanged = {};
  for (var key in marksMap.keys) {
    double markSum = 0, coefficientSum = 0;
    for (var elem in marksMap[key]!) {
      markSum += elem[0] * elem[1];
      coefficientSum += elem[1];
    }
    marksChanged.addAll({key: (markSum / coefficientSum * 100).round() / 100});
  }
  return marksChanged;
}

double getScore(List<List>? markList) {
  double sum = 0;
  for (var elem in markList!) {
    sum += elem[0] * elem[1];
  }
  return sum;
}

double getCoefficient(List<List>? markList) {
  double coefficient = 0;
  for (var elem in markList!) {
    coefficient += elem[1];
  }
  return coefficient;
}

Future<void> main() async {
  // await loginTry("***REMOVED***", "***REMOVED***");
  // final client = await EschoolBase.fromFile("eschool_account");
  // print(client.homeworks());
  // testing();
  // print(await )
  // print(await getMarksMap('200000'));
  // final client = await EschoolBase.fromFile("eschool_account");
  // print(await client.getGroupId("2024"));
  //print(utf8.decode(latin1.encode("ÐÐ¸ÑÐµÑÐ°ÑÑÑÐ°")));
  // print(changeMarks(getMarksMap()));
  // loginTry("***REMOVED***", "***REMOVED***");
  // final client = await EschoolBase.fromFile('eschool_account');
  // int eild = await client.getEild("2024/20252 полугодие");
  // print(eild.toString());
  // print("2023/20241 четверть".substring(9));
  // print('1 четверть' == '1 полугодие');
}
