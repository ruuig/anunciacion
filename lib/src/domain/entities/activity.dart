import 'package:equatable/equatable.dart';

/// Entidad que representa una actividad académica planificada por un docente.
class Activity extends Equatable {
  final int? id;
  final String name;
  final String? description;
  final int teacherId;
  final int subjectId;
  final int gradeId;
  final int sectionId;
  final int periodId;
  final String type;
  final double maxPoints;
  final DateTime? scheduledAt;
  final DateTime? dueDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? gradedStudents;
  final int? totalStudents;
  final double? averagePercentage;
  final String? subjectName;
  final String? gradeName;
  final String? sectionName;
  final String? periodName;

  const Activity({
    this.id,
    required this.name,
    this.description,
    required this.teacherId,
    required this.subjectId,
    required this.gradeId,
    required this.sectionId,
    required this.periodId,
    required this.type,
    required this.maxPoints,
    this.scheduledAt,
    this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.gradedStudents,
    this.totalStudents,
    this.averagePercentage,
    this.subjectName,
    this.gradeName,
    this.sectionName,
    this.periodName,
  });

  /// Constructor de conveniencia para crear una actividad nueva.
  factory Activity.create({
    required String name,
    String? description,
    required int teacherId,
    required int subjectId,
    required int gradeId,
    required int sectionId,
    required int periodId,
    required String type,
    required double maxPoints,
    DateTime? scheduledAt,
    DateTime? dueDate,
  }) {
    final now = DateTime.now();
    return Activity(
      id: null,
      name: name,
      description: description,
      teacherId: teacherId,
      subjectId: subjectId,
      gradeId: gradeId,
      sectionId: sectionId,
      periodId: periodId,
      type: type,
      maxPoints: maxPoints,
      scheduledAt: scheduledAt,
      dueDate: dueDate,
      status: 'pendiente',
      createdAt: now,
      updatedAt: now,
    );
  }

  Activity copyWith({
    int? id,
    String? name,
    String? description,
    int? teacherId,
    int? subjectId,
    int? gradeId,
    int? sectionId,
    int? periodId,
    String? type,
    double? maxPoints,
    DateTime? scheduledAt,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? gradedStudents,
    int? totalStudents,
    double? averagePercentage,
    String? subjectName,
    String? gradeName,
    String? sectionName,
    String? periodName,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      gradeId: gradeId ?? this.gradeId,
      sectionId: sectionId ?? this.sectionId,
      periodId: periodId ?? this.periodId,
      type: type ?? this.type,
      maxPoints: maxPoints ?? this.maxPoints,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gradedStudents: gradedStudents ?? this.gradedStudents,
      totalStudents: totalStudents ?? this.totalStudents,
      averagePercentage: averagePercentage ?? this.averagePercentage,
      subjectName: subjectName ?? this.subjectName,
      gradeName: gradeName ?? this.gradeName,
      sectionName: sectionName ?? this.sectionName,
      periodName: periodName ?? this.periodName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        teacherId,
        subjectId,
        gradeId,
        sectionId,
        periodId,
        type,
        maxPoints,
        scheduledAt,
        dueDate,
        status,
        createdAt,
        updatedAt,
        gradedStudents,
        totalStudents,
        averagePercentage,
        subjectName,
        gradeName,
        sectionName,
        periodName,
      ];
}
