// Servicio de gestión de grados y secciones
import '../entities/entities.dart';
import '../repositories/repositories.dart';

class GradeManagementService {
  final GradeRepository _gradeRepository;
  final SectionRepository _sectionRepository;

  GradeManagementService(this._gradeRepository, this._sectionRepository);

  // ==================== GRADOS ====================

  /// Obtener todos los grados
  Future<List<Grade>> getGrades() async {
    return await _gradeRepository.findAll();
  }

  /// Obtener grados activos
  Future<List<Grade>> getActiveGrades() async {
    return await _gradeRepository.findActiveGrades();
  }

  /// Obtener grados por año académico
  Future<List<Grade>> getGradesByYear(String academicYear) async {
    return await _gradeRepository.findByAcademicYear(academicYear);
  }

  /// Obtener grado por ID
  Future<Grade?> getGradeById(int id) async {
    return await _gradeRepository.findById(id);
  }

  /// Crear un nuevo grado
  Future<Grade> createGrade({
    required String name,
    required int educationalLevelId,
    String? ageRange,
    required String academicYear,
  }) async {
    // Validar que no exista un grado con el mismo nombre y año
    final existing = await _gradeRepository.findByNameAndYear(name, academicYear);
    if (existing != null) {
      throw Exception('Ya existe un grado con el nombre "$name" para el año $academicYear');
    }

    final grade = Grade.create(
      name: name,
      educationalLevelId: educationalLevelId,
      ageRange: ageRange,
      academicYear: academicYear,
    );

    return await _gradeRepository.save(grade);
  }

  /// Actualizar un grado
  Future<Grade> updateGrade(Grade grade) async {
    final exists = await _gradeRepository.existsById(grade.id);
    if (!exists) {
      throw Exception('El grado con ID ${grade.id} no existe');
    }

    return await _gradeRepository.update(grade);
  }

  /// Eliminar un grado
  Future<void> deleteGrade(int id) async {
    // Verificar si el grado tiene secciones
    final sections = await _sectionRepository.findByGrade(id);
    if (sections.isNotEmpty) {
      throw Exception('No se puede eliminar el grado porque tiene ${sections.length} sección(es) asociada(s). Elimina primero todas las secciones.');
    }

    await _gradeRepository.delete(id);
  }

  // ==================== SECCIONES ====================

  /// Obtener todas las secciones
  Future<List<Section>> getSections() async {
    return await _sectionRepository.findAll();
  }

  /// Obtener secciones por grado
  Future<List<Section>> getSectionsByGrade(int gradeId) async {
    return await _sectionRepository.findByGrade(gradeId);
  }

  /// Obtener sección por ID
  Future<Section?> getSectionById(int id) async {
    return await _sectionRepository.findById(id);
  }

  /// Crear una nueva sección
  Future<Section> createSection({
    required int gradeId,
    required String name,
    int? capacity,
  }) async {
    // Validar que el grado exista
    final grade = await _gradeRepository.findById(gradeId);
    if (grade == null) {
      throw Exception('El grado con ID $gradeId no existe');
    }

    // Validar que no exista una sección con el mismo nombre en el grado
    final existing = await _sectionRepository.findByGradeAndName(gradeId, name);
    if (existing != null) {
      throw Exception('Ya existe una sección "$name" en el grado "${grade.name}"');
    }

    final section = Section.create(
      gradeId: gradeId,
      name: name,
      capacity: capacity,
    );

    return await _sectionRepository.save(section);
  }

  /// Actualizar una sección
  Future<Section> updateSection(Section section) async {
    final exists = await _sectionRepository.existsById(section.id);
    if (!exists) {
      throw Exception('La sección con ID ${section.id} no existe');
    }

    return await _sectionRepository.update(section);
  }

  /// Eliminar una sección
  Future<void> deleteSection(int id) async {
    await _sectionRepository.delete(id);
  }

  // ==================== MÉTODOS COMBINADOS ====================

  /// Obtener grados con sus secciones (optimizado)
  Future<List<GradeWithSections>> getGradesWithSections({String? academicYear}) async {
    // Obtener todos los grados
    List<Grade> grades;
    
    if (academicYear != null) {
      grades = await _gradeRepository.findByAcademicYear(academicYear);
    } else {
      grades = await _gradeRepository.findActiveGrades();
    }

    if (grades.isEmpty) {
      return [];
    }

    // Obtener todas las secciones activas de una sola vez
    final allSections = await _sectionRepository.findActiveSections();
    
    // Agrupar secciones por grado_id
    final sectionsByGrade = <int, List<Section>>{};
    for (final section in allSections) {
      sectionsByGrade.putIfAbsent(section.gradeId, () => []).add(section);
    }

    // Construir resultado
    final result = <GradeWithSections>[];
    for (final grade in grades) {
      final sections = sectionsByGrade[grade.id] ?? [];
      result.add(GradeWithSections(grade: grade, sections: sections));
    }

    return result;
  }
}

/// Clase auxiliar para representar un grado con sus secciones
class GradeWithSections {
  final Grade grade;
  final List<Section> sections;

  GradeWithSections({
    required this.grade,
    required this.sections,
  });
}
