import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';

class AdminService {
  final UserRepository _userRepository;
  final RoleRepository _roleRepository;
  final GradeRepository _gradeRepository;
  final StudentRepository _studentRepository;

  AdminService({
    required UserRepository userRepository,
    required RoleRepository roleRepository,
    required GradeRepository gradeRepository,
    required StudentRepository studentRepository,
  })  : _userRepository = userRepository,
        _roleRepository = roleRepository,
        _gradeRepository = gradeRepository,
        _studentRepository = studentRepository;

  // User Management
  Future<List<User>> getUsers() async {
    return await _userRepository.findAll();
  }

  Future<User> createUser({
    required String name,
    required String username,
    required String password,
    required int roleId,
    String? avatarUrl,
    String? phone,
  }) async {
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
      phone: phone != null ? Phone.fromString(phone) : null,
      roleId: roleId,
      avatarUrl: avatarUrl,
    );

    // Save to repository
    return await _userRepository.save(user);
  }

  Future<void> updateUser(User user) async {
    await _userRepository.update(user);
  }

  Future<void> deleteUser(int userId) async {
    await _userRepository.delete(userId);
  }

  // Role Management
  Future<List<Role>> getRoles() async {
    return await _roleRepository.findAll();
  }

  // Grade Management
  Future<List<Grade>> getGrades() async {
    return await _gradeRepository.findAll();
  }

  Future<Grade> createGrade({
    required String name,
    required int educationalLevelId,
    required String academicYear,
    String? ageRange,
  }) async {
    final grade = Grade.create(
      name: name,
      educationalLevelId: educationalLevelId,
      academicYear: academicYear,
      ageRange: ageRange,
    );
    return await _gradeRepository.save(grade);
  }

  // Student Management
  Future<List<Student>> getStudents() async {
    return await _studentRepository.findAll();
  }

  Future<Student> createStudent({
    required String codigo,
    required DPI dpi,
    required String name,
    required DateTime birthDate,
    required int gradeId,
    required int sectionId,
    Gender? gender,
    Address? address,
    Phone? phone,
    Email? email,
    String? avatarUrl,
  }) async {
    final student = Student.create(
      codigo: codigo,
      dpi: dpi,
      name: name,
      birthDate: birthDate,
      gradeId: gradeId,
      sectionId: sectionId,
      gender: gender,
      address: address,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
    );
    return await _studentRepository.save(student);
  }

  // System Settings
  Future<void> updateSystemSettings({
    required String schoolName,
    required String schoolAddress,
    required String schoolPhone,
    required String schoolEmail,
    required String academicYear,
    required bool maintenanceMode,
  }) async {
    // Implementation depends on your system settings storage
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
