// Interfaz para StudentRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class StudentRepository implements BaseRepository<Student, int> {
  // Métodos específicos del repositorio de estudiantes
  Future<Student?> findByDPI(DPI dpi);
  Future<List<Student>> findByGrade(int gradeId);
  Future<List<Student>> findBySection(int sectionId);
  Future<List<Student>> findByParent(int parentId);
  Future<List<Student>> findActiveStudents();
  Future<bool> existsByDPI(DPI dpi);
}
