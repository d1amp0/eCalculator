import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ecalculator/services/eschool/eschool_client.dart';
import 'package:ecalculator/services/eschool/eschool_device_identity.dart';
import 'package:ecalculator/services/eschool/eschool_session.dart';
import 'package:ecalculator/storage/auth_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('login classification', () {
    test('classifies rejected credentials', () async {
      final session = _sessionForResponses([http.Response('{}', 401)]);

      expect(await _login(session), LoginResult.invalidCredentials);
    });

    test('classifies forbidden without retrying', () async {
      var requests = 0;
      final session = _sessionForClient(
        MockClient((request) async {
          requests++;
          return http.Response('{}', 403);
        }),
      );

      expect(await _login(session), LoginResult.forbidden);
      expect(requests, 1);
    });

    test('classifies rate limiting without retrying', () async {
      var requests = 0;
      final session = _sessionForClient(
        MockClient((request) async {
          requests++;
          return http.Response('{}', 429);
        }),
      );

      expect(await _login(session), LoginResult.rateLimited);
      expect(requests, 1);
    });

    test('classifies server and network failures as unavailable', () async {
      final serverFailure = _sessionForResponses([http.Response('{}', 503)]);
      final networkFailure = _sessionForClient(
        MockClient((request) => throw const SocketException('offline')),
      );
      final timeout = _sessionForClient(
        MockClient((request) => throw TimeoutException('timed out')),
      );

      expect(await _login(serverFailure), LoginResult.unavailable);
      expect(await _login(networkFailure), LoginResult.unavailable);
      expect(await _login(timeout), LoginResult.unavailable);
    });

    test('returns a structured MFA_REQUIRED foreground result', () async {
      final session = _sessionForResponses([
        http.Response(
          jsonEncode({
            'code': 'MFA_REQUIRED',
            'challengeToken': 'challenge-secret',
            'factors': [
              {'factorId': 'email', 'type': 'EMAIL'},
            ],
          }),
          409,
        ),
      ]);

      expect(await _login(session), LoginResult.mfaRequired);
      expect(session.state, EschoolSessionState.mfaRequired);
      expect(session.mfaChallenge?.challengeToken, 'challenge-secret');
    });

    test('authenticates after login and state succeed', () async {
      final storage = MemoryAuthStorage();
      final session = _sessionForResponses([
        http.Response(
          '{}',
          200,
          headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
        ),
        http.Response(json.encode({'userId': 42}), 200),
      ], storage: storage);

      expect(
        await _login(session, rememberMe: true),
        LoginResult.authenticated,
      );
      expect(session.isAuthenticated, isTrue);
      expect(storage.value, isNot(contains('credentialHash')));
      expect(storage.value, isNot(contains('derived')));
    });

    test(
      'keeps account B only in memory after failed write and safe cleanup',
      () async {
        final storage = MemoryAuthStorage()
          ..value = _savedAccountA
          ..failWrite = true;
        final session = _sessionForResponses([
          http.Response(
            '{}',
            200,
            headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
          ),
          http.Response(json.encode({'userId': 42}), 200),
        ], storage: storage);

        expect(
          await _login(
            session,
            username: 'account-b',
            rememberMe: true,
          ),
          LoginResult.authenticatedWithoutPersistence,
        );
        expect(session.isAuthenticated, isTrue);
        expect(session.client.username, 'account-b');
        expect(storage.value, isNull);
        expect(storage.clearCalls, 1);
      },
    );

    test('rejects account B when non-remembered cleanup fails', () async {
      final storage = MemoryAuthStorage()
        ..value = _savedAccountA
        ..failClear = true;
      final session = _sessionForResponses([
        http.Response(
          '{}',
          200,
          headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
        ),
        http.Response(json.encode({'userId': 42}), 200),
      ], storage: storage);

      expect(
        await _login(session, username: 'account-b'),
        LoginResult.storageFailure,
      );
      expect(session.isAuthenticated, isFalse);
      expect(() => session.client, throwsStateError);
      expect(storage.value, _savedAccountA);
      expect(storage.clearCalls, 1);
    });

    test('rejects account B when both write and cleanup fail', () async {
      final storage = MemoryAuthStorage()
        ..value = _savedAccountA
        ..failWrite = true
        ..failClear = true;
      final session = _sessionForResponses([
        http.Response(
          '{}',
          200,
          headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
        ),
        http.Response(json.encode({'userId': 42}), 200),
      ], storage: storage);

      expect(
        await _login(
          session,
          username: 'account-b',
          rememberMe: true,
        ),
        LoginResult.storageFailure,
      );
      expect(session.isAuthenticated, isFalse);
      expect(() => session.client, throwsStateError);
      expect(storage.value, _savedAccountA);
      expect(storage.clearCalls, 1);
    });
  });

  group('logout', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'theme': 2,
        'period_type': 1,
        'user': 'legacy credential',
        'saving': true,
      });
    });

    test('clears authentication and preserves unrelated settings', () async {
      final storage = MemoryAuthStorage();
      final session = _successfulSession(storage);
      expect(
        await _login(session, rememberMe: true),
        LoginResult.authenticated,
      );

      await session.logout();

      final preferences = await SharedPreferences.getInstance();
      expect(storage.value, isNull);
      expect(session.isAuthenticated, isFalse);
      expect(preferences.getString('user'), isNull);
      expect(preferences.getBool('saving'), isNull);
      expect(preferences.getInt('theme'), 2);
      expect(preferences.getInt('period_type'), 1);
    });

    test(
      'does not pretend logout succeeded when secure cleanup fails',
      () async {
        final storage = MemoryAuthStorage();
        final session = _successfulSession(storage);
        expect(
          await _login(session, rememberMe: true),
          LoginResult.authenticated,
        );
        storage.failClear = true;

        await expectLater(session.logout(), throwsStateError);

        expect(session.isAuthenticated, isTrue);
        expect(session.client.cookies, isNotEmpty);
        expect(storage.value, isNotNull);
      },
    );
  });

  group('session restore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('keeps saved authentication after a temporary failure', () async {
      final storage = MemoryAuthStorage()..value = _savedSession;
      final session = EschoolSession(
        authStorage: storage,
        restoredClientFactory: _restoredClientFactory(
          MockClient((request) => throw const SocketException('offline')),
        ),
      );

      expect(await session.restore(), isFalse);
      expect(storage.value, _savedSession);
      expect(storage.clearCalls, 0);
    });

    test('activates a valid saved cookie without login', () async {
      final storage = MemoryAuthStorage()..value = _savedSession;
      var requests = 0;
      final session = EschoolSession(
        authStorage: storage,
        restoredClientFactory: _restoredClientFactory(
          MockClient((request) async {
            requests++;
            expect(request.url.path, endsWith('/state'));
            return http.Response(jsonEncode({'userId': 42}), 200);
          }),
        ),
      );

      expect(await session.restore(), isTrue);
      expect(session.isAuthenticated, isTrue);
      expect(session.state, EschoolSessionState.valid);
      expect(requests, 1);
      expect(storage.value, isNot(contains('credentialHash')));
    });

    for (final status in [403, 429]) {
      test('preserves saved cookie and state after restore status $status',
          () async {
        final storage = MemoryAuthStorage()..value = _savedSession;
        var requests = 0;
        final session = EschoolSession(
          authStorage: storage,
          restoredClientFactory: _restoredClientFactory(
            MockClient((request) async {
              requests++;
              return http.Response('{}', status);
            }),
          ),
        );

        expect(await session.restore(), isFalse);
        expect(requests, 1);
        expect(storage.value, _savedSession);
        expect(
          session.state,
          status == 403
              ? EschoolSessionState.forbidden
              : EschoolSessionState.rateLimited,
        );
      });
    }

    test('clears corrupt saved authentication', () async {
      final storage = MemoryAuthStorage()..value = '{not json';
      final session = EschoolSession(authStorage: storage);

      expect(await session.restore(), isFalse);
      expect(storage.value, isNull);
      expect(storage.clearCalls, 1);
    });

    test(
      'clears an expired saved session without reauthentication',
      () async {
        final storage = MemoryAuthStorage()..value = _savedSession;
        var requests = 0;
        final session = EschoolSession(
          authStorage: storage,
          restoredClientFactory: _restoredClientFactory(
            MockClient((request) async {
              requests++;
              return http.Response('{}', 401);
            }),
          ),
        );

        expect(await session.restore(), isFalse);
        expect(requests, 1);
        expect(storage.value, isNull);
        expect(storage.clearCalls, 1);
      },
    );
  });
}

const _savedSession =
    '{"username":"student","credentialHash":"derived","cookies":{"JSESSIONID":"saved"},"userId":42}';
const _savedAccountA =
    '{"username":"account-a","credentialHash":"derived-a","cookies":{"JSESSIONID":"account-a-session"},"userId":1}';

Future<LoginResult> _login(
  EschoolSession session, {
  String username = 'student',
  bool rememberMe = false,
}) {
  return session.login(
    username: username,
    password: 'password',
    rememberMe: rememberMe,
  );
}

EschoolSession _successfulSession(MemoryAuthStorage storage) {
  return _sessionForResponses([
    http.Response(
      '{}',
      200,
      headers: {'set-cookie': 'JSESSIONID=session; Path=/'},
    ),
    http.Response(json.encode({'userId': 42}), 200),
  ], storage: storage);
}

EschoolSession _sessionForResponses(
  List<http.Response> responses, {
  MemoryAuthStorage? storage,
}) {
  var index = 0;
  return _sessionForClient(
    MockClient((request) async => responses[index++]),
    storage: storage,
  );
}

EschoolSession _sessionForClient(
  http.Client httpClient, {
  MemoryAuthStorage? storage,
}) {
  return EschoolSession(
    authStorage: storage ?? MemoryAuthStorage(),
    clientFactory: ({required username, required password}) =>
        EschoolClient.fromPassword(
      username: username,
      password: password,
      httpClient: httpClient,
      deviceIdentityStore: _FixedIdentityStore(),
    ),
  );
}

RestoredEschoolClientFactory _restoredClientFactory(http.Client httpClient) {
  return ({
    required username,
    required cookies,
    required userId,
    required positionId,
    required organizationId,
  }) =>
      EschoolClient(
        username: username,
        credentialHash: null,
        cookies: cookies,
        userId: userId,
        positionId: positionId,
        organizationId: organizationId,
        httpClient: httpClient,
      );
}

class _FixedIdentityStore implements EschoolDeviceIdentityStore {
  @override
  Future<EschoolDeviceIdentity> identityFor(String normalizedLogin) async =>
      const EschoolDeviceIdentity(
        deviceId: '12345678901234567890123456789012',
        pushToken:
            '1234567890123456789012345678901234567890123456789012345678901234',
      );
}

class MemoryAuthStorage implements AuthStorage {
  String? value;
  bool failWrite = false;
  bool failClear = false;
  int clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    if (failClear) throw StateError('secure storage unavailable');
    value = null;
  }

  @override
  Future<String?> readSession() async => value;

  @override
  Future<void> writeSession(String value) async {
    if (failWrite) throw StateError('secure storage unavailable');
    this.value = value;
  }
}
