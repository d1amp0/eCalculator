import 'dart:async';
import 'dart:convert';

import 'package:ecalculator/services/eschool/eschool_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('classifies an explicit login timeout as unavailable without retry',
      () async {
    var requests = 0;
    final client = EschoolClient.fromPassword(
      username: 'student',
      password: 'password',
      requestTimeout: const Duration(milliseconds: 1),
      httpClient: MockClient((request) {
        requests++;
        return Completer<http.Response>().future;
      }),
    );

    expect(await client.authenticate(), AuthenticationResult.unavailable);
    expect(requests, 1);
  });

  test('applies the explicit timeout to authenticated GET requests', () async {
    var requests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      userId: 42,
      requestTimeout: const Duration(milliseconds: 1),
      httpClient: MockClient((request) {
        requests++;
        return Completer<http.Response>().future;
      }),
    );

    await expectLater(
      client.get('getDiaryUnits'),
      throwsA(isA<TimeoutException>()),
    );
    expect(requests, 1);
  });

  test('applies the explicit timeout to PUT requests without retry', () async {
    var requests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      userId: 42,
      requestTimeout: const Duration(milliseconds: 1),
      httpClient: MockClient((request) {
        requests++;
        return Completer<http.Response>().future;
      }),
    );

    await expectLater(
      client.put('send', const {}),
      throwsA(isA<TimeoutException>()),
    );
    expect(requests, 1);
  });

  test('classifies a restored-session validation timeout as unavailable',
      () async {
    var requests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      cookies: const {'JSESSIONID': 'saved-session'},
      requestTimeout: const Duration(milliseconds: 1),
      httpClient: MockClient((request) {
        requests++;
        return Completer<http.Response>().future;
      }),
    );

    expect(await client.validateSession(), SessionValidation.unavailable);
    expect(requests, 1);
  });

  test('validates a restored session without logging in again', () async {
    var loginRequests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      cookies: const {'JSESSIONID': 'saved-session'},
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/login')) loginRequests++;
        expect(request.headers['Cookie'], contains('JSESSIONID=saved-session'));
        return http.Response(json.encode({'userId': 42}), 200);
      }),
    );

    expect(await client.validateSession(), SessionValidation.valid);
    expect(client.userId, 42);
    expect(loginRequests, 0);
  });

  test('reauthenticates once after a 401 and retries the request', () async {
    var protectedRequests = 0;
    var loginRequests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      userId: 42,
      cookies: const {'JSESSIONID': 'expired-session'},
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          loginRequests++;
          return http.Response(
            '{}',
            200,
            headers: {'set-cookie': 'JSESSIONID=fresh-session; Path=/'},
          );
        }
        if (request.url.path.endsWith('/state')) {
          return http.Response(json.encode({'userId': 42}), 200);
        }

        protectedRequests++;
        if (protectedRequests == 1) return http.Response('{}', 401);
        expect(request.headers['Cookie'], contains('JSESSIONID=fresh-session'));
        return http.Response(json.encode({'result': []}), 200);
      }),
    );

    expect(await client.get('getDiaryUnits'), {'result': []});
    expect(loginRequests, 1);
    expect(protectedRequests, 2);
  });

  test('does not loop when a retried request is still unauthorized', () async {
    var loginRequests = 0;
    final client = EschoolClient(
      username: 'student',
      credentialHash: 'derived-credential',
      userId: 42,
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/login')) {
          loginRequests++;
          return http.Response(
            '{}',
            200,
            headers: {'set-cookie': 'JSESSIONID=fresh-session; Path=/'},
          );
        }
        if (request.url.path.endsWith('/state')) {
          return http.Response(json.encode({'userId': 42}), 200);
        }
        return http.Response('{}', 401);
      }),
    );

    await expectLater(
      client.get('getDiaryUnits'),
      throwsA(
        isA<EschoolRequestException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(loginRequests, 1);
  });
}
