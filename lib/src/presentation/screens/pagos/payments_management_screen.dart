import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'unified_payment_screen.dart';
import 'edit_payment_dialog.dart';

class PaymentsManagementScreen extends StatefulWidget {
  const PaymentsManagementScreen({super.key});

  @override
  State<PaymentsManagementScreen> createState() =>
      _PaymentsManagementScreenState();
}

class _PaymentsManagementScreenState extends State<PaymentsManagementScreen>
    with TickerProviderStateMixin {
  final _httpClient = HttpClient();
  late TabController _tabController;

  // Datos
  List<Map<String, dynamic>> _allPayments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _students = [];

  // Filtros
  String _filterName = '';
  int? _filterGrade;
  String _filterType = 'Todos'; // Todos, Inscripción, Enero, Febrero, etc.
  String _paymentType = 'Mensualidad'; // 'Mensualidad' o 'Bus'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final grades = await _httpClient.getList('/grades');
      setState(() {
        _grades = List<Map<String, dynamic>>.from(grades);
      });

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
      final List<Map<String, dynamic>> allPayments = [];

      print('🔍 Cargando pagos de tipo: $_paymentType');

      // Obtener todos los estudiantes de todos los grados
      for (var grade in _grades) {
        try {
          final students =
              await _httpClient.getList('/students?gradeId=${grade['id']}');

          for (var student in students) {
            try {
              if (_paymentType == 'Mensualidad') {
                // Cargar pagos de mensualidad
                final payments = await _httpClient
                    .getList('/api/pagos?estudiante_id=${student['id']}');
                print(
                    '📋 Pagos de mensualidad del estudiante ${student['name']}: ${payments.length}');

                for (var pago in payments) {
                  print(
                      '💰 Pago: concepto_id=${pago['concepto_id']}, mes=${pago['mes']}, monto=${pago['monto']}');

                  // Para mensualidad, incluir pagos con concepto_id=1 o sin concepto_id
                  final pagoConceptoId = pago['concepto_id'];
                  if (pagoConceptoId == null || pagoConceptoId == 1) {
                    allPayments.add({
                      ...pago,
                      'estudiante_nombre': student['name'] ?? '',
                      'grado_nombre': grade['name'] ?? '',
                      'grado_id': grade['id'],
                    });
                    print('✅ Pago de mensualidad agregado');
                  }
                }
              } else {
                // Cargar pagos de bus desde endpoint oficial /api/bus/payments
                final payments = await _httpClient.getList(
                    '/api/bus/payments?estudiante_id=${student['id']}');
                print(
                    '🚌 Pagos de bus del estudiante ${student['name']}: ${payments.length}');

                for (var pago in payments) {
                  print(
                      '💰 Pago bus: mes=${pago['mes']}, monto=${pago['monto']}');

                  allPayments.add({
                    ...pago,
                    'estudiante_nombre': student['name'] ?? '',
                    'grado_nombre': grade['name'] ?? '',
                    'grado_id': grade['id'],
                  });
                  print('✅ Pago de bus agregado');
                }
              }
            } catch (e) {
              print('Error obteniendo pagos del estudiante: $e');
            }
          }
        } catch (e) {
          print('Error obteniendo estudiantes del grado: $e');
        }
      }

      print('📊 Total pagos cargados: ${allPayments.length}');

      setState(() {
        _allPayments = allPayments;
        _applyFilters();
      });
    } catch (e) {
      print('Error cargando pagos: $e');
    }
  }

  void _applyFilters() {
    _filteredPayments = _allPayments.where((pago) {
      // Filtro por nombre
      if (_filterName.isNotEmpty) {
        if (!(pago['estudiante_nombre'] as String? ?? '')
            .toLowerCase()
            .contains(_filterName.toLowerCase())) {
          return false;
        }
      }

      // Filtro por grado
      if (_filterGrade != null) {
        if (pago['grado_id'] != _filterGrade) {
          return false;
        }
      }

      // Filtro por tipo (Inscripción, Mes, etc.)
      if (_filterType != 'Todos') {
        final mes = (pago['mes'] as String? ?? '').toLowerCase();
        if (_filterType == 'Inscripción') {
          if (!mes.contains('inscripción')) return false;
        } else {
          if (!mes.contains(_filterType.toLowerCase())) return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _deletePayment(int paymentId) async {
    try {
      // Usar endpoint según tipo de pago
      if (_paymentType == 'Bus') {
        await _httpClient.delete('/api/bus/payments/$paymentId');
      } else {
        await _httpClient.delete('/api/pagos/$paymentId');
      }

      setState(() {
        _allPayments.removeWhere((p) => p['id'] == paymentId);
        _applyFilters();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pago eliminado'),
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
          ),
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
          'Gestión de Pagos',
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
        bottom: SegmentedTabs(
          labels: const ['Registrar Pago', 'Historial'],
          controller: _tabController,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Registrar Pago
          const UnifiedPaymentScreen(),

          // Tab 2: Historial de Pagos
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildHistorialTab() {
    return _isLoading
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
                                _loadAllPayments();
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
                                _loadAllPayments();
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

              // Filtros
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtros',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),

                    // Filtro por nombre
                    InputField(
                      label: 'Buscar por nombre',
                      hintText: 'Nombre del estudiante...',
                      icon: Icons.search,
                      onChanged: (value) {
                        setState(() {
                          _filterName = value;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro por grado
                    SelectField<int?>(
                      label: 'Grado',
                      placeholder: 'Todos los grados',
                      value: _filterGrade,
                      items: [null, ..._grades.map((g) => g['id'] as int?)],
                      itemLabel: (id) => id == null
                          ? 'Todos los grados'
                          : _grades.firstWhere((g) => g['id'] == id)['name'] ??
                              '',
                      onSelected: (value) {
                        setState(() {
                          _filterGrade = value;
                          _applyFilters();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Filtro por mes (solo para Mensualidad)
                    if (_paymentType == 'Mensualidad')
                      SelectField<String>(
                        label: 'Mes/Período',
                        placeholder: 'Todos',
                        value: _filterType,
                        items: const [
                          'Todos',
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
                        ],
                        itemLabel: (m) => m,
                        onSelected: (value) {
                          setState(() {
                            _filterType = value ?? 'Todos';
                            _applyFilters();
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lista de pagos
              if (_filteredPayments.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No hay pagos registrados',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._filteredPayments.map((pago) {
                  final fecha = pago['fecha_pago'] != null
                      ? DateTime.parse(pago['fecha_pago'].toString())
                      : DateTime.now();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Información principal
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pago['estudiante_nombre'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pago['grado_nombre'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        pago['mes'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${fecha.day}/${fecha.month}/${fecha.year}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Monto y acciones
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Q${pago['monto']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => EditPaymentDialog(
                                          payment: pago,
                                          onUpdated: () {
                                            _loadAllPayments();
                                          },
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    tooltip: 'Editar',
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Eliminar pago',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900)),
                                          content: const Text(
                                              '¿Estás seguro de que deseas eliminar este pago?',
                                              style: TextStyle(fontSize: 16)),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancelar',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deletePayment(pago['id']);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.black,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Eliminar',
                                                  style:
                                                      TextStyle(fontSize: 16)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        size: 20),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(8),
                                    ),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
            ],
          );
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
