import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import 'local_store.dart';
import 'principal_api.dart';

class SyncResult {
  final bool connected;
  final int sent;
  final int received;
  final int rejected;
  final int duplicates;
  final int unsupported;
  final int remaining;
  final List<String> errors;
  final SyncSnapshot? snapshot;
  final String message;

  const SyncResult({
    required this.connected,
    required this.sent,
    required this.received,
    required this.rejected,
    required this.duplicates,
    required this.unsupported,
    required this.remaining,
    required this.errors,
    required this.snapshot,
    required this.message,
  });
}

class SyncService {
  final LocalStore store;
  final PrincipalApi api;

  const SyncService(this.store, this.api);

  int _asInt(dynamic value) => int.tryParse((value ?? '0').toString()) ?? 0;

  List<String> _asErrors(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<SyncResult> synchronize(PrincipalConfig config) async {
    final online = await api.ping(config);
    final queue = await store.loadQueue();
    await store.appendSyncLog('Début synchronisation — file locale: ${queue.length} saisie(s).');
    if (!online) {
      await store.appendSyncLog('ÉCHEC — PC Principal indisponible. ${queue.length} saisie(s) conservée(s).');
      return SyncResult(
        connected: false,
        sent: 0,
        received: 0,
        rejected: 0,
        duplicates: 0,
        unsupported: queue.where((e) => !e.supportedByPrincipalV167).length,
        remaining: queue.length,
        errors: const [],
        snapshot: await store.loadSnapshot(),
        message: 'Principal indisponible. ${queue.length} saisie(s) conservée(s) sur le téléphone.',
      );
    }

    var pending = List<TeacherEvent>.from(queue);
    var sent = 0;
    var received = 0;
    var rejected = 0;
    var duplicates = 0;
    var errors = <String>[];

    final sendable = pending.where((e) => e.supportedByPrincipalV167).toList();
    final unsupported = pending.length - sendable.length;

    if (sendable.isNotEmpty) {
      final response = await api.sendEvents(config, sendable);
      received = _asInt(response['received']);
      rejected = _asInt(response['rejected']);
      duplicates = _asInt(response['duplicates']);
      errors = _asErrors(response['errors']);

      final acknowledged = <String>{
        if (response['acknowledgedIds'] is List)
          ...(response['acknowledgedIds'] as List).map((e) => e.toString()),
      };

      // Sécurité V0.4 : on ne retire JAMAIS une saisie sur la seule base du
      // compteur `received`. Seuls les IDs explicitement accusés sont retirés.
      if (acknowledged.isNotEmpty) {
        final before = pending.length;
        pending.removeWhere((e) => acknowledged.contains(e.id));
        sent = before - pending.length;
      }
      await store.saveQueue(pending);
      await store.appendSyncLog('Envoi événements — reçus: $received, accusés: $sent, rejetés: $rejected, doublons: $duplicates, non compatibles: $unsupported, restant: ${pending.length}${errors.isEmpty ? '' : ' — ${errors.take(5).join(' | ')}'}');
    } else if (unsupported > 0) {
      await store.appendSyncLog('Aucune saisie compatible à envoyer — $unsupported saisie(s) locale(s) non compatible(s).');
    }

    final snapshot = await api.sync(config);
    await store.saveSnapshot(snapshot);
    await store.appendSyncLog('Référentiel/classes reçus — ${snapshot.classes.length} classe(s), ${snapshot.students.length} élève(s).');

    final parts = <String>[
      'Principal connecté.',
      if (sendable.isNotEmpty) '$received reçu(s), $sent accusé(s) par le serveur',
      if (rejected > 0) '$rejected rejeté(s)',
      if (duplicates > 0) '$duplicates doublon(s)',
      if (unsupported > 0) '$unsupported saisie(s) locale(s) non compatible(s) V1.6.7',
      '${pending.length} en attente.',
    ];
    if (errors.isNotEmpty) parts.add('Erreur Principal : ${errors.take(3).join(' | ')}');

    return SyncResult(
      connected: true,
      sent: sent,
      received: received,
      rejected: rejected,
      duplicates: duplicates,
      unsupported: unsupported,
      remaining: pending.length,
      errors: errors,
      snapshot: snapshot,
      message: parts.join(' '),
    );
  }
}
