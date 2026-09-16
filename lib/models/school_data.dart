import 'reference_data.dart';

class StudentHistoryItem {
  final String category;
  final String date;
  final String title;
  final String details;
  final Map<String, dynamic> raw;

  const StudentHistoryItem({required this.category, required this.date, required this.title, required this.details, required this.raw});

  factory StudentHistoryItem.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString();
      }
      return '';
    }
    return StudentHistoryItem(
      category: pick(['category', 'type', 'source']),
      date: pick(['date', 'createdAt', 'updatedAt']),
      title: pick(['title', 'label', 'subject', 'category', 'type']),
      details: pick(['details', 'message', 'note', 'appreciation', 'value']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() => raw;
}

class Student {
  final String id;
  final String matricule;
  final String name;
  final String firstName;
  final String classId;
  final String gender;
  final List<StudentHistoryItem> history;

  const Student({required this.id, required this.matricule, required this.name, required this.firstName, required this.classId, required this.gender, required this.history});

  String get displayName => [name, firstName].where((e) => e.trim().isNotEmpty).join(' ');

  factory Student.fromJson(Map<String, dynamic> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final v = json[key];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
      return '';
    }
    List<StudentHistoryItem> parseHistory(dynamic value) {
      if (value is! List) return const [];
      return value.whereType<Map>().map((e) => StudentHistoryItem.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return Student(
      id: pick(['id', 'studentId', 'ID']),
      matricule: pick(['matricule']),
      name: pick(['name', 'lastName', 'last', 'nom']),
      firstName: pick(['firstName', 'first', 'prenom']),
      classId: pick(['classId', 'classeId', 'class']),
      gender: pick(['gender', 'sexe']),
      history: parseHistory(json['history']),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'matricule': matricule, 'name': name, 'firstName': firstName, 'classId': classId, 'gender': gender, 'history': history.map((e) => e.toJson()).toList()};
}

class SchoolClass {
  final String id;
  final String name;
  final String teacher;
  final List<String> studentIds;

  const SchoolClass({required this.id, required this.name, required this.teacher, required this.studentIds});

  factory SchoolClass.fromJson(Map<String, dynamic> json) {
    final rawIds = (json['studentIds'] ?? json['students'] ?? const []) as dynamic;
    return SchoolClass(
      id: (json['id'] ?? json['classId'] ?? '').toString(),
      name: (json['name'] ?? json['label'] ?? json['className'] ?? '').toString(),
      teacher: (json['teacher'] ?? '').toString(),
      studentIds: rawIds is List ? rawIds.map((e) => e.toString()).toList() : const [],
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'teacher': teacher, 'studentIds': studentIds};
}

class SyncSnapshot {
  final int protocolVersion;
  final String schoolName;
  final String schoolTitle;
  final String schoolYear;
  final String teacher;
  final double evaluationMax;
  final List<SchoolClass> classes;
  final List<Student> students;
  final List<dynamic> bulletinPeriods;
  final List<dynamic> planning;
  final ReferenceCatalog references;
  final Map<String, dynamic> raw;
  final DateTime receivedAt;

  const SyncSnapshot({
    required this.protocolVersion,
    required this.schoolName,
    required this.schoolTitle,
    required this.schoolYear,
    required this.teacher,
    required this.evaluationMax,
    required this.classes,
    required this.students,
    required this.bulletinPeriods,
    required this.planning,
    required this.references,
    required this.raw,
    required this.receivedAt,
  });

  int get historyItems => students.fold(0, (total, s) => total + s.history.length);
  String get displayTitle => schoolTitle.trim().isNotEmpty ? schoolTitle.trim() : (schoolName.trim().isNotEmpty ? schoolName.trim() : 'ÉCOLE GESTION PRO');

  factory SyncSnapshot.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(dynamic value) => value is List ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) return value.toString().trim();
      }
      return '';
    }
    return SyncSnapshot(
      protocolVersion: int.tryParse((json['protocolVersion'] ?? '0').toString()) ?? 0,
      schoolName: pick(['schoolName', 'establishmentName', 'school']),
      schoolTitle: pick(['schoolTitle', 'principalTitle', 'appTitle', 'establishmentTitle', 'schoolName']),
      schoolYear: pick(['schoolYear', 'year']),
      teacher: pick(['teacher', 'teacherName']),
      evaluationMax: double.tryParse((json['evaluationMax'] ?? '20').toString()) ?? 20,
      classes: maps(json['classes']).map(SchoolClass.fromJson).toList(),
      students: maps(json['students']).map(Student.fromJson).toList(),
      bulletinPeriods: json['bulletinPeriods'] is List ? List<dynamic>.from(json['bulletinPeriods']) : const [],
      planning: json['planning'] is List ? List<dynamic>.from(json['planning']) : const [],
      references: ReferenceCatalog.fromRoot(json),
      raw: json,
      receivedAt: DateTime.tryParse((json['_mobileReceivedAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }

  SyncSnapshot mergeReferenceData(Map<String, dynamic> referenceData) {
    final merged = Map<String, dynamic>.from(raw);
    merged['referenceData'] = referenceData;
    // Le Principal peut fournir son titre exact avec le référentiel sans obliger
    // les anciennes réponses V6 /sync à changer de structure.
    for (final key in const ['schoolTitle', 'principalTitle', 'appTitle', 'establishmentTitle']) {
      final value = referenceData[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        merged['schoolTitle'] = value.toString().trim();
        break;
      }
    }
    merged['_mobileReceivedAt'] = DateTime.now().toIso8601String();
    return SyncSnapshot.fromJson(merged);
  }

  Map<String, dynamic> toJson() => {...raw, '_mobileReceivedAt': receivedAt.toIso8601String()};
}
