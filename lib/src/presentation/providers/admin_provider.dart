import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/phone.dart';

// Provider for admin state
class AdminState {
  final List<User> users;
  final List<Role> roles;
  final List<Grade> grades;
  final List<Student> students;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.users = const [],
    this.roles = const [],
    this.grades = const [],
    this.students = const [],
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<User>? users,
    List<Role>? roles,
    List<Grade>? grades,
    List<Student>? students,
    bool? isLoading,
    String? error,
  }) {
    return AdminState(
      users: users ?? this.users,
      roles: roles ?? this.roles,
      grades: grades ?? this.grades,
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Admin Notifier
class AdminNotifier extends StateNotifier<AdminState> {
  final UserRepository _userRepository;
  // final RoleRepository _roleRepository; // TODO: Implementar
  final GradeRepository _gradeRepository;
  final StudentRepository _studentRepository;

  AdminNotifier({
    required UserRepository userRepository,
    // required RoleRepository roleRepository, // TODO: Implementar
    required GradeRepository gradeRepository,
    required StudentRepository studentRepository,
  })  : _userRepository = userRepository,
        // _roleRepository = roleRepository, // TODO: Implementar
        _gradeRepository = gradeRepository,
        _studentRepository = studentRepository,
        super(const AdminState());

  // Load all data
  Future<void> loadData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final users = await _userRepository.findActiveUsers();
      final roles =
          <Role>[]; // await _roleRepository.findAll(); // TODO: Implementar
      final grades = await _gradeRepository.findAll();
      final students = await _studentRepository.findAll();

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
    String? email,
    String? phone,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

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

  // Add other CRUD operations for users, grades, students, etc.
  // ...
}

// Provider
final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier(
    userRepository: ref.watch(userRepositoryProvider),
    // roleRepository: ref.watch(roleRepositoryProvider), // TODO: Implementar
    gradeRepository: ref.watch(gradeRepositoryProvider),
    studentRepository: ref.watch(studentRepositoryProvider),
  );
});
