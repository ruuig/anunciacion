import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:anunciacion/src/infrastructure/http/http_payment_client.dart';

class PaymentManualPage extends StatefulWidget {
  final int gradeId;
  final String gradeName;
  final List<Map<String, dynamic>> students;
  final VoidCallback onSaved;

  const PaymentManualPage({
    super.key,
    required this.gradeId,
    required this.gradeName,
    required this.students,
    required this.onSaved,
  });

  @override
  State<PaymentManualPage> createState() => _PaymentManualPageState();
}

class _PaymentManualPageState extends State<PaymentManualPage> {
  final _httpClient = HttpClient();
  late final HttpPaymentClient _paymentClient;
  
  Map<String, dynamic>? _selectedStudent;
  final _amountCtrl = TextEditingController(text: '350');
  final _refCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  String _month = _getCurrentMonth();
  String _metodoPago = 'Efectivo';

  final _months = _generateMonths();
  final _metodosPago = const ['Efectivo', 'Transferencia', 'Cheque', 'Depósito'];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentClient = HttpPaymentClient(_httpClient);
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
      await _paymentClient.createPayment(
        estudianteId: _selectedStudent!['id'],
        monto: amount,
        mes: _month,
        metodoPago: _metodoPago,
        referencia: _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      );

      if (mounted) {
        widget.onSaved();
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
          'Registrar Pago',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school_outlined, color: Colors.black),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grado',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Text(
                            widget.gradeName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  'Estudiante',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SelectField<Map<String, dynamic>>(
                  label: '',
                  placeholder: 'Selecciona un estudiante...',
                  value: _selectedStudent,
                  items: widget.students,
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
                  onSelected: (v) => setState(() => _month = v!),
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
                  onSelected: (v) => setState(() => _metodoPago = v!),
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
