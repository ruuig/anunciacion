// Interfaz para SubjectRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class SubjectRepository implements BaseRepository<Subject, int> {
  // Métodos específicos del repositorio de materias
  Future<Subject?> findByCode(String code);
  Future<Subject?> findByName(String name);
  Future<List<Subject>> findActiveSubjects();
  Future<bool> existsByCode(String code);
  Future<bool> existsByName(String name);
}
