import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class IncidentScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;
  const IncidentScreen({super.key, required this.config, required this.snapshot, required this.student, required this.store});

  @override
  State<IncidentScreen> createState() => _IncidentScreenState();
}

class _IncidentScreenState extends State<IncidentScreen> {
  DateTime date = DateTime.now();
  String family = 'Discipline';
  String? nature;
  String? detail;
  String priority = 'Normal';
  final message = TextEditingController();

  static const Map<String, List<String>> detailsByNature = {
    'Bavardage': ['Répété malgré rappel', 'Perturbe le cours', 'Discussion ponctuelle'],
    'Grossièreté': ['Paroles déplacées', 'Insulte envers un élève', 'Insulte envers un adulte'],
    'Téléphone': ['Utilisation en cours', 'Sonnerie / notification', 'Refus de ranger le téléphone'],
    'Bagarre': ['Dispute physique', 'Coups', 'Provocation / altercation'],
    'Insolence': ['Réponse irrespectueuse', 'Refus d'obéir', 'Attitude provocatrice'],
    'Harcèlement': ['Verbal', 'Physique', 'Numérique / réseaux'],
    'Non apporté': ['Cahier', 'Livre', 'Mushaf', 'Matériel demandé'],
    'En mauvais état': ['Cahier', 'Livre', 'Mushaf', 'Matériel demandé'],
    'Fait partiellement': ['Travail incomplet', 'Exercices partiels', 'Leçon partiellement préparée'],
    'Non fait': ['Aucun travail rendu', 'Leçon non préparée', 'Exercices non faits'],
  };

  List<String> get details => List<String>.from(detailsByNature[nature] ?? const <String>[]);

  static const Map<String, List<String>> builtIn = {
    'Discipline': [
      'Bavardage',
      'Grossièreté',
      'Téléphone',
      'Bagarre',
      'Insolence',
      'Harcèlement',
    ],
    'Matériel': [
      'Non apporté',
      'En mauvais état',
    ],
    'Devoirs': [
      'Fait partiellement',
      'Non fait',
    ],
  };

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  List<String> get natures {
    final base = List<String>.from(builtIn[family] ?? const <String>[]);
    if (family == 'Autre') {
      final fromPrincipal = widget.snapshot.references.incidentTypes;
      if (fromPrincipal.isNotEmpty) base.addAll(fromPrincipal);
      if (base.isEmpty) base.add('Autre');
    }
    return base.toSet().toList();
  }

  String get structuredCategory {
    final n = nature?.trim() ?? '';
    if (family == 'Discipline') return 'Discipline — $n';
    if (family == 'Matériel') return 'Matériel — $n';
    if (family == 'Devoirs') return 'Devoir — $n';
    return n.isEmpty ? 'Autre' : n;
  }

  String get generatedRemark {
    final n = nature?.trim() ?? '';
    final d = detail?.trim() ?? '';
    if (n.isEmpty) return '';
    switch (family) {
      case 'Discipline':
        return 'Signalement de discipline : $n${d.isEmpty ? '' : ' — $d'}.';
      case 'Matériel':
        return 'Signalement matériel : $n${d.isEmpty ? '' : ' — $d'}.';
      case 'Devoirs':
        return 'Suivi des devoirs : $n${d.isEmpty ? '' : ' — $d'}.';
      default:
        return n;
    }
  }

  Future<void> save() async {
    if (nature == null || nature!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir la nature du signalement.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final custom = message.text.trim();
    final text = custom.isEmpty ? generatedRemark : '$generatedRemark $custom';
    final event = TeacherEvent.create(
      type: 'communication',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'date': _date(date),
        'category': structuredCategory,
        'subject': 'Signalement : $structuredCategory',
        'priority': priority,
        if ((detail ?? '').trim().isNotEmpty) 'detail': detail!.trim(),
        'message': text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signalement enregistré. Il sera soumis au Principal.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: const Text('Discipline / comportement')),
        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
            children: [
              Text(widget.student.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(DateTime.now().year - 1), lastDate: DateTime(DateTime.now().year + 1));
                  if (d != null) setState(() => date = d);
                },
                child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text(_date(date))),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: family,
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: const ['Discipline', 'Matériel', 'Devoirs', 'Autre'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() {
                  family = v ?? 'Discipline';
                  nature = null;
                  detail = null;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: nature,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nature du signalement'),
                items: natures.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() { nature = v; detail = null; }),
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: detail,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Détail / nature précise'),
                  items: details.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => detail = v),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priorité'),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normale')),
                  DropdownMenuItem(value: 'Important', child: Text('Importante')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgente')),
                ],
                onChanged: (v) => setState(() => priority = v ?? 'Normal'),
              ),
              const SizedBox(height: 12),
              if (nature != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(generatedRemark, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              const SizedBox(height: 8),
              TextField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'Remarque complémentaire (facultative)')),
              const SizedBox(height: 22),
              FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer pour validation du Principal')),
            ],
          ),
        ),
      );
}
