import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';

class UnifiedPaymentScreen extends StatefulWidget {
  const UnifiedPaymentScreen({super.key});

  @override
  State<UnifiedPaymentScreen> createState() => _UnifiedPaymentScreenState();
}

class _UnifiedPaymentScreenState extends State<UnifiedPaymentScreen> {
  final _httpClient = HttpClient();

  // Listas de datos
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _busStudents = [];
  Map<String, dynamic>? _selectedGrade;
  Map<String, dynamic>? _selectedStudent;

  // Controladores
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  // Estado
  String _paymentType = 'Mensualidad'; // 'Mensualidad' o 'Bus'
  String _month = _getCurrentMonth();
  String _metodoPago = 'Efectivo';
  File? _selectedFile;
  String? _fileName;
  bool _isLoading = false;
  bool _isExtracting = false;

  final _months = _generateMonths();
  final _metodosPago = const [
    'Efectivo',
    'Transferencia',
    'Cheque',
    'Depósito'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static String _getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
    ];
    // Limitar a octubre si estamos en nov/dic
    final monthIndex = now.month > 10 ? 9 : now.month - 1;
    return months[monthIndex];
  }

  static List<String> _generateMonths() {
    final months = [
      'Inscripción',
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
    ];
    return months;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _httpClient.getList('/grades');
      final busStudents =
          await _httpClient.getList('/api/bus/students?activo=true');

      setState(() {
        _grades = List<Map<String, dynamic>>.from(grades);
        _busStudents = List<Map<String, dynamic>>.from(busStudents);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _loadStudentsByGrade(int gradeId) async {
    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList('/students?gradeId=$gradeId');
      setState(() {
        _allStudents = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estudiantes: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _currentStudents {
    return _paymentType == 'Bus' ? _busStudents : _allStudents;
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
        });

        // Extraer información del PDF automáticamente
        await _extractPdfInfo(file);
      }
    } catch (e) {
      print('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  Future<void> _extractPdfInfo(File pdfFile) async {
    setState(() => _isExtracting = true);

    try {
      final bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      String text = PdfTextExtractor(document).extractText();
      document.dispose();

      print('PDF Text: $text');

      // Extraer monto
      final totalRegex =
          RegExp(r'Total[^\d]*(\d+\.?\d*)', caseSensitive: false);
      final totalMatch = totalRegex.firstMatch(text);
      if (totalMatch != null) {
        _amountCtrl.text = totalMatch.group(1) ?? '';
      }

      // Extraer número de DTE
      final dteRegex = RegExp(r'Numero de DTE:\s*(\d+)', caseSensitive: false);
      final dteMatch = dteRegex.firstMatch(text);
      if (dteMatch != null) {
        _refCtrl.text = 'DTE: ${dteMatch.group(1)}';
      }

      // Extraer mes
      final mesDescRegex = RegExp(r'mes de (\w+)', caseSensitive: false);
      final mesDescMatch = mesDescRegex.firstMatch(text);
      if (mesDescMatch != null) {
        final mesTexto = mesDescMatch.group(1)?.toLowerCase();
        final mesesMap = {
          'enero': 'Enero',
          'febrero': 'Febrero',
          'marzo': 'Marzo',
          'abril': 'Abril',
          'mayo': 'Mayo',
          'junio': 'Junio',
          'julio': 'Julio',
          'agosto': 'Agosto',
          'septiembre': 'Septiembre',
          'octubre': 'Octubre',
          'noviembre': 'Noviembre',
          'diciembre': 'Diciembre',
        };

        if (mesTexto != null && mesesMap.containsKey(mesTexto)) {
          final now = DateTime.now();
          final mesCompleto = '${mesesMap[mesTexto]} ${now.year}';
          if (_months.contains(mesCompleto)) {
            setState(() => _month = mesCompleto);
          }
        }
      }

      // Extraer grado (ej: "1ro. Primaria Sección A")
      final gradoRegex = RegExp(
          r'(\d+)(?:ro|do|to|vo|mo|no)\.?\s+(Primaria|Secundaria|Básico|Diversificado)(?:\s+Sección\s+([A-Z]))?',
          caseSensitive: false);
      final gradoMatch = gradoRegex.firstMatch(text);
      if (gradoMatch != null && _paymentType == 'Mensualidad') {
        final numero = gradoMatch.group(1);
        final nivel = gradoMatch.group(2);
        final seccion = gradoMatch.group(3);

        // Buscar el grado que coincida
        final gradoEncontrado = _grades.firstWhere(
          (g) {
            final nombreGrado = (g['nombre'] as String).toLowerCase();
            final nivelMatch = nombreGrado.contains(nivel?.toLowerCase() ?? '');
            final numeroMatch = nombreGrado.contains(numero ?? '');
            final seccionMatch =
                seccion == null || nombreGrado.contains(seccion.toLowerCase());
            return nivelMatch && numeroMatch && seccionMatch;
          },
          orElse: () => {},
        );

        if (gradoEncontrado.isNotEmpty) {
          setState(() => _selectedGrade = gradoEncontrado);
          // Cargar estudiantes de ese grado
          await _loadStudentsByGrade(gradoEncontrado['id']);
        }
      }

      // Extraer nombre del estudiante
      final alumnoRegex = RegExp(r'Alumna?:\s*([^\n.]+)', caseSensitive: false);
      final alumnoMatch = alumnoRegex.firstMatch(text);
      if (alumnoMatch != null) {
        final nombreAlumno = alumnoMatch.group(1)?.trim();
        if (nombreAlumno != null) {
          final estudianteEncontrado = _currentStudents.firstWhere(
            (s) => (s['nombre'] as String)
                .toLowerCase()
                .contains(nombreAlumno.toLowerCase()),
            orElse: () => {},
          );
          if (estudianteEncontrado.isNotEmpty) {
            setState(() => _selectedStudent = estudianteEncontrado);
          }
        }
      }

      // Detectar método de pago
      if (text.toLowerCase().contains('transferencia')) {
        setState(() => _metodoPago = 'Transferencia');

        final transRegex =
            RegExp(r'Transferencia\s*(\d+)', caseSensitive: false);
        final transMatch = transRegex.firstMatch(text);
        if (transMatch != null && _refCtrl.text.isEmpty) {
          _refCtrl.text = 'Trans: ${transMatch.group(1)}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Información extraída del PDF'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error extracting PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al extraer información: $e')),
        );
      }
    } finally {
      setState(() => _isExtracting = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedGrade = null;
      _selectedStudent = null;
      _selectedFile = null;
      _fileName = null;
      _allStudents = [];
      _amountCtrl.clear();
      _refCtrl.clear();
      _notasCtrl.clear();
      _month = _getCurrentMonth();
      _metodoPago = 'Efectivo';
    });
  }

  Future<void> _savePayment() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estudiante')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final endpoint =
          _paymentType == 'Bus' ? '/api/bus/payments' : '/api/pagos';
      final estudianteId = _paymentType == 'Bus'
          ? _selectedStudent!['estudiante_id']
          : _selectedStudent!['id'];

      await _httpClient.post(endpoint, {
        'estudiante_id': estudianteId,
        'monto': amount,
        'mes': _month,
        'metodo_pago': _metodoPago,
        'referencia':
            _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        'concepto_id':
            _paymentType == 'Bus' ? 2 : 1, // 1 = Mensualidad, 2 = Bus
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✓ Pago de ${_paymentType.toLowerCase()} registrado correctamente'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Limpiar formulario para siguiente registro
        _clearForm();
      }
    } catch (e) {
      print('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error al guardar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading && _allStudents.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Selector de tipo de pago
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tipo de Pago',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentTypeButton(
                            label: 'Mensualidad',
                            icon: Icons.school_outlined,
                            isSelected: _paymentType == 'Mensualidad',
                            onTap: () {
                              setState(() {
                                _paymentType = 'Mensualidad';
                                _selectedStudent = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PaymentTypeButton(
                            label: 'Bus',
                            icon: Icons.directions_bus_rounded,
                            isSelected: _paymentType == 'Bus',
                            onTap: () {
                              setState(() {
                                _paymentType = 'Bus';
                                _selectedStudent = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Área de carga de PDF
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comprobante (Opcional)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _isExtracting ? null : _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F5F7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE6E7EA),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_isExtracting)
                              const CircularProgressIndicator()
                            else
                              Icon(
                                _selectedFile != null
                                    ? Icons.check_circle_outline
                                    : Icons.cloud_upload_outlined,
                                size: 40,
                                color: _selectedFile != null
                                    ? Colors.green
                                    : Colors.black54,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              _isExtracting
                                  ? 'Extrayendo información...'
                                  : _selectedFile != null
                                      ? _fileName ?? 'Archivo cargado'
                                      : 'Toca para cargar PDF',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedFile != null
                                    ? Colors.green
                                    : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (!_isExtracting) ...[
                              const SizedBox(height: 4),
                              Text(
                                _selectedFile != null
                                    ? 'Los campos se llenaron automáticamente'
                                    : 'O llena los campos manualmente',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_selectedFile != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedFile = null;
                            _fileName = null;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Quitar archivo'),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Grado y Estudiante
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selección de Estudiante',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),

                    // Selector de grado
                    if (_paymentType == 'Mensualidad' ||
                        _paymentType == 'Bus') ...[
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
                            _allStudents = [];
                          });
                          if (v != null) {
                            _loadStudentsByGrade(v['id']);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Selector de estudiante
                    SelectField<Map<String, dynamic>>(
                      label: 'Estudiante',
                      placeholder: (_paymentType == 'Mensualidad' ||
                                  _paymentType == 'Bus') &&
                              _selectedGrade == null
                          ? 'Primero selecciona un grado'
                          : 'Selecciona un estudiante...',
                      value: _selectedStudent,
                      items: _currentStudents,
                      itemLabel: (s) {
                        final nombre = s['name'] ??
                            s['nombre'] ??
                            s['estudiante_nombre'] ??
                            s['student_name'] ??
                            'Sin nombre';
                        return nombre;
                      },
                      onSelected: (v) {
                        setState(() {
                          _selectedStudent = v;
                          // Si es bus, prellenar monto
                          if (_paymentType == 'Bus' &&
                              v != null &&
                              v['monto_mensual'] != null) {
                            _amountCtrl.text = v['monto_mensual'].toString();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Detalles del pago
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles del Pago',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    SelectField<String>(
                      label: 'Mes / Periodo',
                      placeholder: 'Selecciona...',
                      value: _month,
                      items: _months,
                      itemLabel: (m) => m,
                      onSelected: (v) => setState(() => _month = v),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Monto (Q)',
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      icon: Icons.attach_money_rounded,
                    ),
                    const SizedBox(height: 16),
                    SelectField<String>(
                      label: 'Método de Pago',
                      placeholder: 'Selecciona...',
                      value: _metodoPago,
                      items: _metodosPago,
                      itemLabel: (m) => m,
                      onSelected: (v) => setState(() => _metodoPago = v),
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Referencia (Opcional)',
                      controller: _refCtrl,
                      hintText: 'No. boleta, DTE, transferencia',
                      icon: Icons.receipt_outlined,
                    ),
                    const SizedBox(height: 16),
                    InputField(
                      label: 'Notas (Opcional)',
                      controller: _notasCtrl,
                      hintText: 'Observaciones adicionales',
                      maxLines: 3,
                      icon: Icons.note_outlined,
                    ),
                  ],
                ),
              ),

              // Botón de guardar
              const SizedBox(height: 24),
              BlackButton(
                label: _isLoading ? 'Guardando...' : 'Guardar Pago',
                icon: Icons.save_outlined,
                onPressed: _isLoading ? null : _savePayment,
              ),
              const SizedBox(height: 24),
            ],
          );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }
}

class _PaymentTypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentTypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE6E7EA),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
