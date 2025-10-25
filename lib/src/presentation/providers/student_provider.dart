// Provider para gestión de estado de estudiantes
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../../application/use_cases/use_cases.dart';
import '../../infrastructure/repositories/repositories_impl.dart';

// Estado de estudiantes
class StudentState {
  final List<Student> students;
  final List<Grade> grades;
  final List<Section> sections;
  final bool isLoading;
  final String? error;

  const StudentState({
    this.students = const [],
    this.grades = const [],
    this.sections = const [],
    this.isLoading = false,
    this.error,
  });

  StudentState copyWith({
    List<Student>? students,
    List<Grade>? grades,
    List<Section>? sections,
    bool? isLoading,
    String? error,
  }) {
    return StudentState(
      students: students ?? this.students,
      grades: grades ?? this.grades,
      sections: sections ?? this.sections,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider de estado de estudiantes
class StudentNotifier extends StateNotifier<StudentState> {
  final CreateStudentUseCase _createStudentUseCase;
  final GetStudentsByGradeUseCase _getStudentsByGradeUseCase;
  final GetSectionsByGradeUseCase _getSectionsByGradeUseCase;

  StudentNotifier(
    this._createStudentUseCase,
    this._getStudentsByGradeUseCase,
    this._getSectionsByGradeUseCase,
  ) : super(const StudentState());

  Future<void> createStudent({
    required DPI dpi,
    required String name,
    required DateTime birthDate,
    Gender? gender,
    Address? address,
    Phone? phone,
    Email? email,
    String? avatarUrl,
    required int gradeId,
    required int sectionId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _createStudentUseCase.execute(
      CreateStudentInput(
        dpi: dpi,
        name: name,
        birthDate: birthDate,
        gender: gender,
        address: address,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
        gradeId: gradeId,
        sectionId: sectionId,
      ),
    );

    result.fold(
      (student) {
        final updatedStudents = [...state.students, student];
        state = state.copyWith(
          students: updatedStudents,
          isLoading: false,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
    );
  }

  Future<void> getStudentsByGrade(int gradeId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getStudentsByGradeUseCase.execute(gradeId);

    result.fold(
      (students) {
        state = state.copyWith(
          students: students,
          isLoading: false,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
    );
  }

  Future<void> getSectionsByGrade(int gradeId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getSectionsByGradeUseCase.execute(gradeId);

    result.fold(
      (sections) {
        state = state.copyWith(
          sections: sections,
          isLoading: false,
          error: null,
        );
      },
      (error) {
        state = state.copyWith(
          isLoading: false,
          error: error,
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearStudents() {
    state = state.copyWith(students: []);
  }
}

// Providers usando Riverpod
final studentRepositoryProvider = Provider<StudentRepositoryImpl>((ref) {
  return StudentRepositoryImpl();
});

final gradeRepositoryProvider = Provider<GradeRepositoryImpl>((ref) {
  return GradeRepositoryImpl();
});

final sectionRepositoryProvider = Provider<SectionRepositoryImpl>((ref) {
  return SectionRepositoryImpl();
});

final createStudentUseCaseProvider = Provider<CreateStudentUseCase>((ref) {
  final studentRepo = ref.watch(studentRepositoryProvider);
  final gradeRepo = ref.watch(gradeRepositoryProvider);
  final sectionRepo = ref.watch(sectionRepositoryProvider);
  return CreateStudentUseCase(studentRepo, gradeRepo, sectionRepo);
});

final getStudentsByGradeUseCaseProvider =
    Provider<GetStudentsByGradeUseCase>((ref) {
  final studentRepo = ref.watch(studentRepositoryProvider);
  return GetStudentsByGradeUseCase(studentRepo);
});

final getSectionsByGradeUseCaseProvider =
    Provider<GetSectionsByGradeUseCase>((ref) {
  final sectionRepo = ref.watch(sectionRepositoryProvider);
  return GetSectionsByGradeUseCase(sectionRepo);
});

final studentProvider =
    StateNotifierProvider<StudentNotifier, StudentState>((ref) {
  final createStudentUseCase = ref.watch(createStudentUseCaseProvider);
  final getStudentsByGradeUseCase =
      ref.watch(getStudentsByGradeUseCaseProvider);
  final getSectionsByGradeUseCase =
      ref.watch(getSectionsByGradeUseCaseProvider);

  return StudentNotifier(
    createStudentUseCase,
    getStudentsByGradeUseCase,
    getSectionsByGradeUseCase,
  );
});
