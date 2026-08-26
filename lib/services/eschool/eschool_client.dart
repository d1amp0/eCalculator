import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:ecalculator/domain/mark_calculator.dart';
import 'package:http/http.dart' as http;

const _baseUrl = 'https://app.eschool.center/ec-server';
const _characters =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

class EschoolClient {
  EschoolClient({
    required this.username,
    required this.credentialHash,
    http.Client? httpClient,
    Map<String, String>? cookies,
    this.userId,
    this.period = '',
  })  : _httpClient = httpClient ?? http.Client(),
        _cookies = Map.of(cookies ?? const {});

  final String username;
  final String? credentialHash;
  final http.Client _httpClient;
  final Map<String, String> _cookies;

  int? userId;
  String period;
  Future<void> Function()? onSessionChanged;

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static EschoolClient fromPassword({
    required String username,
    required String password,
    http.Client? httpClient,
  }) {
    return EschoolClient(
      username: username,
      credentialHash: hashPassword(password),
      httpClient: httpClient,
    );
  }

  Future<bool> authenticate() async {
    final credential = credentialHash;
    if (credential == null) return false;

    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/login'),
      headers: const {'User-Agent': 'Mozilla/5.0'},
      body: {
        'username': username,
        'password': credential,
        'device': json.encode({
          'cliType': 'web',
          'cliVer': 'v.1588',
          'pushToken': _randomString(64),
          'deviceId': '8ezTOdgnXcJlv5gQR0Qqgb52kO5l4jht',
          'deviceName': 'Chrome',
          'deviceModel': 136,
          'cliOs': 'Win32',
          'cliOsVer': 'null',
        }),
      },
    );

    if (response.statusCode != 200) return false;
    _updateCookies(response);

    final stateResponse = await _rawGet(Uri.parse('$_baseUrl/state'));
    if (stateResponse.statusCode != 200) return false;
    _updateUserId(stateResponse);
    await onSessionChanged?.call();
    return userId != null;
  }

  /// Checks a restored cookie without sending the reusable credential.
  Future<SessionValidation> validateSession() async {
    if (_cookies.isEmpty) return SessionValidation.unauthorized;
    try {
      final response = await _rawGet(Uri.parse('$_baseUrl/state'));
      if (response.statusCode == 401) return SessionValidation.unauthorized;
      if (response.statusCode != 200) return SessionValidation.unavailable;
      _updateUserId(response);
      return userId == null
          ? SessionValidation.unavailable
          : SessionValidation.valid;
    } on Object {
      return SessionValidation.unavailable;
    }
  }

  Future<Map<String, dynamic>> getState() async {
    final response = await _get(Uri.parse('$_baseUrl/state'));
    return _decodeMap(response);
  }

  Future<Map<String, dynamic>> get(
    String method, {
    String prefix = 'student',
    Map<String, dynamic>? params,
  }) async {
    final query = <String, String>{
      if (userId != null) 'userId': userId.toString(),
      if (period.isNotEmpty && prefix == 'student') 'eiId': period,
      if (params != null)
        for (final entry in params.entries) entry.key: entry.value.toString(),
    };
    final url =
        Uri.parse('$_baseUrl/$prefix/$method').replace(queryParameters: query);
    return _decodeMap(await _get(url));
  }

  Future<Map<String, dynamic>> getPeriods(String groupId) async {
    final url = Uri.parse('$_baseUrl/dict/periods/0')
        .replace(queryParameters: {'groupId': groupId});
    return _decodeMap(await _get(url));
  }

  Future<Map<String, dynamic>> put(
    String method,
    Map<String, dynamic> data, {
    String prefix = 'chat',
    String urlData = '',
  }) async {
    final url = Uri.parse(
      '$_baseUrl/$prefix/$method${urlData.isNotEmpty ? '?$urlData' : ''}',
    );
    var response = await _rawPut(url, data);
    if (response.statusCode == 401 && await authenticate()) {
      response = await _rawPut(url, data);
    }
    return _decodeMap(response);
  }

  Future<int> school() async {
    final state = await getState();
    return state['user']['currentPosition']['orgnum'] as int;
  }

  Future<List<dynamic>> marks() async {
    final diaryUnits = await get('getDiaryUnits');
    final units = {
      for (final unit in (diaryUnits['result'] ?? const []))
        if (unit is Map<String, dynamic> &&
            unit.containsKey('unitId') &&
            unit.containsKey('unitName'))
          unit['unitId']: unit['unitName'],
    };

    final periodResult = (await get('getDiaryPeriod'))['result'] ?? const [];
    return periodResult
        .where((lesson) =>
            lesson is Map<String, dynamic> && lesson.containsKey('markVal'))
        .map((lesson) => [
              lesson['markVal'],
              lesson['mktWt'] ?? 1,
              lesson['startDt'],
              lesson['lessonId'],
              lesson['lptName'],
              units[lesson['unitId']],
            ])
        .toList();
  }

  Future<List<dynamic>> marksApp() async {
    final diaryUnits = await get('getDiaryUnits');
    final units = {
      for (final unit in (diaryUnits['result'] ?? const []))
        if (unit is Map<String, dynamic> &&
            unit.containsKey('unitId') &&
            unit.containsKey('unitName'))
          unit['unitId']: unit['unitName'],
    };

    final periodResult = (await get('getDiaryPeriod'))['result'] ?? const [];
    return periodResult
        .where((lesson) =>
            lesson is Map<String, dynamic> &&
            MarkCalculator.parse(lesson['markVal']?.toString() ?? '') != null)
        .map((lesson) => [
              MarkCalculator.parse(lesson['markVal'].toString()),
              lesson['mktWt'] ?? 1,
              units[lesson['unitId']],
              lesson['startDt'],
            ])
        .toList();
  }

  Future<List<String>> units() async {
    final result = (await get('getDiaryUnits'))['result'] as List<dynamic>;
    return result
        .map<String>((lesson) => lesson['unitName'] as String)
        .toList();
  }

  Future<List<dynamic>> _classesForUser() async {
    final url = Uri.parse('$_baseUrl/usr/getClassByUser')
        .replace(queryParameters: {'userId': userId.toString()});
    final response = await _get(url);
    final decoded = json.decode(response.body);
    return decoded is List<dynamic> ? decoded : const [];
  }

  Future<List<String>> academicYears() async {
    final years = <String>{};
    for (final item in await _classesForUser()) {
      if (item is! Map<String, dynamic>) continue;
      final match = RegExp(r'(\d{4})').firstMatch(
        item['begDateStr']?.toString() ?? '',
      );
      if (match == null) continue;
      final start = int.parse(match.group(1)!);
      years.add('$start/${start + 1}');
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  Future<String?> getGroupId(String year) async {
    final url = Uri.parse('$_baseUrl/usr/getClassByUser')
        .replace(queryParameters: {'userId': userId.toString()});
    final response = await _get(url);
    final responses =
        response.body.substring(1, response.body.length - 1).split('},{');
    for (final element in responses) {
      final yearStart = element.indexOf('begDateStr') + 13;
      if (element.substring(yearStart, yearStart + 4) == year) {
        return element.substring(
          element.indexOf('groupId') + 9,
          element.indexOf(','),
        );
      }
    }
    return null;
  }

  Future<int> getEild(String name) async {
    final groupId = await getGroupId(name.substring(0, 4));
    if (groupId == null) return 400;

    final periods = await getPeriods(groupId);
    for (final element in periods['items'] ?? const []) {
      if (utf8.decode(latin1.encode(element['name'])) == name.substring(9)) {
        return element['id'] as int;
      }
    }
    return 400;
  }

  Future<List<Map<String, dynamic>>> diary({int? d1, int? d2}) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final startDate = d1 ?? currentTime - 48 * 3600 * 1000;
    final endDate = d2 ?? startDate + 14 * 24 * 3600 * 1000;
    final url = Uri.parse('$_baseUrl/student/diary').replace(queryParameters: {
      'userId': userId.toString(),
      'd1': startDate.toString(),
      'd2': endDate.toString(),
    });
    final response = await _get(url);
    return List<Map<String, dynamic>>.from(
      jsonDecode(response.body)['lesson'] ?? const [],
    );
  }

  Future<List<dynamic>> homeworks({int? d1, int? d2}) async {
    final lessons = await diary(d1: d1, d2: d2);
    final result = <dynamic>[];

    for (final lesson in lessons) {
      final parts = (lesson['part'] as List?)
          ?.where((part) => part['variant'] != null)
          .toList();
      if (parts == null || parts.isEmpty) continue;

      final variant = (parts.first['variant'] as List?)?.first;
      if (variant == null ||
          (variant['text'] == null && variant['file'] == null)) {
        continue;
      }
      if (variant['text'] == null) continue;

      result.add([
        variant['id'],
        lesson['unit']['name'],
        lesson['date'],
        variant['text'],
        false,
        (variant['file'] as List?)
            ?.map((file) => [file['id'], file['fileName']])
            .toList(),
      ]);
    }
    return result;
  }

  void clearSession() {
    _cookies.clear();
    userId = null;
  }

  Future<http.Response> _get(Uri url) async {
    var response = await _rawGet(url);
    if (response.statusCode == 401 && await authenticate()) {
      response = await _rawGet(url);
    }
    return response;
  }

  Future<http.Response> _rawGet(Uri url) => _httpClient.get(
        url,
        headers: {
          'Cookie': _cookieHeader,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
              'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 '
              'Safari/537.36',
        },
      );

  Future<http.Response> _rawPut(Uri url, Map<String, dynamic> data) =>
      _httpClient.put(
        url,
        body: json.encode(data),
        headers: {
          'Cookie': '$_cookieHeader; site_ver=app; clientVer=v.1587; '
              'es_prs=93799; es_user=150251; es_org=6; es_pos=S; '
              'clientUrl=/Private/student/diary/1%3Fd1%3D1745787600000',
        },
      );

  String get _cookieHeader =>
      _cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');

  void _updateCookies(http.Response response) {
    final rawCookies = response.headers['set-cookie'];
    if (rawCookies == null) return;
    final matches =
        RegExp(r'(?:^|,\s*)([A-Za-z0-9_]+)=([^;,\s]*)').allMatches(rawCookies);
    for (final match in matches) {
      _cookies[match.group(1)!] = match.group(2)!;
    }
  }

  void _updateUserId(http.Response response) {
    final state = jsonDecode(response.body) as Map<String, dynamic>;
    final value = state['userId'];
    userId = value is int ? value : int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw EschoolRequestException(response.statusCode);
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }
}

class EschoolRequestException implements Exception {
  const EschoolRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'eSchool request failed with status $statusCode';
}

enum SessionValidation { valid, unauthorized, unavailable }

String _randomString(int length) {
  final random = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _characters.codeUnitAt(random.nextInt(_characters.length)),
    ),
  );
}
