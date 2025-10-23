// Interfaz para GradeRepository
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';


abstract class GradeRepository implements BaseRepository<Grade, int> {
  // Métodos específicos del repositorio de grados
  Future<List<Grade>> findByEducationalLevel(int educationalLevelId);
  Future<List<Grade>> findByAcademicYear(String academicYear);
  Future<Grade?> findByNameAndYear(String name, String academicYear);
  Future<List<Grade>> findActiveGrades();
}
