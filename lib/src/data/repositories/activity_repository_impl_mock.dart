import '../../domain/entities/activity.dart';
import '../../domain/repositories/activity_repository.dart';

class ActivityRepositoryImplMock implements ActivityRepository {
  final List<Activity> _storage = [
    Activity(
      id: 1,
      name: 'Examen Parcial - Fracciones',
      subject: 'Matemáticas',
      grade: '3ro Primaria',
      section: 'A',
      period: 'Primer Bimestre',
      type: 'Examen',
      points: 25,
      date: DateTime(2025, 2, 15),
      status: 'completed',
      studentsGraded: 24,
      totalStudents: 28,
      averageGrade: 78.5,
      description: 'Examen de fracciones con problemas prácticos.',
    ),
    Activity(
      id: 2,
      name: 'Tarea - Ejercicios de suma',
      subject: 'Matemáticas',
      grade: '2do Primaria',
      section: 'B',
      period: 'Primer Bimestre',
      type: 'Tarea',
      points: 10,
      date: DateTime(2025, 2, 10),
      status: 'pending',
      studentsGraded: 0,
      totalStudents: 30,
      averageGrade: null,
    ),
  ];

  // Método nuevo que imita un getAll del repositorio real
  Future<List<Activity>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List<Activity>.from(_storage);
  }

  @override
  Future<Activity> createActivity(Activity activity) async {
    _storage.add(activity);
    return activity;
  }

  @override
  Future<void> deleteActivity(int id) async {
    _storage.removeWhere((a) => a.id == id);
  }

  @override
  Future<List<Activity>> getActivities() async {
    return await getAll(); // usa el nuevo método
  }

  @override
  Future<Activity?> getActivityById(int id) async {
    try {
      return _storage.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Activity> gradeActivity({
    required int activityId,
    required int studentsGraded,
    required String status,
    double? averageGrade,
    List<ActivityGroup>? groups,
  }) async {
    final idx = _storage.indexWhere((a) => a.id == activityId);
    if (idx == -1) throw Exception('Activity not found');
    final old = _storage[idx];
    final updated = old.copyWith(
      studentsGraded: studentsGraded,
      status: status,
      averageGrade: averageGrade,
      groups: groups,
    );
    _storage[idx] = updated;
    return updated;
  }

  @override
  Future<Activity> updateActivity(Activity activity) async {
    final idx = _storage.indexWhere((a) => a.id == activity.id);
    if (idx == -1) {
      _storage.add(activity);
      return activity;
    }
    _storage[idx] = activity;
    return activity;
  }
}
