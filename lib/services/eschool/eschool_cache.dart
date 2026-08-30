typedef EschoolClock = DateTime Function();

abstract final class EschoolCachePolicy {
  static const academicYears = Duration(hours: 24);
  static const classes = Duration(hours: 18);
  static const periods = Duration(hours: 18);
  static const subjects = Duration(hours: 12);
  static const markDictionaries = Duration(hours: 24);
}

class EschoolCacheKey {
  const EschoolCacheKey(this.kind, this.scope);

  final String kind;
  final String scope;

  @override
  bool operator ==(Object other) =>
      other is EschoolCacheKey && other.kind == kind && other.scope == scope;

  @override
  int get hashCode => Object.hash(kind, scope);
}

class EschoolMetadataCache {
  EschoolMetadataCache({EschoolClock? clock}) : _clock = clock ?? DateTime.now;

  final EschoolClock _clock;
  final Map<EschoolCacheKey, _CacheEntry<Object>> _entries = {};

  T? get<T>(EschoolCacheKey key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (!_clock().isBefore(entry.expiresAt)) {
      _entries.remove(key);
      return null;
    }
    return entry.value as T;
  }

  void put<T extends Object>(EschoolCacheKey key, T value, Duration ttl) {
    _entries[key] = _CacheEntry<Object>(value, _clock().add(ttl));
  }

  Future<T> getOrLoad<T extends Object>(
    EschoolCacheKey key,
    Duration ttl,
    Future<T> Function() loader,
  ) async {
    final cached = get<T>(key);
    if (cached != null) return cached;
    final loaded = await loader();
    put(key, loaded, ttl);
    return loaded;
  }

  void invalidate(EschoolCacheKey key) => _entries.remove(key);

  void invalidateWhere(bool Function(EschoolCacheKey key) predicate) {
    _entries.removeWhere((key, _) => predicate(key));
  }

  void clear() => _entries.clear();
}

class _CacheEntry<T> {
  const _CacheEntry(this.value, this.expiresAt);

  final T value;
  final DateTime expiresAt;
}
