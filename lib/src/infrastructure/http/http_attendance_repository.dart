import '../../domain/entities/attendance.dart';
import 'http_client.dart';
import 'api_config.dart';

class HttpAttendanceRepository {
  final HttpClient _httpClient = HttpClient();

  /// Registrar entrada de estudiante por código
  Future<Attendance> registerEntry(String studentCode) async {
    try {
      final data = await _httpClient.post('${ApiConfig.attendance}/entry', {
        'codigo': studentCode, // El backend espera 'codigo'
      });
      return _mapToAttendance(data);
    } catch (e) {
      print('Error registering entry: $e');
      rethrow;
    }
  }

  /// Registrar salida de estudiante por código
  Future<Attendance> registerExit(String studentCode) async {
    try {
      final data = await _httpClient.post('${ApiConfig.attendance}/exit', {
        'codigo': studentCode, // El backend espera 'codigo'
      });
      return _mapToAttendance(data);
    } catch (e) {
      print('Error registering exit: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas del día (resumen de asistencia)
  Future<AttendanceSummary> getEntrySummary({int? gradeId}) async {
    try {
      final params = gradeId != null ? '?gradoId=$gradeId' : '';
      final data =
          await _httpClient.get('${ApiConfig.attendance}/stats$params');
      return _mapToSummary(data);
    } catch (e) {
      print('Error getting entry summary: $e');
      rethrow;
    }
  }

  /// Obtener estadísticas del día (resumen de salida)
  Future<AttendanceSummary> getExitSummary({int? gradeId}) async {
    try {
      final params = gradeId != null ? '?gradoId=$gradeId' : '';
      final data =
          await _httpClient.get('${ApiConfig.attendance}/stats$params');
      return _mapToSummary(data, isExit: true);
    } catch (e) {
      print('Error getting exit summary: $e');
      rethrow;
    }
  }

  /// Buscar estudiante por código o nombre
  Future<List<Attendance>> searchStudents(String query, {int? gradeId}) async {
    try {
      final params = gradeId != null ? '&gradeId=$gradeId' : '';
      final data =
          await _httpClient.getList('/attendance/search?query=$query$params');
      return data
          .map((json) => _mapToAttendance(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching students: $e');
      rethrow;
    }
  }

  /// Obtener lista de estudiantes para registro manual (desde estudiantes)
  Future<List<Attendance>> getTodayAttendance(
      {int? gradeId, String? nombre, String? tipo}) async {
    try {
      // Obtener estudiantes del endpoint de estudiantes, no de asistencia
      String params = '';
      if (gradeId != null) params += '?gradoId=$gradeId';
      if (nombre != null)
        params += (params.isEmpty ? '?' : '&') + 'nombre=$nombre';

      try {
        final data =
            await _httpClient.getList('${ApiConfig.estudiantes}$params');
        return data
            .map((json) => _mapToAttendance(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Si falla, intentamos desde asistencia como fallback
        print('Warning: Could not get students: $e');
        try {
          final data =
              await _httpClient.getList('${ApiConfig.attendance}/today$params');
          return data
              .map((json) => _mapToAttendance(json as Map<String, dynamic>))
              .toList();
        } catch (e2) {
          print('Warning: Could not get today attendance: $e2');
          return [];
        }
      }
    } catch (e) {
      print('Error getting today attendance: $e');
      return [];
    }
  }

  /// Registrar entrada manual de estudiante
  Future<Attendance> registerManualEntry(String codeOrId) async {
    try {
      String codigo = codeOrId;

      // Si es un número (ID), obtener el código del estudiante
      if (int.tryParse(codeOrId) != null) {
        try {
          final studentData =
              await _httpClient.get('${ApiConfig.estudiantes}/$codeOrId');
          codigo = studentData['codigo'] ?? codeOrId;
        } catch (e) {
          print('Warning: Could not get student code: $e');
          // Continuar con el ID si falla
        }
      }

      final body = {'codigo': codigo};
      final data =
          await _httpClient.post('${ApiConfig.attendance}/entry', body);
      return _mapToAttendance(data);
    } catch (e) {
      print('Error registering manual entry: $e');
      rethrow;
    }
  }

  /// Registrar salida manual de estudiante
  Future<Attendance> registerManualExit(String codeOrId) async {
    try {
      String codigo = codeOrId;

      // Si es un número (ID), obtener el código del estudiante
      if (int.tryParse(codeOrId) != null) {
        try {
          final studentData =
              await _httpClient.get('${ApiConfig.estudiantes}/$codeOrId');
          codigo = studentData['codigo'] ?? codeOrId;
        } catch (e) {
          print('Warning: Could not get student code: $e');
          // Continuar con el ID si falla
        }
      }

      final body = {'codigo': codigo};
      final data = await _httpClient.post('${ApiConfig.attendance}/exit', body);
      return _mapToAttendance(data);
    } catch (e) {
      print('Error registering manual exit: $e');
      rethrow;
    }
  }

  Attendance _mapToAttendance(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      studentId: json['estudianteId'] ?? json['studentId'] ?? 0,
      studentCode: json['codigo'] ?? json['studentCode'] ?? '',
      studentName: json['nombre'] ?? json['studentName'] ?? '',
      gradeId: json['gradoId'] ?? json['gradeId'] ?? 0,
      gradeName: json['gradoNombre'] ?? json['gradeName'] ?? '',
      sectionId: json['sectionId'] ?? 0,
      sectionName: json['sectionName'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      entryTime: json['horaEntrada'] != null
          ? DateTime.parse(json['horaEntrada'])
          : json['entryTime'] != null
              ? DateTime.parse(json['entryTime'])
              : null,
      exitTime: json['horaSalida'] != null
          ? DateTime.parse(json['horaSalida'])
          : json['exitTime'] != null
              ? DateTime.parse(json['exitTime'])
              : null,
      status: json['estado'] ?? json['status'] ?? 'present',
    );
  }

  AttendanceSummary _mapToSummary(Map<String, dynamic> json,
      {bool isExit = false}) {
    // El backend retorna: total, entered, exited, pending
    if (isExit) {
      // Para salida: mostrar "Ya salieron" y "Quedan"
      return AttendanceSummary(
        total: json['total'] ?? 0,
        present: json['exited'] ?? 0, // Ya salieron
        absent: json['pending'] ?? 0, // Quedan (aún en el colegio)
        late: json['entered'] ?? 0, // No usado en salida
        excused: 0,
      );
    } else {
      // Para entrada: mostrar "En el colegio" y "Faltan por llegar"
      return AttendanceSummary(
        total: json['total'] ?? 0,
        present: json['entered'] ?? 0, // En el colegio
        absent: json['pending'] ?? 0, // Faltan por llegar
        late: json['exited'] ?? 0, // No usado en entrada
        excused: 0,
      );
    }
  }
}

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final int late;
  final int excused;

  AttendanceSummary({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
  });

  int get pending => total - present;
}
