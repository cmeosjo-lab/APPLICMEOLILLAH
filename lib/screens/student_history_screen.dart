import 'package:flutter/material.dart';
import '../models/school_data.dart';

class StudentHistoryScreen extends StatefulWidget {
  final Student student;
  final String title;
  const StudentHistoryScreen({super.key, required this.student, required this.title});

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  String filter = 'Tout';

  @override
  Widget build(BuildContext context) {
    final all = List<StudentHistoryItem>.from(widget.student.history)..sort((a, b) => b.date.compareTo(a.date));
    final items = filter == 'Tout' ? all : all.where((e) => ('${e.category} ${e.title}').toLowerCase().contains(filter.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(children: [
          SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 10, 12, 6), child: Row(children: ['Tout','Absence','Retard','Coran','Discipline','Matériel','Devoir','Évaluation'].map((x) => Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(x), selected: filter == x, onSelected: (_) => setState(() => filter = x)))).toList())),
          Expanded(child: items.isEmpty
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Aucun historique renvoyé par le PC Principal pour cet élève.\n\nLe Principal reste la base officielle.", textAlign: TextAlign.center)))
          : ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                48 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final e = items[i];
                return Card(child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: const CircleAvatar(child: Icon(Icons.history)),
                  title: Text(e.title.isEmpty ? (e.category.isEmpty ? 'Événement' : e.category) : e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text([if (e.date.isNotEmpty) e.date, if (e.details.isNotEmpty) e.details].join('\n')),
                ));
              },
            ),
          ),
        ]),
    );
  }
}
