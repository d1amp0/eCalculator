import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
    length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));


class EschoolBase {
  String? username;
  String? password;
  List<dynamic> handledHomeworks = [];
  List<dynamic> handledMsgs = [];
  List<dynamic> handledMarks = [];
  String period;
  dynamic homeworkHandler;
  dynamic markHandler;
  dynamic messageHandler;
  int? userId;
  String? filename;
  Map<String, String> cookies = {};

  EschoolBase({
    this.username,
    this.password,
    List<dynamic>? handledHomeworks,
    List<dynamic>? handledMsgs,
    List<dynamic>? handledMarks,
    this.period = '204184',
    this.userId,
    this.filename,
  }) {
    this.handledHomeworks = handledHomeworks ?? [];
    this.handledMsgs = handledMsgs ?? [];
    this.handledMarks = handledMarks ?? [];
  }

  Future<int> auth() async {
    final url = Uri.parse('https://app.eschool.center/ec-server/login');
    final headers = {'User-Agent': 'Mozilla/5.0'};
    final body = {
      'username': username,
      'password': password,
      'device': json.encode({
        "cliType": "web",
        "cliVer": "v.1588",
        "pushToken": getRandomString(64),
        "deviceId": "8ezTOdgnXcJlv5gQR0Qqgb52kO5l4jht",
        "deviceName": "Chrome",
        "deviceModel": 136,
        "cliOs": "Win32",
        "cliOsVer": "null"
      })
    };

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      _updateCookies(response);
      final stateResponse = await getState();
      userId = stateResponse['userId'];
      return 200;
    }
    return 401;
  }

  void _updateCookies(http.Response response) {
    final rawCookies = response.headers['set-cookie'];
    if (rawCookies != null) {
      rawCookies.split(',').forEach((cookie) {
        final cookieParts = cookie.split(';')[0].split('=');
        if (cookieParts.length == 2) {
          cookies[cookieParts[0]] = cookieParts[1];
        }
      });
    }
  }

  Future<Map<String, dynamic>> getState() async {
    final url = Uri.parse('https://app.eschool.center/ec-server/state');
    final response = await _get(url);
    return jsonDecode(response.body);
  }

  Future<http.Response> _get(Uri url) async {
    final response = await http.get(url, headers: {'Cookie': _getCookies(),
      'User-Agent': "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
          "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 "
          "Safari/537.36"});
    if (response.statusCode == 401) {
      await auth();
      return _get(url);
    }
    return response;
  }

  String _getCookies() {
    return cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static Future<EschoolBase> login(String login, {String? password, String period = '204464', String? filename}) async {
    final base = EschoolBase(period: period, filename: filename);
    password ??= stdin.readLineSync()!;
    base.username = login;
    base.password = sha256.convert(utf8.encode(password)).toString();
    final statusCode = await base.auth();
    return statusCode == 200 ? base : throw Exception('Login failed');
  }

  void save() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = json.encode({
      'username': username,
      'password': password,
      'handledHomeworks': handledHomeworks,
      'handledMsgs': handledMsgs,
      'handledMarks': handledMarks,
      'userId': userId
    });
    prefs.setString("user", data);
  }

  static Future<EschoolBase> fromFile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final data = json.decode(prefs.getString("user")!);
    return EschoolBase(
      username: data['username'],
      password: data['password'],
      handledHomeworks: data['handledHomeworks'],
      handledMsgs: data['handledMsgs'],
      handledMarks: data['handledMarks'],
      userId: data['userId'],
    );
  }

  Future<Map<String, dynamic>> get(String method, {String prefix = 'student', Map<String, dynamic>? params}) async {
    final queryString = params != null ? params.entries.map((e) => '${e.key}=${e.value}').join('&') : '';
    final url = Uri.parse(
        'https://app.eschool.center/ec-server/$prefix/$method?userId=$userId${period.isNotEmpty && prefix == 'student' ? '&eiId=$period' : ''}${queryString.isNotEmpty ? '&$queryString' : ''}');
    final response = await _get(url);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getPeriods(String groupId) async {
    final url = Uri.parse('https://app.eschool.center/ec-server/dict/periods/0?groupId=$groupId');
    final response = await _get(url);
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> put(String method, Map<String, dynamic> data, {String prefix = 'chat', String urlData = ''}) async {
    final url = Uri.parse('https://app.eschool.center/ec-server/$prefix/$method${urlData.isNotEmpty ? '?$urlData' : ''}');
    final response = await http.put(url, body: json.encode(data), headers: {'Cookie': "${_getCookies()}; site_ver=app; clientVer=v.1587; es_prs=93799; es_user=150251; es_org=6; es_pos=S; clientUrl=/Private/student/diary/1%3Fd1%3D1745787600000"});
    if (response.statusCode == 401) {
      await auth();
      return put(method, data, prefix: prefix, urlData: urlData);
    }
    return json.decode(response.body);
  }
  //Other
  Future<int> school() async {
    final state = await getState();
    return state['user']['currentPosition']['orgnum'];
  }

  Future<List<dynamic>> marks() async {
    final diaryUnits = await get('getDiaryUnits');
    final units = {
      for (var unit in (diaryUnits['result'] ?? []))
        if (unit is Map<String, dynamic> && unit.containsKey('unitId') && unit.containsKey('unitName'))
          unit['unitId']: unit['unitName']
    };

    final diaryPeriod = await get('getDiaryPeriod');
    final periodResult = diaryPeriod['result'] ?? [];

    return periodResult
        .where((lesson) => lesson is Map<String, dynamic> && lesson.containsKey('markVal'))
        .map((lesson) {
      return [
        lesson['markVal'],
        lesson['mktWt'] ?? 1,
        lesson['startDt'],
        lesson['lessonId'],
        lesson['lptName'],
        units[lesson['unitId']]
      ];
    }).toList();
  }

  Future<List<dynamic>> marksApp() async {
    final diaryUnits = await get('getDiaryUnits');
    final units = {
      for (var unit in (diaryUnits['result'] ?? []))
        if (unit is Map<String, dynamic> && unit.containsKey('unitId') && unit.containsKey('unitName'))
          unit['unitId']: unit['unitName']
    };

    final diaryPeriod = await get('getDiaryPeriod');
    final periodResult = diaryPeriod['result'] ?? [];

    return periodResult
        .where((lesson) =>
    lesson is Map<String, dynamic> &&
        lesson.containsKey('markVal') &&
        getMark(lesson['markVal']) != 0)
        .map((lesson) {
      return [
        getMark(lesson['markVal']),
        lesson['mktWt'] ?? 1,
        units[lesson['unitId']],
        lesson['startDt'],
      ];
    }).toList();
  }

  double getMark(String mark) {
    try {
      int floatMark = int.parse(mark.substring(0, 1));
      if (mark.length == 2 && floatMark != 0) {
        if (mark[1] == '+') {
          return floatMark + 0.2;
        } else if (mark[1] == '-') {
          return floatMark - 0.2;
        }
      }
      return floatMark.toDouble();
    } catch (e) {
      return 0;
    }
  }

  Future<List<String>> units() async {
    final result = (await get('getDiaryUnits'))['result'];
    return result.map<String>((lesson) => lesson['unitName']).toList();
  }

  Future<String?> getGroupId(String year) async {
    String method = "getClassByUser", prefix = "usr";
    const queryString = '';
    final url = Uri.parse(
        'https://app.eschool.center/ec-server/$prefix/$method?userId=$userId${period.isNotEmpty && prefix == 'student' ? '&eiId=$period' : ''}${queryString.isNotEmpty ? '&$queryString' : ''}');
    final response = await _get(url);
    List<String> responses = response.body.substring(1, response.body.length - 1).split("},{");
    for (var elem in responses) {
      if (elem.substring(elem.indexOf('begDateStr') + 13, elem.indexOf('begDateStr') + 17) == year) {
        return elem.substring(elem.indexOf("groupId") + 9, elem.indexOf(','));
      }
    }
    return null;
  }

  Future<int> getEild(String name) async {
    final groupId = await getGroupId(name.substring(0, 4));
    if (groupId == null) return 400;

    final periods = await getPeriods(groupId);
    for (var elem in periods['items']) {
      if (utf8.decode(latin1.encode(elem['name'])) == name.substring(9)) {
        return elem['id'];
      }
    }
    return 400;
  }

  Future<List<Map<String, dynamic>>> diary({int? d1, int? d2}) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final startDate = d1 ?? currentTime - 48 * 3600 * 1000;
    final endDate = d2 ?? startDate + 14 * 24 * 3600 * 1000;

    final url = Uri.parse(
        'https://app.eschool.center/ec-server/student/diary?userId=$userId&d1=$startDate&d2=$endDate');
    final response = await _get(url);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body)['lesson'] ?? []);
  }

  Future<List<dynamic>> homeworks({int? d1, int? d2}) async {
    final lessons = await diary(d1: d1, d2: d2);
    final result = <dynamic>[];

    for (var lesson in lessons) {
      final parts = (lesson['part'] as List?)?.where((part) => part['variant'] != null).toList();
      if (parts == null || parts.isEmpty) continue;

      final part = parts[0];
      final variant = (part['variant'] as List?)?.first;
      if (variant == null || (variant['text'] == null && variant['file'] == null)) continue;

      if (variant['text'] != null) {
        result.add([
          variant['id'],
          lesson['unit']['name'],
          lesson['date'],
          variant['text'],
          false,
          (variant['file'] as List?)?.map((file) =>
          [
            file['id'],
            file['fileName']
          ]).toList()
        ]);
      }
    }
    return result;
  }
}