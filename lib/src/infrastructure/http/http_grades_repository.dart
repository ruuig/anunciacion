import 'http_client.dart';

class HttpGradesRepository {
  final HttpClient _httpClient = HttpClient();

  // Guardar nota manual de un estudiante
  Future<void> saveManualGrade({
    required int estudianteId,
    required int materiaId,
    required int gradoId,
    required int docenteId,
    required String periodo,
    required int anoAcademico,
    required double notaManual,
    String? observaciones,
  }) async {
    try {
      await _httpClient.post('/api/activities/final-grades', {
        'estudianteId': estudianteId,
        'materiaId': materiaId,
        'gradoId': gradoId,
        'docenteId': docenteId,
        'periodo': periodo,
        'anoAcademico': anoAcademico,
        'notaManual': notaManual,
        'observaciones': observaciones,
      });
    } catch (e) {
      print('Error saving manual grade: $e');
      rethrow;
    }
  }

  // Guardar múltiples notas manuales
  Future<void> saveManualGrades({
    required List<Map<String, dynamic>> grades,
    required int materiaId,
    required int gradoId,
    required int docenteId,
    required String periodo,
    required int anoAcademico,
  }) async {
    try {
      for (final grade in grades) {
        if (grade['grade'] != null) {
          await saveManualGrade(
            estudianteId: grade['id'],
            materiaId: materiaId,
            gradoId: gradoId,
            docenteId: docenteId,
            periodo: periodo,
            anoAcademico: anoAcademico,
            notaManual: grade['grade'].toDouble(),
          );
        }
      }
    } catch (e) {
      print('Error saving manual grades: $e');
      rethrow;
    }
  }

  // Obtener calificaciones de un grado/materia/período
  Future<List<Map<String, dynamic>>> getGrades({
    required int materiaId,
    required int gradoId,
    required String periodo,
    required int anoAcademico,
  }) async {
    try {
      final data = await _httpClient.getList(
        '/api/activities/final-grades?materiaId=$materiaId&gradoId=$gradoId&periodo=$periodo&anoAcademico=$anoAcademico',
      );
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting grades: $e');
      return [];
    }
  }

  // Obtener calificación de un estudiante específico
  Future<Map<String, dynamic>?> getStudentGrade({
    required int estudianteId,
    required int materiaId,
    required int gradoId,
    required String periodo,
    required int anoAcademico,
  }) async {
    try {
      final data = await _httpClient.get(
        '/api/activities/student/$estudianteId/final-grade?materiaId=$materiaId&gradoId=$gradoId&periodo=$periodo&anoAcademico=$anoAcademico',
      );
      return data;
    } catch (e) {
      print('Error getting student grade: $e');
      return null;
    }
  }

  // Crear actividad
  Future<Map<String, dynamic>> createActivity({
    required String nombre,
    String? descripcion,
    required int materiaId,
    required int gradoId,
    required int docenteId,
    required String periodo,
    required int anoAcademico,
    required double ponderacion,
    DateTime? fechaEntrega,
    String? tipo,
  }) async {
    try {
      final data = await _httpClient.post('/api/activities', {
        'nombre': nombre,
        'descripcion': descripcion,
        'materiaId': materiaId,
        'gradoId': gradoId,
        'docenteId': docenteId,
        'periodo': periodo,
        'anoAcademico': anoAcademico,
        'ponderacion': ponderacion,
        'fechaEntrega': fechaEntrega?.toIso8601String(),
        'tipo': tipo,
      });
      return data;
    } catch (e) {
      print('Error creating activity: $e');
      rethrow;
    }
  }

  // Obtener actividades
  Future<List<Map<String, dynamic>>> getActivities({
    required int materiaId,
    required int gradoId,
    required String periodo,
    required int anoAcademico,
    int? docenteId,
  }) async {
    try {
      String url = '/api/activities?materiaId=$materiaId&gradoId=$gradoId&periodo=$periodo&anoAcademico=$anoAcademico';
      if (docenteId != null) {
        url += '&docenteId=$docenteId';
      }
      final data = await _httpClient.getList(url);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting activities: $e');
      return [];
    }
  }

  // Calificar actividad (asignar nota a estudiante en una actividad)
  Future<void> gradeActivity({
    required int actividadId,
    required int estudianteId,
    required double nota,
    String? observaciones,
  }) async {
    try {
      await _httpClient.post('/api/activities/grades', {
        'actividadId': actividadId,
        'estudianteId': estudianteId,
        'nota': nota,
        'observaciones': observaciones,
      });
    } catch (e) {
      print('Error grading activity: $e');
      rethrow;
    }
  }

  // Obtener calificaciones de una actividad
  Future<List<Map<String, dynamic>>> getActivityGrades(int actividadId) async {
    try {
      final data = await _httpClient.getList('/api/activities/$actividadId/grades');
      return data.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error getting activity grades: $e');
      return [];
    }
  }
}
