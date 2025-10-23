// Interfaz para StudentParentRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class StudentParentRepository
    implements BaseRepository<StudentParent, int> {
  // Métodos específicos del repositorio de relaciones estudiante-padre
  Future<List<StudentParent>> findByStudent(int studentId);
  Future<List<StudentParent>> findByParent(int parentId);
  Future<List<StudentParent>> findPrimaryContacts(int studentId);
  Future<List<StudentParent>> findEmergencyContacts(int studentId);
}
