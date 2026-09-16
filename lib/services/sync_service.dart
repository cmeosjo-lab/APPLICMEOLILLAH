import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import 'local_store.dart';
import 'principal_api.dart';

class SyncResult {
  final bool connected;
  final int sent;
  final int remaining;
  final SyncSnapshot? snapshot;
  final String message;

  const SyncResult({
    required this.connected,
    required this.sent,
    required this.remaining,
    required this.snapshot,
    required this.message,
  });
}

class SyncService {
  final LocalStore store;
  final PrincipalApi api;

  const SyncService(this.store, this.api);

  Future<SyncResult> synchronize(PrincipalConfig config) async {
    final online = await api.ping(config);
    final queue = await store.loadQueue();
    if (!online) {
      return SyncResult(
        connected: false,
        sent: 0,
        remaining: queue.length,
        snapshot: await store.loadSnapshot(),
        message: 'Principal indisponible. Travail local conservé.',
      );
    }

    var pending = List<TeacherEvent>.from(queue);
    var sent = 0;
    if (pending.isNotEmpty) {
      final response = await api.sendEvents(config, pending);
      final acknowledged = <String>{
        if (response['acknowledgedIds'] is List)
          ...(response['acknowledgedIds'] as List).map((e) => e.toString()),
      };

      if (acknowledged.isNotEmpty) {
        final before = pending.length;
        pending.removeWhere((e) => acknowledged.contains(e.id));
        sent = before - pending.length;
      } else {
        final received = int.tryParse((response['received'] ?? '0').toString()) ?? 0;
        if (received >= pending.length) {
          sent = pending.length;
          pending = [];
        }
      }
      await store.saveQueue(pending);
    }

    final snapshot = await api.sync(config);
    await store.saveSnapshot(snapshot);
    return SyncResult(
      connected: true,
      sent: sent,
      remaining: pending.length,
      snapshot: snapshot,
      message: 'Synchronisation terminée.',
    );
  }
}
