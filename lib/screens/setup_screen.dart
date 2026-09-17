import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/principal_config.dart';
import '../services/local_store.dart';
import '../services/principal_api.dart';
import '../services/platform_permissions.dart';

class SetupScreen extends StatefulWidget {
  final LocalStore store;
  final PrincipalApi api;
  final void Function(PrincipalConfig) onConnected;

  const SetupScreen({
    super.key,
    required this.store,
    required this.api,
    required this.onConnected,
  });

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final host = TextEditingController();
  final port = TextEditingController(text: '8080');
  final teacher = TextEditingController();
  final code = TextEditingController();
  final deviceName = TextEditingController();
  bool busy = false;
  String? error;


  @override
  void initState() {
    super.initState();
    widget.store.getOrCreateDeviceName().then((v) {
      if (mounted && deviceName.text.trim().isEmpty) setState(() => deviceName.text = v);
    });
  }

  PrincipalConfig get config => PrincipalConfig(
        host: host.text.trim(),
        port: int.tryParse(port.text.trim()) ?? 0,
        teacher: teacher.text.trim(),
        code: code.text.trim(),
      );

  Future<void> connect() async {
    setState(() {
      busy = true;
      error = null;
    });
    final c = config;
    if (c.host.isEmpty || c.port <= 0 || c.teacher.isEmpty || c.code.isEmpty) {
      setState(() {
        busy = false;
        error = 'Adresse, port, professeur et code sont obligatoires.';
      });
      return;
    }
    final lanPermission = await PlatformPermissions.ensureLocalNetwork();
    if (!lanPermission.mayProceed) {
      setState(() {
        busy = false;
        error = lanPermission.message;
      });
      return;
    }
    final ok = await widget.api.ping(c);
    if (!ok) {
      setState(() {
        busy = false;
        error = 'PC Principal introuvable sur le réseau local. Vérifier le Wi-Fi, l’adresse, le port et l’autorisation Réseau local / Appareils à proximité.';
      });
      return;
    }
    try {
      final deviceId = await widget.store.getOrCreateDeviceId();
      final chosenName = deviceName.text.trim();
      if (chosenName.isNotEmpty) await widget.store.setDeviceName(chosenName);
      final savedName = await widget.store.getOrCreateDeviceName();
      final snapshot = await widget.api.sync(c, deviceId: deviceId, deviceName: savedName);
      await widget.store.saveConfig(c);
      await widget.store.saveSnapshot(snapshot);
      widget.onConnected(c);
    } catch (e) {
      setState(() {
        busy = false;
        error = e.toString();
      });
    }
  }

  Future<void> scanQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScanner()),
    );
    if (result == null) return;
    try {
      final p = result.split('|');
      if (p.length == 5 && p[0] == 'ECOLEPRO') {
        setState(() {
          host.text = p[1];
          port.text = p[2];
          teacher.text = p[3];
          code.text = p[4];
          error = null;
        });
      } else {
        setState(() => error = 'QR non reconnu.');
      }
    } catch (_) {
      setState(() => error = 'QR non reconnu.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('GESTCOURS')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 620 ? 560.0 : constraints.maxWidth;
            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                56 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset('assets/plume_gravure.png', width: 92, height: 92, fit: BoxFit.cover),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Connexion au Principal',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Réseau local • aucune connexion Internet nécessaire',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: host,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'Adresse IP du PC Principal',
                            hintText: '192.168.1.10',
                            prefixIcon: Icon(Icons.computer),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: port,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            prefixIcon: Icon(Icons.lan_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: teacher,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Professeur',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: code,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Code généré par le Principal',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: deviceName,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nom de ce téléphone',
                            helperText: 'Détecté automatiquement ; vous pouvez le renommer.',
                            prefixIcon: Icon(Icons.phone_android_outlined),
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed: busy ? null : connect,
                          icon: const Icon(Icons.login),
                          label: Text(busy ? 'Connexion…' : 'Se connecter par code'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: busy ? null : scanQr,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scanner un QR code (option)'),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Le code reste la méthode principale. Le QR est seulement une méthode rapide proposée en plus.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QrScanner extends StatefulWidget {
  const _QrScanner();

  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  bool finished = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner le QR du Principal')),
      body: MobileScanner(
        onDetect: (capture) {
          if (finished) return;
          final value = capture.barcodes.isNotEmpty
              ? capture.barcodes.first.rawValue
              : null;
          if (value != null && value.isNotEmpty) {
            finished = true;
            Navigator.of(context).pop(value);
          }
        },
      ),
    );
  }
}
