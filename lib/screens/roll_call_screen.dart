import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class RollCallScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final SchoolClass schoolClass;
  final List<Student> students;
  final LocalStore store;

  const RollCallScreen({super.key, required this.config, required this.snapshot, required this.schoolClass, required this.students, required this.store});

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen> {
  final Map<String, String> status = {};
  final Map<String, bool> justified = {};
  final Map<String, TimeOfDay> arrival = {};
  DateTime date = DateTime.now();

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _time(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _state(Student s) => status[s.id] ?? 'present';

  Future<void> _pickDate() async {
    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(DateTime.now().year - 2), lastDate: DateTime(DateTime.now().year + 1));
    if (d != null) setState(() => date = d);
  }

  Future<void> _pickArrival(Student s) async {
    final t = await showTimePicker(context: context, initialTime: arrival[s.id] ?? TimeOfDay.now());
    if (t != null) setState(() => arrival[s.id] = t);
  }

  Future<void> _save() async {
    final deviceId = await widget.store.getOrCreateDeviceId();
    var count = 0;
    for (final s in widget.students) {
      final st = _state(s);
      if (st == 'present') continue;
      final isLate = st == 'retard';
      final t = arrival[s.id] ?? TimeOfDay.now();
      await widget.store.enqueue(TeacherEvent.create(
        type: 'attendance',
        teacher: widget.config.teacher,
        studentId: s.id,
        classId: widget.schoolClass.id,
        deviceId: deviceId,
        payload: {
          'date': _date(date),
          'status': isLate ? 'Retard' : 'Absence',
          'justified': justified[s.id] ?? false,
          if (isLate) 'arrivalTime': _time(t),
          'note': 'Appel de classe mobile',
        },
      ));
      count++;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(count == 0 ? 'Tous les élèves sont présents.' : '$count absence/retard enregistré(s) en attente de synchronisation.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.schoolClass.name.trim().isEmpty ? 'Classe' : widget.schoolClass.name.trim();
    return Scaffold(
      appBar: AppBar(title: Text('Appel — $name')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(_date(date)))),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer')),
            ]),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Align(alignment: Alignment.centerLeft, child: Text('Présent par défaut. Modifiez uniquement les absents et retardataires.'))),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 32),
              itemCount: widget.students.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = widget.students[i];
                final st = _state(s);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'present', label: Text('Présent')),
                          ButtonSegment(value: 'absence', label: Text('Absent')),
                          ButtonSegment(value: 'retard', label: Text('Retard')),
                        ],
                        selected: {st},
                        onSelectionChanged: (v) => setState(() => status[s.id] = v.first),
                      ),
                      if (st != 'present') ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                            child: CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Justifié'),
                              value: justified[s.id] ?? false,
                              onChanged: (v) => setState(() => justified[s.id] = v ?? false),
                            ),
                          ),
                          if (st == 'retard')
                            TextButton.icon(onPressed: () => _pickArrival(s), icon: const Icon(Icons.schedule), label: Text(_time(arrival[s.id] ?? TimeOfDay.now()))),
                        ]),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
