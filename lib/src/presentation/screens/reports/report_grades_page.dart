import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportGradesPage extends StatefulWidget {
  const ReportGradesPage({super.key});

  @override
  State<ReportGradesPage> createState() => _ReportGradesPageState();
}

class _ReportGradesPageState extends State<ReportGradesPage> {
  final _httpClient = HttpClient();

  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedGrade;
  Map<String, dynamic>? _selectedStudent;
  String _selectedBimester = 'Bimestre 1';

  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  final _bimesters = [
    'Bimestre 1',
    'Bimestre 2',
    'Bimestre 3',
    'Bimestre 4',
  ];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _httpClient.getList('/grades');
      setState(() {
        _grades = List<Map<String, dynamic>>.from(grades);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al cargar grados'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _loadStudentsByGrade(int gradeId) async {
    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList('/students?gradeId=$gradeId');
      setState(() {
        _students = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al cargar estudiantes'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _generatePdfForStudent(Map<String, dynamic> student) async {
    setState(() => _isGeneratingPdf = true);
    try {
      // Obtener docentes asignados al grado
      var teachersResponse = await _httpClient
          .getList('/grades/${_selectedGrade!['id']}/teachers');
      print('👨‍🏫 Docentes del grado: $teachersResponse');

      // Obtener todas las materias/clases de los docentes
      final List<Map<String, dynamic>> subjects = [];
      for (var teacher in teachersResponse) {
        try {
          var teacherSubjects = await _httpClient
              .getList('/api/materias/teacher/${teacher['id']}');
          print('📚 Materias del docente ${teacher['id']}: $teacherSubjects');
          subjects.addAll(teacherSubjects.cast<Map<String, dynamic>>());
        } catch (e) {
          print('❌ Error obteniendo materias del docente: $e');
        }
      }

      print('📚 Total de materias obtenidas: ${subjects.length}');

      // Obtener calificaciones para cada materia
      final List<Map<String, dynamic>> grades = [];
      // Extraer el año del grado (ej: "2024-2025" -> "2025")
      final academicYear =
          _selectedGrade!['academicYear'].toString().contains('-')
              ? _selectedGrade!['academicYear'].toString().split('-')[1]
              : _selectedGrade!['academicYear'].toString();
      // Convertir "Bimestre X" a número (ej: "Bimestre 1" -> "1")
      final periodo = _selectedBimester.replaceAll(RegExp(r'[^\d]'), '');
      for (var subject in subjects) {
        print('📖 Procesando materia: ${subject}');
        try {
          final gradeData = await _httpClient.get(
              '/api/activities/student/${student['id']}/final-grade?materiaId=${subject['id']}&gradoId=${_selectedGrade!['id']}&periodo=$periodo&anoAcademico=$academicYear');
          print('📊 Calificación obtenida: $gradeData');
          print(
              '📊 Calificación obtenida notaFinal: ${gradeData['notaFinal']}, notaManual: ${gradeData['notaManual']}');
          // Convertir a double para comparar
          final notaFinal =
              double.tryParse(gradeData['notaFinal']?.toString() ?? '0') ?? 0;
          final notaManual =
              double.tryParse(gradeData['notaManual']?.toString() ?? '0') ?? 0;
          // Usar notaManual si es mayor que notaFinal, sino usar notaFinal
          final nota =
              (notaManual > 0 && (notaFinal == 0 || notaManual > notaFinal))
                  ? notaManual
                  : notaFinal;
          grades.add({
            'subject_name':
                subject['nombre'] ?? subject['name'] ?? 'Sin nombre',
            'final_grade': nota.toString(),
          });
        } catch (e) {
          print(
              '⚠️ Error obteniendo calificación para materia ${subject['id']}: $e');
          // Si no hay calificación, dejar en blanco
          grades.add({
            'subject_name':
                subject['nombre'] ?? subject['name'] ?? 'Sin nombre',
            'final_grade': '',
          });
        }
      }

      // Cargar logo PNG
      final logoPng = await rootBundle.load('assets/logoanunciacion.png');

      final pdf = await _createStudentPdf(student, grades, logoPng);
      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF generado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error al generar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generatePdfForGrade() async {
    if (_selectedGrade == null) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();

      // Cargar logo PNG
      final logoPng = await rootBundle.load('assets/logoanunciacion.png');

      // Obtener docentes asignados al grado
      var teachersResponse = await _httpClient
          .getList('/grades/${_selectedGrade!['id']}/teachers');

      // Obtener todas las materias/clases de los docentes
      final List<Map<String, dynamic>> subjects = [];
      for (var teacher in teachersResponse) {
        try {
          var teacherSubjects = await _httpClient
              .getList('/api/materias/teacher/${teacher['id']}');
          subjects.addAll(teacherSubjects.cast<Map<String, dynamic>>());
        } catch (e) {
          // Ignorar errores
        }
      }

      // Extraer el año del grado (ej: "2024-2025" -> "2025")
      final academicYear =
          _selectedGrade!['academicYear'].toString().contains('-')
              ? _selectedGrade!['academicYear'].toString().split('-')[1]
              : _selectedGrade!['academicYear'].toString();
      // Convertir "Bimestre X" a número (ej: "Bimestre 1" -> "1")
      final periodo = _selectedBimester.replaceAll(RegExp(r'[^\d]'), '');

      // Generar PDF para cada estudiante del grado
      for (var student in _students) {
        // Obtener calificaciones para cada materia
        final List<Map<String, dynamic>> grades = [];
        for (var subject in subjects) {
          try {
            final gradeData = await _httpClient.get(
                '/api/activities/student/${student['id']}/final-grade?materiaId=${subject['id']}&gradoId=${_selectedGrade!['id']}&periodo=$periodo&anoAcademico=$academicYear');

            // Convertir a double para comparar
            final notaFinal =
                double.tryParse(gradeData['notaFinal']?.toString() ?? '0') ?? 0;
            final notaManual =
                double.tryParse(gradeData['notaManual']?.toString() ?? '0') ??
                    0;
            // Usar notaManual si es mayor que notaFinal, sino usar notaFinal
            final nota =
                (notaManual > 0 && (notaFinal == 0 || notaManual > notaFinal))
                    ? notaManual
                    : notaFinal;

            grades.add({
              'subject_name':
                  subject['nombre'] ?? subject['name'] ?? 'Sin nombre',
              'final_grade': nota.toString(),
            });
          } catch (e) {
            print(
                '⚠️ Error obteniendo calificación para materia ${subject['id']}: $e');
            // Si no hay calificación, dejar en blanco
            grades.add({
              'subject_name':
                  subject['nombre'] ?? subject['name'] ?? 'Sin nombre',
              'final_grade': '',
            });
          }
        }

        pdf.addPage(
          _createGradePage(student, grades, logoPng),
        );
      }

      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF del grado generado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error al generar PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<pw.Document> _createStudentPdf(
    Map<String, dynamic> student,
    List<dynamic> grades,
    ByteData logoPng,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(_createGradePage(student, grades, logoPng));
    return pdf;
  }

  pw.Page _createGradePage(
    Map<String, dynamic> student,
    List<dynamic> grades,
    ByteData logoPng,
  ) {
    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header con logo y nombre del colegio
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Colegio Parroquial Privado',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Nuestra Señora de la Anunciación',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Ficha de Calificaciones',
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                // Logo
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(pw.MemoryImage(logoPng.buffer.asUint8List())),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Información del estudiante
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Estudiante: ${student['name'] ?? ''}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Bimestre: $_selectedBimester',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Grado: ${_selectedGrade?['name'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tabla de calificaciones
            pw.Expanded(
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  // Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Materia',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Nota',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Filas de datos
                  ...grades.map((grade) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(grade['subject_name'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            grade['final_grade'] != null &&
                                    grade['final_grade'] != ''
                                ? int.tryParse(
                                            grade['final_grade'].toString()) !=
                                        null
                                    ? grade['final_grade'].toString()
                                    : double.tryParse(
                                                grade['final_grade'].toString())
                                            ?.toStringAsFixed(0) ??
                                        ''
                                : '',
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Promedio
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey300,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Promedio General:',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _calculateAverage(grades).toStringAsFixed(0),
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double _calculateAverage(List<dynamic> grades) {
    if (grades.isEmpty) return 0.0;

    // Solo contar las notas que no están vacías
    final validGrades = grades.where((grade) {
      final gradeStr = grade['final_grade']?.toString() ?? '';
      return gradeStr.isNotEmpty;
    }).toList();

    if (validGrades.isEmpty) return 0.0;

    final total = validGrades.fold<double>(0, (sum, grade) {
      final gradeValue =
          double.tryParse(grade['final_grade']?.toString() ?? '0') ?? 0;
      return sum + gradeValue;
    });

    return double.parse((total / validGrades.length).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Reportes de Notas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Selector de grado
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleccionar Grado',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      SelectField<Map<String, dynamic>>(
                        label: 'Grado',
                        placeholder: 'Selecciona un grado...',
                        value: _selectedGrade,
                        items: _grades,
                        itemLabel: (g) => g['name'] ?? '',
                        onSelected: (v) {
                          setState(() {
                            _selectedGrade = v;
                            _selectedStudent = null;
                            _students = [];
                          });
                          if (v != null) {
                            _loadStudentsByGrade(v['id']);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SelectField<String>(
                        label: 'Bimestre',
                        placeholder: 'Selecciona...',
                        value: _selectedBimester,
                        items: _bimesters,
                        itemLabel: (b) => b,
                        onSelected: (v) =>
                            setState(() => _selectedBimester = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de estudiante (opcional)
                if (_selectedGrade != null) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estudiante (Opcional)',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        SelectField<Map<String, dynamic>>(
                          label: 'Estudiante',
                          placeholder: 'Selecciona un estudiante...',
                          value: _selectedStudent,
                          items: _students,
                          itemLabel: (s) => s['name'] ?? '',
                          onSelected: (v) =>
                              setState(() => _selectedStudent = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botones de descarga
                if (_selectedGrade != null) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Generar Reportes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),

                        // Botón para estudiante individual
                        if (_selectedStudent != null)
                          SizedBox(
                            width: double.infinity,
                            child: BlackButton(
                              label: _isGeneratingPdf
                                  ? 'Generando PDF...'
                                  : 'Descargar PDF Estudiante',
                              icon: Icons.download_outlined,
                              onPressed: _isGeneratingPdf
                                  ? null
                                  : () =>
                                      _generatePdfForStudent(_selectedStudent!),
                            ),
                          ),

                        if (_selectedStudent != null)
                          const SizedBox(height: 12),

                        // Botón para grado completo
                        SizedBox(
                          width: double.infinity,
                          child: BlackButton(
                            label: _isGeneratingPdf
                                ? 'Generando PDF...'
                                : 'Descargar PDF Grado Completo',
                            icon: Icons.download_for_offline_outlined,
                            onPressed: _isGeneratingPdf || _students.isEmpty
                                ? null
                                : _generatePdfForGrade,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
