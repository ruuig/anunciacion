import '../../domain/entities/parent.dart';
import '../../domain/value_objects/value_objects.dart';
import '../http/http_client.dart';
import '../http/api_config.dart';

class HttpParentRepository {
  final _httpClient = HttpClient();

  Future<Parent?> findById(int id) async {
    try {
      final data = await _httpClient.get('${ApiConfig.padres}/$id');
      return _mapToParent(data);
    } catch (e) {
      print('Error finding parent by id: $e');
      return null;
    }
  }

  Future<List<Parent>> findAll() async {
    try {
      final data = await _httpClient.getList(ApiConfig.padres);
      return data.map((json) => _mapToParent(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error finding all parents: $e');
      return [];
    }
  }

  Future<Parent> save(Parent entity) async {
    try {
      final body = _mapFromParent(entity);
      final data = await _httpClient.post(ApiConfig.padres, body);
      return _mapToParent(data);
    } catch (e) {
      print('Error saving parent: $e');
      rethrow;
    }
  }

  Future<Parent> update(Parent entity) async {
    try {
      final body = _mapFromParent(entity);
      final data = await _httpClient.put('${ApiConfig.padres}/${entity.id}', body);
      return _mapToParent(data);
    } catch (e) {
      print('Error updating parent: $e');
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _httpClient.delete('${ApiConfig.padres}/$id');
    } catch (e) {
      print('Error deleting parent: $e');
      rethrow;
    }
  }

  // Asignar estudiante a padre
  Future<void> assignStudent(int parentId, int studentId, {bool isPrimary = false, bool isEmergency = false}) async {
    try {
      await _httpClient.post('${ApiConfig.padres}/$parentId/students', {
        'studentId': studentId,
        'isPrimary': isPrimary,
        'isEmergency': isEmergency,
      });
    } catch (e) {
      print('Error assigning student to parent: $e');
      rethrow;
    }
  }

  // Remover estudiante de padre
  Future<void> removeStudent(int parentId, int studentId) async {
    try {
      await _httpClient.delete('${ApiConfig.padres}/$parentId/students/$studentId');
    } catch (e) {
      print('Error removing student from parent: $e');
      rethrow;
    }
  }

  // Obtener IDs de estudiantes de un padre
  Future<List<int>> getStudentsByParent(int parentId) async {
    try {
      final data = await _httpClient.getList('${ApiConfig.padres}/$parentId/students');
      return data.cast<int>();
    } catch (e) {
      print('Error getting students by parent: $e');
      return [];
    }
  }

  // Obtener padres de un estudiante
  Future<List<Parent>> getParentsByStudent(int studentId) async {
    try {
      final data = await _httpClient.getList('${ApiConfig.padres}/students/$studentId/parents');
      return data.map((json) => _mapToParent(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error getting parents by student: $e');
      return [];
    }
  }

  Parent _mapToParent(Map<String, dynamic> json) {
    return Parent(
      id: json['id'] ?? 0,
      dpi: json['dpi'] != null ? _parseDPI(json['dpi']) : null,
      name: json['nombre'] ?? '',
      relation: json['relacion'] ?? '',
      phone: _parsePhone(json['telefono']) ?? Phone.fromString('00000000'),
      secondaryPhone: json['telefonoSecundario'] != null ? _parsePhone(json['telefonoSecundario']) : null,
      email: json['email'] != null ? _parseEmail(json['email']) : null,
      address: json['direccion'] != null ? _parseAddress(json['direccion']) : null,
      occupation: json['ocupacion'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _mapFromParent(Parent parent) {
    return {
      'dpi': parent.dpi?.value,
      'nombre': parent.name,
      'relacion': parent.relation,
      'telefono': parent.phone.value,
      'telefonoSecundario': parent.secondaryPhone?.value,
      'email': parent.email?.value,
      'direccion': parent.address?.toString(),
      'ocupacion': parent.occupation,
    };
  }

  // Helper parsers
  DPI? _parseDPI(dynamic value) {
    try {
      return DPI.fromString(value?.toString() ?? '');
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
