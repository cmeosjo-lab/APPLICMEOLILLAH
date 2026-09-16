import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class AttendanceScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;
  const AttendanceScreen({super.key, required this.config, required this.snapshot, required this.student, required this.store});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String kind = 'absence';
  bool justified = false;
  DateTime date = DateTime.now();
  TimeOfDay? arrival;
  final note = TextEditingController();

  String _time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (value != null) setState(() => date = value);
  }

  Future<void> pickArrival() async {
    final value = await showTimePicker(context: context, initialTime: arrival ?? TimeOfDay.now());
    if (value != null) setState(() => arrival = value);
  }

  Future<void> save() async {
    if (kind == 'retard' && arrival == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquer l’heure d’arrivée pour un retard.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final event = TeacherEvent.create(
      type: 'attendance',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'date': _date(date),
        'status': kind,
        'justified': justified,
        if (kind == 'retard' && arrival != null) 'arrivalTime': _time(arrival!),
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saisie conservée localement jusqu’à synchronisation.')));
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
            Text(widget.student.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date'),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                  const Icon(Icons.calendar_month_outlined),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: kind,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'absence', child: Text('Absence')),
                DropdownMenuItem(value: 'retard', child: Text('Retard')),
              ],
              onChanged: (v) => setState(() { kind = v ?? 'absence'; if (kind == 'absence') arrival = null; }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<bool>(
              value: justified,
              decoration: InputDecoration(labelText: kind == 'absence' ? 'Absence' : 'Retard'),
              items: [
                DropdownMenuItem(value: true, child: Text(kind == 'absence' ? 'Justifiée' : 'Justifié')),
                DropdownMenuItem(value: false, child: Text(kind == 'absence' ? 'Non justifiée' : 'Non justifié')),
              ],
              onChanged: (v) => setState(() => justified = v ?? false),
            ),
            if (kind == 'retard') ...[
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: pickArrival,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Heure d'arrivée"),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(arrival == null ? 'Choisir l’heure' : _time(arrival!)),
                    const Icon(Icons.schedule),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Justification / remarque'), maxLines: 3),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer')),
          ]),
        ),
      );
}
