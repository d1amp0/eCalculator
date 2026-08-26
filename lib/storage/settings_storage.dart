import 'package:shared_preferences/shared_preferences.dart';

/// Storage for non-sensitive application preferences only.
class SettingsStorage {
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  Future<int?> readInt(String key) async => (await _preferences).getInt(key);

  Future<bool?> readBool(String key) async => (await _preferences).getBool(key);

  Future<String?> readString(String key) async =>
      (await _preferences).getString(key);

  Future<void> writeInt(String key, int value) async {
    await (await _preferences).setInt(key, value);
  }

  Future<void> writeBool(String key, bool value) async {
    await (await _preferences).setBool(key, value);
  }

  Future<void> writeString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }

  /// Removes authentication data written by versions before v4.
  ///
  /// The old `user` value can contain a reusable password hash, so it must not
  /// remain in SharedPreferences after upgrade.
  Future<void> removeLegacyAuthData() async {
    final preferences = await _preferences;
    await preferences.remove('user');
    await preferences.remove('saving');
  }
}
