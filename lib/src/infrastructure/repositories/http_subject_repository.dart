import '../../domain/entities/subject.dart';
import '../http/http_client.dart';
import '../http/api_config.dart';

class HttpSubjectRepository {
  final _httpClient = HttpClient();

  Future<Subject?> findById(int id) async {
    try {
      final data = await _httpClient.get('${ApiConfig.materias}/$id');
      return _mapToSubject(data);
    } catch (e) {
      print('Error finding subject by id: $e');
      return null;
    }
  }

  Future<List<Subject>> findAll() async {
    try {
      final data = await _httpClient.getList(ApiConfig.materias);
      return data
          .map((json) => _mapToSubject(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error finding all subjects: $e');
      return [];
    }
  }

  Future<Subject> save(Subject entity) async {
    try {
      final body = _mapFromSubject(entity);
      final data = await _httpClient.post(ApiConfig.materias, body);
      return _mapToSubject(data);
    } catch (e) {
      print('Error saving subject: $e');
      rethrow;
    }
  }

  Future<Subject> update(Subject entity) async {
    try {
      final body = _mapFromSubject(entity);
      final data =
          await _httpClient.put('${ApiConfig.materias}/${entity.id}', body);
      return _mapToSubject(data);
    } catch (e) {
      print('Error updating subject: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _httpClient.delete('${ApiConfig.materias}/$id');
    } catch (e) {
      print('Error deleting subject: $e');
      rethrow;
    }
  }

  // Asignar docente a materia
  Future<void> assignTeacher(int subjectId, int teacherId) async {
    try {
      await _httpClient.post('${ApiConfig.materias}/$subjectId/teachers', {
        'teacherId': teacherId,
      });
    } catch (e) {
      print('Error assigning teacher to subject: $e');
      rethrow;
    }
  }

  // Remover docente de materia
  Future<void> removeTeacher(int subjectId, int teacherId) async {
    try {
      await _httpClient
          .delete('${ApiConfig.materias}/$subjectId/teachers/$teacherId');
    } catch (e) {
      print('Error removing teacher from subject: $e');
      rethrow;
    }
  }

  // Obtener docentes de una materia
  Future<List<Map<String, dynamic>>> getTeachersBySubject(int subjectId) async {
    try {
      final data = await _httpClient
          .getList('${ApiConfig.materias}/$subjectId/teachers');
      return data
          .map((json) => {
                'id': json['id'] ?? 0,
                'nombre': json['nombre'] ?? '',
              })
          .toList();
    } catch (e) {
      print('Error getting teachers by subject: $e');
      return [];
    }
  }

  // Asignar materia y docente a un grado
  Future<void> assignToGrade({
    required int gradeId,
    required int subjectId,
    required int teacherId,
    required String anoAcademico,
  }) async {
    try {
      await _httpClient.post('${ApiConfig.materias}/assign-to-grade', {
        'gradeId': gradeId,
        'subjectId': subjectId,
        'teacherId': teacherId,
        'anoAcademico': anoAcademico,
      });
    } catch (e) {
      print('Error assigning subject to grade: $e');
      rethrow;
    }
  }

  // Obtener materias de un grado
  Future<List<Map<String, dynamic>>> getGradeSubjects(
      int gradeId, String anoAcademico) async {
    try {
      final data = await _httpClient.getList(
          '${ApiConfig.materias}/grade/$gradeId?anoAcademico=$anoAcademico');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting grade subjects: $e');
      return [];
    }
  }

  // Remover materia de un grado
  Future<void> removeFromGrade(
      int gradeId, int subjectId, String anoAcademico) async {
    try {
      await _httpClient.delete(
          '${ApiConfig.materias}/grade/$gradeId/subject/$subjectId?anoAcademico=$anoAcademico');
    } catch (e) {
      print('Error removing subject from grade: $e');
      rethrow;
    }
  }

  Subject _mapToSubject(Map<String, dynamic> json) {
    // Parse teachers if present
    List<Map<String, dynamic>>? teachers;
    if (json['teachers'] != null) {
      teachers = (json['teachers'] as List)
          .map((t) => {
                'id': t['id'] ?? 0,
                'nombre': t['nombre'] ?? '',
              })
          .toList();
    }

    return Subject(
      id: json['id'] ?? 0,
      name: json['nombre'] ?? '',
      code: json['codigo'],
      description: json['descripcion'],
      active: json['activo'] ?? true,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      teachers: teachers,
    );
  }

  Map<String, dynamic> _mapFromSubject(Subject subject) {
    return {
      'nombre': subject.name,
      'codigo': subject.code,
      'descripcion': subject.description,
      'activo': subject.active,
    };
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
