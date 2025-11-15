import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';
import 'bus_payment_page.dart';
import 'bus_assign_page.dart';

class BusServiceScreen extends StatefulWidget {
  const BusServiceScreen({super.key});

  @override
  State<BusServiceScreen> createState() => _BusServiceScreenState();
}

class _BusServiceScreenState extends State<BusServiceScreen> {
  final _httpClient = HttpClient();
  List<Map<String, dynamic>> _busStudents = [];
  bool _isLoading = false;
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadBusStudents();
  }

  Future<void> _loadBusStudents() async {
    setState(() => _isLoading = true);
    try {
      final students = await _httpClient.getList(
        '/api/bus/students?activo=${_showActiveOnly ? 'true' : 'false'}',
      );
      setState(() {
        _busStudents = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bus students: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estudiantes: $e')),
        );
      }
    }
  }

  Future<void> _deactivateService(int estudianteId, String nombre) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar Servicio'),
        content: Text('¿Desactivar servicio de bus para $nombre?'),
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

    if (confirm != true) return;

    try {
      await _httpClient.put('/api/bus/deactivate/$estudianteId', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio desactivado correctamente'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadBusStudents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al desactivar: $e')),
        );
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
        title: const Text(
          'Servicio de Bus',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showActiveOnly ? Icons.visibility : Icons.visibility_off,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                _showActiveOnly = !_showActiveOnly;
              });
              _loadBusStudents();
            },
            tooltip: _showActiveOnly ? 'Mostrar inactivos' : 'Mostrar activos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBusStudents,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Botones de acción
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Servicio de Bus',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Asigna el servicio de bus a estudiantes y registra pagos.',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: BlackButton(
                            label: 'Asignar servicio de bus',
                            icon: Icons.directions_bus_rounded,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BusAssignPage(),
                                ),
                              );
                              _loadBusStudents();
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: BlackButton(
                            label: 'Registrar pago de bus',
                            icon: Icons.attach_money_rounded,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BusPaymentPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estadísticas
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.people, color: Colors.blue, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                '${_busStudents.length}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                _showActiveOnly ? 'Con servicio' : 'Total',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: Colors.black12,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.attach_money, color: Colors.green, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                'Q${_busStudents.fold<double>(0, (sum, s) => sum + (s['monto_mensual'] ?? 0)).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'Total mensual',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de estudiantes
                  if (_busStudents.isEmpty)
                    AppCard(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_bus_outlined,
                                size: 64,
                                color: Colors.black26,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _showActiveOnly
                                    ? 'No hay estudiantes con servicio activo'
                                    : 'No hay estudiantes registrados',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ..._busStudents.map((student) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: student['activo'] == true
                                            ? Colors.green.shade50
                                            : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.directions_bus_rounded,
                                        color: student['activo'] == true
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student['nombre'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            student['grado'] ?? 'Sin grado',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (student['activo'] == true)
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        onPressed: () => _deactivateService(
                                          student['estudiante_id'],
                                          student['nombre'],
                                        ),
                                        tooltip: 'Desactivar servicio',
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F5F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Monto mensual',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            'Q${student['monto_mensual']?.toStringAsFixed(2) ?? '0.00'}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (student['ruta'] != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Ruta',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            Text(
                                              student['ruta'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
