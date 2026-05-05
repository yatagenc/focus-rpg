// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import '../data/models/app_settings.dart';

class WebSettingsStorage {
  static const String _storageKey = 'focus_rpg_app_settings';
  static const String _cookieKey = 'focus_rpg_app_settings';

  AppSettings? load() {
    final String? rawSettings =
        _readCookie(_cookieKey) ?? html.window.localStorage[_storageKey];
    if (rawSettings == null) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(rawSettings);
      if (decoded is! Map<String, Object?>) {
        return null;
      }

      return AppSettings.fromMap(decoded);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  void save(AppSettings settings) {
    final String rawSettings = jsonEncode(settings.toMap());
    html.window.localStorage[_storageKey] = rawSettings;
    _writeCookie(_cookieKey, rawSettings);
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
