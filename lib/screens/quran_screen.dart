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
  String mode = 'memorisation';
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
    setState(() { surah = value; verseFrom = null; verseTo = null; });
  }

  Future<void> save() async {
    if (surah == null && hizb == null && juz == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisir au moins une Sourate, un Hizb ou un Juz.')));
      return;
    }
    final deviceId = await widget.store.getOrCreateDeviceId();
    final event = TeacherEvent.create(
      type: 'quranValidation',
      teacher: widget.config.teacher,
      studentId: widget.student.id,
      classId: widget.student.classId,
      deviceId: deviceId,
      payload: {
        'mode': mode,
        if (surah != null) 'surah': surah!.label,
        if (surah != null) 'surahNumber': surah!.number,
        if (surah != null && surah!.arabic.isNotEmpty) 'surahArabic': surah!.arabic,
        if (verseFrom != null) 'verseFrom': verseFrom,
        if (verseTo != null) 'verseTo': verseTo,
        if (hizb != null) 'hizb': hizb!.number,
        if (hizb != null && hizb!.arabic.isNotEmpty) 'hizbArabic': hizb!.arabic,
        if (juz != null) 'juz': juz!.number,
        if (juz != null && juz!.arabic.isNotEmpty) 'juzArabic': juz!.arabic,
        if (note.text.trim().isNotEmpty) 'note': note.text.trim(),
      },
    );
    await widget.store.enqueue(event);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Suivi Coran enregistré localement.')));
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
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              48 + MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom,
            ),
            children: [
          Text('Suivi Coran — ${widget.student.displayName}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(ref.receivedFromPrincipal ? 'Listes synchronisées depuis le PC Principal.' : 'Le référentiel du Principal n’a pas encore été reçu.', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: mode,
            decoration: const InputDecoration(labelText: 'Type de suivi'),
            items: const [
              DropdownMenuItem(value: 'memorisation', child: Text('Mémorisation')),
              DropdownMenuItem(value: 'revision', child: Text('Révision')),
              DropdownMenuItem(value: 'validation', child: Text('Validation')),
            ],
            onChanged: (v) => setState(() => mode = v ?? 'memorisation'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReferenceItem>(
            value: surah,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sourate'),
            items: ref.surahs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis, textDirection: e.arabic.isNotEmpty ? TextDirection.rtl : null))).toList(),
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
                onChanged: (v) => setState(() { verseFrom = v; if (verseTo != null && v != null && verseTo! < v) verseTo = v; }),
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
            decoration: const InputDecoration(labelText: 'Hizb — numéro et nom arabe'),
            items: ref.hizbs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl))).toList(),
            onChanged: ref.hizbs.isEmpty ? null : (v) => setState(() => hizb = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ReferenceItem>(
            value: juz,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Juz — numéro et nom arabe'),
            items: ref.juzs.map((e) => DropdownMenuItem(value: e, child: Text(e.displayLabel, overflow: TextOverflow.ellipsis, textDirection: TextDirection.rtl))).toList(),
            onChanged: ref.juzs.isEmpty ? null : (v) => setState(() => juz = v),
          ),
          if (ref.surahs.isEmpty || ref.hizbs.isEmpty || ref.juzs.isEmpty) ...[
            const SizedBox(height: 10),
            const Text('Les rideaux vides seront remplis dès que le PC Principal transmettra son référentiel Coran.', style: TextStyle(fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 12),
          TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Remarque facultative')),
          const SizedBox(height: 22),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('Enregistrer le suivi')),
        ]),
      ),
    );
  }
}
