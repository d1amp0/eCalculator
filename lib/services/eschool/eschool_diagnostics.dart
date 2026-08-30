import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef EschoolDiagnosticSink = void Function(String message);

/// Opt-in, metadata-only tracing for the controlled eSchool protocol audit.
///
/// This tracer deliberately never accepts request bodies, response text,
/// header values, or query parameter values. It is disabled unless the app is
/// launched with `--dart-define=ESCHOOL_PROTOCOL_AUDIT=true`.
class EschoolDiagnostics {
  EschoolDiagnostics({
    required this.enabled,
    EschoolDiagnosticSink? sink,
  }) : _sink = sink ?? ((message) => debugPrint(message));

  factory EschoolDiagnostics.fromEnvironment() => EschoolDiagnostics(
        enabled: const bool.fromEnvironment('ESCHOOL_PROTOCOL_AUDIT'),
      );

  final bool enabled;
  final EschoolDiagnosticSink _sink;
  int _sequence = 0;

  Future<http.Response> trace({
    required String method,
    required Uri uri,
    required String sessionUse,
    required Iterable<String> requestCookieNames,
    required Future<http.Response> Function() send,
  }) async {
    if (!enabled) return send();

    final stopwatch = Stopwatch()..start();
    try {
      final response = await send();
      stopwatch.stop();
      _emit({
        'sequence': ++_sequence,
        'method': method,
        'path': uri.path,
        'queryNames': uri.queryParameters.keys.map(_safeName).toList()..sort(),
        'status': response.statusCode,
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'responseBytes': response.bodyBytes.length,
        'cookieNames': <String>{
          ...requestCookieNames.map(_safeName),
          ..._setCookieNames(response),
        }.toList()
          ..sort(),
        'sessionUse': sessionUse,
        ..._responseShape(response),
      });
      return response;
    } on Object {
      stopwatch.stop();
      _emit({
        'sequence': ++_sequence,
        'method': method,
        'path': uri.path,
        'queryNames': uri.queryParameters.keys.map(_safeName).toList()..sort(),
        'status': 'transport-error',
        'elapsedMs': stopwatch.elapsedMilliseconds,
        'responseBytes': null,
        'cookieNames': requestCookieNames.map(_safeName).toList()..sort(),
        'sessionUse': sessionUse,
      });
      rethrow;
    }
  }

  /// Emits cache lifecycle metadata without accepting cache scopes, keys, or
  /// persisted values. Cache kinds and reasons are restricted to known-safe
  /// tokens before reaching the diagnostic sink.
  void cacheEvent({
    required String event,
    String? kind,
    String? reason,
    int? discovered,
    int? accepted,
    int? rejected,
    int? records,
  }) {
    if (!enabled) return;
    _emit({
      'event': _safeCacheEvent(event),
      if (kind != null) 'kind': _safeCacheKind(kind),
      if (reason != null) 'reason': _safeCacheReason(reason),
      if (discovered != null) 'discovered': discovered,
      if (accepted != null) 'accepted': accepted,
      if (rejected != null) 'rejected': rejected,
      if (records != null) 'records': records,
    });
  }

  void _emit(Map<String, Object?> metadata) {
    _sink('ESCOOL_PROTOCOL_AUDIT ${jsonEncode(metadata)}');
  }
}

Map<String, Object?> _responseShape(http.Response response) {
  try {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map) {
      final map = Map<Object?, Object?>.from(decoded);
      final shapes = _selectedShapes(map);
      return {
        'topLevelType': 'map',
        'topLevelKeys': map.keys.map((key) => _safeName('$key')).toList()
          ..sort(),
        if (shapes.isNotEmpty) 'selectedShapes': shapes,
      };
    }
    if (decoded is List) {
      final shape = _firstMapShape(decoded);
      return {
        'topLevelType': 'list',
        if (shape != null) 'selectedShapes': {'item': shape},
      };
    }
    return {'topLevelType': _typeName(decoded)};
  } on Object {
    return {'topLevelType': 'non-json-or-unreadable'};
  }
}

Map<String, Object?> _selectedShapes(Map<Object?, Object?> map) {
  const selected = {
    'result',
    'items',
    'lesson',
    'user',
    'profile',
    'currentPosition',
  };
  final shapes = <String, Object?>{};
  for (final key in selected) {
    final value = map[key];
    final shape = value is List
        ? _firstMapShape(value)
        : value is Map
            ? _mapShape(value)
            : null;
    if (shape != null) shapes[key] = shape;
  }
  return shapes;
}

Map<String, Object?>? _firstMapShape(List<dynamic> values, [int depth = 0]) {
  for (final value in values) {
    if (value is Map) return _mapShape(value, depth);
  }
  return null;
}

Map<String, Object?> _mapShape(Map<dynamic, dynamic> map, [int depth = 0]) {
  final shape = <String, Object?>{};
  final entries = map.entries.toList()
    ..sort((a, b) => '${a.key}'.compareTo('${b.key}'));
  for (final entry in entries) {
    final rawKey = '${entry.key}';
    final value = entry.value;
    final safeKey = _safeName(rawKey);
    if (depth < 2 && _nestedListFields.contains(rawKey) && value is List) {
      final item = _firstMapShape(value, depth + 1);
      shape[safeKey] = {
        'type': 'list',
        if (item != null) 'item': item,
      };
    } else if (depth < 2 && _nestedMapFields.contains(rawKey) && value is Map) {
      shape[safeKey] = {
        'type': 'map',
        'fields': _mapShape(value, depth + 1),
      };
    } else {
      shape[safeKey] = _typeName(value);
    }
  }
  return shape;
}

Iterable<String> _setCookieNames(http.Response response) sync* {
  final raw = response.headers['set-cookie'];
  if (raw == null) return;
  final matches = RegExp(r'(?:^|,\s*)([A-Za-z0-9_]+)=').allMatches(raw);
  for (final match in matches) {
    yield _safeName(match.group(1)!);
  }
}

String _typeName(Object? value) => switch (value) {
      null => 'null',
      bool() => 'bool',
      int() => 'int',
      double() => 'double',
      String() => 'string',
      List() => 'list',
      Map() => 'map',
      _ => 'other',
    };

String _safeName(String value) {
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]{0,63}$').hasMatch(value)) {
    return value;
  }
  return '[redacted-name]';
}

String _safeCacheEvent(String value) =>
    _cacheEvents.contains(value) ? value : 'redacted';

String _safeCacheKind(String value) =>
    _cacheKinds.contains(value) ? value : 'redacted';

String _safeCacheReason(String value) =>
    _cacheReasons.contains(value) ? value : 'redacted';

const _nestedListFields = {'part', 'variant', 'mark', 'file'};
const _nestedMapFields = {'currentPosition', 'unit'};
const _cacheEvents = {
  'cache-hit',
  'cache-miss',
  'cache-init',
  'cache-invalidated',
  'cache-cleared',
  'cache-storage-failure',
};
const _cacheKinds = {
  'academic-years',
  'classes',
  'periods',
  'subjects',
  'mark-dictionaries',
};
const _cacheReasons = {
  'not-found',
  'expired',
  'schema-mismatch',
  'protocol-mismatch',
  'key-mismatch',
  'decode-failed',
  'storage-read-failed',
  'storage-write-failed',
  'storage-remove-failed',
  'storage-clear-failed',
  'explicitly-invalidated',
  'cleared',
};
