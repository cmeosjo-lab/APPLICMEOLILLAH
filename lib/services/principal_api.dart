import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';

class PrincipalApiException implements Exception {
  final String message;
  PrincipalApiException(this.message);
  @override
  String toString() => message;
}

class PrincipalApi {
  static const int supportedProtocol = 6;
  final Duration timeout;

  const PrincipalApi({this.timeout = const Duration(seconds: 8)});

  Uri _uri(PrincipalConfig c, String path, [Map<String, String>? query]) =>
      Uri.parse('${c.baseUrl}$path').replace(queryParameters: query);

  Map<String, String> _authQuery(PrincipalConfig c, {String deviceId = '', String deviceName = ''}) => {
        'teacher': c.teacher,
        'code': c.code,
        if (deviceId.isNotEmpty) 'deviceId': deviceId,
        if (deviceName.isNotEmpty) 'deviceName': deviceName,
      };

  Future<bool> _pingOnce(PrincipalConfig c) async {
    try {
      final r = await http.get(_uri(c, '/api/v1/ping')).timeout(const Duration(milliseconds: 2800));
      return r.statusCode >= 200 && r.statusCode < 300;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Trois essais courts évitent qu'une microcoupure Wi-Fi soit présentée
  /// immédiatement comme un vrai mode hors connexion.
  Future<bool> ping(PrincipalConfig c) async {
    for (var i = 0; i < 3; i++) {
      if (await _pingOnce(c)) return true;
      if (i < 2) await Future<void>.delayed(const Duration(milliseconds: 650));
    }
    return false;
  }

  Future<Map<String, dynamic>?> _referenceData(
    PrincipalConfig c, {
    String deviceId = '',
    String deviceName = '',
  }) async {
    try {
      final r = await http.get(
        _uri(c, '/api/v1/reference-data', _authQuery(c, deviceId: deviceId, deviceName: deviceName)),
        headers: {'Accept': 'application/json', 'User-Agent': 'GESTCOURS-Prof-Mobile/0.6.1'},
      ).timeout(timeout);
      if (r.statusCode < 200 || r.statusCode >= 300 || r.bodyBytes.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(r.bodyBytes));
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<SyncSnapshot> sync(
    PrincipalConfig c, {
    String deviceId = '',
    String deviceName = '',
  }) async {
    final r = await http.get(
      _uri(c, '/api/v1/sync', _authQuery(c, deviceId: deviceId, deviceName: deviceName)),
      headers: {'Accept': 'application/json', 'User-Agent': 'GESTCOURS-Prof-Mobile/0.6.1'},
    ).timeout(timeout);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final body = utf8.decode(r.bodyBytes).trim();
      if (r.statusCode == 403 && body.toLowerCase().contains('appareil')) {
        throw PrincipalApiException('Nouvel appareil à autoriser sur le PC Principal.');
      }
      throw PrincipalApiException('Synchronisation refusée (${r.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    if (decoded is! Map) throw PrincipalApiException('Réponse de synchronisation invalide.');
    var snapshot = SyncSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    if (snapshot.protocolVersion != 0 && snapshot.protocolVersion != supportedProtocol) {
      throw PrincipalApiException('Version de protocole incompatible : Principal ${snapshot.protocolVersion}, mobile $supportedProtocol.');
    }

    final references = await _referenceData(c, deviceId: deviceId, deviceName: deviceName);
    if (references != null && references.isNotEmpty) snapshot = snapshot.mergeReferenceData(references);
    return snapshot;
  }

  Future<Map<String, dynamic>> sendEvents(
    PrincipalConfig c,
    List<TeacherEvent> events, {
    String deviceId = '',
    String deviceName = '',
  }) async {
    if (events.isEmpty) return {'received': 0, 'acknowledgedIds': <String>[]};
    final body = {
      'protocolVersion': supportedProtocol,
      'teacher': c.teacher,
      'events': events.map((e) => e.toProtocolV6Json()).toList(),
    };
    final r = await http.post(
      _uri(c, '/api/v1/events', _authQuery(c, deviceId: deviceId, deviceName: deviceName)),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'User-Agent': 'GESTCOURS-Prof-Mobile/0.6.1'},
      body: jsonEncode(body),
    ).timeout(timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) {
      final text = utf8.decode(r.bodyBytes).trim();
      if (r.statusCode == 403 && text.toLowerCase().contains('appareil')) {
        throw PrincipalApiException('Nouvel appareil à autoriser sur le PC Principal.');
      }
      throw PrincipalApiException('Transmission refusée (${r.statusCode}) : $text');
    }
    if (r.bodyBytes.isEmpty) return {'received': events.length};
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {'received': events.length};
  }

  Future<Map<String, Map<String, String>>> eventStatuses(
    PrincipalConfig c,
    List<String> ids, {
    String deviceId = '',
    String deviceName = '',
  }) async {
    if (ids.isEmpty) return {};
    try {
      final q = _authQuery(c, deviceId: deviceId, deviceName: deviceName);
      q['ids'] = ids.take(120).join(',');
      final r = await http.get(
        _uri(c, '/api/v1/event-status', q),
        headers: {'Accept': 'application/json', 'User-Agent': 'GESTCOURS-Prof-Mobile/0.6.1'},
      ).timeout(timeout);
      if (r.statusCode < 200 || r.statusCode >= 300 || r.bodyBytes.isEmpty) return {};
      final decoded = jsonDecode(utf8.decode(r.bodyBytes));
      if (decoded is! Map || decoded['items'] is! List) return {};
      final out = <String, Map<String, String>>{};
      for (final raw in decoded['items'] as List) {
        if (raw is! Map) continue;
        final m = Map<String, dynamic>.from(raw);
        final id = (m['id'] ?? '').toString();
        if (id.isEmpty) continue;
        out[id] = {
          'status': (m['status'] ?? 'received').toString(),
          'reviewNote': (m['reviewNote'] ?? '').toString(),
          'reviewedAt': (m['reviewedAt'] ?? '').toString(),
        };
      }
      return out;
    } catch (_) {
      return {};
    }
  }
}
