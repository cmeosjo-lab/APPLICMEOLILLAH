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
      );

  /// Format compatible V6 : les champs mobiles privés commencent par _mobile et
  /// ne sont pas envoyés au Principal. Le payload métier est fusionné à la racine.
  Map<String, dynamic> toProtocolV6Json() => {
        'id': id,
        'category': type,
        'teacher': teacher,
        'studentId': studentId,
        'classId': classId,
        if (deviceId.isNotEmpty) 'deviceId': deviceId,
        'createdAt': createdAt.toIso8601String(),
        ...payload,
      };

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
      };

  TeacherEvent copyWithStatus(String newStatus) => TeacherEvent(
        id: id,
        type: type,
        teacher: teacher,
        studentId: studentId,
        classId: classId,
        deviceId: deviceId,
        createdAt: createdAt,
        payload: payload,
        status: newStatus,
      );
}
