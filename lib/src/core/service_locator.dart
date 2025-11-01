import 'package:anunciacion/src/application/use_cases/create_activity.dart';
import 'package:anunciacion/src/application/use_cases/get_activities.dart';
import 'package:anunciacion/src/application/use_cases/get_activity_by_id.dart';
import 'package:anunciacion/src/application/use_cases/update_activity.dart';
import 'package:anunciacion/src/application/use_cases/delete_activity.dart';
import 'package:anunciacion/src/application/use_cases/grade_activity.dart';
import 'package:anunciacion/src/data/repositories/activity_repository_impl_mock.dart';
import 'package:get_it/get_it.dart';

import '../domain/repositories/activity_repository.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  sl.registerLazySingleton<ActivityRepository>(
      () => ActivityRepositoryImplMock());

  sl.registerLazySingleton(() => GetActivities(sl()));
  sl.registerLazySingleton(() => GetActivityById(sl()));
  sl.registerLazySingleton(() => CreateActivity(sl()));
  sl.registerLazySingleton(() => UpdateActivity(sl()));
  sl.registerLazySingleton(() => DeleteActivity(sl()));
  sl.registerLazySingleton(() => GradeActivity(sl()));
}
