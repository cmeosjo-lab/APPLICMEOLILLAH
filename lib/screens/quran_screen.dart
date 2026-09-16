import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/reference_data.dart';
import '../models/school_data.dart';
import '../models/teacher_event.dart';
import '../services/local_store.dart';

class QuranScreen extends StatefulWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;
  const QuranScreen({super.key, required this.config, required this.snapshot, required this.student, required this.store});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  ReferenceItem? surah;
  int? verseFrom;
  int? verseTo;
  ReferenceItem? hizb;
  ReferenceItem? juz;
  final note = TextEditingController();

  List<int> get verses {
    final max = surah?.verseCount ?? 0;
    return max > 0 ? List<int>.generate(max, (i) => i + 1) : const [];
  }

  void onSurah(ReferenceItem? value) {
    setState(() {
      surah = value;
      verseFrom = null;
      verseTo = null;
    });
  }

  String _today() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year.toString().padLeft(4, '0')}';
  }

  Future<void> save() async {
    if (hizb == null && juz == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Le Principal V1.6.7 accepte la validation d’un Hizb ou d’un Juz. Choisir l’un des deux.'),
      ));
      return;
    }
    final chosen = hizb ?? juz!;
    final kind = hizb != null ? 'Hizb' : 'Juz';
    final deviceId = await widget.store.getOrCreateDeviceId();
    final event = TeacherEvent.create(
      type: 'quran_validation',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'date': _today(),
        'kind': kind,
        'number': chosen.number,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Validation $kind enregistrée. Synchroniser pour l’envoyer au Principal.')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final ref = widget.snapshot.references;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(widget.snapshot.displayTitle)),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, 48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom),
          children: [
            Text('Suivi Coran — ${widget.student.displayName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Compatibilité V1.6.7 : la validation synchronisée concerne Hizb/Juz. Les rideaux Sourate/versets sont conservés à l’écran pour la future extension du Principal.'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReferenceItem>(
              value: surah,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sourate (affichage / future extension)'),
              items: ref.surahs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: ref.surahs.isEmpty ? null : onSurah,
            ),
            if (surah != null && verses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: DropdownButtonFormField<int>(
                  value: verseFrom,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Verset de'),
                  items: verses.map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                  onChanged: (v) => setState(() {
                    verseFrom = v;
                    if (verseTo != null && v != null && verseTo! < v) verseTo = v;
                  }),
                )),
                const SizedBox(width: 10),
                Expanded(child: DropdownButtonFormField<int>(
                  value: verseTo,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Verset à'),
                  items: verses.where((v) => verseFrom == null || v >= verseFrom!).map((v) => DropdownMenuItem(value: v, child: Text('$v'))).toList(),
                  onChanged: (v) => setState(() => verseTo = v),
                )),
              ]),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<ReferenceItem>(
              value: hizb,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hizb à valider'),
              items: ref.hizbs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: ref.hizbs.isEmpty ? null : (v) => setState(() {
                hizb = v;
                if (v != null) juz = null;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ReferenceItem>(
              value: juz,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Juz à valider'),
              items: ref.juzs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: ref.juzs.isEmpty ? null : (v) => setState(() {
                juz = v;
                if (v != null) hizb = null;
              }),
            ),
            if (ref.hizbs.isEmpty && ref.juzs.isEmpty) ...[
              const SizedBox(height: 10),
              const Text('Le référentiel Hizb/Juz n’a pas encore été transmis par le Principal.', style: TextStyle(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Remarque facultative')),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer la validation')),
          ],
        ),
      ),
    );
  }
}
