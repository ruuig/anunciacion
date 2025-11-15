import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportPaymentsPage extends StatefulWidget {
  const ReportPaymentsPage({super.key});

  @override
  State<ReportPaymentsPage> createState() => _ReportPaymentsPageState();
}

class _ReportPaymentsPageState extends State<ReportPaymentsPage> {
  final _httpClient = HttpClient();

  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedGrade;
  bool _isLoading = false;
  bool _isGeneratingPdf = false;

  // Tarifas por nivel educativo
  final Map<int, Map<String, double>> _tarifas = {
    1: {'inscripcion': 170, 'colegiatura': 245}, // Preprimaria
    2: {'inscripcion': 170, 'colegiatura': 270}, // Primaria
    3: {'inscripcion': 250, 'colegiatura': 350}, // Secundaria
  };

  // Meses del año (enero a octubre)
  final List<String> _meses = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre'
  ];

  late String _selectedMonth;

  @override
  void initState() {
    super.initState();
    // Limitar a meses disponibles (enero a octubre = 1-10)
    final currentMonth = DateTime.now().month;
    final monthIndex =
        currentMonth > 10 ? 9 : currentMonth - 1; // Si es nov/dic, usar octubre
    _selectedMonth = _meses[monthIndex];
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
      print('🔍 Intentando cargar estudiantes para grado: $gradeId');

      // Intentar primer endpoint
      List<dynamic> students = [];
      try {
        students = await _httpClient.getList('/students?gradeId=$gradeId');
        print(
            '✅ Endpoint /students?gradeId=$gradeId funcionó: ${students.length} estudiantes');
        if (students.isNotEmpty) {
          print('📋 Primer estudiante: ${students[0]}');
        }
      } catch (e1) {
        print('❌ Endpoint /students?gradeId=$gradeId falló: $e1');

        // Intentar segundo endpoint
        try {
          students =
              await _httpClient.getList('/api/estudiantes?grado_id=$gradeId');
          print(
              '✅ Endpoint /api/estudiantes?grado_id=$gradeId funcionó: ${students.length} estudiantes');
        } catch (e2) {
          print('❌ Endpoint /api/estudiantes?grado_id=$gradeId falló: $e2');

          // Intentar tercer endpoint
          try {
            students =
                await _httpClient.getList('/api/students?gradeId=$gradeId');
            print(
                '✅ Endpoint /api/students?gradeId=$gradeId funcionó: ${students.length} estudiantes');
          } catch (e3) {
            print('❌ Endpoint /api/students?gradeId=$gradeId falló: $e3');
            rethrow;
          }
        }
      }

      setState(() {
        _students = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });

      print('📊 Total estudiantes cargados: ${_students.length}');

      if (students.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No hay estudiantes en este grado'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error al cargar estudiantes: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getStudentsWithKeys() {
    // Ordenar estudiantes alfabéticamente por apellido
    final sortedStudents = List<Map<String, dynamic>>.from(_students);
    sortedStudents.sort((a, b) {
      final nameA = (a['name'] as String? ?? '').toLowerCase();
      final nameB = (b['name'] as String? ?? '').toLowerCase();
      print('🔤 Comparando: "$nameA" vs "$nameB"');
      return nameA.compareTo(nameB);
    });

    print('✅ Estudiantes ordenados: ${sortedStudents.length}');

    // Agregar clave numérica
    return sortedStudents.asMap().entries.map((entry) {
      final student = entry.value;
      final clave = (entry.key + 1).toString();
      print('🏷️ Clave $clave: ${student['name']}');
      return {
        ...student,
        'clave': clave,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _getStudentPaymentStatus() async {
    final List<Map<String, dynamic>> paymentStatus = [];

    // Usar estudiantes ordenados
    final studentsWithKeys = _getStudentsWithKeys();

    for (var student in studentsWithKeys) {
      try {
        final payments = await _httpClient
            .getList('/api/pagos?estudiante_id=${student['id']}');

        // Obtener tarifas según nivel educativo del grado
        int levelId = 1; // Default Preprimaria
        if (_selectedGrade != null) {
          levelId = _selectedGrade!['educationalLevelId'] as int? ??
              _selectedGrade!['educational_level_id'] as int? ??
              1;
        }
        final tarifa = _tarifas[levelId] ?? _tarifas[1]!;

        print(
            '📊 Grado: ${_selectedGrade!['name']}, Level ID: $levelId, Tarifa: $tarifa');

        // Calcular estado de pagos
        double totalPagado = 0;
        bool inscripcionPagada = false;
        int mesesPagados = 0;

        for (var pago in payments) {
          final monto = double.tryParse(pago['monto'].toString()) ?? 0;
          totalPagado += monto;

          if (pago['mes']?.toString().toLowerCase().contains('inscripción') ??
              false) {
            inscripcionPagada = true;
          } else {
            mesesPagados++;
          }
        }

        // Calcular deuda
        double deuda = 0;
        if (!inscripcionPagada) {
          deuda += tarifa['inscripcion']!;
        }
        deuda +=
            (10 - mesesPagados) * tarifa['colegiatura']!; // Asumir 10 meses

        paymentStatus.add({
          'estudiante_id': student['id'],
          'estudiante_nombre': (student['name'] as String?) ?? '',
          'total_pagado': totalPagado,
          'inscripcion_pagada': inscripcionPagada,
          'meses_pagados': mesesPagados,
          'deuda': deuda,
          'solvente': deuda <= 0,
          'tarifa': tarifa,
          'clave': (student['clave'] as String?) ?? '',
        });
      } catch (e) {
        print('Error obteniendo pagos para estudiante ${student['id']}: $e');
      }
    }

    return paymentStatus;
  }

  Future<void> _generateSolvenciaPdf() async {
    if (_selectedGrade == null) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final paymentStatus = await _getStudentPaymentStatus();
      final pdf = pw.Document();
      final logoPng = await rootBundle.load('assets/logoanunciacion.png');

      // Filtrar solo solventes para este mes
      final monthIndex = _meses.indexOf(_selectedMonth) + 1;
      final solventesDelMes = paymentStatus.where((s) {
        final mesesPagados = s['meses_pagados'] as int;
        return mesesPagados >= monthIndex;
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Colegio Parroquial Privado',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Nuestra Señora de la Anunciación',
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Reporte de Solvencias - $_selectedMonth',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 80,
                      height: 80,
                      child: pw.Image(
                          pw.MemoryImage(logoPng.buffer.asUint8List())),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Información del grado
                pw.Text(
                  'Grado: ${_selectedGrade!['name']}',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Mes: $_selectedMonth',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),

                // Título
                pw.Text(
                  'Estudiantes Solventes',
                  style: pw.TextStyle(
                      fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),

                // Lista de solventes
                if (solventesDelMes.isEmpty)
                  pw.Text('No hay estudiantes solventes para este mes')
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: solventesDelMes.map((s) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 4),
                        child: pw.Text(
                          '✓ ${s['estudiante_nombre']}',
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ PDF de solvencias generado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _generateResumenPagos() async {
    if (_selectedGrade == null) return;

    setState(() => _isGeneratingPdf = true);
    try {
      final pdf = pw.Document();
      final logoPng = await rootBundle.load('assets/logoanunciacion.png');

      // Obtener todos los pagos del grado
      final List<Map<String, dynamic>> allPayments = [];
      for (var student in _students) {
        try {
          final payments = await _httpClient
              .getList('/api/pagos?estudiante_id=${student['id']}');
          for (var pago in payments) {
            allPayments.add({
              ...pago,
              'estudiante_nombre': student['name'] ?? '',
              'grado_nombre': _selectedGrade!['name'],
            });
          }
        } catch (e) {
          print('Error obteniendo pagos: $e');
        }
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Colegio Parroquial Privado',
                            style: pw.TextStyle(
                                fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'Nuestra Señora de la Anunciación',
                            style: pw.TextStyle(
                                fontSize: 18, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Resumen de Pagos',
                            style: const pw.TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      width: 60,
                      height: 60,
                      child: pw.Image(
                          pw.MemoryImage(logoPng.buffer.asUint8List())),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 2),
                pw.SizedBox(height: 20),

                // Tabla de pagos
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    // Header
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Estudiante',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Grado',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Mes',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Monto',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Fecha',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Hora',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Filas de datos
                    ...allPayments.map((pago) {
                      final fechaPago = pago['fecha_pago'] != null
                          ? DateTime.parse(pago['fecha_pago'].toString())
                          : DateTime.now();
                      final hora = pago['fecha_registro'] != null
                          ? DateTime.parse(pago['fecha_registro'].toString())
                          : DateTime.now();

                      // Procesar mes: si contiene "Inscripción" mostrar "Inscripción", sino extraer solo el mes
                      String mesDisplay = pago['mes']?.toString() ?? '';
                      if (mesDisplay.toLowerCase().contains('inscripción')) {
                        mesDisplay = 'Inscripción';
                      } else {
                        // Extraer solo el mes (Enero, Febrero, etc.) sin el año
                        // Formato esperado: "Enero 2025" o "Enero"
                        final parts = mesDisplay.split(' ');
                        if (parts.isNotEmpty) {
                          mesDisplay =
                              parts[0]; // Tomar solo la primera parte (el mes)
                        }
                      }

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                pago['estudiante_nombre']?.toString() ?? '',
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                pago['grado_nombre']?.toString() ?? '',
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(mesDisplay,
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Q${pago['monto']}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${fechaPago.day}/${fechaPago.month}/${fechaPago.year}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                '${hora.hour}:${hora.minute.toString().padLeft(2, '0')}',
                                style: const pw.TextStyle(fontSize: 10)),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(onLayout: (format) => pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Resumen de pagos generado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Pagos y Solvencias',
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
                          print(
                              '🎯 Grado seleccionado: ${v?['name']}, ID: ${v?['id']}');
                          setState(() {
                            _selectedGrade = v;
                            _students = [];
                          });
                          if (v != null) {
                            final gradeId = v['id'] is int
                                ? v['id']
                                : int.tryParse(v['id'].toString()) ?? 0;
                            print(
                                '📍 Cargando estudiantes para grado ID: $gradeId');
                            _loadStudentsByGrade(gradeId);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Mostrar botones de descarga si hay grado seleccionado
                if (_selectedGrade != null) ...[
                  // Botones para descargar reportes
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Descargar Reportes',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),

                        // Selector de mes para solvencia
                        const Text(
                          'Mes para Solvencia:',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedMonth,
                          items: _meses.map((mes) {
                            return DropdownMenuItem(
                              value: mes,
                              child: Text(mes),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMonth = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Botón descargar solvencia
                        BlackButton(
                          label: _isGeneratingPdf
                              ? 'Generando PDF...'
                              : 'Descargar Solvencias ($_selectedMonth)',
                          icon: Icons.download_outlined,
                          onPressed:
                              _isGeneratingPdf ? null : _generateSolvenciaPdf,
                        ),
                        const SizedBox(height: 12),

                        // Botón descargar resumen de pagos
                        BlackButton(
                          label: _isGeneratingPdf
                              ? 'Generando PDF...'
                              : 'Descargar Resumen de Pagos',
                          icon: Icons.download_outlined,
                          onPressed:
                              _isGeneratingPdf ? null : _generateResumenPagos,
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
