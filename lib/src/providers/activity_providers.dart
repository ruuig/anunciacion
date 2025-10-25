import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:postgres/postgres.dart' as postgres;

import '../application/use_cases/activities/create_activity_use_case.dart';
import '../application/use_cases/activities/delete_activity_use_case.dart';
import '../application/use_cases/activities/get_activities_use_case.dart';
import '../application/use_cases/activities/get_activity_grades_use_case.dart';
import '../application/use_cases/activities/grade_activity_use_case.dart';
import '../application/use_cases/activities/update_activity_use_case.dart';
import '../domain/domain.dart';
import '../infrastructure/infrastructure.dart';

class ActivityFiltersNotifier extends StateNotifier<ActivityFilters> {
  ActivityFiltersNotifier() : super(const ActivityFilters());

  void setGrade(int? gradeId) {
    final shouldResetSection = gradeId == null || gradeId != state.gradeId;
    state = state.copyWith(
      gradeId: gradeId,
      sectionId: shouldResetSection ? null : state.sectionId,
    );
  }

  void setSection(int? sectionId) {
    state = state.copyWith(sectionId: sectionId);
  }

  void setSubject(int? subjectId) {
    state = state.copyWith(subjectId: subjectId);
  }

  void setType(String? type) {
    state = state.copyWith(type: type);
  }

  void clear() => state = const ActivityFilters();
}

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepositoryImpl();
});

final gradeRepositoryProvider = Provider<GradeRepository>((ref) {
  return GradeRepositoryImpl();
});

final sectionRepositoryProvider = Provider<SectionRepository>((ref) {
  return SectionRepositoryImpl();
});

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl();
});

final getActivitiesUseCaseProvider = Provider<GetActivitiesUseCase>((ref) {
  return GetActivitiesUseCase(ref.watch(activityRepositoryProvider));
});

final createActivityUseCaseProvider = Provider<CreateActivityUseCase>((ref) {
  return CreateActivityUseCase(ref.watch(activityRepositoryProvider));
});

final updateActivityUseCaseProvider = Provider<UpdateActivityUseCase>((ref) {
  return UpdateActivityUseCase(ref.watch(activityRepositoryProvider));
});

final deleteActivityUseCaseProvider = Provider<DeleteActivityUseCase>((ref) {
  return DeleteActivityUseCase(ref.watch(activityRepositoryProvider));
});

final gradeActivityUseCaseProvider = Provider<GradeActivityUseCase>((ref) {
  return GradeActivityUseCase(ref.watch(activityRepositoryProvider));
});

final getActivityGradesUseCaseProvider = Provider<GetActivityGradesUseCase>((ref) {
  return GetActivityGradesUseCase(ref.watch(activityRepositoryProvider));
});

final activityFiltersProvider =
    StateNotifierProvider<ActivityFiltersNotifier, ActivityFilters>((ref) {
  return ActivityFiltersNotifier();
});

final activitiesProvider =
    FutureProvider.autoDispose<List<Activity>>((ref) async {
  final filters = ref.watch(activityFiltersProvider);
  final useCase = ref.watch(getActivitiesUseCaseProvider);
  return useCase(filters: filters);
});

final activityGradesProvider = FutureProvider.autoDispose.family<List<ActivityGrade>, int>((ref, activityId) async {
  final useCase = ref.watch(getActivityGradesUseCaseProvider);
  return useCase(activityId);
});

final createActivityProvider = Provider<Future<Activity> Function(Activity)>((ref) {
  final useCase = ref.watch(createActivityUseCaseProvider);
  return (activity) async {
    final created = await useCase(activity);
    ref.invalidate(activitiesProvider);
    return created;
  };
});

final updateActivityProvider = Provider<Future<Activity> Function(Activity)>((ref) {
  final useCase = ref.watch(updateActivityUseCaseProvider);
  return (activity) async {
    final updated = await useCase(activity);
    ref.invalidate(activitiesProvider);
    return updated;
  };
});

final deleteActivityProvider = Provider<Future<void> Function(int)>((ref) {
  final useCase = ref.watch(deleteActivityUseCaseProvider);
  return (id) async {
    await useCase(id);
    ref.invalidate(activitiesProvider);
  };
});

final gradeActivityProvider = Provider<
    Future<void> Function({
  required int activityId,
  required int gradedBy,
  required List<ActivityGrade> grades,
})>((ref) {
  final useCase = ref.watch(gradeActivityUseCaseProvider);
  return ({required int activityId, required int gradedBy, required List<ActivityGrade> grades}) async {
    await useCase(activityId: activityId, gradedBy: gradedBy, grades: grades);
    ref
      ..invalidate(activitiesProvider)
      ..invalidate(activityGradesProvider(activityId));
  };
});

final activeGradesProvider = FutureProvider.autoDispose<List<Grade>>((ref) async {
  final repo = ref.watch(gradeRepositoryProvider);
  return repo.findActiveGrades();
});

final sectionsForSelectedGradeProvider =
    FutureProvider.autoDispose<List<Section>>((ref) async {
  final filters = ref.watch(activityFiltersProvider);
  if (filters.gradeId == null) {
    return const [];
  }
  final repo = ref.watch(sectionRepositoryProvider);
  return repo.findByGrade(filters.gradeId!);
});

final activeSubjectsProvider = FutureProvider.autoDispose<List<Subject>>((ref) async {
  final repo = ref.watch(subjectRepositoryProvider);
  return repo.findActiveSubjects();
});

final activityTypesProvider = Provider<List<String>>((ref) {
  return const ['Examen', 'Tarea', 'Proyecto', 'Laboratorio', 'Quiz', 'Otro'];
});

class PeriodOption {
  const PeriodOption({required this.id, required this.name});
  final int id;
  final String name;
}

final periodOptionsProvider = FutureProvider.autoDispose<List<PeriodOption>>((ref) async {
  final db = await DatabaseHelper().database;
  final result = await db.execute(
    postgres.Sql.named('SELECT id, nombre FROM periodos_academicos WHERE activo = TRUE ORDER BY orden'),
  );
  return result
      .map((row) => row.toColumnMap())
      .map((row) => PeriodOption(
            id: row['id'] as int,
            name: row['nombre'] as String? ?? '',
          ))
      .toList();
});
