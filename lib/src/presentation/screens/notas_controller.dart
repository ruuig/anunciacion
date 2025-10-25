import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/application/use_cases/grade/get_grades_use_case.dart';
import 'package:anunciacion/src/application/use_cases/grade/upsert_grade_use_case.dart';
import 'package:anunciacion/src/presentation/providers/providers.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';

/// Estado de la pantalla de notas
class NotasState {
  final bool loading;
  final String? error;
  final List<GradeEntry> entries;
  final double average;
  final int? groupId;
  final int? subjectId;
  final int? periodId;

  const NotasState({
    this.loading = false,
    this.error,
    this.entries = const [],
    this.average = 0.0,
    this.groupId,
    this.subjectId,
    this.periodId,
  });

  NotasState copyWith({
    bool? loading,
    String? error,
    List<GradeEntry>? entries,
    double? average,
    int? groupId,
    int? subjectId,
    int? periodId,
  }) {
    return NotasState(
      loading: loading ?? this.loading,
      error: error ?? this.error,
      entries: entries ?? this.entries,
      average: average ?? this.average,
      groupId: groupId ?? this.groupId,
      subjectId: subjectId ?? this.subjectId,
      periodId: periodId ?? this.periodId,
    );
  }
}

/// Provider del estado de notas
final notasControllerProvider =
    StateNotifierProvider<NotasController, NotasState>((ref) {
  final getGradesUseCase = ref.watch(getGradesUseCaseProvider);
  final upsertGradeUseCase = ref.watch(upsertGradeUseCaseProvider);
  return NotasController(getGradesUseCase, upsertGradeUseCase);
});

/// Controller para manejar la lógica de la pantalla de notas
class NotasController extends StateNotifier<NotasState> {
  final GetGradesUseCase _getGradesUseCase;
  final UpsertGradeUseCase _upsertGradeUseCase;

  NotasController(this._getGradesUseCase, this._upsertGradeUseCase)
      : super(const NotasState());

  /// Establece los filtros y recarga los datos
  void setFilters({
    int? groupId,
    int? subjectId,
    int? periodId,
  }) {
    state = state.copyWith(
      groupId: groupId ?? state.groupId,
      subjectId: subjectId ?? state.subjectId,
      periodId: periodId ?? state.periodId,
      error: null,
    );
  }

  /// Carga las calificaciones con los filtros actuales
  Future<void> load() async {
    if (state.groupId == null || state.subjectId == null || state.periodId == null) {
      state = state.copyWith(
        error: 'Debe seleccionar grado, materia y período',
        loading: false,
      );
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      final entries = await _getGradesUseCase.call(
        groupId: state.groupId!,
        subjectId: state.subjectId!,
        periodId: state.periodId!,
      );

      final average = _calculateAverage(entries);

      state = state.copyWith(
        entries: entries,
        average: average.isNaN ? 0.0 : average,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al cargar calificaciones: $e',
        loading: false,
      );
    }
  }

  /// Actualiza el valor de una calificación
  void updateValue(int studentId, double? value) {
    final updatedEntries = state.entries.map((entry) {
      if (entry.studentId == studentId) {
        return GradeEntry(
          id: entry.id,
          studentId: entry.studentId,
          subjectId: entry.subjectId,
          periodId: entry.periodId,
          value: value,
          studentName: entry.studentName,
        );
      }
      return entry;
    }).toList();

    final average = _calculateAverage(updatedEntries);

    state = state.copyWith(
      entries: updatedEntries,
      average: average,
      error: null,
    );
  }

  /// Guarda todas las calificaciones modificadas
  Future<void> saveAll() async {
    if (state.entries.isEmpty) return;

    state = state.copyWith(loading: true, error: null);

    try {
      await _upsertGradeUseCase.upsertBatch(state.entries);

      // Recargar para obtener los datos actualizados
      await load();
    } catch (e) {
      state = state.copyWith(
        error: 'Error al guardar calificaciones: $e',
        loading: false,
      );
    }
  }

  /// Limpia el estado
  void clear() {
    state = const NotasState();
  }

  double _calculateAverage(List<GradeEntry> entries) {
    final valid = entries
        .where((e) => e.value != null)
        .map((e) => e.value!)
        .toList();
    if (valid.isEmpty) return 0.0;
    final total = valid.reduce((a, b) => a + b);
    return total / valid.length;
  }
}
