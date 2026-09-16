import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../services/local_store.dart';
import 'student_screen.dart';

class ClassesScreen extends StatelessWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final LocalStore store;
  const ClassesScreen({super.key, required this.config, required this.snapshot, required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(snapshot.displayTitle)),
        body: SafeArea(
          child: ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              48 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: snapshot.classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = snapshot.classes[i];
              final students = snapshot.students.where((s) => s.classId == c.id || c.studentIds.contains(s.id)).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
              return Card(
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                  title: Text(c.name.isEmpty ? c.id : c.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text('${students.length} élève(s)'),
                  children: students.map((s) => ListTile(
                    title: Text(s.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(s.matricule),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentScreen(config: config, snapshot: snapshot, student: s, store: store))),
                  )).toList(),
                ),
              );
            },
          ),
        ),
      );
}
