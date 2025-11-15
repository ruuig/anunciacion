import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';

class GeneralReportsScreen extends StatefulWidget {
  const GeneralReportsScreen({super.key});

  @override
  State<GeneralReportsScreen> createState() => _GeneralReportsScreenState();
}

class _GeneralReportsScreenState extends State<GeneralReportsScreen> {
  final _httpClient = HttpClient();

  bool _isLoading = false;
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _allBusPayments = [];

  double _totalMensualidad = 0;
  double _totalBus = 0;
  int _totalPaymentsMensualidad = 0;
  int _totalPaymentsBus = 0;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      // Cargar grados
      final grades = await _httpClient.getList('/grades');
      setState(() => _grades = List<Map<String, dynamic>>.from(grades));

      // Cargar todos los pagos
      await _loadAllPayments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllPayments() async {
    try {
      final List<Map<String, dynamic>> allPaymentsMensualidad = [];
      final List<Map<String, dynamic>> allPaymentsBus = [];
      Set<int> uniqueStudents = {};

      double totalMensualidad = 0;
      double totalBus = 0;

      print('📊 Iniciando carga de pagos para reporte general...');

      // Obtener todos los estudiantes y sus pagos
      for (var grade in _grades) {
        try {
          final students =
              await _httpClient.getList('/students?gradeId=${grade['id']}');
          print('📚 Grado ${grade['name']}: ${students.length} estudiantes');

          for (var student in students) {
            uniqueStudents.add(student['id'] as int);

            try {
              // Pagos de mensualidad
              final payments = await _httpClient
                  .getList('/api/pagos?estudiante_id=${student['id']}');
              print(
                  '📋 Pagos mensualidad para ${student['name']}: ${payments.length}');

              for (var pago in payments) {
                // Filtrar solo pagos con concepto_id=1 o sin concepto_id
                final conceptoId = pago['concepto_id'];
                if (conceptoId == null || conceptoId == 1) {
                  final monto = double.tryParse(pago['monto'].toString()) ?? 0;
                  totalMensualidad += monto;
                  allPaymentsMensualidad.add({
                    ...pago,
                    'estudiante_nombre': student['name'] ?? '',
                    'grado_nombre': grade['name'] ?? '',
                  });
                  print('✅ Pago mensualidad: ${pago['mes']} - Q${monto}');
                }
              }
            } catch (e) {
              print('❌ Error obteniendo pagos de mensualidad: $e');
            }

            try {
              // Pagos de bus desde endpoint oficial /api/bus/payments
              List<dynamic> busPayments = [];
              try {
                busPayments = await _httpClient.getList(
                    '/api/bus/payments?estudiante_id=${student['id']}');
                print(
                    '🚌 Endpoint /api/bus/payments?estudiante_id=${student['id']} retornó: ${busPayments.length} pagos');
              } catch (e1) {
                print('❌ /api/bus/payments con estudiante_id falló: $e1');
                try {
                  // Intentar sin filtro
                  busPayments = await _httpClient.getList('/api/bus/payments');
                  print(
                      '🚌 Endpoint /api/bus/payments (sin filtro) retornó: ${busPayments.length} pagos');
                  // Filtrar por estudiante manualmente
                  busPayments = busPayments
                      .where((p) => p['estudiante_id'] == student['id'])
                      .toList();
                  print(
                      '🚌 Después de filtrar por estudiante: ${busPayments.length} pagos');
                } catch (e2) {
                  print('❌ /api/bus/payments sin filtro también falló: $e2');
                }
              }

              for (var pago in busPayments) {
                final monto = double.tryParse(pago['monto'].toString()) ?? 0;
                totalBus += monto;
                allPaymentsBus.add({
                  ...pago,
                  'estudiante_nombre': student['name'] ?? '',
                  'grado_nombre': grade['name'] ?? '',
                });
                print('✅ Pago bus agregado: ${pago['mes']} - Q${monto}');
              }
            } catch (e) {
              print('❌ Error general obteniendo pagos de bus: $e');
            }
          }
        } catch (e) {
          print('❌ Error obteniendo estudiantes: $e');
        }
      }

      print(
          '📊 Totales cargados - Mensualidad: Q${totalMensualidad.toStringAsFixed(2)}, Bus: Q${totalBus.toStringAsFixed(2)}');

      setState(() {
        _allPayments = allPaymentsMensualidad;
        _allBusPayments = allPaymentsBus;
        _totalMensualidad = totalMensualidad;
        _totalBus = totalBus;
        _totalPaymentsMensualidad = allPaymentsMensualidad.length;
        _totalPaymentsBus = allPaymentsBus.length;
        _totalStudents = uniqueStudents.length;
      });
    } catch (e) {
      print('Error cargando pagos: $e');
    }
  }

  Future<void> _generateGeneralReport() async {
    try {
      final pdf = pw.Document();
      final now = DateTime.now();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'REPORTE GENERAL DE PAGOS',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Escuela Anunciación',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generado: ${now.day}/${now.month}/${now.year} a las ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 20),
              ],
            ),

            // Resumen General
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESUMEN GENERAL',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Estudiantes:',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text('$_totalStudents',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Pagos Registrados:',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              '${_totalPaymentsMensualidad + _totalPaymentsBus}',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Dinero Total Ingresado:',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              'Q${(_totalMensualidad + _totalBus).toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Desglose por tipo
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MENSUALIDAD',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Pagos: $_totalPaymentsMensualidad',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(
                            'Total: Q${_totalMensualidad.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(
                            'Promedio: Q${(_totalMensualidad / (_totalPaymentsMensualidad > 0 ? _totalPaymentsMensualidad : 1)).toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BUS',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Pagos: $_totalPaymentsBus',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text('Total: Q${_totalBus.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.Text(
                            'Promedio: Q${(_totalBus / (_totalPaymentsBus > 0 ? _totalPaymentsBus : 1)).toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Tabla de pagos por grado
            pw.Text(
              'DESGLOSE POR GRADO',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Grado',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Pagos Mensualidad',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Mensualidad',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Pagos Bus',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Total Bus',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                // Filas por grado
                ..._grades.map((grade) {
                  final pagosMensualidad = _allPayments
                      .where((p) => p['grado_nombre'] == grade['name'])
                      .length;
                  final totalMensualidad = _allPayments
                      .where((p) => p['grado_nombre'] == grade['name'])
                      .fold<double>(
                          0,
                          (sum, p) =>
                              sum +
                              (double.tryParse(p['monto'].toString()) ?? 0));

                  final pagosBus = _allBusPayments
                      .where((p) => p['grado_nombre'] == grade['name'])
                      .length;
                  final totalBus = _allBusPayments
                      .where((p) => p['grado_nombre'] == grade['name'])
                      .fold<double>(
                          0,
                          (sum, p) =>
                              sum +
                              (double.tryParse(p['monto'].toString()) ?? 0));

                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(grade['name'] ?? '',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(pagosMensualidad.toString(),
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                            'Q${totalMensualidad.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(pagosBus.toString(),
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Q${totalBus.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✗ Error al generar reporte: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Reportes General',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
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
                // Resumen General
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen General',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryBox(
                              'Total Estudiantes',
                              _totalStudents.toString(),
                              Icons.people_outline,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'Total Pagos',
                              (_totalPaymentsMensualidad + _totalPaymentsBus)
                                  .toString(),
                              Icons.receipt_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryBox(
                              'Dinero Total',
                              'Q${(_totalMensualidad + _totalBus).toStringAsFixed(2)}',
                              Icons.attach_money,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Desglose por tipo
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Desglose por Tipo de Pago',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Mensualidad',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pagos: $_totalPaymentsMensualidad',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: Q${_totalMensualidad.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Promedio: Q${(_totalMensualidad / (_totalPaymentsMensualidad > 0 ? _totalPaymentsMensualidad : 1)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bus',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pagos: $_totalPaymentsBus',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: Q${_totalBus.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Promedio: Q${(_totalBus / (_totalPaymentsBus > 0 ? _totalPaymentsBus : 1)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Botón descargar
                BlackButton(
                  label: 'Descargar Reporte PDF',
                  icon: Icons.download_outlined,
                  onPressed: _generateGeneralReport,
                ),
                const SizedBox(height: 16),

                // Botón recargar
                ElevatedButton.icon(
                  onPressed: _loadReportData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recargar Datos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
