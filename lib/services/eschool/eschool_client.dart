import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ecalculator/services/eschool/eschool_cache.dart';
import 'package:ecalculator/services/eschool/eschool_device_identity.dart';
import 'package:ecalculator/services/eschool/eschool_diagnostics.dart';
import 'package:ecalculator/services/eschool/eschool_models.dart';
import 'package:ecalculator/services/eschool/eschool_protocol.dart';
import 'package:http/http.dart' as http;

const eschoolRequestTimeout = Duration(seconds: 15);

class EschoolClient {
  EschoolClient({
    required this.username,
    required String? credentialHash,
    http.Client? httpClient,
    Map<String, String>? cookies,
    this.userId,
    this.positionId,
    this.organizationId,
    this.requestTimeout = eschoolRequestTimeout,
    EschoolDiagnostics? diagnostics,
    EschoolDeviceIdentityStore? deviceIdentityStore,
    EschoolDeviceMetadata? deviceMetadata,
    EschoolMetadataCache? cache,
  })  : _credentialHash = credentialHash,
        _httpClient = httpClient ?? http.Client(),
        _cookies = Map.of(cookies ?? const {}),
        _diagnostics = diagnostics ?? EschoolDiagnostics.fromEnvironment(),
        _deviceIdentityStore =
            deviceIdentityStore ?? SecureEschoolDeviceIdentityStore(),
        _deviceMetadata = deviceMetadata ?? EschoolDeviceMetadata.current(),
        _cache = cache ?? EschoolMetadataCache(),
        _sessionUse =
            (cookies?.isNotEmpty ?? false) ? _restoredSession : _freshLogin,
        sessionState = (cookies?.isNotEmpty ?? false)
            ? EschoolSessionState.unknown
            : EschoolSessionState.expired;

  final String username;

  /// Reusable credential material available only to explicit foreground login.
  String? _credentialHash;
  final http.Client _httpClient;
  final Map<String, String> _cookies;
  final EschoolDiagnostics _diagnostics;
  final EschoolDeviceIdentityStore _deviceIdentityStore;
  final EschoolDeviceMetadata _deviceMetadata;
  final EschoolMetadataCache _cache;
  final Duration requestTimeout;

  String _sessionUse;
  int? userId;
  String? positionId;
  String? organizationId;
  EschoolSessionState sessionState;
  Future<void> Function()? onSessionChanged;

  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  static String hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  static EschoolClient fromPassword({
    required String username,
    required String password,
    http.Client? httpClient,
    Duration requestTimeout = eschoolRequestTimeout,
    EschoolDiagnostics? diagnostics,
    EschoolDeviceIdentityStore? deviceIdentityStore,
    EschoolDeviceMetadata? deviceMetadata,
    EschoolMetadataCache? cache,
  }) {
    return EschoolClient(
      username: username,
      credentialHash: hashPassword(password),
      httpClient: httpClient,
      requestTimeout: requestTimeout,
      diagnostics: diagnostics,
      deviceIdentityStore: deviceIdentityStore,
      deviceMetadata: deviceMetadata,
      cache: cache,
    );
  }

  /// This is the only operation allowed to submit reusable credentials.
  /// Generic requests and session restoration never invoke it.
  Future<AuthenticationOutcome> authenticate() async {
    final credential = _credentialHash;
    _credentialHash = null;
    if (credential == null) {
      return const AuthenticationOutcome(
        AuthenticationResult.invalidCredentials,
      );
    }

    final EschoolDeviceIdentity identity;
    try {
      identity = await _deviceIdentityStore.identityFor(
        normalizeEschoolLogin(username),
      );
    } on Object {
      sessionState = EschoolSessionState.unavailable;
      return const AuthenticationOutcome(AuthenticationResult.unavailable);
    }

    final http.Response response;
    try {
      final url = _uri(EschoolProtocol.login);
      response = await _diagnostics.trace(
        method: 'POST',
        uri: url,
        sessionUse: _freshLogin,
        requestCookieNames: const [],
        send: () => _httpClient.post(
          url,
          headers: const {'User-Agent': 'Mozilla/5.0'},
          body: {
            'username': username,
            'password': credential,
            'device': json.encode({
              'cliType': 'web',
              'cliVer': EschoolProtocol.clientVersion,
              'pushToken': identity.pushToken,
              'deviceId': identity.deviceId,
              'deviceName': _deviceMetadata.deviceName,
              'deviceModel': _deviceMetadata.deviceModel,
              'cliOs': _deviceMetadata.cliOs,
              'cliOsVer': _deviceMetadata.cliOsVer,
            }),
          },
        ).timeout(requestTimeout),
      );
    } on Object {
      sessionState = EschoolSessionState.unavailable;
      return const AuthenticationOutcome(AuthenticationResult.unavailable);
    }

    if (response.statusCode == 409) {
      final challenge = _mfaChallenge(response.body);
      if (challenge != null) {
        sessionState = EschoolSessionState.mfaRequired;
        return AuthenticationOutcome(
          AuthenticationResult.mfaRequired,
          mfaChallenge: challenge,
        );
      }
      sessionState = EschoolSessionState.unavailable;
      return const AuthenticationOutcome(AuthenticationResult.unavailable);
    }
    if (response.statusCode != 200) {
      final result = _loginResultForStatus(response.statusCode);
      sessionState = _sessionStateForAuthentication(result);
      return AuthenticationOutcome(result);
    }

    _updateCookies(response);
    _sessionUse = _freshLogin;
    final validation = await validateSession();
    switch (validation) {
      case SessionValidation.valid:
        await onSessionChanged?.call();
        return const AuthenticationOutcome(AuthenticationResult.authenticated);
      case SessionValidation.expired:
        return const AuthenticationOutcome(
          AuthenticationResult.invalidCredentials,
        );
      case SessionValidation.forbidden:
        return const AuthenticationOutcome(AuthenticationResult.forbidden);
      case SessionValidation.rateLimited:
        return const AuthenticationOutcome(AuthenticationResult.rateLimited);
      case SessionValidation.unavailable:
        return const AuthenticationOutcome(AuthenticationResult.unavailable);
    }
  }

  /// Validates a restored cookie with /state and never attempts /login.
  Future<SessionValidation> validateSession() async {
    if (_cookies.isEmpty) {
      sessionState = EschoolSessionState.expired;
      return SessionValidation.expired;
    }
    try {
      final response = await _rawGet(_uri(EschoolProtocol.state));
      switch (response.statusCode) {
        case 200:
          final decoded = _tryDecodeMap(response.body);
          if (decoded == null || decoded['authenticated'] == false) {
            sessionState = EschoolSessionState.expired;
            return SessionValidation.expired;
          }
          _updateSessionIdentity(decoded);
          if (userId == null) {
            sessionState = EschoolSessionState.unavailable;
            return SessionValidation.unavailable;
          }
          sessionState = EschoolSessionState.valid;
          return SessionValidation.valid;
        case 401:
          sessionState = EschoolSessionState.expired;
          return SessionValidation.expired;
        case 403:
          sessionState = EschoolSessionState.forbidden;
          return SessionValidation.forbidden;
        case 429:
          sessionState = EschoolSessionState.rateLimited;
          return SessionValidation.rateLimited;
        default:
          sessionState = EschoolSessionState.unavailable;
          return SessionValidation.unavailable;
      }
    } on Object {
      sessionState = EschoolSessionState.unavailable;
      return SessionValidation.unavailable;
    }
  }

  Future<Map<String, dynamic>> getState() async =>
      _decodeMap(await _get(_uri(EschoolProtocol.state)));

  Future<List<String>> academicYears() async {
    final years = await _cache.getOrLoad<List<EschoolAcademicYear>>(
      EschoolCacheKey('academic-years', _accountScope),
      EschoolCachePolicy.academicYears,
      _loadAcademicYears,
    );
    final names = years.map((year) => year.displayName).whereType<String>();
    final unique = names.toSet().toList()..sort((a, b) => b.compareTo(a));
    if (unique.isNotEmpty) return unique;

    final derived = <String>{};
    for (final item in await _classesForUser()) {
      final start = item.startDate;
      if (start != null) derived.add('${start.year}/${start.year + 1}');
    }
    return derived.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<String?> periodId(String combinedName) async {
    if (combinedName.length < 9) return null;
    final yearName = combinedName.substring(0, 9);
    final periodName = combinedName.substring(9);
    final classes = await _classesForUser();
    EschoolClassInfo? classInfo;
    for (final item in classes) {
      if (item.belongsToDisplayYear(yearName)) {
        classInfo = item;
        break;
      }
    }
    if (classInfo == null) return null;
    final periods = await _periodsForGroup(classInfo.groupId);
    for (final period in periods) {
      if (period.name == periodName ||
          _decodeLegacyText(period.name) == periodName) {
        return period.id;
      }
    }
    return null;
  }

  Future<List<EschoolResolvedGrade>> grades(String periodId) async {
    var subjects = await _subjectsForPeriod(periodId);
    final gradesJson = await _getJson(
      _uri(
        EschoolProtocol.diaryPeriod,
        query: {'userId': '$userId', 'eiId': periodId},
      ),
    );
    final response = EschoolGradesResponse.fromJson(gradesJson);
    var byId = {for (final subject in subjects) subject.unitId: subject};
    if (response.lessons.any((lesson) => !byId.containsKey(lesson.unitId))) {
      _cache.invalidate(
        EschoolCacheKey('subjects', '$_accountScope|$periodId'),
      );
      subjects = await _subjectsForPeriod(periodId);
      byId = {for (final subject in subjects) subject.unitId: subject};
    }

    final resolved = <EschoolResolvedGrade>[];
    for (final lesson in response.lessons) {
      final subject = byId[lesson.unitId];
      if (subject == null) continue;
      for (final part in lesson.parts) {
        for (final mark in part.marks) {
          resolved.add(
            EschoolResolvedGrade(
              subject: subject,
              lesson: lesson,
              part: part,
              mark: mark,
            ),
          );
        }
      }
    }
    return resolved;
  }

  Future<EschoolDiaryResponse> diary({int? d1, int? d2}) async {
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final startDate = d1 ?? currentTime - 48 * 3600 * 1000;
    final endDate = d2 ?? startDate + 14 * 24 * 3600 * 1000;
    final response = await _getJson(
      _uri(
        EschoolProtocol.personDiary,
        query: {
          'prsId': '$userId',
          'd1': '$startDate',
          'd2': '$endDate',
        },
      ),
    );
    return EschoolDiaryResponse.fromJson(response);
  }

  /// The calculator needs only a compact read-only homework projection, so
  /// getPrsDiary is simpler than the dedicated list/details API.
  Future<List<dynamic>> homeworks({int? d1, int? d2}) async {
    final diaryResponse = await diary(d1: d1, d2: d2);
    final result = <dynamic>[];
    for (final lesson in diaryResponse.lessons) {
      final variants = lesson.parts.expand((part) => part.variants);
      final variant = variants.isEmpty ? null : variants.first;
      if (variant == null || lesson.unitName == null || lesson.date == null) {
        continue;
      }
      result.add([
        variant.id,
        lesson.unitName,
        lesson.date!.millisecondsSinceEpoch,
        variant.text,
        false,
        variant.files.map((file) => [file.id, file.name]).toList(),
      ]);
    }
    return result;
  }

  void invalidateAcademicMetadata() => _cache.clear();

  void clearSession() {
    _cookies.clear();
    userId = null;
    positionId = null;
    organizationId = null;
    sessionState = EschoolSessionState.expired;
    _sessionUse = _freshLogin;
    _cache.clear();
  }

  Future<List<EschoolAcademicYear>> _loadAcademicYears() async {
    final value = await _getJson(_uri(EschoolProtocol.academicYears));
    return _responseList(value)
        .map(EschoolAcademicYear.tryParse)
        .whereType<EschoolAcademicYear>()
        .toList(growable: false);
  }

  Future<List<EschoolClassInfo>> _classesForUser() {
    return _cache.getOrLoad<List<EschoolClassInfo>>(
      EschoolCacheKey('classes', _accountScope),
      EschoolCachePolicy.classes,
      () async {
        final value = await _getJson(
          _uri(
            EschoolProtocol.classesByUser,
            query: {'userId': '$userId'},
          ),
        );
        return _responseList(value)
            .map(EschoolClassInfo.tryParse)
            .whereType<EschoolClassInfo>()
            .toList(growable: false);
      },
    );
  }

  Future<List<EschoolPeriod>> _periodsForGroup(String groupId) {
    return _cache.getOrLoad<List<EschoolPeriod>>(
      EschoolCacheKey('periods', '$_accountScope|$groupId'),
      EschoolCachePolicy.periods,
      () async {
        final value = await _getJson(
          _uri(EschoolProtocol.periods, query: {'groupId': groupId}),
        );
        return _responseList(value, preferredKey: 'items')
            .map(EschoolPeriod.tryParse)
            .whereType<EschoolPeriod>()
            .toList(growable: false);
      },
    );
  }

  Future<List<EschoolSubjectMetadata>> _subjectsForPeriod(String periodId) {
    return _cache.getOrLoad<List<EschoolSubjectMetadata>>(
      EschoolCacheKey('subjects', '$_accountScope|$periodId'),
      EschoolCachePolicy.subjects,
      () async {
        final value = await _getJson(
          _uri(
            EschoolProtocol.diaryUnits,
            query: {'userId': '$userId', 'eiId': periodId},
          ),
        );
        return _responseList(value)
            .map(EschoolSubjectMetadata.tryParse)
            .whereType<EschoolSubjectMetadata>()
            .toList(growable: false);
      },
    );
  }

  String get _accountScope =>
      '${EschoolProtocol.clientVersion}|${normalizeEschoolLogin(username)}|'
      '${userId ?? '-'}|${positionId ?? '-'}|${organizationId ?? '-'}';

  Future<Object?> _getJson(Uri url) async {
    final response = await _get(url);
    try {
      return json.decode(response.body);
    } on FormatException {
      throw const EschoolProtocolException('Invalid JSON response');
    }
  }

  Future<http.Response> _get(Uri url) async {
    final http.Response response;
    try {
      response = await _rawGet(url);
    } on Object {
      sessionState = EschoolSessionState.unavailable;
      rethrow;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _recordRequestState(response.statusCode);
      throw EschoolRequestException(response.statusCode);
    }
    return response;
  }

  Future<http.Response> _rawGet(Uri url) => _diagnostics.trace(
        method: 'GET',
        uri: url,
        sessionUse: _sessionUse,
        requestCookieNames: _cookies.keys,
        send: () => _httpClient.get(
          url,
          headers: {
            'Cookie': _cookieHeader,
            'User-Agent':
                'Mozilla/5.0 eCalculator/${EschoolProtocol.clientVersion}',
          },
        ).timeout(requestTimeout),
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

  void _updateSessionIdentity(Map<String, dynamic> state) {
    final previousUserId = userId;
    final previousPositionId = positionId;
    final previousOrganizationId = organizationId;
    final user = eschoolMap(state['user']);
    final position = eschoolMap(user?['currentPosition']);
    userId = eschoolInt(
      state['userId'] ?? user?['userId'] ?? user?['id'] ?? position?['userId'],
    );
    positionId = eschoolString(
      position?['positionId'] ?? position?['posId'] ?? position?['id'],
    );
    organizationId = eschoolString(
      position?['orgnum'] ?? position?['orgId'] ?? state['orgId'],
    );
    if ((previousUserId != null && previousUserId != userId) ||
        (previousPositionId != null && previousPositionId != positionId) ||
        (previousOrganizationId != null &&
            previousOrganizationId != organizationId)) {
      _cache.clear();
    }
  }

  void _recordRequestState(int statusCode) {
    if (statusCode == 401) sessionState = EschoolSessionState.expired;
    if (statusCode == 403) sessionState = EschoolSessionState.forbidden;
    if (statusCode == 429) sessionState = EschoolSessionState.rateLimited;
    if (statusCode >= 500) sessionState = EschoolSessionState.unavailable;
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final result = _tryDecodeMap(response.body);
    if (result == null) {
      throw const EschoolProtocolException('Expected a JSON object');
    }
    return result;
  }
}

class AuthenticationOutcome {
  const AuthenticationOutcome(this.result, {this.mfaChallenge});

  final AuthenticationResult result;
  final EschoolMfaChallenge? mfaChallenge;
}

class EschoolRequestException implements Exception {
  const EschoolRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'eSchool request failed with status $statusCode';
}

class EschoolProtocolException implements Exception {
  const EschoolProtocolException(this.message);

  final String message;
}

enum EschoolSessionState {
  unknown,
  valid,
  expired,
  forbidden,
  rateLimited,
  unavailable,
  mfaRequired,
  captchaRequired,
}

enum SessionValidation { valid, expired, forbidden, rateLimited, unavailable }

enum AuthenticationResult {
  authenticated,
  invalidCredentials,
  forbidden,
  rateLimited,
  unavailable,
  mfaRequired,
  captchaRequired,
}

AuthenticationResult _loginResultForStatus(int statusCode) {
  if (statusCode == 403) return AuthenticationResult.forbidden;
  if (statusCode == 429) return AuthenticationResult.rateLimited;
  if (statusCode == 400 || statusCode == 401 || statusCode == 422) {
    return AuthenticationResult.invalidCredentials;
  }
  return AuthenticationResult.unavailable;
}

EschoolSessionState _sessionStateForAuthentication(
    AuthenticationResult result) {
  switch (result) {
    case AuthenticationResult.authenticated:
      return EschoolSessionState.valid;
    case AuthenticationResult.invalidCredentials:
      return EschoolSessionState.expired;
    case AuthenticationResult.forbidden:
      return EschoolSessionState.forbidden;
    case AuthenticationResult.rateLimited:
      return EschoolSessionState.rateLimited;
    case AuthenticationResult.unavailable:
      return EschoolSessionState.unavailable;
    case AuthenticationResult.mfaRequired:
      return EschoolSessionState.mfaRequired;
    case AuthenticationResult.captchaRequired:
      return EschoolSessionState.captchaRequired;
  }
}

EschoolMfaChallenge? _mfaChallenge(String body) {
  final decoded = _tryDecodeMap(body);
  if (decoded == null || decoded['code'] != 'MFA_REQUIRED') return null;
  return EschoolMfaChallenge.tryParse(decoded);
}

Map<String, dynamic>? _tryDecodeMap(String body) {
  try {
    return eschoolMap(json.decode(body));
  } on FormatException {
    return null;
  }
}

List<Object?> _responseList(Object? value, {String preferredKey = 'result'}) {
  if (value is List) return value.cast<Object?>();
  final map = eschoolMap(value);
  return eschoolList(map?[preferredKey] ?? map?['result'] ?? map?['items']);
}

Uri _uri(String path, {Map<String, String>? query}) =>
    Uri.parse('${EschoolProtocol.baseUrl}$path')
        .replace(queryParameters: query);

String _decodeLegacyText(String value) {
  try {
    return utf8.decode(latin1.encode(value));
  } on Object {
    return value;
  }
}

const _freshLogin = 'fresh-login';
const _restoredSession = 'restored-session';
