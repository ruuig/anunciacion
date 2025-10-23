// Caso de uso para obtener secciones por grado
import 'package:anunciacion/src/domain/entities/entities.dart';
import 'package:anunciacion/src/domain/repositories/repositories.dart';
import 'base_use_case.dart';

class GetSectionsByGradeUseCase extends UseCase<int, Result<List<Section>>> {
  final SectionRepository sectionRepository;

  GetSectionsByGradeUseCase(this.sectionRepository);

  @override
  Future<Result<List<Section>>> execute(int gradeId) async {
    try {
      final sections = await sectionRepository.findByGrade(gradeId);

      // Filtrar solo secciones activas
      final activeSections =
          sections.where((section) => section.active).toList();

      return Result.success(activeSections);
    } catch (e) {
      return Result.failure('Error al obtener secciones: $e');
    }
  }
}
