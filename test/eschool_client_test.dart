import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ecalculator/services/eschool/eschool_cache.dart';
import 'package:ecalculator/services/eschool/eschool_client.dart';
import 'package:ecalculator/services/eschool/eschool_device_identity.dart';
import 'package:ecalculator/services/eschool/eschool_diagnostics.dart';
import 'package:ecalculator/services/eschool/eschool_models.dart';
import 'package:ecalculator/services/eschool/eschool_protocol.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Object gradesFixture;

  setUpAll(() async {
    gradesFixture = jsonDecode(
      await File('test/fixtures/eschool/grades_nested.json').readAsString(),
    );
  });

  group('session semantics', () {
    test('validates a restored session without login', () async {
      var requests = 0;
      final client = _restoredClient(
        MockClient((request) async {
          requests++;
          expect(request.url.path, endsWith('/state'));
          return http.Response(
            jsonEncode({
              'authenticated': true,
              'userId': 42,
              'user': {
                'currentPosition': {'positionId': 9, 'orgnum': 6},
              },
            }),
            200,
          );
        }),
      );

      expect(await client.validateSession(), SessionValidation.valid);
      expect(client.sessionState, EschoolSessionState.valid);
      expect(client.userId, 42);
      expect(client.positionId, '9');
      expect(client.organizationId, '6');
      expect(requests, 1);
    });

    for (final status in [401, 403, 429]) {
      test('$status never logs in or retries', () async {
        var requests = 0;
        final client = _restoredClient(
          MockClient((request) async {
            requests++;
            expect(request.url.path, isNot(endsWith('/login')));
            return http.Response('{}', status);
          }),
        );

        await expectLater(
          client.getState(),
          throwsA(
            isA<EschoolRequestException>().having(
              (error) => error.statusCode,
              'statusCode',
              status,
            ),
          ),
        );
        expect(requests, 1);
        expect(
          client.sessionState,
          status == 401
              ? EschoolSessionState.expired
              : status == 403
                  ? EschoolSessionState.forbidden
                  : EschoolSessionState.rateLimited,
        );
      });
    }

    test('transient validation failure is unavailable without retry', () async {
      var requests = 0;
      final client = _restoredClient(
        MockClient((request) async {
          requests++;
          return http.Response('{}', 503);
        }),
      );

      expect(await client.validateSession(), SessionValidation.unavailable);
      expect(client.sessionState, EschoolSessionState.unavailable);
      expect(requests, 1);
    });

    test('request timeout is unavailable without retry', () async {
      var requests = 0;
      final client = _restoredClient(
        MockClient((request) {
          requests++;
          return Completer<http.Response>().future;
        }),
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(client.getState(), throwsA(isA<TimeoutException>()));
      expect(client.sessionState, EschoolSessionState.unavailable);
      expect(requests, 1);
    });
  });

  group('foreground login', () {
    test('uses SHA-256 and current persistent device shape', () async {
      final identityStore = _CountingIdentityStore();
      final devices = <Map<String, dynamic>>[];
      final passwordFields = <String>[];
      final client = EschoolClient.fromPassword(
        username: ' Student ',
        password: 'password',
        deviceIdentityStore: identityStore,
        deviceMetadata: const EschoolDeviceMetadata(
          deviceName: 'Test browser',
          deviceModel: '123',
          cliOs: 'Test OS',
          cliOsVer: '1',
        ),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/login')) {
            passwordFields.add(request.bodyFields['password']!);
            devices.add(
              jsonDecode(request.bodyFields['device']!) as Map<String, dynamic>,
            );
            return http.Response(
              '{}',
              200,
              headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
            );
          }
          return http.Response(jsonEncode({'userId': 42}), 200);
        }),
      );

      final outcome = await client.authenticate();
      expect(outcome.result, AuthenticationResult.authenticated);
      expect(
        passwordFields.single,
        EschoolClient.hashPassword('password'),
      );
      expect(devices.single, {
        'cliType': 'web',
        'cliVer': EschoolProtocol.clientVersion,
        'pushToken': _CountingIdentityStore.pushToken,
        'deviceId': _CountingIdentityStore.deviceId,
        'deviceName': 'Test browser',
        'deviceModel': '123',
        'cliOs': 'Test OS',
        'cliOsVer': '1',
      });
      expect(identityStore.logins, ['student']);
    });

    test('persistent store reuses install ID and per-account push token',
        () async {
      final values = _MemoryDeviceValueStore();
      final firstStore = SecureEschoolDeviceIdentityStore(store: values);
      final first = await firstStore.identityFor('student');
      final second = await firstStore.identityFor('student');
      final other = await firstStore.identityFor('other-student');
      final afterRestart = await SecureEschoolDeviceIdentityStore(store: values)
          .identityFor('student');

      expect(first.deviceId, hasLength(32));
      expect(first.pushToken, hasLength(64));
      expect(second.deviceId, first.deviceId);
      expect(second.pushToken, first.pushToken);
      expect(other.deviceId, first.deviceId);
      expect(other.pushToken, isNot(first.pushToken));
      expect(afterRestart.deviceId, first.deviceId);
      expect(afterRestart.pushToken, first.pushToken);
    });

    test('maps 409 MFA_REQUIRED defensively without exposing its token',
        () async {
      final events = <String>[];
      final client = EschoolClient.fromPassword(
        username: 'student',
        password: 'password',
        deviceIdentityStore: _CountingIdentityStore(),
        diagnostics: EschoolDiagnostics(enabled: true, sink: events.add),
        httpClient: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'code': 'MFA_REQUIRED',
              'challengeToken': 'private-challenge-token',
              'expiresAt': '2026-08-30T13:00:00Z',
              'factors': [
                {'factorId': 'email-1', 'type': 'EMAIL'},
                {'factorId': 'totp-1', 'type': 'TOTP'},
                {'unexpected': true},
              ],
              'unknown': {'ignored': true},
            }),
            409,
          );
        }),
      );

      final outcome = await client.authenticate();
      expect(outcome.result, AuthenticationResult.mfaRequired);
      expect(client.sessionState, EschoolSessionState.mfaRequired);
      expect(outcome.mfaChallenge?.challengeToken, 'private-challenge-token');
      expect(
        outcome.mfaChallenge?.factors.map((factor) => factor.type),
        ['EMAIL', 'TOTP'],
      );
      expect(events.join(), isNot(contains('private-challenge-token')));
      expect(events.join(),
          isNot(contains(EschoolClient.hashPassword('password'))));
      expect(events.join(), isNot(contains(_CountingIdentityStore.deviceId)));
      expect(events.join(), isNot(contains(_CountingIdentityStore.pushToken)));
    });
  });

  group('current grades protocol', () {
    test('uses underscored path and parses nested optional grade fields',
        () async {
      final paths = <String>[];
      final client = _restoredClient(
        MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/getDiaryUnits/')) {
            expect(request.url.queryParameters, {'userId': '42', 'eiId': '7'});
            return http.Response(
              jsonEncode({
                'result': [
                  {
                    'unitId': 10,
                    'unitName': 'Алгебра',
                    'markSysId': 1,
                    'average': 4.5,
                  },
                ],
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          expect(request.url.path, endsWith('/student/getDiaryPeriod_'));
          expect(request.url.queryParameters, {'userId': '42', 'eiId': '7'});
          return _jsonResponse(gradesFixture);
        }),
      );

      final grades = await client.grades('7');
      expect(paths, [
        '/ec-server/student/getDiaryUnits/',
        '/ec-server/student/getDiaryPeriod_',
      ]);
      expect(grades, hasLength(3));
      expect(grades[0].subject.unitName, 'Алгебра');
      expect(grades[0].part.weight, 2);
      expect(grades[0].mark.value, '5');
      expect(grades[0].mark.markNumber, 1);
      expect(grades[0].identity.provisionalKey, '100|200|-|1');
      expect(grades[1].mark.criterionUseId, 'criterion-1');
      expect(grades[1].mark.criterionLabel, 'Accuracy');
      expect(grades[2].mark.markNumber, isNull);
      expect(grades[2].mark.teacherName, isNull);
    });

    test('ignores unknown fields and tolerates empty/missing parts', () {
      final response = EschoolGradesResponse.fromJson({
        'result': [
          {'lessonId': 1, 'unitId': 2, 'part': [], 'newField': 'ignored'},
          {'lessonId': 2, 'unitId': 2},
          {'lessonId': 3},
          'not-an-object',
        ],
      });

      expect(response.lessons, hasLength(2));
      expect(response.lessons.every((lesson) => lesson.parts.isEmpty), isTrue);
    });

    test('caches only subject projection while grades remain dynamic',
        () async {
      var unitRequests = 0;
      var gradeRequests = 0;
      final client = _restoredClient(
        MockClient((request) async {
          if (request.url.path.endsWith('/getDiaryUnits/')) {
            unitRequests++;
            return http.Response(
              jsonEncode({
                'result': [
                  {'unitId': 10, 'unitName': 'Алгебра', 'average': 2},
                ],
              }),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }
          gradeRequests++;
          return _jsonResponse(gradesFixture);
        }),
      );

      await client.grades('7');
      await client.grades('7');
      expect(unitRequests, 1);
      expect(gradeRequests, 2);
    });
  });

  group('structured academic metadata', () {
    test('uses and caches the current academic years endpoint', () async {
      var requests = 0;
      final client = _restoredClient(
        MockClient((request) async {
          requests++;
          expect(request.url.path, '/ec-server/yearplan/academyears');
          return http.Response(
            jsonEncode([
              {
                'yearId': 26,
                'begDate': '2026-09-01',
                'endDate': '2027-05-31',
              },
            ]),
            200,
          );
        }),
      );

      expect(await client.academicYears(), ['2026/2027']);
      expect(await client.academicYears(), ['2026/2027']);
      expect(requests, 1);
    });

    test('resolves class and period from decoded IDs and dates', () async {
      final paths = <String>[];
      final client = _restoredClient(
        MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/usr/getClassByUser')) {
            return http.Response(
              jsonEncode([
                {
                  'groupId': 77,
                  'yearId': 26,
                  'begDateStr': '01.09.2026',
                },
              ]),
              200,
            );
          }
          expect(request.url.queryParameters, {'groupId': '77'});
          return http.Response(
            jsonEncode({
              'items': [
                {'id': 88, 'name': '1 четверть'},
              ],
            }),
            200,
            headers: const {'content-type': 'application/json'},
          );
        }),
      );

      expect(await client.periodId('2026/20271 четверть'), '88');
      expect(paths, [
        '/ec-server/usr/getClassByUser',
        '/ec-server/dict/periods/0',
      ]);
    });
  });

  test('homework uses current getPrsDiary read contract', () async {
    Uri? requested;
    final client = _restoredClient(
      MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({
            'lesson': [
              {
                'id': 1,
                'date': 1788048000000,
                'unit': {'name': 'Алгебра'},
                'part': [
                  {
                    'variant': [
                      {
                        'id': 99,
                        'text': 'Решить задачу',
                        'file': [
                          {'id': 7, 'fileName': 'task.pdf'},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
            'user': [],
          }),
          200,
          headers: const {'content-type': 'application/json'},
        );
      }),
    );

    final items = await client.homeworks(d1: 1, d2: 2);
    expect(requested?.path, '/ec-server/student/getPrsDiary');
    expect(requested?.queryParameters, {
      'prsId': '42',
      'd1': '1',
      'd2': '2',
    });
    expect(items.single[0], '99');
    expect(items.single[1], 'Алгебра');
    expect(items.single[3], 'Решить задачу');
  });

  group('metadata cache', () {
    test('hit, expiry, scope isolation, and invalidation are explicit',
        () async {
      var now = DateTime(2026, 8, 30, 12);
      final cache = EschoolMetadataCache(clock: () => now);
      var loads = 0;
      Future<String> load() async => 'value-${++loads}';
      const accountA =
          EschoolCacheKey('subjects', 'account-a|class-1|period-1');
      const accountB =
          EschoolCacheKey('subjects', 'account-b|class-1|period-1');

      expect(
        await cache.getOrLoad(accountA, const Duration(hours: 1), load),
        'value-1',
      );
      expect(
        await cache.getOrLoad(accountA, const Duration(hours: 1), load),
        'value-1',
      );
      expect(
        await cache.getOrLoad(accountB, const Duration(hours: 2), load),
        'value-2',
      );
      now = now.add(const Duration(hours: 1));
      expect(
        await cache.getOrLoad(accountA, const Duration(hours: 1), load),
        'value-3',
      );
      cache.invalidate(accountA);
      expect(cache.get<String>(accountA), isNull);
      expect(cache.get<String>(accountB), 'value-2');
    });
  });
}

http.Response _jsonResponse(Object? value, [int statusCode = 200]) =>
    http.Response(
      jsonEncode(value),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );

EschoolClient _restoredClient(
  http.Client httpClient, {
  Duration requestTimeout = eschoolRequestTimeout,
}) {
  return EschoolClient(
    username: 'student',
    credentialHash: null,
    userId: 42,
    positionId: 'position-1',
    cookies: const {'JSESSIONID': 'saved-session'},
    requestTimeout: requestTimeout,
    httpClient: httpClient,
    deviceIdentityStore: _CountingIdentityStore(),
  );
}

class _CountingIdentityStore implements EschoolDeviceIdentityStore {
  static const deviceId = '12345678901234567890123456789012';
  static const pushToken =
      '1234567890123456789012345678901234567890123456789012345678901234';

  final List<String> logins = [];

  @override
  Future<EschoolDeviceIdentity> identityFor(String normalizedLogin) async {
    logins.add(normalizedLogin);
    return const EschoolDeviceIdentity(
      deviceId: deviceId,
      pushToken: pushToken,
    );
  }
}

class _MemoryDeviceValueStore implements EschoolDeviceValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
