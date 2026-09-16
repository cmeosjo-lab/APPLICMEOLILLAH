import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class EvaluationScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;

  const EvaluationScreen({
    super.key,
    required this.config,
    required this.snapshot,
    required this.student,
    required this.store,
  });

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  DateTime date = DateTime.now();
  String? periodId;
  int? tajwidLevel;
  final quran = TextEditingController();
  final arabic = TextEditingController();
  final aqida = TextEditingController();
  final fiqh = TextEditingController();
  final sira = TextEditingController();
  final bonus = TextEditingController();
  final appreciation = TextEditingController();

  String _date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';

  List<Map<String, dynamic>> get periods {
    final result = <Map<String, dynamic>>[];
    for (final raw in widget.snapshot.bulletinPeriods) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final ids = m['classIds'];
      final allowed = ids is! List || ids.isEmpty || ids.map((e) => e.toString()).contains(widget.student.classId);
      if (allowed) result.add(m);
    }
    return result;
  }

  double? _score(TextEditingController c) {
    final text = c.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  String _periodLabel(Map<String, dynamic> p) {
    final name = (p['name'] ?? p['label'] ?? p['period'] ?? '').toString().trim();
    final start = (p['startDate'] ?? '').toString().trim();
    final end = (p['endDate'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    if (start.isNotEmpty || end.isNotEmpty) return '$start — $end';
    return (p['id'] ?? 'Période').toString();
  }

  Future<void> pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (value != null) setState(() => date = value);
  }

  Future<void> save() async {
    final scores = <String, double?>{
      'quran': _score(quran),
      'arabic': _score(arabic),
      'aqida': _score(aqida),
      'fiqh': _score(fiqh),
      'sira': _score(sira),
      'bonus': _score(bonus),
    };
    final invalid = scores.entries.where((e) => e.value != null && (e.value! < 0 || e.value! > widget.snapshot.evaluationMax)).toList();
    if (invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Les notes doivent être comprises entre 0 et ${widget.snapshot.evaluationMax.toStringAsFixed(widget.snapshot.evaluationMax % 1 == 0 ? 0 : 1)}.')));
      return;
    }
    if (scores.values.every((v) => v == null) && tajwidLevel == null && appreciation.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saisir au moins une note, un niveau de Tajwid ou une appréciation.')));
      return;
    }

    final payload = <String, dynamic>{
      'date': _date(date),
      if (periodId != null && periodId!.isNotEmpty) 'periodId': periodId,
      if (scores['quran'] != null) 'quran': scores['quran'],
      if (scores['arabic'] != null) 'arabic': scores['arabic'],
      if (scores['aqida'] != null) 'aqida': scores['aqida'],
      if (scores['fiqh'] != null) 'fiqh': scores['fiqh'],
      if (scores['sira'] != null) 'sira': scores['sira'],
      if (scores['bonus'] != null) 'bonus': scores['bonus'],
      if (tajwidLevel != null) 'tajwidLevel': tajwidLevel,
      if (appreciation.text.trim().isNotEmpty) 'appreciation': appreciation.text.trim(),
    };

    Map<String, dynamic>? selectedPeriod;
    for (final p in periods) {
      if ((p['id'] ?? '').toString() == periodId) {
        selectedPeriod = p;
        break;
      }
    }
    if (selectedPeriod != null) {
      final name = (selectedPeriod['name'] ?? '').toString().trim();
      final start = (selectedPeriod['startDate'] ?? '').toString().trim();
      final end = (selectedPeriod['endDate'] ?? '').toString().trim();
      if (name.isNotEmpty) payload['period'] = name;
      if (start.isNotEmpty) payload['periodStart'] = start;
      if (end.isNotEmpty) payload['periodEnd'] = end;
    }

    final deviceId = await widget.store.getOrCreateDeviceId();
    await widget.store.enqueue(TeacherEvent.create(
      type: 'evaluation',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: payload,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Évaluation enregistrée. Synchroniser pour l’envoyer au Principal.')));
    Navigator.pop(context, true);
  }

  Widget scoreField(String label, TextEditingController controller) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: '$label / ${widget.snapshot.evaluationMax.toStringAsFixed(widget.snapshot.evaluationMax % 1 == 0 ? 0 : 1)}'),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(widget.snapshot.displayTitle)),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
            children: [
              Text('Évaluation — ${widget.student.displayName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              InkWell(
                onTap: pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'),
                    const Icon(Icons.calendar_month_outlined),
                  ]),
                ),
              ),
              if (periods.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: periodId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Période de bulletin (facultatif)'),
                  items: periods.map((p) => DropdownMenuItem(value: (p['id'] ?? '').toString(), child: Text(_periodLabel(p), overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => periodId = v),
                ),
              ],
              const SizedBox(height: 12),
              scoreField('Coran', quran),
              const SizedBox(height: 10),
              scoreField('Arabe', arabic),
              const SizedBox(height: 10),
              scoreField('Aqida', aqida),
              const SizedBox(height: 10),
              scoreField('Fiqh', fiqh),
              const SizedBox(height: 10),
              scoreField('Sira', sira),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: tajwidLevel,
                decoration: const InputDecoration(labelText: 'Niveau de Tajwid'),
                items: [1, 2, 3, 4, 5].map((n) => DropdownMenuItem(value: n, child: Text('Niveau $n'))).toList(),
                onChanged: (v) => setState(() => tajwidLevel = v),
              ),
              const SizedBox(height: 10),
              scoreField('Bonus', bonus),
              const SizedBox(height: 10),
              TextField(controller: appreciation, maxLines: 3, decoration: const InputDecoration(labelText: 'Appréciation facultative')),
              const SizedBox(height: 22),
              FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer l’évaluation')),
            ],
          ),
        ),
      );
}
