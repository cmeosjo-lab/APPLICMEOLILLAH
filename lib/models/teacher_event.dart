import 'package:uuid/uuid.dart';

class TeacherEvent {
  static const _uuid = Uuid();

  final String id;
  final String type;
  final String teacher;
  final String studentId;
  final String classId;
  final String deviceId;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final String status;
  final String reviewNote;

  const TeacherEvent({
    required this.id,
    required this.type,
    required this.teacher,
    required this.studentId,
    required this.classId,
    this.deviceId = '',
    required this.createdAt,
    required this.payload,
    this.status = 'pending',
    this.reviewNote = '',
  });

  factory TeacherEvent.create({
    required String type,
    required String teacher,
    required String studentId,
    required String classId,
    String deviceId = '',
    required Map<String, dynamic> payload,
  }) =>
      TeacherEvent(
        id: 'MOB-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4()}',
        type: type,
        teacher: teacher,
        studentId: studentId,
        classId: classId,
        deviceId: deviceId,
        createdAt: DateTime.now(),
        payload: payload,
      );

  factory TeacherEvent.fromJson(Map<String, dynamic> json) => TeacherEvent(
        id: (json['id'] ?? '').toString(),
        type: (json['type'] ?? json['category'] ?? '').toString(),
        teacher: (json['teacher'] ?? '').toString(),
        studentId: (json['studentId'] ?? '').toString(),
        classId: (json['classId'] ?? '').toString(),
        deviceId: (json['deviceId'] ?? '').toString(),
        createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
        payload: json['payload'] is Map ? Map<String, dynamic>.from(json['payload']) : <String, dynamic>{},
        status: (json['_mobileStatus'] ?? 'pending').toString(),
        reviewNote: (json['_reviewNote'] ?? '').toString(),
      );

  /// Types effectivement compris par le serveur Principal V1.6.7.
  bool get supportedByPrincipalV167 => const {
        'attendance',
        'evaluation',
        'communication',
        'quranValidation',
        'quran_validation',
        'quranProgress',
        'quran_progress',
        'homework',
        'annualAppreciation',
        'annual_appreciation',
      }.contains(type);

  String get protocolType {
    if (type == 'quranValidation') return 'quran_validation';
    if (type == 'annualAppreciation') return 'annual_appreciation';
    if (type == 'quranProgress') return 'quran_progress';
    return type;
  }

  String get unsupportedLabel {
    if (type == 'lessonFollowUp') return 'suivi de leçon';
    return type;
  }

  /// Format réseau exact du Principal V1.6.7 :
  /// - champ `type` (et non `category`)
  /// - payload métier imbriqué sous sa clé dédiée.
  Map<String, dynamic> toProtocolV6Json() {
    final result = <String, dynamic>{
      'id': id,
      'teacher': teacher,
      'type': protocolType,
      'studentId': studentId,
      'classId': classId,
      if (deviceId.isNotEmpty) 'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
    };

    switch (protocolType) {
      case 'attendance':
        result['attendance'] = payload;
        break;
      case 'evaluation':
        result['evaluation'] = payload;
        break;
      case 'communication':
        result['communication'] = payload;
        break;
      case 'quran_validation':
        result['quranValidation'] = payload;
        break;
      case 'quran_progress':
        result['quranProgress'] = payload;
        break;
      case 'homework':
        result['homework'] = payload;
        break;
      case 'annual_appreciation':
        result['annualAppreciation'] = payload;
        break;
      default:
        // Les types non pris en charge ne sont normalement pas envoyés par
        // SyncService. La clé reste utile pour le diagnostic local.
        result['payload'] = payload;
    }
    return result;
  }

  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'type': type,
        'teacher': teacher,
        'studentId': studentId,
        'classId': classId,
        'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        '_mobileStatus': status,
        if (reviewNote.isNotEmpty) '_reviewNote': reviewNote,
      };

  TeacherEvent copyWithStatus(String newStatus, {String? note}) => TeacherEvent(
        id: id,
        type: type,
        teacher: teacher,
        studentId: studentId,
        classId: classId,
        deviceId: deviceId,
        createdAt: createdAt,
        payload: payload,
        status: newStatus,
        reviewNote: note ?? reviewNote,
      );
}
