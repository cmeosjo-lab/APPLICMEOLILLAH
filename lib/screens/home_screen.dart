import 'package:flutter/material.dart';
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
      setState(() { snapshot = result.snapshot; pending = result.remaining; connected = result.connected; status = result.message; });
    } catch (e) {
      if (mounted) setState(() { connected = false; status = e.toString(); });
    } finally {
      if (mounted) setState(() => syncing = false);
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
            onSelected: (v) async { if (v == 'disconnect') { await widget.store.clearConfig(); widget.onDisconnect(); } },
            itemBuilder: (_) => const [PopupMenuItem(value: 'disconnect', child: Text('Déconnecter cet appareil'))],
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
              Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: const CircleAvatar(child: Icon(Icons.outbox_outlined)),
                title: const Text('Saisies en attente', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Conservées sur le téléphone jusqu’à confirmation du Principal'),
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
              Text('Android / iOS • réseau local • protocole V6', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            ]);
          }),
        ),
      ),
    );
  }
}
