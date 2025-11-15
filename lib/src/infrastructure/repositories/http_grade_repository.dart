import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../http/http_client.dart';
import '../http/api_config.dart';

class HttpGradeRepository implements GradeRepository {
  final _httpClient = HttpClient();

  @override
  Future<Grade?> findById(int id) async {
    try {
      // El backend no tiene endpoint para buscar por ID, buscar en todos
      final all = await findAll();
      return all.where((g) => g.id == id).firstOrNull;
    } catch (e) {
      print('Error finding grade by id: $e');
      return null;
    }
  }

  @override
  Future<List<Grade>> findAll() async {
    try {
      final data = await _httpClient.getList(ApiConfig.grados);
      return data.map((json) => _mapToGrade(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error finding all grades: $e');
      return [];
    }
  }

  @override
  Future<Grade> save(Grade entity) async {
    try {
      final body = _mapFromGrade(entity);
      final data = await _httpClient.post(ApiConfig.grados, body);
      return _mapToGrade(data);
    } catch (e) {
      print('Error saving grade: $e');
      rethrow;
    }
  }

  @override
  Future<Grade> update(Grade entity) async {
    try {
      final body = _mapFromGrade(entity);
      final data = await _httpClient.put('${ApiConfig.grados}/${entity.id}', body);
      return _mapToGrade(data);
    } catch (e) {
      print('Error updating grade: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _httpClient.delete('${ApiConfig.grados}/$id');
    } catch (e) {
      print('Error deleting grade: $e');
      rethrow;
    }
  }

  @override
  Future<bool> existsById(int id) async {
    try {
      // El backend no tiene endpoint para buscar por ID, buscar en todos
      final all = await findAll();
      return all.any((g) => g.id == id);
    } catch (e) {
      print('Error checking if grade exists: $e');
      return false;
    }
  }

  @override
  Future<List<Grade>> findActiveGrades() async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((g) => g.active).toList();
    } catch (e) {
      print('Error finding active grades: $e');
      return [];
    }
  }

  @override
  Future<List<Grade>> findByEducationalLevel(int levelId) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((g) => g.educationalLevelId == levelId).toList();
    } catch (e) {
      print('Error finding grades by educational level: $e');
      return [];
    }
  }

  @override
  Future<List<Grade>> findByAcademicYear(String academicYear) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((g) => g.academicYear == academicYear).toList();
    } catch (e) {
      print('Error finding grades by academic year: $e');
      return [];
    }
  }

  @override
  Future<Grade?> findByNameAndYear(String name, String academicYear) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((g) => g.name == name && g.academicYear == academicYear).firstOrNull;
    } catch (e) {
      print('Error finding grade by name and year: $e');
      return null;
    }
  }

  Grade _mapToGrade(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      educationalLevelId: json['educationalLevelId'] ?? 1,
      ageRange: json['ageRange'],
      academicYear: json['academicYear'] ?? '',
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _mapFromGrade(Grade grade) {
    return {
      'name': grade.name,
      'educationalLevelId': grade.educationalLevelId,
      'ageRange': grade.ageRange,
      'academicYear': grade.academicYear,
      'active': grade.active,
    };
  }

  // Asignar docente a grado
  Future<void> assignTeacher(int gradeId, int teacherId, String anoAcademico) async {
    try {
      await _httpClient.post(
        '${ApiConfig.grados}/$gradeId/teachers',
        {
          'teacherId': teacherId,
          'anoAcademico': anoAcademico,
        },
      );
    } catch (e) {
      print('Error assigning teacher to grade: $e');
      rethrow;
    }
  }

  // Remover docente de grado
  Future<void> removeTeacher(int gradeId, int teacherId, String anoAcademico) async {
    try {
      await _httpClient.delete(
        '${ApiConfig.grados}/$gradeId/teachers/$teacherId?anoAcademico=$anoAcademico',
      );
    } catch (e) {
      print('Error removing teacher from grade: $e');
      rethrow;
    }
  }

  // Obtener docentes de un grado
  Future<List<Map<String, dynamic>>> getGradeTeachers(int gradeId, String anoAcademico) async {
    try {
      final data = await _httpClient.getList(
        '${ApiConfig.grados}/$gradeId/teachers?anoAcademico=$anoAcademico',
      );
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting grade teachers: $e');
      return [];
    }
  }
}
