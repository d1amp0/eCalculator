import 'dart:convert';

import 'package:ecalculator/services/eschool/eschool_client.dart';
import 'package:ecalculator/storage/auth_storage.dart';
import 'package:ecalculator/storage/settings_storage.dart';

enum LoginResult {
  authenticated,
  authenticatedWithoutPersistence,
  invalidCredentials,
}

class EschoolSession {
  EschoolSession({
    AuthStorage? authStorage,
    SettingsStorage? settingsStorage,
  })  : _authStorage = authStorage ?? SecureAuthStorage(),
        _settingsStorage = settingsStorage ?? SettingsStorage();

  final AuthStorage _authStorage;
  final SettingsStorage _settingsStorage;

  EschoolClient? _client;
  bool _remembered = false;

  bool get isAuthenticated => _client != null;

  EschoolClient get client {
    final value = _client;
    if (value == null) throw StateError('No authenticated eSchool session');
    return value;
  }

  Future<bool> restore() async {
    await _removeLegacyAuthentication();

    final String? encoded;
    try {
      encoded = await _authStorage.readSession();
    } on Object {
      return false;
    }
    if (encoded == null) return false;

    try {
      final saved = json.decode(encoded) as Map<String, dynamic>;
      final candidate = EschoolClient(
        username: saved['username'] as String,
        credentialHash: saved['credentialHash'] as String?,
        cookies: Map<String, String>.from(saved['cookies'] as Map),
        userId: saved['userId'] as int?,
      );
      final validation = await candidate.validateSession();
      if (validation == SessionValidation.unavailable) return false;
      if (validation == SessionValidation.unauthorized &&
          !await candidate.authenticate()) {
        return false;
      }

      _remembered = true;
      _client = candidate;
      candidate.onSessionChanged = _persistCurrentSession;
      await _persistCurrentSession();
      return true;
    } on FormatException {
      await _clearStoredSessionBestEffort();
      return false;
    } on TypeError {
      await _clearStoredSessionBestEffort();
      return false;
    } on Object {
      return false;
    }
  }

  Future<LoginResult> login({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final candidate = EschoolClient.fromPassword(
      username: username,
      password: password,
    );
    try {
      if (!await candidate.authenticate()) {
        return LoginResult.invalidCredentials;
      }
    } on Object {
      return LoginResult.invalidCredentials;
    }

    _client = candidate;
    _remembered = rememberMe;
    candidate.onSessionChanged = _persistCurrentSession;

    try {
      if (rememberMe) {
        await _persistCurrentSession();
      } else {
        await _authStorage.clear();
      }
      return LoginResult.authenticated;
    } on Object {
      _remembered = false;
      return LoginResult.authenticatedWithoutPersistence;
    }
  }

  Future<void> logout() async {
    final oldClient = _client;
    _client = null;
    _remembered = false;
    oldClient?.clearSession();
    await _authStorage.clear();
    await _removeLegacyAuthentication();
  }

  Future<void> _persistCurrentSession() async {
    if (!_remembered || _client == null) return;
    final current = _client!;
    await _authStorage.writeSession(json.encode({
      'username': current.username,
      'credentialHash': current.credentialHash,
      'cookies': current.cookies,
      'userId': current.userId,
    }));
  }

  Future<void> _removeLegacyAuthentication() async {
    try {
      await _settingsStorage.removeLegacyAuthData();
    } on Object {
      // SharedPreferences is never used as an authentication fallback.
    }
  }

  Future<void> _clearStoredSessionBestEffort() async {
    try {
      await _authStorage.clear();
    } on Object {
      // An inaccessible secure store cannot be replaced by insecure storage.
    }
  }
}

final eschoolSession = EschoolSession();
