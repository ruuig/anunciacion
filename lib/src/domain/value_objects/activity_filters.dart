import 'package:equatable/equatable.dart';

/// Valor que representa los filtros disponibles para consultar actividades.
class ActivityFilters extends Equatable {
  final int? gradeId;
  final int? sectionId;
  final int? subjectId;
  final String? type;

  const ActivityFilters({
    this.gradeId,
    this.sectionId,
    this.subjectId,
    this.type,
  });

  ActivityFilters copyWith({
    int? gradeId,
    int? sectionId,
    int? subjectId,
    String? type,
  }) {
    return ActivityFilters(
      gradeId: gradeId ?? this.gradeId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      type: type ?? this.type,
    );
  }

  ActivityFilters clearGrade() => copyWith(gradeId: null, sectionId: null);

  ActivityFilters clearSection() => copyWith(sectionId: null);

  ActivityFilters clearSubject() => copyWith(subjectId: null);

  ActivityFilters clearType() => copyWith(type: null);

  @override
  List<Object?> get props => [gradeId, sectionId, subjectId, type];
}
