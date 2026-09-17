import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';
import '../services/principal_api.dart';
import '../services/sync_service.dart';
import '../widgets/school_header.dart';
import 'classes_screen.dart';

class HomeScreen extends StatefulWidget {
  final PrincipalConfig config;
  final LocalStore store;
  final PrincipalApi api;
  final VoidCallback onDisconnect;
  const HomeScreen({super.key, required this.config, required this.store, required this.api, required this.onDisconnect});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SyncSnapshot? snapshot;
  int pending = 0;
  bool syncing = false;
  bool connected = false;
  String status = 'Chargement…';
  int lastReceived = 0;
  int lastConfirmed = 0;
  int lastRejected = 0;
  int lastDuplicates = 0;
  int lastUnsupported = 0;
  int consecutiveFailures = 0;
  DateTime? lastSuccess;
  Timer? retryTimer;

  @override
  void initState() {
    super.initState();
    load();
    retryTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!mounted || syncing) return;
      if (!connected || pending > 0) sync(silent: true);
    });
  }

  @override
  void dispose() {
    retryTimer?.cancel();
    super.dispose();
  }

  String _clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<void> load() async {
    final local = await widget.store.loadSnapshot();
    final queue = await widget.store.loadQueue();
    if (mounted) setState(() {
      snapshot = local;
      pending = queue.length;
      status = 'Données locales disponibles';
    });
    await sync();
  }

  Future<void> sync({bool silent = false}) async {
    if (syncing) return;
    setState(() => syncing = true);
    try {
      final result = await SyncService(widget.store, widget.api).synchronize(widget.config);
      if (!mounted) return;
      setState(() {
        snapshot = result.snapshot;
        pending = result.remaining;
        connected = result.connected;
        status = result.message;
        lastReceived = result.received;
        lastConfirmed = result.sent;
        lastRejected = result.rejected;
        lastDuplicates = result.duplicates;
        lastUnsupported = result.unsupported;
        if (result.connected) {
          consecutiveFailures = 0;
          lastSuccess = DateTime.now();
        } else {
          consecutiveFailures++;
        }
      });
    } catch (e) {
      if (mounted) setState(() {
        connected = false;
        consecutiveFailures++;
        status = e.toString();
      });
    } finally {
      if (mounted) setState(() => syncing = false);
    }
    if (!silent && mounted && connected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synchronisation terminée.')));
    }
  }

  String _eventType(TeacherEvent e) {
    switch (e.protocolType) {
      case 'attendance':
        return (e.payload['status'] ?? 'Absence / retard').toString();
      case 'evaluation':
        return 'Contrôle / note';
      case 'communication':
        return (e.payload['category'] ?? 'Signalement').toString();
      case 'homework':
        return 'Devoir';
      case 'quran_validation':
        return 'Validation Coran';
      case 'quran_progress':
        return 'Progression Coran';
      default:
        return e.protocolType;
    }
  }

  String _studentName(String id) {
    final s = snapshot?.students.where((x) => x.id == id).toList() ?? const <Student>[];
    return s.isEmpty ? '' : s.first.displayName;
  }

  Future<void> showPendingQueue() async {
    final items = await widget.store.loadQueue();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Saisies en attente (${items.length})'),
        content: SizedBox(
          width: 760,
          child: items.isEmpty
              ? const Text('Aucune saisie en attente.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final e = items[i];
                    final student = _studentName(e.studentId);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_eventType(e), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text([student, e.payload['date']?.toString() ?? ''].where((x) => x.trim().isNotEmpty).join(' • ')),
                      trailing: IconButton(
                        tooltip: 'Supprimer cette saisie locale',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Supprimer cette saisie ?'),
                              content: const Text('Elle n’a pas encore été accusée par le Principal.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
                                FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer')),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await widget.store.removeQueued(e.id);
                            if (context.mounted) Navigator.pop(context);
                            await loadLocalCounts();
                          }
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> showSentHistory() async {
    final items = await widget.store.loadSentHistory();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suivi des saisies transmises'),
        content: SizedBox(
          width: 780,
          child: items.isEmpty
              ? const Text('Aucune saisie transmise enregistrée sur ce téléphone.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final e = items[items.length - 1 - i];
                    final statusText = switch (e.status) {
                      'validated' => 'Validée',
                      'refused' => 'Refusée',
                      'received' => 'Reçue par le Principal',
                      _ => e.status,
                    };
                    final student = _studentName(e.studentId);
                    final detail = <String>[statusText, student, e.reviewNote].where((x) => x.trim().isNotEmpty).join(' • ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_eventType(e), style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(detail),
                    );
                  },
                ),
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  Future<void> loadLocalCounts() async {
    final queue = await widget.store.loadQueue();
    if (mounted) setState(() => pending = queue.length);
  }

  Future<void> showSyncLog() async {
    final items = await widget.store.loadSyncLog();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Journal de synchronisation'),
        content: SizedBox(
          width: 760,
          child: items.isEmpty
              ? const Text('Aucune synchronisation enregistrée.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (_, i) => SelectableText(items[items.length - 1 - i]),
                ),
        ),
        actions: [
          TextButton(
            onPressed: items.isEmpty ? null : () async {
              await widget.store.clearSyncLog();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Vider le journal'),
          ),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> backupLocal() async {
    final raw = await widget.store.exportBundle();
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde locale copiée. Conservez-la dans un fichier privé.')));
  }

  Future<void> restoreLocal() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer une sauvegarde locale'),
        content: SizedBox(width: 680, child: TextField(controller: c, maxLines: 12, decoration: const InputDecoration(hintText: 'Collez ici la sauvegarde JSON'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurer')),
        ],
      ),
    );
    if (ok != true || c.text.trim().isEmpty) return;
    try {
      await widget.store.importBundle(c.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde restaurée.')));
      await load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde invalide.')));
    }
  }

  Future<void> openClasses() async {
    final s = snapshot;
    if (s == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesScreen(config: widget.config, snapshot: s, store: widget.store)));
    await loadLocalCounts();
  }

  Widget actionButton(IconData icon, String label, VoidCallback? onTap) => SizedBox(
    width: 160,
    height: 82,
    child: FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 26),
      label: Text(label, textAlign: TextAlign.center),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final connectionTitle = connected
        ? 'PC Principal connecté'
        : (consecutiveFailures >= 3 ? 'Travail hors connexion' : 'Principal momentanément inaccessible');
    final lastLine = lastSuccess == null ? '' : ' • dernière synchro OK ${_clock(lastSuccess!)}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('GESTCOURS PROF'),
        actions: [
          IconButton(tooltip: 'Synchroniser', onPressed: syncing ? null : sync, icon: const Icon(Icons.sync)),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'log') await showSyncLog();
              if (v == 'backup') await backupLocal();
              if (v == 'restore') await restoreLocal();
              if (v == 'disconnect') {
                await widget.store.clearConfig();
                widget.onDisconnect();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'log', child: Text('Journal technique')),
              PopupMenuItem(value: 'backup', child: Text('Sauvegarder les données locales')),
              PopupMenuItem(value: 'restore', child: Text('Restaurer une sauvegarde')),
              PopupMenuItem(value: 'disconnect', child: Text('Déconnecter cet appareil')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: sync,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom),
            children: [
              SchoolHeader(title: s?.displayTitle ?? 'GESTCOURS', subtitle: s?.schoolYear ?? '', teacher: widget.config.teacher),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(connected ? Icons.lan : Icons.wifi_off)),
                  title: Text(connectionTitle, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('$status$lastLine'),
                  trailing: syncing ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : null,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.outbox_outlined),
                      title: const Text('Saisies en attente', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Touchez pour voir ou supprimer une saisie non encore envoyée.'),
                      trailing: Text('$pending', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      onTap: showPendingQueue,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Suivi des saisies'),
                      subtitle: const Text('Reçue • Validée • Refusée et motif du Principal'),
                      onTap: showSentHistory,
                    ),
                  ],
                ),
              ),
              if (lastReceived > 0 || lastRejected > 0 || lastDuplicates > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Reçus : $lastReceived')),
                    Chip(label: Text('Accusés : $lastConfirmed')),
                    if (lastRejected > 0) Chip(label: Text('Rejetés : $lastRejected')),
                    if (lastDuplicates > 0) Chip(label: Text('Doublons : $lastDuplicates')),
                    if (lastUnsupported > 0) Chip(label: Text('Non compatibles : $lastUnsupported')),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  actionButton(Icons.fact_check_outlined, 'Appel', s == null ? null : openClasses),
                  actionButton(Icons.grading_outlined, 'Contrôles', s == null ? null : openClasses),
                  actionButton(Icons.auto_stories_outlined, 'Coran', s == null ? null : openClasses),
                  actionButton(Icons.assignment_outlined, 'Devoirs', s == null ? null : openClasses),
                  actionButton(Icons.history, 'Historique', s == null ? null : openClasses),
                  actionButton(Icons.sync, 'Synchroniser', syncing ? null : sync),
                ],
              ),
              const SizedBox(height: 18),
              if (s != null)
                Text(
                  '${s.classes.length} classe(s) • ${s.students.length} élève(s) • V0.6.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
