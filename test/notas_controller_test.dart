import 'package:anunciacion/src/application/use_cases/grade/get_grades_use_case.dart';
import 'package:anunciacion/src/application/use_cases/grade/upsert_grade_use_case.dart';
import 'package:anunciacion/src/domain/entities/grade_entry.dart';
import 'package:anunciacion/src/domain/repositories/student_grade_repository.dart';
import 'package:anunciacion/src/presentation/screens/notas_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStudentGradeRepository implements StudentGradeRepository {
  _FakeStudentGradeRepository(this._entries);

  final List<GradeEntry> _entries;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<bool> existsById(int id) async => false;

  @override
  Future<List<GradeEntry>> findAll() async => _entries;

  @override
  Future<GradeEntry?> findById(int id) async => null;

  @override
  Future<double> getAverage({
    required int groupId,
    required int subjectId,
    required int periodId,
  }) async => 0.0;

  @override
  Future<List<GradeEntry>> getGrades({
    required int groupId,
    required int subjectId,
    required int periodId,
  }) async => _entries;

  @override
  Future<List<GradeEntry>> getStudentGrades({
    required int studentId,
    required int subjectId,
    required int periodId,
  }) async => _entries;

  @override
  Future<GradeEntry> save(GradeEntry entity) async => entity;

  @override
  Future<GradeEntry> update(GradeEntry entity) async => entity;

  @override
  Future<void> upsertGrade({
    required int studentId,
    required int subjectId,
    required int periodId,
    required double value,
  }) async {}

  @override
  Future<void> upsertGradesBatch(List<GradeEntry> entries) async {}
}

void main() {
  test('load asigna promedio 0 cuando todas las notas son nulas', () async {
    const entries = [
      GradeEntry(studentId: 1, subjectId: 1, periodId: 1, value: null),
      GradeEntry(studentId: 2, subjectId: 1, periodId: 1, value: null),
      GradeEntry(studentId: 3, subjectId: 1, periodId: 1, value: null),
    ];

    final repository = _FakeStudentGradeRepository(entries);
    final controller = NotasController(
      GetGradesUseCase(repository),
      UpsertGradeUseCase(repository),
    );

    controller.setFilters(groupId: 1, subjectId: 1, periodId: 1);
    await controller.load();

    expect(controller.state.average, 0.0);
    expect(controller.state.entries, entries);
  });
}
