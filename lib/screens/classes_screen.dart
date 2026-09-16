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

  List<Student> _studentsFor(SchoolClass c) => snapshot.students
      .where((s) => s.classId == c.id || c.studentIds.contains(s.id))
      .toList()
    ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(snapshot.displayTitle)),
        body: SafeArea(
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(12, 12, 12, 48 + MediaQuery.of(context).padding.bottom),
            itemCount: snapshot.classes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = snapshot.classes[i];
              final students = _studentsFor(c);
              final className = c.name.trim().isEmpty ? 'Classe' : c.name.trim();
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
                  title: Text(className, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  subtitle: Text('${students.length} élève(s)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClassStudentsScreen(
                        config: config,
                        snapshot: snapshot,
                        schoolClass: c,
                        students: students,
                        store: store,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class ClassStudentsScreen extends StatelessWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final SchoolClass schoolClass;
  final List<Student> students;
  final LocalStore store;

  const ClassStudentsScreen({
    super.key,
    required this.config,
    required this.snapshot,
    required this.schoolClass,
    required this.students,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final className = schoolClass.name.trim().isEmpty ? 'Classe' : schoolClass.name.trim();
    return Scaffold(
      appBar: AppBar(title: Text(className)),
      body: SafeArea(
        child: students.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Aucun élève reçu pour cette classe.')))
            : ListView.separated(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 48 + MediaQuery.of(context).padding.bottom),
                itemCount: students.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = students[i];
                  final display = s.displayName.trim().isNotEmpty
                      ? s.displayName.trim()
                      : (s.matricule.trim().isNotEmpty ? s.matricule.trim() : 'Élève');
                  return ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(display, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: s.matricule.trim().isEmpty ? null : Text('Matricule : ${s.matricule}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentScreen(config: config, snapshot: snapshot, student: s, store: store),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
