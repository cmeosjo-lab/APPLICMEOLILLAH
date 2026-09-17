import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class HomeworkScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SchoolClass schoolClass;
  final LocalStore store;
  const HomeworkScreen({super.key, required this.config, required this.schoolClass, required this.store});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  DateTime date = DateTime.now();
  String subject = 'Arabe';
  final lessonNumbers = TextEditingController();
  final exerciseNumbers = TextEditingController();
  final manualText = TextEditingController();

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _save() async {
    if (lessonNumbers.text.trim().isEmpty && exerciseNumbers.text.trim().isEmpty && manualText.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquer une leçon, un exercice ou une consigne.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final isQuran = subject == 'Coran';
    await widget.store.enqueue(TeacherEvent.create(
      type: 'homework',
      teacher: widget.config.teacher,
      studentId: '',
      classId: widget.schoolClass.id,
      deviceId: deviceId,
      payload: {
        'date': _date(date),
        'audience': 'Classe',
        if (!isQuran) 'book': subject,
        if (!isQuran && lessonNumbers.text.trim().isNotEmpty) 'lessonNumbers': lessonNumbers.text.trim(),
        if (!isQuran && exerciseNumbers.text.trim().isNotEmpty) 'exerciseNumbers': exerciseNumbers.text.trim(),
        if (manualText.text.trim().isNotEmpty) 'manualText': manualText.text.trim(),
      },
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devoir enregistré. Il sera soumis au Principal pour validation.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Devoir — ${widget.schoolClass.name}')),
    body: SafeArea(child: ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom),
      children: [
        InkWell(
          onTap: () async { final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(DateTime.now().year-1), lastDate: DateTime(DateTime.now().year+1)); if (d != null) setState(() => date=d); },
          child: InputDecorator(decoration: const InputDecoration(labelText: 'Date'), child: Text(_date(date))),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: subject,
          decoration: const InputDecoration(labelText: 'Matière'),
          items: const ['Arabe','Aqida','Fiqh','Sira','Tajwid','Coran'].map((e) => DropdownMenuItem(value:e, child:Text(e))).toList(),
          onChanged: (v) => setState(() => subject = v ?? 'Arabe'),
        ),
        const SizedBox(height: 12),
        if (subject != 'Coran') ...[
          TextField(controller: lessonNumbers, decoration: const InputDecoration(labelText: 'Leçon(s) n°')),
          const SizedBox(height: 10),
          TextField(controller: exerciseNumbers, decoration: const InputDecoration(labelText: 'Exercice(s) n°')),
          const SizedBox(height: 10),
        ],
        TextField(controller: manualText, maxLines: 5, decoration: InputDecoration(labelText: subject == 'Coran' ? 'Consigne Coran' : 'Consigne complémentaire')),
        const SizedBox(height: 22),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.send_outlined), label: const Text('Envoyer au Principal pour validation')),
      ],
    )),
  );
}
