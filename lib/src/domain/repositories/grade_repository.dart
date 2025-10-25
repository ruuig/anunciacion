// Interfaz para repositorio de grados escolares
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';

abstract class GradeRepository implements BaseRepository<Grade, int> {
  // Buscar grados por nivel educativo
  Future<List<Grade>> findByEducationalLevel(int educationalLevelId);

  // Buscar grados por año académico
  Future<List<Grade>> findByAcademicYear(String academicYear);

  // Buscar grado por nombre y año
  Future<Grade?> findByNameAndYear(String name, String academicYear);

  // Buscar grados activos
  Future<List<Grade>> findActiveGrades();
}
