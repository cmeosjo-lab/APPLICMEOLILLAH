import 'package:flutter/material.dart';
import '../models/school_data.dart';

class StudentHistoryScreen extends StatelessWidget {
  final Student student;
  final String title;
  const StudentHistoryScreen({super.key, required this.student, required this.title});

  @override
  Widget build(BuildContext context) {
    final items = List<StudentHistoryItem>.from(student.history)..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
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
    );
  }
}
