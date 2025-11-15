import 'package:flutter/material.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';

class EditPaymentDialog extends StatefulWidget {
  final Map<String, dynamic> payment;
  final VoidCallback onUpdated;

  const EditPaymentDialog({
    super.key,
    required this.payment,
    required this.onUpdated,
  });

  @override
  State<EditPaymentDialog> createState() => _EditPaymentDialogState();
}

class _EditPaymentDialogState extends State<EditPaymentDialog> {
  final _httpClient = HttpClient();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  
  String _selectedMonth = '';
  String _selectedMetodo = 'Efectivo';
  bool _isLoading = false;

  final _months = [
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

  final _metodosPago = const [
    'Efectivo',
    'Transferencia',
    'Cheque',
    'Depósito'
  ];

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.payment['monto']?.toString() ?? '';
    _refCtrl.text = widget.payment['referencia']?.toString() ?? '';
    _notesCtrl.text = widget.payment['notas']?.toString() ?? '';
    
    // Extraer solo el mes del campo 'mes'
    String mes = widget.payment['mes']?.toString() ?? 'Enero';
    if (mes.toLowerCase().contains('inscripción')) {
      _selectedMonth = 'Inscripción';
    } else {
      // Extraer solo la primera palabra (el mes)
      final parts = mes.split(' ');
      _selectedMonth = parts.isNotEmpty ? parts[0] : 'Enero';
    }
    
    _selectedMetodo = widget.payment['metodo_pago']?.toString() ?? 'Efectivo';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePayment() async {
    if (_amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✗ Ingresa un monto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final payload = {
        'monto': double.parse(_amountCtrl.text),
        'mes': _selectedMonth,
        'metodo_pago': _selectedMetodo,
        'referencia': _refCtrl.text.isEmpty ? null : _refCtrl.text,
        'notas': _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      };

      await _httpClient.put('/api/pagos/${widget.payment['id']}', payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pago actualizado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        widget.onUpdated();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✗ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF7F8FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Editar Pago',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.payment['estudiante_nombre'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Body
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Información del estudiante
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información del Estudiante',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.payment['estudiante_nombre'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.school_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.payment['grado_nombre'] ?? '',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        
                        InputField(
                          label: 'Monto (Q)',
                          controller: _amountCtrl,
                          hintText: '0.00',
                          keyboardType: TextInputType.number,
                          icon: Icons.attach_money,
                        ),
                        const SizedBox(height: 16),
                        
                        SelectField<String>(
                          label: 'Mes/Período',
                          placeholder: 'Selecciona el mes...',
                          value: _selectedMonth,
                          items: _months,
                          itemLabel: (m) => m,
                          onSelected: (v) {
                            setState(() => _selectedMonth = v ?? 'Enero');
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        SelectField<String>(
                          label: 'Método de Pago',
                          placeholder: 'Selecciona método...',
                          value: _selectedMetodo,
                          items: _metodosPago,
                          itemLabel: (m) => m,
                          onSelected: (v) {
                            setState(() => _selectedMetodo = v ?? 'Efectivo');
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        InputField(
                          label: 'Referencia/No. Recibo',
                          controller: _refCtrl,
                          hintText: 'Número de referencia',
                          icon: Icons.receipt_outlined,
                        ),
                        const SizedBox(height: 16),
                        
                        InputField(
                          label: 'Notas (Opcional)',
                          controller: _notesCtrl,
                          hintText: 'Observaciones adicionales',
                          maxLines: 3,
                          icon: Icons.note_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Botón guardar
                  BlackButton(
                    label: _isLoading ? 'Guardando...' : 'Guardar Cambios',
                    icon: Icons.save_outlined,
                    onPressed: _isLoading ? null : _updatePayment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
