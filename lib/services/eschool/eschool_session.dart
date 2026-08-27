import 'dart:convert';

import 'package:ecalculator/services/eschool/eschool_client.dart';
import 'package:ecalculator/storage/auth_storage.dart';
import 'package:ecalculator/storage/settings_storage.dart';

enum LoginResult {
  authenticated,
  authenticatedWithoutPersistence,
  invalidCredentials,
  unavailable,
  forbidden,
  rateLimited,
  storageFailure,
}

typedef EschoolClientFactory = EschoolClient Function({
  required String username,
  required String password,
});

typedef RestoredEschoolClientFactory = EschoolClient Function({
  required String username,
  required String? credentialHash,
  required Map<String, String> cookies,
  required int? userId,
});

class EschoolSession {
  EschoolSession({
    AuthStorage? authStorage,
    SettingsStorage? settingsStorage,
    EschoolClientFactory? clientFactory,
    RestoredEschoolClientFactory? restoredClientFactory,
  })  : _authStorage = authStorage ?? SecureAuthStorage(),
        _settingsStorage = settingsStorage ?? SettingsStorage(),
        _clientFactory = clientFactory ?? EschoolClient.fromPassword,
        _restoredClientFactory = restoredClientFactory ?? _createRestoredClient;

  final AuthStorage _authStorage;
  final SettingsStorage _settingsStorage;
  final EschoolClientFactory _clientFactory;
  final RestoredEschoolClientFactory _restoredClientFactory;

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
      final candidate = _restoredClientFactory(
        username: saved['username'] as String,
        credentialHash: saved['credentialHash'] as String?,
        cookies: Map<String, String>.from(saved['cookies'] as Map),
        userId: saved['userId'] as int?,
      );
      final validation = await candidate.validateSession();
      if (validation == SessionValidation.unavailable) return false;
      if (validation == SessionValidation.unauthorized) {
        final authentication = await candidate.authenticate();
        if (authentication == AuthenticationResult.invalidCredentials) {
          await _clearStoredSessionBestEffort();
          return false;
        }
        if (authentication != AuthenticationResult.authenticated) return false;
      }

      _remembered = true;
      _client = candidate;
      candidate.onSessionChanged = _persistCurrentSession;
      try {
        await _persistCurrentSession();
      } on Object {
        // The restored session is already authenticated. Keep it in memory,
        // but do not repeatedly attempt writes to an unavailable secure store.
        _remembered = false;
      }
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
    final candidate = _clientFactory(username: username, password: password);
    final AuthenticationResult authentication;
    try {
      authentication = await candidate.authenticate();
    } on Object {
      return LoginResult.unavailable;
    }
    switch (authentication) {
      case AuthenticationResult.invalidCredentials:
        return LoginResult.invalidCredentials;
      case AuthenticationResult.unavailable:
        return LoginResult.unavailable;
      case AuthenticationResult.forbidden:
        return LoginResult.forbidden;
      case AuthenticationResult.rateLimited:
        return LoginResult.rateLimited;
      case AuthenticationResult.authenticated:
        break;
    }

    if (!rememberMe) {
      try {
        await _authStorage.clear();
      } on Object {
        return LoginResult.storageFailure;
      }
      _activate(candidate, remembered: false);
      return LoginResult.authenticated;
    }

    try {
      await _authStorage.writeSession(_encodeSession(candidate));
    } on Object {
      try {
        await _authStorage.clear();
      } on Object {
        return LoginResult.storageFailure;
      }
      _activate(candidate, remembered: false);
      return LoginResult.authenticatedWithoutPersistence;
    }

    _activate(candidate, remembered: true);
    return LoginResult.authenticated;
  }

  Future<void> logout() async {
    // Keep the in-memory session usable until every persistent authentication
    // location has been cleared. A failed secure-store operation can then be
    // retried without pretending that logout succeeded.
    await _authStorage.clear();
    await _settingsStorage.removeLegacyAuthData();

    final oldClient = _client;
    _client = null;
    _remembered = false;
    oldClient?.clearSession();
  }

  Future<void> _persistCurrentSession() async {
    if (!_remembered || _client == null) return;
    await _authStorage.writeSession(_encodeSession(_client!));
  }

  void _activate(EschoolClient candidate, {required bool remembered}) {
    _client = candidate;
    _remembered = remembered;
    candidate.onSessionChanged = _persistCurrentSession;
  }

  String _encodeSession(EschoolClient current) {
    return json.encode({
      'username': current.username,
      'credentialHash': current.credentialHash,
      'cookies': current.cookies,
      'userId': current.userId,
    });
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

EschoolClient _createRestoredClient({
  required String username,
  required String? credentialHash,
  required Map<String, String> cookies,
  required int? userId,
}) {
  return EschoolClient(
    username: username,
    credentialHash: credentialHash,
    cookies: cookies,
    userId: userId,
  );
}

final eschoolSession = EschoolSession();
