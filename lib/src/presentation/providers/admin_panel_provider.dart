import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/phone.dart';
import 'package:anunciacion/src/domain/value_objects/dpi.dart';
import 'package:anunciacion/src/domain/value_objects/user_status.dart';
import 'package:anunciacion/src/domain/value_objects/user_status.dart';
import 'package:anunciacion/src/presentation/providers/user_provider.dart';

import 'package:anunciacion/src/presentation/providers/student_provider.dart';

// State for admin panel
class AdminPanelState {
  final List<User> users;
  final List<Role> roles;
  final List<Grade> grades;
  final List<Student> students;
  final bool isLoading;
  final String? error;
  final String activeTab;

  const AdminPanelState({
    this.users = const [],
    this.roles = const [],
    this.grades = const [],
    this.students = const [],
    this.isLoading = false,
    this.error,
    this.activeTab = 'users',
  });

  AdminPanelState copyWith({
    List<User>? users,
    List<Role>? roles,
    List<Grade>? grades,
    List<Student>? students,
    bool? isLoading,
    String? error,
    String? activeTab,
  }) {
    return AdminPanelState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      grades: grades ?? this.grades,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// Notifier for admin panel
class AdminPanelNotifier extends StateNotifier<AdminPanelState> {
  final UserRepository _userRepository;
  // final RoleRepository _roleRepository; // TODO: Implementar
  final GradeRepository _gradeRepository;
  final StudentRepository _studentRepository;

  AdminPanelNotifier({
    required UserRepository userRepository,
    // required RoleRepository roleRepository, // TODO: Implementar
    required GradeRepository gradeRepository,
    required StudentRepository studentRepository,
  })  : _userRepository = userRepository,
        // _roleRepository = roleRepository, // TODO: Implementar
        _gradeRepository = gradeRepository,
        _studentRepository = studentRepository,
        super(const AdminPanelState());

  // Set active tab
  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  // Load initial data
  Future<void> loadInitialData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Load data with explicit type handling
      final usersFuture = _userRepository.findAll();
      // final rolesFuture = _roleRepository.findAll(); // TODO: Implementar
      final gradesFuture = _gradeRepository.findAll();
      final studentsFuture = _studentRepository.findAll();

      // Wait for all futures to complete
      final users = await usersFuture;
      final roles = <Role>[]; // await rolesFuture; // TODO: Implementar
      final grades = await gradesFuture;
      final students = await studentsFuture;

      state = state.copyWith(
        users: users,
        roles: roles,
        grades: grades,
        students: students,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar los datos: $e',
      );
    }
  }

  // User management
  Future<void> createUser({
    required String name,
    required String username,
    required String password,
    required int roleId,
    String? phone,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Check if username already exists
      final existingUser = await _userRepository.findByUsername(username);
      if (existingUser != null) {
        throw Exception('El nombre de usuario ya está en uso');
      }

      // Create new user
      final user = User.create(
        name: name,
        username: username,
        plainPassword: password,
        roleId: roleId,
        phone: phone != null ? Phone(phone) : null,
      );

      final createdUser = await _userRepository.save(user);

      state = state.copyWith(
        users: [...state.users, createdUser],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear el usuario: $e',
      );
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(User user) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedUser = await _userRepository.update(user);

      state = state.copyWith(
        users: state.users
            .map((u) => u.id == updatedUser.id ? updatedUser : u)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar el usuario: $e',
      );
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(int userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _userRepository.delete(userId);

      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar el usuario: $e',
      );
      rethrow;
    }
  }

  // Grade management
  Future<void> createGrade(String name, {String? description}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final grade = Grade(
        id: 0, // Will be set by the repository
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        educationalLevelId: 0,
        academicYear: "2024",
        active: true,
      );

      final createdGrade = await _gradeRepository.save(grade);

      state = state.copyWith(
        grades: [...state.grades, createdGrade],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear el grado: $e',
      );
      rethrow;
    }
  }

  // Role management
  Future<void> createRole(String name, String description, int level) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final role = Role(
        id: 0,
        name: name,
        description: description,
        level: level,
        createdAt: DateTime.now(),
      );

      // final createdRole = await _roleRepository.save(role); // TODO: Implementar
      final createdRole = role; // Temporal

      state = state.copyWith(
        roles: [...state.roles, createdRole],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear el rol: $e',
      );
      rethrow;
    }
  }

  // Student management
  Future<void> createStudent({
    required String name,
    required String codigo,
    required String dpiNumber,
    required DateTime birthDate,
    required int sectionId,
    required int gradeId,
    required DateTime enrollmentDate,
    required String status,
    String? phoneNumber,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final student = Student(
        id: 0,
        codigo: codigo,
        name: name,
        dpi: DPI(dpiNumber),
        birthDate: birthDate,
        sectionId: sectionId,
        gradeId: gradeId,
        enrollmentDate: enrollmentDate,
        status: UserStatus.fromString(status),
        phone: phoneNumber != null ? Phone(phoneNumber) : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdStudent = await _studentRepository.save(student);

      state = state.copyWith(
        students: [...state.students, createdStudent],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear el estudiante: $e',
      );
      rethrow;
    }
  }

  // Update student
  Future<void> updateStudent(Student student) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final updatedStudent = await _studentRepository.update(student);

      state = state.copyWith(
        students: state.students
            .map((s) => s.id == updatedStudent.id ? updatedStudent : s)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar el estudiante: $e',
      );
      rethrow;
    }
  }

  // Delete student
  Future<void> deleteStudent(int studentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _studentRepository.delete(studentId);

      state = state.copyWith(
        students: state.students.where((s) => s.id != studentId).toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al eliminar el estudiante: $e',
      );
      rethrow;
    }
  }

// Provider
  final adminPanelProvider =
      StateNotifierProvider<AdminPanelNotifier, AdminPanelState>((ref) {
    return AdminPanelNotifier(
      userRepository: ref.watch(userRepositoryProvider),
      // roleRepository: ref.watch(roleRepositoryProvider), // TODO: Implementar roleRepositoryProvider
      gradeRepository: ref.watch(gradeRepositoryProvider),
      studentRepository: ref.watch(studentRepositoryProvider),
    );
  });
}
