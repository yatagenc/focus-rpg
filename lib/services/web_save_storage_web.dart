// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../models/player_save.dart';

class WebSaveStorage {
  static const String _storageKey = 'focus_rpg_player_saves';
  static const String _cookieKey = 'focus_rpg_player_saves';

  List<PlayerSave> load() {
    final String? rawSaves =
        _readCookie(_cookieKey) ?? html.window.localStorage[_storageKey];
    if (rawSaves == null) {
      return <PlayerSave>[];
    }

    try {
      final Object? decoded = jsonDecode(rawSaves);
      if (decoded is! List) {
        return <PlayerSave>[];
      }

      return decoded
          .whereType<Map>()
          .map(_normalizeMap)
          .map(PlayerSave.fromMap)
          .toList();
    } on FormatException {
      return <PlayerSave>[];
    } on TypeError {
      return <PlayerSave>[];
    }
  }

  void save(List<PlayerSave> saves) {
    final List<Map<String, Object?>> encodedSaves = saves
        .map((PlayerSave save) => save.toMap())
        .toList();
    final String rawSaves = jsonEncode(encodedSaves);
    html.window.localStorage[_storageKey] = rawSaves;
    _writeCookie(_cookieKey, rawSaves);
  }

  Map<String, Object?> _normalizeMap(Map<dynamic, dynamic> map) {
    return map.map(
      (dynamic key, dynamic value) =>
          MapEntry<String, Object?>(key.toString(), value as Object?),
    );
  }

  String? _readCookie(String key) {
    final String cookieHeader = html.document.cookie ?? '';
    if (cookieHeader.isEmpty) {
      return null;
    }

    for (final String cookie in cookieHeader.split(';')) {
      final List<String> parts = cookie.trim().split('=');
      if (parts.length < 2 || parts.first != key) {
        continue;
      }

      return Uri.decodeComponent(parts.sublist(1).join('='));
    }

    return null;
  }

  void _writeCookie(String key, String value) {
    final int maxAgeSeconds = const Duration(days: 3650).inSeconds;
    html.document.cookie =
        '$key=${Uri.encodeComponent(value)}; max-age=$maxAgeSeconds; path=/; SameSite=Lax';
  }
}
