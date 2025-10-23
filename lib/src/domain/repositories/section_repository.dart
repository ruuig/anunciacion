// Interfaz para SectionRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class SectionRepository implements BaseRepository<Section, int> {
  // Métodos específicos del repositorio de secciones
  Future<List<Section>> findByGrade(int gradeId);
  Future<Section?> findByGradeAndName(int gradeId, String name);
  Future<List<Section>> findActiveSections();
}
