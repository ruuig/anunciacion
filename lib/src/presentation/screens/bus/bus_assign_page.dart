import 'package:flutter/material.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';

class BusAssignPage extends StatefulWidget {
  const BusAssignPage({super.key});

  @override
  State<BusAssignPage> createState() => _BusAssignPageState();
}

class _BusAssignPageState extends State<BusAssignPage> {
  final _httpClient = HttpClient();
  List<Map<String, dynamic>> _grades = [];
  List<Map<String, dynamic>> _allStudents = [];
  Map<String, dynamic>? _selectedGrade;
  Map<String, dynamic>? _selectedStudent;
  
  final _montoCtrl = TextEditingController(text: '200');
  final _rutaCtrl = TextEditingController();
  final _paradaCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

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
      final allStudents = await _httpClient.getList('/students');
      final busStudents = await _httpClient.getList('/api/bus/students?activo=true');
      
      // Filtrar estudiantes que NO tienen servicio de bus
      final busStudentIds = (busStudents as List)
          .map((s) => s['estudiante_id'])
          .toSet();
      
      final availableStudents = (allStudents as List)
          .where((s) => !busStudentIds.contains(s['id']))
          .toList();
      
      setState(() {
        _grades = List<Map<String, dynamic>>.from(grades);
        _allStudents = List<Map<String, dynamic>>.from(availableStudents);
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
      setState(() {
        _allStudents = List<Map<String, dynamic>>.from(students);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading students by grade: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignService() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un estudiante')),
      );
      return;
    }

    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _httpClient.post('/api/bus/assign', {
        'estudiante_id': _selectedStudent!['id'],
        'monto_mensual': monto,
        'ruta': _rutaCtrl.text.trim().isEmpty ? null : _rutaCtrl.text.trim(),
        'parada': _paradaCtrl.text.trim().isEmpty ? null : _paradaCtrl.text.trim(),
        'notas': _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Servicio asignado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error assigning bus service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ Error al asignar'),
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: const Text(
          'Asignar Servicio de Bus',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: _isLoading && _allStudents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selección de Estudiante',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                          });
                          if (v != null) {
                            _loadStudentsByGrade(v['id']);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      SelectField<Map<String, dynamic>>(
                        label: 'Estudiante',
                        placeholder: _selectedGrade == null
                            ? 'Primero selecciona un grado'
                            : 'Selecciona un estudiante...',
                        value: _selectedStudent,
                        items: _allStudents,
                        itemLabel: (s) => s['name'] ?? '',
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
                        'Detalles del Servicio',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Monto Mensual (Q)',
                        controller: _montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        icon: Icons.attach_money_rounded,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Ruta (Opcional)',
                        controller: _rutaCtrl,
                        hintText: 'Ej: Ruta Norte, Ruta Sur',
                        icon: Icons.route_outlined,
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        label: 'Parada (Opcional)',
                        controller: _paradaCtrl,
                        hintText: 'Ubicación de la parada',
                        icon: Icons.location_on_outlined,
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
          label: _isLoading ? 'Guardando...' : 'Asignar Servicio',
          icon: Icons.directions_bus_rounded,
          onPressed: _isLoading ? null : _assignService,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _rutaCtrl.dispose();
    _paradaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }
}
