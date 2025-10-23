// Interfaz para ParentRepository
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';

import 'package:anunciacion/src/domain/repositories/repositories.dart';

abstract class ParentRepository implements BaseRepository<Parent, int> {
  // Métodos específicos del repositorio de padres
  Future<Parent?> findByDPI(DPI dpi);
  Future<List<Parent>> findByStudent(int studentId);
  Future<bool> existsByDPI(DPI dpi);
}
