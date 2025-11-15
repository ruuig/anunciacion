import 'package:flutter/material.dart';
import '../../widgets/widgets.dart';
import '../../widgets/SegmentedTabs.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/grade_management_service.dart';
import '../../../infrastructure/repositories/http_grade_repository.dart';
import '../../../infrastructure/repositories/http_section_repository.dart';
import '../../../infrastructure/repositories/http_subject_repository.dart';
import 'create_edit_grade_page.dart';
import '../materias/create_edit_subject_page.dart';

class GradesSubjectsManagementPage extends StatefulWidget {
  const GradesSubjectsManagementPage({super.key});

  @override
  State<GradesSubjectsManagementPage> createState() =>
      _GradesSubjectsManagementPageState();
}

class _GradesSubjectsManagementPageState
    extends State<GradesSubjectsManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configurar Grados y Materias',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        bottom: SegmentedTabs(
          labels: const ['Grados', 'Materias'],
          controller: _tabController,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GradesTab(),
          _SubjectsTab(),
        ],
      ),
    );
  }
}

// ==================== TAB DE GRADOS ====================
class _GradesTab extends StatefulWidget {
  const _GradesTab();

  @override
  State<_GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<_GradesTab> {
  final _gradeService = GradeManagementService(
    HttpGradeRepository(),
    HttpSectionRepository(),
  );

  List<GradeWithSections> gradesWithSections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      // Cargar todos los grados sin filtrar por año académico
      gradesWithSections = await _gradeService.getGradesWithSections();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar grados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addGrade() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditGradePage(),
      ),
    );
    if (result == true) {
      _loadGrades();
    }
  }

  Future<void> _editGrade(Grade grade) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditGradePage(grade: grade),
      ),
    );
    if (result == true) {
      _loadGrades();
    }
  }

  Future<void> _deleteGrade(Grade grade) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar desactivación'),
        content: Text('¿Estás seguro de desactivar el grado "${grade.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Usar soft delete: actualizar el estado active a false
        await _gradeService.deleteGrade(grade.id);
        _loadGrades();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Grado desactivado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✗ Error al desactivar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gradesWithSections.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Grados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                BlackButton(
                  label: 'Nuevo Grado',
                  icon: Icons.add,
                  onPressed: _addGrade,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EmptyState(
            title: 'Sin grados',
            description: 'No hay grados registrados. Crea uno para comenzar.',
            icon: Icon(Icons.school_outlined, size: 48, color: Colors.black45),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Grados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              BlackButton(
                label: 'Nuevo Grado',
                icon: Icons.add,
                onPressed: _addGrade,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...gradesWithSections.map((gradeWithSections) {
          final grade = gradeWithSections.grade;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Año: ${grade.academicYear}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _editGrade(grade),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                        tooltip: 'Editar grado',
                      ),
                      IconButton(
                        onPressed: () => _deleteGrade(grade),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar grado',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ==================== TAB DE MATERIAS ====================
class _SubjectsTab extends StatefulWidget {
  const _SubjectsTab();

  @override
  State<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<_SubjectsTab> {
  final _subjectRepository = HttpSubjectRepository();

  List<Subject> _allSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _subjectRepository.findAll();
      setState(() {
        _allSubjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar materias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSubject() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditSubjectPage(),
      ),
    );
    if (result == true) {
      _loadSubjects();
    }
  }

  Future<void> _editSubject(Subject subject) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditSubjectPage(subject: subject),
      ),
    );
    if (result == true) {
      _loadSubjects();
    }
  }

  Future<void> _deleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar eliminación'),
        content:
            Text('¿Estás seguro de eliminar la materia "${subject.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _subjectRepository.delete(subject.id);
        _loadSubjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materia eliminada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allSubjects.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Materias',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                BlackButton(
                  label: 'Nueva Materia',
                  icon: Icons.add,
                  onPressed: _addSubject,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const EmptyState(
            title: 'Sin materias',
            description: 'No hay materias registradas. Crea una para comenzar.',
            icon: Icon(Icons.book_outlined, size: 48, color: Colors.black45),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Materias',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              BlackButton(
                label: 'Nueva Materia',
                icon: Icons.add,
                onPressed: _addSubject,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._allSubjects.map((subject) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (subject.code != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Código: ${subject.code}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (subject.teachers != null &&
                            subject.teachers!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Docentes: ${subject.teachers!.map((t) => t['nombre'] ?? t['name'] ?? '').join(", ")}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _editSubject(subject),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                        tooltip: 'Editar materia',
                      ),
                      IconButton(
                        onPressed: () => _deleteSubject(subject),
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar materia',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
