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

      final validEntries = entries
          .where((entry) => entry.value != null)
          .map((entry) => entry.value!)
          .toList();

      final double average;
      if (validEntries.isEmpty) {
        average = 0.0;
      } else {
        final total = validEntries.reduce((a, b) => a + b);
        average = total / validEntries.length;
      }

      state = state.copyWith(
        entries: entries,
        average: average,
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
  void updateValue(int studentId, double value) {
    final updatedEntries = state.entries.map((entry) {
      if (entry.studentId == studentId) {
        return entry.copyWith(value: value);
      }
      return entry;
    }).toList();

    state = state.copyWith(entries: updatedEntries);
  }

  /// Guarda todas las calificaciones modificadas
  Future<void> saveAll() async {
    if (state.entries.isEmpty) return;

    try {
      GradeEntry? invalidEntry;
      for (final entry in state.entries) {
        final value = entry.value;
        if (value != null && (value < 0 || value > 100)) {
          invalidEntry = entry;
          break;
        }
      }

      if (invalidEntry != null && invalidEntry.value != null) {
        throw RangeError.range(
          invalidEntry.value!,
          0,
          100,
          'value',
          'Las calificaciones deben estar entre 0 y 100.',
        );
      }

      state = state.copyWith(loading: true, error: null);

      await _upsertGradeUseCase.upsertBatch(state.entries);
      state = state.copyWith(loading: false);

      // Recargar para obtener los datos actualizados
      await load();
    } on RangeError catch (e) {
      state = state.copyWith(
        error: e.message ?? 'Las calificaciones deben estar entre 0 y 100.',
        loading: false,
      );
      rethrow;
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
}
