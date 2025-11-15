import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../http/http_client.dart';
import '../http/api_config.dart';

class HttpSectionRepository implements SectionRepository {
  final _httpClient = HttpClient();

  @override
  Future<Section?> findById(int id) async {
    try {
      // El backend no tiene endpoint para buscar por ID, buscar en todos
      final all = await findAll();
      return all.where((s) => s.id == id).firstOrNull;
    } catch (e) {
      print('Error finding section by id: $e');
      return null;
    }
  }

  @override
  Future<List<Section>> findAll() async {
    try {
      final data = await _httpClient.getList(ApiConfig.secciones);
      return data.map((json) => _mapToSection(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error finding all sections: $e');
      return [];
    }
  }

  @override
  Future<Section> save(Section entity) async {
    try {
      final body = _mapFromSection(entity);
      final data = await _httpClient.post(ApiConfig.secciones, body);
      return _mapToSection(data);
    } catch (e) {
      print('Error saving section: $e');
      rethrow;
    }
  }

  @override
  Future<Section> update(Section entity) async {
    try {
      final body = _mapFromSection(entity);
      final data = await _httpClient.put('${ApiConfig.secciones}/${entity.id}', body);
      return _mapToSection(data);
    } catch (e) {
      print('Error updating section: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _httpClient.delete('${ApiConfig.secciones}/$id');
    } catch (e) {
      print('Error deleting section: $e');
      rethrow;
    }
  }

  @override
  Future<bool> existsById(int id) async {
    try {
      // El backend no tiene endpoint para buscar por ID, buscar en todos
      final all = await findAll();
      return all.any((s) => s.id == id);
    } catch (e) {
      print('Error checking if section exists: $e');
      return false;
    }
  }

  @override
  Future<List<Section>> findByGrade(int gradeId) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.gradeId == gradeId).toList();
    } catch (e) {
      print('Error finding sections by grade: $e');
      return [];
    }
  }

  @override
  Future<List<Section>> findActiveSections() async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.active).toList();
    } catch (e) {
      print('Error finding active sections: $e');
      return [];
    }
  }

  @override
  Future<Section?> findByGradeAndName(int gradeId, String name) async {
    try {
      // El backend no soporta filtros, obtener todos y filtrar localmente
      final all = await findAll();
      return all.where((s) => s.gradeId == gradeId && s.name == name).firstOrNull;
    } catch (e) {
      print('Error finding section by grade and name: $e');
      return null;
    }
  }

  Section _mapToSection(Map<String, dynamic> json) {
    return Section(
      id: json['id'] ?? 0,
      gradeId: json['gradeId'] ?? 0,
      name: json['name'] ?? '',
      capacity: json['capacity'],
      studentCount: json['studentCount'] ?? 0,
      active: json['active'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> _mapFromSection(Section section) {
    return {
      'gradeId': section.gradeId,
      'name': section.name,
      'capacity': section.capacity,
      'active': section.active,
    };
  }
}
