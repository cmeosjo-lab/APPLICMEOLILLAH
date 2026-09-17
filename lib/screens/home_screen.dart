import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
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

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final local = await widget.store.loadSnapshot();
    final queue = await widget.store.loadQueue();
    if (mounted) setState(() { snapshot = local; pending = queue.length; status = 'Données locales disponibles'; });
    await sync();
  }

  Future<void> sync() async {
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
      });
    } catch (e) {
      if (mounted) setState(() { connected = false; status = e.toString(); });
    } finally {
      if (mounted) setState(() => syncing = false);
    }
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sauvegarde locale copiée dans le presse-papiers. Conservez-la dans un fichier texte privé.')));
  }

  Future<void> restoreLocal() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer une sauvegarde locale'),
        content: SizedBox(width: 680, child: TextField(controller: c, maxLines: 12, decoration: const InputDecoration(hintText: 'Collez ici la sauvegarde JSON'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Restaurer'))],
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

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    return Scaffold(
      appBar: AppBar(
        title: Text(s?.displayTitle ?? 'ÉCOLE GESTION PRO'),
        actions: [
          IconButton(tooltip: 'Synchroniser', onPressed: syncing ? null : sync, icon: const Icon(Icons.sync)),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'log') await showSyncLog();
              if (v == 'backup') await backupLocal();
              if (v == 'restore') await restoreLocal();
              if (v == 'disconnect') { await widget.store.clearConfig(); widget.onDisconnect(); }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'log', child: Text('Journal de synchronisation')),
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
          child: LayoutBuilder(builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 720 ? 32.0 : 16.0;
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontal,
                16,
                horizontal,
                48 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
              SchoolHeader(title: s?.displayTitle ?? 'ÉCOLE GESTION PRO', subtitle: s?.schoolYear ?? '', teacher: widget.config.teacher),
              const SizedBox(height: 14),
              Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(child: Icon(connected ? Icons.lan : Icons.wifi_off)),
                title: Text(connected ? 'PC Principal connecté' : 'Travail hors connexion', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(status),
                trailing: syncing ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : null,
              )),
              const SizedBox(height: 10),
              if (lastReceived > 0 || lastConfirmed > 0 || lastRejected > 0 || lastDuplicates > 0 || lastUnsupported > 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diagnostic du dernier envoi', style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Reçus : $lastReceived')),
                            Chip(label: Text('Accusés : $lastConfirmed')),
                            if (lastRejected > 0) Chip(label: Text('Rejetés : $lastRejected')),
                            if (lastDuplicates > 0) Chip(label: Text('Doublons : $lastDuplicates')),
                            if (lastUnsupported > 0) Chip(label: Text('Non compatibles V1.6.7 : $lastUnsupported')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('Une saisie n’est retirée du téléphone que si le Principal renvoie explicitement son identifiant.'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(child: Icon(Icons.outbox_outlined)),
                title: const Text('Saisies en attente', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Conservées sur le téléphone jusqu’à accusé de réception du serveur Principal'),
                trailing: Text('$pending', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              )),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: s == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClassesScreen(config: widget.config, snapshot: s, store: widget.store))).then((_) => load()),
                icon: const Icon(Icons.groups_2_outlined),
                label: Text('Mes classes (${s?.classes.length ?? 0})'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(onPressed: syncing ? null : sync, icon: const Icon(Icons.sync), label: const Text('Synchroniser maintenant')),
              const SizedBox(height: 20),
              if (s != null) Wrap(spacing: 8, runSpacing: 8, children: [
                Chip(avatar: const Icon(Icons.history, size: 18), label: Text('${s.historyItems} historique(s)')),
                Chip(avatar: const Icon(Icons.menu_book, size: 18), label: Text('${s.references.lessons.length} leçon(s)')),
                Chip(avatar: const Icon(Icons.auto_stories, size: 18), label: Text('${s.references.surahs.length} sourate(s)')),
                Chip(avatar: const Icon(Icons.translate, size: 18), label: Text(s.references.receivedFromPrincipal ? 'Référentiel Principal reçu' : 'Référentiel à synchroniser')),
              ]),
              const SizedBox(height: 18),
              Text('V0.5.0 • 12 améliorations • Android / iOS • réseau local • protocole V6', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ]);
          }),
        ),
      ),
    );
  }
}
