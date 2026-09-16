import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';

class LocalStore {
  static const _configKey = 'principal_config_v1';
  static const _snapshotKey = 'school_snapshot_v1';
  static const _queueKey = 'teacher_event_queue_v1';
  static const _deviceKey = 'mobile_device_id_v1';

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

  Future<List<TeacherEvent>> loadQueue() async {
    final p = await _prefs;
    final raw = p.getString(_queueKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw);
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => TeacherEvent.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveQueue(List<TeacherEvent> events) async {
    final p = await _prefs;
    await p.setString(_queueKey, jsonEncode(events.map((e) => e.toLocalJson()).toList()));
  }

  Future<void> enqueue(TeacherEvent event) async {
    final events = await loadQueue();
    events.add(event);
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
}
