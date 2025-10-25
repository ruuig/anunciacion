import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/value_objects/activity_filters.dart';
import 'package:anunciacion/src/domain/repositories/base_repository.dart';

/// Contrato para trabajar con actividades académicas y sus calificaciones.
abstract class ActivityRepository extends BaseRepository<Activity, int> {
  /// Obtiene la lista de actividades aplicando filtros opcionales.
  Future<List<Activity>> getActivities({ActivityFilters? filters});

  /// Crea una nueva actividad.
  Future<Activity> createActivity(Activity activity);

  /// Actualiza la información de una actividad existente.
  Future<Activity> updateActivity(Activity activity);

  /// Elimina una actividad por su identificador.
  Future<void> deleteActivity(int id);

  /// Obtiene las calificaciones registradas para una actividad.
  Future<List<ActivityGrade>> getActivityGrades(int activityId);

  /// Registra o actualiza calificaciones para los estudiantes de una actividad.
  Future<void> saveActivityGrades({
    required int activityId,
    required int gradedBy,
    required List<ActivityGrade> grades,
  });
}
