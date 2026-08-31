import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _characters =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

class EschoolDeviceIdentity {
  const EschoolDeviceIdentity({
    required this.deviceId,
    required this.pushToken,
  });

  final String deviceId;
  final String pushToken;
}

abstract interface class EschoolDeviceIdentityStore {
  Future<EschoolDeviceIdentity> identityFor(String normalizedLogin);
}

abstract interface class EschoolDeviceValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class FlutterSecureDeviceValueStore implements EschoolDeviceValueStore {
  FlutterSecureDeviceValueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Keeps the installation ID and per-account push token separate from the
/// saved login session so logout/session expiry never rotates the device.
class SecureEschoolDeviceIdentityStore implements EschoolDeviceIdentityStore {
  SecureEschoolDeviceIdentityStore({EschoolDeviceValueStore? store})
      : _store = store ?? FlutterSecureDeviceValueStore();

  static const _deviceIdKey = 'eschool.device.id.v1';
  static const _pushTokenPrefix = 'eschool.device.push.v1.';

  final EschoolDeviceValueStore _store;

  @override
  Future<EschoolDeviceIdentity> identityFor(String normalizedLogin) async {
    var deviceId = await _store.read(_deviceIdKey);
    if (deviceId == null || deviceId.length != 32) {
      deviceId = generateEschoolRandomString(32);
      await _store.write(_deviceIdKey, deviceId);
    }

    final accountKey = sha256.convert(normalizedLogin.codeUnits).toString();
    final pushKey = '$_pushTokenPrefix$accountKey';
    var pushToken = await _store.read(pushKey);
    if (pushToken == null || pushToken.length != 64) {
      pushToken = generateEschoolRandomString(64);
      await _store.write(pushKey, pushToken);
    }
    return EschoolDeviceIdentity(
      deviceId: deviceId,
      pushToken: pushToken,
    );
  }
}

class EschoolDeviceMetadata {
  const EschoolDeviceMetadata({
    required this.deviceName,
    required this.deviceModel,
    required this.cliOs,
    this.cliOsVer,
  });

  final String deviceName;
  final String deviceModel;
  final String cliOs;
  final String? cliOsVer;

  factory EschoolDeviceMetadata.current() {
    final platform = defaultTargetPlatform.name;
    return EschoolDeviceMetadata(
      deviceName: kIsWeb ? 'Web browser' : 'eCalculator',
      deviceModel: kIsWeb ? 'Flutter Web' : 'Flutter',
      cliOs: platform,
      cliOsVer: null,
    );
  }
}

String normalizeEschoolLogin(String login) => login.trim().toLowerCase();

@visibleForTesting
String generateEschoolRandomString(int length) {
  final random = Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => _characters.codeUnitAt(random.nextInt(_characters.length)),
    ),
  );
}
