import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';

class BusPaymentPage extends StatefulWidget {
  const BusPaymentPage({super.key});

  @override
  State<BusPaymentPage> createState() => _BusPaymentPageState();
}

class _BusPaymentPageState extends State<BusPaymentPage> {
  final _httpClient = HttpClient();
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _allBusStudents = [];
  List<Map<String, dynamic>> _currentStudents = [];
  Map<String, dynamic>? _selectedGrade;
  Map<String, dynamic>? _selectedStudent;

  final _amountCtrl = TextEditingController(text: '200');
  final _refCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _month = _getCurrentMonth();
  String _metodoPago = 'Efectivo';

  final _months = _generateMonths();
  final _metodosPago = const [
    'Efectivo',
    'Transferencia',
    'Cheque',
    'Depósito'
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _httpClient.getList('/grades');
      final busStudents =
          await _httpClient.getList('/api/bus/students?activo=true');

      setState(() {
        _grades = List<Map<String, dynamic>>.from(grades);
        _allBusStudents = List<Map<String, dynamic>>.from(busStudents);
        _currentStudents = [];
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al cargar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _loadStudentsByGrade(int gradeId) async {
    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList('/students?gradeId=$gradeId');

      // Filtrar solo estudiantes que tienen bus activo
      final busStudentIds =
          _allBusStudents.map((s) => s['estudiante_id']).toSet();
      final filteredStudents = (students as List)
          .where((s) => busStudentIds.contains(s['id']))
          .toList();

      // Enriquecer con datos del bus
      final enrichedStudents = filteredStudents.map((student) {
        final busData = _allBusStudents.firstWhere(
          (b) => b['estudiante_id'] == student['id'],
          orElse: () => {},
        );
        return {...student, ...busData};
      }).toList();

      setState(() {
        _currentStudents = List<Map<String, dynamic>>.from(enrichedStudents);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students by grade: $e');
      setState(() => _isLoading = false);
    }
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
      'Noviembre',
      'Diciembre'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  static List<String> _generateMonths() {
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
      'Noviembre',
      'Diciembre'
    ];
    final result = <String>[];
    for (int i = 0; i < 12; i++) {
      result.add('${months[i]} ${now.year}');
    }
    return result;
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
      await _httpClient.post('/api/bus/payments', {
        'estudiante_id': _selectedStudent!['estudiante_id'],
        'monto': amount,
        'mes': _month,
        'metodo_pago': _metodoPago,
        'referencia':
            _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pago registrado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving bus payment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al guardar'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: const Text(
          '🚌 PAGO DE BUS - PRUEBA 🚌',
          style: TextStyle(
              fontWeight: FontWeight.w900, color: Colors.red, fontSize: 18),
        ),
      ),
      body: _isLoading && _allBusStudents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _allBusStudents.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay estudiantes con servicio de bus activo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selección de Estudiante',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          SelectField<Map<String, dynamic>>(
                            label: '',
                            placeholder: 'Selecciona un estudiante...',
                            value: _selectedStudent,
                            items: _allBusStudents,
                            itemLabel: (s) =>
                                'Q${s['monto_mensual']?.toStringAsFixed(2) ?? '0.00'}',
                            onSelected: (v) {
                              setState(() {
                                _selectedStudent = v;
                                // Prellenar el monto con el monto mensual del servicio
                                _amountCtrl.text =
                                    v['monto_mensual']?.toString() ?? '200';
                              });
                            },
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
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
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
      bottomNavigationBar: _allBusStudents.isEmpty
          ? null
          : Container(
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
