import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class HomeworkScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SchoolClass schoolClass;
  final List<Student> students;
  final LocalStore store;
  const HomeworkScreen({super.key, required this.config, required this.schoolClass, required this.students, required this.store});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  DateTime date = DateTime.now();
  String audience = 'Classe';
  String? studentId;
  final Set<String> subjects = {'Arabe'};
  bool quranCollective = false;
  final book = TextEditingController();
  final lessonNumbers = TextEditingController();
  final exerciseNumbers = TextEditingController();
  final manualText = TextEditingController();

  static const subjectList = ['Arabe', 'Aqida', 'Fiqh', 'Sira', 'Tajwid', 'Coran'];

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir au moins une matière.')));
      return;
    }
    if (audience == 'Élève' && (studentId == null || studentId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir un élève.')));
      return;
    }
    if (lessonNumbers.text.trim().isEmpty && exerciseNumbers.text.trim().isEmpty && manualText.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquer une leçon, un exercice ou une consigne.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    var count = 0;
    for (final subject in subjects) {
      final chosenBook = book.text.trim().isEmpty ? subject : book.text.trim();
      await widget.store.enqueue(TeacherEvent.create(
        type: 'homework',
        teacher: widget.config.teacher,
        studentId: audience == 'Élève' ? (studentId ?? '') : '',
        classId: widget.schoolClass.id,
        deviceId: deviceId,
        payload: {
          'date': _date(date),
          'audience': audience,
          'subject': subject,
          'book': chosenBook,
          if (lessonNumbers.text.trim().isNotEmpty) 'lessonNumbers': lessonNumbers.text.trim(),
          if (exerciseNumbers.text.trim().isNotEmpty) 'exerciseNumbers': exerciseNumbers.text.trim(),
          if (manualText.text.trim().isNotEmpty) 'manualText': manualText.text.trim(),
        },
      ));
      count++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count devoir(s) enregistré(s). Validation par le Principal requise.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Devoir — ${widget.schoolClass.name}')),
    body: SafeArea(child: ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom),
      children: [
        InkWell(
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(DateTime.now().year - 1), lastDate: DateTime(DateTime.now().year + 1));
            if (d != null) setState(() => date = d);
          },
          child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text(_date(date))),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Coran', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Devoir collectif de Coran pour toute la classe'),
          value: quranCollective,
          onChanged: (v) => setState(() {
            quranCollective = v ?? false;
            if (quranCollective) {
              audience = 'Classe';
              studentId = null;
              subjects.add('Coran');
            } else {
              subjects.remove('Coran');
              if (subjects.isEmpty) subjects.add('Arabe');
            }
          }),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: audience,
          decoration: const InputDecoration(labelText: 'Destinataire'),
          items: const ['Classe', 'Élève'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() {
            audience = v ?? 'Classe';
            if (audience == 'Classe') studentId = null;
            if (audience == 'Élève') quranCollective = false;
          }),
        ),
        if (audience == 'Élève') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: studentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Élève'),
            items: widget.students.map((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName))).toList(),
            onChanged: (v) => setState(() => studentId = v),
          ),
        ],
        const SizedBox(height: 14),
        const Text('Matière(s)', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subjectList.map((s) => FilterChip(
            label: Text(s),
            selected: subjects.contains(s),
            onSelected: (selected) => setState(() {
              if (selected) {
                subjects.add(s);
              } else {
                subjects.remove(s);
              }
            }),
          )).toList(),
        ),
        const SizedBox(height: 14),
        TextField(controller: book, decoration: const InputDecoration(labelText: 'Livre (facultatif, sinon matière utilisée)')),
        const SizedBox(height: 10),
        TextField(controller: lessonNumbers, decoration: const InputDecoration(labelText: 'Leçon(s) / numéro(s)')),
        const SizedBox(height: 10),
        TextField(controller: exerciseNumbers, decoration: const InputDecoration(labelText: 'Exercice(s) / numéro(s)')),
        const SizedBox(height: 10),
        TextField(controller: manualText, maxLines: 5, decoration: const InputDecoration(labelText: 'Consigne complémentaire')),
        const SizedBox(height: 22),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.send_outlined), label: const Text('Envoyer au Principal pour validation')),
      ],
    )),
  );
}
