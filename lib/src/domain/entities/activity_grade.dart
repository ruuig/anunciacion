import 'package:equatable/equatable.dart';

/// Entidad que representa la calificación de un estudiante en una actividad.
class ActivityGrade extends Equatable {
  final int? id;
  final int activityId;
  final int studentId;
  final String? studentName;
  final double? obtainedPoints;
  final double? percentage;
  final String? comments;
  final int? gradedBy;
  final DateTime? gradedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ActivityGrade({
    this.id,
    required this.activityId,
    required this.studentId,
    this.studentName,
    this.obtainedPoints,
    this.percentage,
    this.comments,
    this.gradedBy,
    this.gradedAt,
    this.createdAt,
    this.updatedAt,
  });

  ActivityGrade copyWith({
    int? id,
    int? activityId,
    int? studentId,
    String? studentName,
    double? obtainedPoints,
    double? percentage,
    String? comments,
    int? gradedBy,
    DateTime? gradedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityGrade(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      obtainedPoints: obtainedPoints ?? this.obtainedPoints,
      percentage: percentage ?? this.percentage,
      comments: comments ?? this.comments,
      gradedBy: gradedBy ?? this.gradedBy,
      gradedAt: gradedAt ?? this.gradedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        activityId,
        studentId,
        studentName,
        obtainedPoints,
        percentage,
        comments,
        gradedBy,
        gradedAt,
        createdAt,
        updatedAt,
      ];
}
