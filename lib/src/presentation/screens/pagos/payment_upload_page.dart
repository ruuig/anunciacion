import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:anunciacion/src/infrastructure/http/http_payment_client.dart';

class PaymentUploadPage extends StatefulWidget {
  const PaymentUploadPage({super.key});

  @override
  State<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends State<PaymentUploadPage> {
  final _httpClient = HttpClient();
  late final HttpPaymentClient _paymentClient;
  
  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  File? _selectedFile;
  String? _fileName;
  
  final _amountCtrl = TextEditingController(text: '350');
  final _refCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _month = _getCurrentMonth();
  String _metodoPago = 'Transferencia';

  final _months = _generateMonths();
  final _metodosPago = const ['Efectivo', 'Transferencia', 'Cheque', 'Depósito'];

  bool _isLoading = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _paymentClient = HttpPaymentClient(_httpClient);
    _loadStudents();
  }

  static String _getCurrentMonth() {
    final now = DateTime.now();
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  static List<String> _generateMonths() {
    final now = DateTime.now();
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    final result = <String>[];
    for (int i = 0; i < 12; i++) {
      result.add('${months[i]} ${now.year}');
    }
    return result;
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList('/students');
      setState(() {
        _students = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estudiantes: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
        });

        // Extraer información del PDF si es un PDF
        if (result.files.single.extension == 'pdf') {
          await _extractPdfInfo(file);
        }
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
    try {
      // Cargar el PDF
      final bytes = await pdfFile.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      
      // Extraer texto de todas las páginas
      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      
      print('PDF Text extracted: $text'); // Debug
      
      // Buscar monto total (última aparición de número después de "Total")
      final totalRegex = RegExp(r'Total[^\d]*(\d+\.?\d*)', caseSensitive: false);
      final totalMatch = totalRegex.firstMatch(text);
      if (totalMatch != null) {
        _amountCtrl.text = totalMatch.group(1) ?? '';
      }

      // Buscar número de DTE como referencia
      final dteRegex = RegExp(r'Numero de DTE:\s*(\d+)', caseSensitive: false);
      final dteMatch = dteRegex.firstMatch(text);
      if (dteMatch != null) {
        _refCtrl.text = 'DTE: ${dteMatch.group(1)}';
      }

      // Buscar mes en la descripción (ej: "mes de octubre")
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
            setState(() {
              _month = mesCompleto;
            });
          }
        }
      }

      // Buscar nombre del estudiante en la descripción
      final alumnoRegex = RegExp(r'Alumna?:\s*([^\n.]+)', caseSensitive: false);
      final alumnoMatch = alumnoRegex.firstMatch(text);
      if (alumnoMatch != null) {
        final nombreAlumno = alumnoMatch.group(1)?.trim();
        if (nombreAlumno != null) {
          // Buscar estudiante por nombre
          final estudianteEncontrado = _students.firstWhere(
            (s) => (s['nombre'] as String).toLowerCase().contains(nombreAlumno.toLowerCase()),
            orElse: () => {},
          );
          if (estudianteEncontrado.isNotEmpty) {
            setState(() {
              _selectedStudent = estudianteEncontrado;
            });
          }
        }
      }

      // Buscar método de pago (Transferencia, Efectivo, etc.)
      if (text.toLowerCase().contains('transferencia')) {
        setState(() {
          _metodoPago = 'Transferencia';
        });
        
        // Buscar número de transferencia
        final transRegex = RegExp(r'Transferencia\s*(\d+)', caseSensitive: false);
        final transMatch = transRegex.firstMatch(text);
        if (transMatch != null && _refCtrl.text.isEmpty) {
          _refCtrl.text = 'Trans: ${transMatch.group(1)}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Información extraída del recibo'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error extracting PDF info: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al extraer información: $e')),
        );
      }
    }
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
      // TODO: Aquí deberías subir el archivo al servidor primero
      // y obtener la URL del comprobante
      String? comprobanteUrl;
      if (_selectedFile != null) {
        // comprobanteUrl = await _uploadFile(_selectedFile!);
        comprobanteUrl = 'pendiente_subir'; // Placeholder
      }

      await _paymentClient.createPayment(
        estudianteId: _selectedStudent!['id'],
        monto: amount,
        mes: _month,
        metodoPago: _metodoPago,
        referencia: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        comprobanteUrl: comprobanteUrl,
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago registrado correctamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar pago: $e')),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: const Text(
          'Cargar Comprobante',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: _isLoading && _students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Área de arrastre de archivos
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comprobante de Pago',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: _isDragging 
                                ? Colors.blue.shade50 
                                : const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isDragging 
                                  ? Colors.blue 
                                  : const Color(0xFFE6E7EA),
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _selectedFile != null 
                                    ? Icons.check_circle_outline 
                                    : Icons.cloud_upload_outlined,
                                size: 48,
                                color: _selectedFile != null 
                                    ? Colors.green 
                                    : Colors.black54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFile != null
                                    ? _fileName ?? 'Archivo seleccionado'
                                    : 'Arrastra el comprobante aquí',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedFile != null 
                                      ? Colors.green 
                                      : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFile != null
                                    ? 'Toca para cambiar'
                                    : 'o toca para seleccionar',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'PDF, JPG, PNG (máx. 5MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedFile = null;
                              _fileName = null;
                            });
                          },
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Quitar archivo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estudiante',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SelectField<Map<String, dynamic>>(
                        label: '',
                        placeholder: 'Selecciona un estudiante...',
                        value: _selectedStudent,
                        items: _students,
                        itemLabel: (s) => s['nombre'] ?? '',
                        onSelected: (v) => setState(() => _selectedStudent = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del Pago',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                        hintText: 'No. boleta, banco, etc.',
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
              ],
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: BlackButton(
          label: _isLoading ? 'Guardando...' : 'Guardar Pago',
          icon: Icons.save_outlined,
          onPressed: _isLoading ? null : _savePayment,
        ),
      ),
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
