import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/value_objects/value_objects.dart';
import '../http/http_client.dart';
import '../http/api_config.dart';

class HttpStudentRepository implements StudentRepository {
  final _httpClient = HttpClient();

  @override
  Future<Student?> findById(int id) async {
    try {
      final data = await _httpClient.get('${ApiConfig.estudiantes}/$id');
      return _mapToStudent(data);
    } catch (e) {
      print('Error finding student by id: $e');
      return null;
    }
  }

  @override
  Future<List<Student>> findAll() async {
    try {
      final data = await _httpClient.getList(ApiConfig.estudiantes);
      return data
          .map((json) => _mapToStudent(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error finding all students: $e');
      return [];
    }
  }

  @override
  Future<Student> save(Student entity) async {
    try {
      final body = _mapFromStudent(entity);
      final data = await _httpClient.post(ApiConfig.estudiantes, body);
      return _mapToStudent(data);
    } catch (e) {
      print('Error saving student: $e');
      rethrow;
    }
  }

  @override
  Future<Student> update(Student entity) async {
    try {
      final body = _mapFromStudent(entity);
      final data =
          await _httpClient.put('${ApiConfig.estudiantes}/${entity.id}', body);
      return _mapToStudent(data);
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _httpClient.delete('${ApiConfig.estudiantes}/$id');
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  @override
  Future<bool> existsById(int id) async {
    final student = await findById(id);
    return student != null;
  }

  @override
  Future<Student?> findByDPI(DPI dpi) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.dpi.value == dpi.value).firstOrNull;
    } catch (e) {
      print('Error finding student by DPI: $e');
      return null;
    }
  }

  @override
  Future<List<Student>> findByGrade(int gradeId) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.gradeId == gradeId).toList();
    } catch (e) {
      print('Error finding students by grade: $e');
      return [];
    }
  }

  @override
  Future<List<Student>> findBySection(int sectionId) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.sectionId == sectionId).toList();
    } catch (e) {
      print('Error finding students by section: $e');
      return [];
    }
  }

  @override
  Future<List<Student>> findByParent(int parentId) async {
    // Por ahora retornar lista vacía - necesita implementación en backend
    return [];
  }

  @override
  Future<List<Student>> findActiveStudents() async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all
          .where((s) => s.status.value == UserStatusValue.activo)
          .toList();
    } catch (e) {
      print('Error finding active students: $e');
      return [];
    }
  }

  @override
  Future<bool> existsByDPI(DPI dpi) async {
    final student = await findByDPI(dpi);
    return student != null;
  }

  Student _mapToStudent(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? 0,
      codigo: json['codigo'],
      dpi: _parseDPI(json['dpi']),
      name: json['name'] ?? '',
      birthDate: _parseDateTime(json['birthDate']) ?? DateTime.now(),
      gender: json['gender'] != null ? _parseGender(json['gender']) : null,
      address: json['address'] != null ? _parseAddress(json['address']) : null,
      phone: json['phone'] != null ? _parsePhone(json['phone']) : null,
      email: json['email'] != null ? _parseEmail(json['email']) : null,
      avatarUrl: json['avatarUrl'],
      gradeId: json['gradeId'] ?? 1,
      sectionId: json['sectionId'] ?? 1,
      enrollmentDate: _parseDateTime(json['enrollmentDate']) ?? DateTime.now(),
      status: UserStatus.fromString(json['status'] ?? 'activo'),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _mapFromStudent(Student student) {
    return {
      'codigo': student.codigo,
      'name': student.name,
      'dpi': student.dpi.value,
      'birthDate': student.birthDate.toIso8601String(),
      'gender': student.gender?.value.toString().split('.').last,
      'address': student.address?.toString(),
      'phone': student.phone?.value,
      'email': student.email?.value,
      'avatarUrl': student.avatarUrl,
      'gradeId': student.gradeId,
      // sectionId ya no se envía - las secciones están en el nombre del grado
      'enrollmentDate': student.enrollmentDate.toIso8601String(),
      'status': student.status.value.toString().split('.').last,
    };
  }

  // Helper parsers
  DPI _parseDPI(dynamic value) {
    try {
      return DPI.fromString(value?.toString() ?? '0000000000000');
    } catch (e) {
      return DPI.fromString('0000000000000');
    }
  }

  Gender? _parseGender(dynamic value) {
    try {
      return Gender.fromString(value.toString());
    } catch (e) {
      return null;
    }
  }

  Address? _parseAddress(dynamic value) {
    try {
      final addressStr = value.toString();
      if (!addressStr.contains(',') || addressStr.split(',').length < 3) {
        return Address(
          street: addressStr,
          city: 'Guatemala',
          state: 'Guatemala',
          zipCode: '01001',
        );
      }
      return Address.fromString(addressStr);
    } catch (e) {
      return null;
    }
  }

  Phone? _parsePhone(dynamic value) {
    try {
      return Phone.fromString(value.toString());
    } catch (e) {
      return null;
    }
  }

  Email? _parseEmail(dynamic value) {
    try {
      return Email.fromString(value.toString());
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
