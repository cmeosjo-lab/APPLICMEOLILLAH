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
  String? nature;
  String priority = 'normal';
  final message = TextEditingController();

  List<String> get natures {
    final fromPrincipal = widget.snapshot.references.incidentTypes;
    if (fromPrincipal.isNotEmpty) return fromPrincipal;
    return const ['Discipline', 'Comportement', 'Matériel', 'Travail / devoir', 'Respect / langage', 'Sécurité', 'Autre'];
  }

  Future<void> save() async {
    if (nature == null || message.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir la nature et décrire l’incident.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final event = TeacherEvent.create(
      type: 'communication',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'kind': 'incident',
        'subject': 'Incident disciplinaire',
        'nature': nature,
        'priority': priority,
        'message': message.text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident enregistré et placé en attente de transmission.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(widget.snapshot.displayTitle)),
        body: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
            children: [
            Text('Incident — ${widget.student.displayName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: nature,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Nature de l’incident'),
              items: natures.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => nature = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: const InputDecoration(labelText: 'Priorité'),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normale')),
                DropdownMenuItem(value: 'important', child: Text('Importante')),
                DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
              ],
              onChanged: (v) => setState(() => priority = v ?? 'normal'),
            ),
            const SizedBox(height: 12),
            TextField(controller: message, maxLines: 5, decoration: const InputDecoration(labelText: 'Description / suite à donner')),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.send_outlined), label: const Text('Enregistrer pour le Principal')),
          ]),
        ),
      );
}
