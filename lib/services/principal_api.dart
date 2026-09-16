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

  Uri _uri(PrincipalConfig c, String path, [Map<String, String>? query]) => Uri.parse('${c.baseUrl}$path').replace(queryParameters: query);

  Future<bool> ping(PrincipalConfig c) async {
    try {
      final r = await http.get(_uri(c, '/api/v1/ping')).timeout(timeout);
      return r.statusCode >= 200 && r.statusCode < 300;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> _referenceData(PrincipalConfig c) async {
    try {
      final r = await http.get(
        _uri(c, '/api/v1/reference-data', {'teacher': c.teacher, 'code': c.code}),
        headers: {'Accept': 'application/json', 'User-Agent': 'ECOLE-Gestion-Prof-Mobile/0.3'},
      ).timeout(timeout);
      if (r.statusCode < 200 || r.statusCode >= 300 || r.bodyBytes.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(r.bodyBytes));
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      // V1.6.7 ne fournit pas encore obligatoirement cet endpoint : la synchro V6 reste fonctionnelle.
      return null;
    }
  }

  Future<SyncSnapshot> sync(PrincipalConfig c) async {
    final r = await http.get(
      _uri(c, '/api/v1/sync', {'teacher': c.teacher, 'code': c.code}),
      headers: {'Accept': 'application/json', 'User-Agent': 'ECOLE-Gestion-Prof-Mobile/0.3'},
    ).timeout(timeout);

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw PrincipalApiException('Synchronisation refusée (${r.statusCode}).');
    }
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    if (decoded is! Map) throw PrincipalApiException('Réponse de synchronisation invalide.');
    var snapshot = SyncSnapshot.fromJson(Map<String, dynamic>.from(decoded));
    if (snapshot.protocolVersion != 0 && snapshot.protocolVersion != supportedProtocol) {
      throw PrincipalApiException('Version de protocole incompatible : Principal ${snapshot.protocolVersion}, mobile $supportedProtocol.');
    }

    // Extension non bloquante : permet au Principal d'envoyer les noms arabes,
    // les leçons et les natures d'incident sans casser la compatibilité V6.
    final references = await _referenceData(c);
    if (references != null && references.isNotEmpty) snapshot = snapshot.mergeReferenceData(references);
    return snapshot;
  }

  Future<Map<String, dynamic>> sendEvents(PrincipalConfig c, List<TeacherEvent> events) async {
    if (events.isEmpty) return {'received': 0, 'acknowledgedIds': <String>[]};
    final body = {
      'protocolVersion': supportedProtocol,
      'teacher': c.teacher,
      'events': events.map((e) => e.toProtocolV6Json()).toList(),
    };
    final r = await http.post(
      _uri(c, '/api/v1/events', {'teacher': c.teacher, 'code': c.code}),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode(body),
    ).timeout(timeout);
    if (r.statusCode < 200 || r.statusCode >= 300) throw PrincipalApiException('Transmission refusée (${r.statusCode}).');
    if (r.bodyBytes.isEmpty) return {'received': events.length};
    final decoded = jsonDecode(utf8.decode(r.bodyBytes));
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {'received': events.length};
  }
}
