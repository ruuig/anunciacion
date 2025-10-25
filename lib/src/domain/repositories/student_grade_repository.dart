// Interfaz para repositorio de calificaciones de estudiantes
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';

abstract class StudentGradeRepository implements BaseRepository<GradeEntry, int> {
  // Buscar calificaciones por grupo, materia y período
  Future<List<GradeEntry>> getGrades({
    required int groupId,
    required int subjectId,
    required int periodId,
  });

  // Insertar/actualizar una calificación individual
  Future<void> upsertGrade({
    required int studentId,
    required int subjectId,
    required int periodId,
    required double value,
  });

  // Insertar/actualizar múltiples calificaciones
  Future<void> upsertGradesBatch(List<GradeEntry> entries);

  // Calcular promedio de calificaciones
  Future<double> getAverage({
    required int groupId,
    required int subjectId,
    required int periodId,
  });

  // Buscar calificaciones de un estudiante específico
  Future<List<GradeEntry>> getStudentGrades({
    required int studentId,
    required int subjectId,
    required int periodId,
  });
}
