import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/application/use_cases/grade/get_grades_use_case.dart';
import 'package:anunciacion/src/application/use_cases/grade/upsert_grade_use_case.dart';
import 'package:anunciacion/src/infrastructure/repositories/student_grade_repository_impl.dart';
import 'package:anunciacion/src/domain/repositories/student_grade_repository.dart';

// Provider para el repositorio de calificaciones
final studentGradeRepositoryProvider = Provider<StudentGradeRepository>((ref) {
  return StudentGradeRepositoryImpl();
});

// Provider para el use case de obtener calificaciones
final getGradesUseCaseProvider = Provider<GetGradesUseCase>((ref) {
  final repository = ref.watch(studentGradeRepositoryProvider);
  return GetGradesUseCase(repository);
});

// Provider para el use case de upsert de calificaciones
final upsertGradeUseCaseProvider = Provider<UpsertGradeUseCase>((ref) {
  final repository = ref.watch(studentGradeRepositoryProvider);
  return UpsertGradeUseCase(repository);
});
