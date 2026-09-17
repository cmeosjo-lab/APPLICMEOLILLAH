import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';

class LocalStore {
  static const _configKey = 'principal_config_v1';
  static const _snapshotKey = 'school_snapshot_v1';
  static const _queueKey = 'teacher_event_queue_v1';
  static const _sentKey = 'teacher_event_sent_v1';
  static const _deviceKey = 'mobile_device_id_v1';
  static const _deviceNameKey = 'mobile_device_name_v1';
  static const _syncLogKey = 'sync_log_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveConfig(PrincipalConfig config) async {
    final p = await _prefs;
    await p.setString(_configKey, jsonEncode(config.toJson()));
  }

  Future<PrincipalConfig?> loadConfig() async {
    final p = await _prefs;
    final raw = p.getString(_configKey);
    if (raw == null) return null;
    return PrincipalConfig.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<void> clearConfig() async {
    final p = await _prefs;
    await p.remove(_configKey);
  }

  Future<void> saveSnapshot(SyncSnapshot snapshot) async {
    final p = await _prefs;
    await p.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
  }

  Future<SyncSnapshot?> loadSnapshot() async {
    final p = await _prefs;
    final raw = p.getString(_snapshotKey);
    if (raw == null) return null;
    return SyncSnapshot.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<List<TeacherEvent>> _loadEvents(String key) async {
    final p = await _prefs;
    final raw = p.getString(key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => TeacherEvent.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> _saveEvents(String key, List<TeacherEvent> events) async {
    final p = await _prefs;
    await p.setString(key, jsonEncode(events.map((e) => e.toLocalJson()).toList()));
  }

  Future<List<TeacherEvent>> loadQueue() => _loadEvents(_queueKey);
  Future<void> saveQueue(List<TeacherEvent> events) => _saveEvents(_queueKey, events);
  Future<List<TeacherEvent>> loadSentHistory() => _loadEvents(_sentKey);

  Future<void> saveSentHistory(List<TeacherEvent> events) async {
    var copy = List<TeacherEvent>.from(events);
    if (copy.length > 200) copy = copy.sublist(copy.length - 200);
    await _saveEvents(_sentKey, copy);
  }

  Future<void> enqueue(TeacherEvent event) async {
    final events = await loadQueue();
    events.add(event);
    await saveQueue(events);
  }

  Future<void> removeQueued(String id) async {
    final events = await loadQueue();
    events.removeWhere((e) => e.id == id);
    await saveQueue(events);
  }

  Future<String> getOrCreateDeviceId() async {
    final p = await _prefs;
    var value = p.getString(_deviceKey);
    if (value == null || value.isEmpty) {
      value = 'PHONE-${DateTime.now().microsecondsSinceEpoch}';
      await p.setString(_deviceKey, value);
    }
    return value;
  }

  Future<String> _detectDeviceName() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final d = await info.androidInfo;
        final maker = d.manufacturer.trim();
        final model = d.model.trim();
        final joined = [maker, model].where((e) => e.isNotEmpty).join(' ');
        if (joined.isNotEmpty) return joined;
      } else if (Platform.isIOS) {
        final d = await info.iosInfo;
        final n = d.name.trim();
        final model = d.model.trim();
        final joined = [n, model].where((e) => e.isNotEmpty).join(' — ');
        if (joined.isNotEmpty) return joined;
      }
    } catch (_) {}
    return 'Téléphone Prof';
  }

  Future<String> getOrCreateDeviceName() async {
    final p = await _prefs;
    var value = p.getString(_deviceNameKey)?.trim() ?? '';
    if (value.isEmpty) {
      value = await _detectDeviceName();
      await p.setString(_deviceNameKey, value);
    }
    return value;
  }

  Future<void> setDeviceName(String value) async {
    final p = await _prefs;
    final v = value.trim();
    if (v.isEmpty) {
      await p.remove(_deviceNameKey);
    } else {
      await p.setString(_deviceNameKey, v);
    }
  }

  Future<void> appendSyncLog(String message) async {
    final p = await _prefs;
    final items = p.getStringList(_syncLogKey) ?? <String>[];
    final now = DateTime.now();
    final stamp = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    items.add('$stamp  $message');
    if (items.length > 200) items.removeRange(0, items.length - 200);
    await p.setStringList(_syncLogKey, items);
  }

  Future<List<String>> loadSyncLog() async {
    final p = await _prefs;
    return List<String>.from(p.getStringList(_syncLogKey) ?? const <String>[]);
  }

  Future<void> clearSyncLog() async {
    final p = await _prefs;
    await p.remove(_syncLogKey);
  }

  Future<String> exportBundle() async {
    final p = await _prefs;
    return jsonEncode({
      'version': 2,
      'config': p.getString(_configKey),
      'snapshot': p.getString(_snapshotKey),
      'queue': p.getString(_queueKey),
      'sent': p.getString(_sentKey),
      'deviceId': p.getString(_deviceKey),
      'deviceName': p.getString(_deviceNameKey),
      'syncLog': p.getStringList(_syncLogKey) ?? <String>[],
    });
  }

  Future<void> importBundle(String raw) async {
    final data = jsonDecode(raw);
    if (data is! Map) throw const FormatException('Sauvegarde invalide');
    final p = await _prefs;
    Future<void> putString(String key, dynamic value) async {
      final v = value?.toString() ?? '';
      if (v.isEmpty || v == 'null') { await p.remove(key); } else { await p.setString(key, v); }
    }
    await putString(_configKey, data['config']);
    await putString(_snapshotKey, data['snapshot']);
    await putString(_queueKey, data['queue']);
    await putString(_sentKey, data['sent']);
    await putString(_deviceKey, data['deviceId']);
    await putString(_deviceNameKey, data['deviceName']);
    if (data['syncLog'] is List) {
      await p.setStringList(_syncLogKey, (data['syncLog'] as List).map((e) => e.toString()).toList());
    }
  }
}
