import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';
import '../utils/constants.dart';

/// Thin wrapper around [SharedPreferences] for local persistence, mirroring
/// the web app's localStorage usage.
class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _instance() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<AppData> loadData() async {
    final prefs = await _instance();
    final raw = prefs.getString(prefsDataKey) ?? prefs.getString(prefsLegacyDataKey);
    if (raw == null || raw.isEmpty) return AppData.empty();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return AppData.fromJson(json);
    } catch (_) {
      return AppData.empty();
    }
  }

  Future<void> saveData(AppData data) async {
    final prefs = await _instance();
    await prefs.setString(prefsDataKey, jsonEncode(data.toJson()));
  }

  Future<void> clearData() async {
    final prefs = await _instance();
    await prefs.remove(prefsDataKey);
    await prefs.remove(prefsLegacyDataKey);
  }

  Future<String?> getTheme() async {
    final prefs = await _instance();
    return prefs.getString(prefsThemeKey);
  }

  Future<void> setTheme(String theme) async {
    final prefs = await _instance();
    await prefs.setString(prefsThemeKey, theme);
  }

  Future<String?> getSound() async {
    final prefs = await _instance();
    return prefs.getString(prefsSoundKey);
  }

  Future<void> setSound(String sound) async {
    final prefs = await _instance();
    await prefs.setString(prefsSoundKey, sound);
  }

  Future<Map<String, String>?> getCloudSettings() async {
    final prefs = await _instance();
    final raw = prefs.getString(prefsCloudSettingsKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return {'url': json['url']?.toString() ?? '', 'key': json['key']?.toString() ?? ''};
    } catch (_) {
      return null;
    }
  }

  Future<void> setCloudSettings(String url, String key) async {
    final prefs = await _instance();
    await prefs.setString(prefsCloudSettingsKey, jsonEncode({'url': url, 'key': key}));
  }

  Future<bool> getPending() async {
    final prefs = await _instance();
    return prefs.getString(prefsPendingKey) == '1';
  }

  Future<void> setPending(bool pending) async {
    final prefs = await _instance();
    if (pending) {
      await prefs.setString(prefsPendingKey, '1');
    } else {
      await prefs.remove(prefsPendingKey);
    }
  }
}
