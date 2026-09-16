import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/reference_data.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class LessonFollowUpScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;
  const LessonFollowUpScreen({super.key, required this.config, required this.snapshot, required this.student, required this.store});

  @override
  State<LessonFollowUpScreen> createState() => _LessonFollowUpScreenState();
}

class _LessonFollowUpScreenState extends State<LessonFollowUpScreen> {
  String? subject;
  ReferenceItem? lesson;
  String status = 'fait';
  final note = TextEditingController();

  Future<void> save() async {
    if (lesson == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir une leçon.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final event = TeacherEvent.create(
      type: 'lessonFollowUp',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'lessonId': lesson!.id,
        'lesson': lesson!.label,
        if (lesson!.number > 0) 'lessonNumber': lesson!.number,
        if (lesson!.subject.isNotEmpty) 'subject': lesson!.subject,
        'status': status,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suivi de leçon enregistré.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final allLessons = widget.snapshot.references.lessons;
    final subjects = allLessons.map((e) => e.subject.trim()).where((e) => e.isNotEmpty).toSet().toList()..sort();
    final lessons = subject == null || subject!.isEmpty
        ? allLessons
        : allLessons.where((e) => e.subject.trim() == subject).toList();
    return Scaffold(
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
          Text('Suivi de leçon — ${widget.student.displayName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (subjects.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              value: subject,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Matière'),
              items: [
                const DropdownMenuItem<String>(value: '', child: Text('Toutes les matières')),
                ...subjects.map((e) => DropdownMenuItem<String>(value: e, child: Text(e))),
              ],
              onChanged: (v) => setState(() {
                subject = (v == null || v.isEmpty) ? null : v;
                lesson = null;
              }),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<ReferenceItem>(
            value: lesson,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Leçon'),
            items: lessons.map((e) {
              final prefix = e.subject.isEmpty ? '' : '${e.subject} — ';
              return DropdownMenuItem(value: e, child: Text('$prefix${e.displayLabel}', overflow: TextOverflow.ellipsis));
            }).toList(),
            onChanged: lessons.isEmpty ? null : (v) => setState(() => lesson = v),
          ),
          if (lessons.isEmpty) ...[
            const SizedBox(height: 8),
            const Text('Aucune liste de leçons reçue du PC Principal. Synchroniser après activation du référentiel.', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: status,
            decoration: const InputDecoration(labelText: 'État de la leçon'),
            items: const [
              DropdownMenuItem(value: 'fait', child: Text('Faite / acquise')),
              DropdownMenuItem(value: 'a_revoir', child: Text('À revoir')),
              DropdownMenuItem(value: 'non_acquise', child: Text('Non acquise')),
              DropdownMenuItem(value: 'absent', child: Text('Élève absent')),
            ],
            onChanged: (v) => setState(() => status = v ?? 'fait'),
          ),
          const SizedBox(height: 12),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Observation facultative')),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: lessons.isEmpty ? null : save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer')),
        ]),
      ),
    );
  }
}
