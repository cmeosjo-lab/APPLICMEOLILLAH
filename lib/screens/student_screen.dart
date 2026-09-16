import 'package:flutter/material.dart';
import '../models/principal_config.dart';
import '../models/school_data.dart';
import '../services/local_store.dart';
import '../widgets/action_tile.dart';
import 'attendance_screen.dart';
import 'incident_screen.dart';
import 'lesson_followup_screen.dart';
import 'quran_screen.dart';
import 'student_history_screen.dart';

class StudentScreen extends StatelessWidget {
  final PrincipalConfig config;
  final SyncSnapshot snapshot;
  final Student student;
  final LocalStore store;

  const StudentScreen({super.key, required this.config, required this.snapshot, required this.student, required this.store});

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(snapshot.displayTitle)),
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
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const CircleAvatar(radius: 24, child: Icon(Icons.person_outline)),
                title: Text(student.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                subtitle: Text(student.matricule.isEmpty ? 'Matricule non renseigné' : student.matricule),
              ),
            ),
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.event_busy_outlined,
              title: 'Absence / retard',
              subtitle: 'Justifié ou non justifié, heure d’arrivée pour les retards',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(config: config, snapshot: snapshot, student: student, store: store))),
            ),
            const SizedBox(height: 10),
            ActionTile(
              icon: Icons.auto_stories_outlined,
              title: 'Suivi Coran',
              subtitle: 'Sourate, versets, Hizb et Juz depuis le référentiel du Principal',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuranScreen(config: config, snapshot: snapshot, student: student, store: store))),
            ),
            const SizedBox(height: 10),
            ActionTile(
              icon: Icons.menu_book_outlined,
              title: 'Suivi de leçon',
              subtitle: 'Choisir la leçon dans le rideau synchronisé du Principal',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonFollowUpScreen(config: config, snapshot: snapshot, student: student, store: store))),
            ),
            const SizedBox(height: 10),
            ActionTile(
              icon: Icons.report_outlined,
              title: 'Incident',
              subtitle: 'Nature en rideau, priorité et description',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IncidentScreen(config: config, snapshot: snapshot, student: student, store: store))),
            ),
            const SizedBox(height: 10),
            ActionTile(
              icon: Icons.history,
              title: 'Historique du Principal',
              subtitle: '${student.history.length} événement(s) synchronisé(s)',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentHistoryScreen(student: student, title: snapshot.displayTitle))),
            ),
          ]),
        ),
      );
}
