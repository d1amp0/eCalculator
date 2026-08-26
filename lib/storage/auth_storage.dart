import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists authentication material without exposing a storage implementation
/// to the networking or UI layers.
abstract interface class AuthStorage {
  Future<String?> readSession();

  Future<void> writeSession(String value);

  Future<void> clear();
}

class SecureAuthStorage implements AuthStorage {
  SecureAuthStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'eschool.auth_session.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readSession() => _storage.read(key: _sessionKey);

  @override
  Future<void> writeSession(String value) =>
      _storage.write(key: _sessionKey, value: value);

  @override
  Future<void> clear() => _storage.delete(key: _sessionKey);
}
