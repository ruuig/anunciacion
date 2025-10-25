import 'package:equatable/equatable.dart';

/// Entidad que representa una calificación/nota de un estudiante
class GradeEntry extends Equatable {
  final int? id;
  final int studentId;
  final int subjectId;
  final int periodId;
  final double? value;

  const GradeEntry({
    this.id,
    required this.studentId,
    required this.subjectId,
    required this.periodId,
    this.value,
  });

  /// Constructor para crear una nueva entrada de calificación
  factory GradeEntry.create({
    required int studentId,
    required int subjectId,
    required int periodId,
    double? value,
  }) {
    return GradeEntry(
      id: null,
      studentId: studentId,
      subjectId: subjectId,
      periodId: periodId,
      value: value,
    );
  }

  /// Crea una copia con campos modificados
  GradeEntry copyWith({
    int? id,
    int? studentId,
    int? subjectId,
    int? periodId,
    double? value,
  }) {
    return GradeEntry(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      periodId: periodId ?? this.periodId,
      value: value ?? this.value,
    );
  }

  @override
  List<Object?> get props => [id, studentId, subjectId, periodId, value];

  @override
  String toString() =>
      'GradeEntry(id: $id, studentId: $studentId, subjectId: $subjectId, periodId: $periodId, value: $value)';
}
