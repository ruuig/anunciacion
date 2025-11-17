import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../infrastructure/http/http_attendance_repository.dart';
import '../../infrastructure/repositories/http_grade_repository.dart';
import '../../domain/entities/entities.dart';

/// Página principal: dos apartados -> Entrada / Salida
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _attendanceRepository = HttpAttendanceRepository();
  final _gradeRepository = HttpGradeRepository();

  // Datos del backend
  List<Grade> _grades = [];
  Grade? _selectedInGrade;
  Grade? _selectedOutGrade;
  String _inSearchName = '';
  String _outSearchName = '';

  // Resúmenes de asistencia
  AttendanceSummary? _entrySummary;
  AttendanceSummary? _exitSummary;
  bool _loadingEntrySummary = true;
  bool _loadingExitSummary = true;

  // Estudiantes registrados hoy
  List<Attendance> _entryRegisteredToday = [];
  List<Attendance> _exitRegisteredToday = [];

  bool showInFilters = true;
  bool showOutFilters = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final grades = await _gradeRepository.findActiveGrades();
      final entrySummary = await _attendanceRepository.getEntrySummary();
      final exitSummary = await _attendanceRepository.getExitSummary();

      // Cargar estudiantes que ya entraron hoy
      final entryRegistered = await _attendanceRepository.getTodayAttendance();
      final entryFiltered = entryRegistered
          .where((a) => a.entryTime != null && a.exitTime == null)
          .toList();

      // Cargar estudiantes que ya salieron hoy
      final exitFiltered =
          entryRegistered.where((a) => a.exitTime != null).toList();

      if (mounted) {
        setState(() {
          _grades = grades;
          _entrySummary = entrySummary;
          _exitSummary = exitSummary;
          _entryRegisteredToday = entryFiltered;
          _exitRegisteredToday = exitFiltered;
          _loadingEntrySummary = false;
          _loadingExitSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingEntrySummary = false;
          _loadingExitSummary = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _refreshSummaries() async {
    try {
      final entrySummary = await _attendanceRepository.getEntrySummary(
        gradeId: _selectedInGrade?.id,
      );
      final exitSummary = await _attendanceRepository.getExitSummary(
        gradeId: _selectedOutGrade?.id,
      );

      // Recargar estudiantes registrados
      final entryRegistered = await _attendanceRepository.getTodayAttendance();
      final entryFiltered = entryRegistered
          .where((a) => a.entryTime != null && a.exitTime == null)
          .toList();

      final exitFiltered =
          entryRegistered.where((a) => a.exitTime != null).toList();

      if (mounted) {
        setState(() {
          _entrySummary = entrySummary;
          _exitSummary = exitSummary;
          _entryRegisteredToday = entryFiltered;
          _exitRegisteredToday = exitFiltered;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    }
  }

  Future<void> _handleQREntry(String code) async {
    try {
      await _attendanceRepository.registerEntry(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Entrada registrada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshSummaries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleQRExit(String code) async {
    try {
      await _attendanceRepository.registerExit(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Salida registrada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _refreshSummaries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Abre el lector QR continuo en un bottom sheet
  Future<void> _openScanner({
    required void Function(String code) onCode,
    String title = 'Escanear Código QR',
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.82,
        child: _ContinuousScannerSheet(
          title: title,
          onCode: onCode,
        ),
      ),
    );
    // Al cerrar el scanner, podrías refrescar listas desde backend si hace falta.
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .5,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Gestión de Asistencia',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        bottom: SegmentedTabs(
          labels: const ['Entrada', 'Salida'],
          controller: _tab,
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // -------- TAB ENTRADA --------
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // KPI tarjeta grande
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          label: 'En el colegio',
                          value: '${_entrySummary?.present ?? 0}',
                          icon: Icons.groups_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiTile(
                          label: 'Faltan por llegar',
                          value: '${_entrySummary?.pending ?? 0}',
                          icon: Icons.schedule_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filtros (ocultables)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Filtros de Asistencia',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => showInFilters = !showInFilters),
                            icon: const Icon(Icons.filter_alt_outlined),
                            label: Text(showInFilters ? 'Ocultar' : 'Mostrar'),
                          ),
                        ],
                      ),
                      if (showInFilters) ...[
                        const SizedBox(height: 8),
                        SelectField<Grade?>(
                          label: 'Filtrar por Grado',
                          placeholder: 'Todos los grados',
                          value: _selectedInGrade,
                          items: [null, ..._grades],
                          itemLabel: (g) => g?.name ?? 'Todos',
                          onSelected: (v) {
                            setState(() => _selectedInGrade = v);
                            _refreshSummaries();
                          },
                        ),
                        const SizedBox(height: 12),
                        InputField(
                          label: 'Buscar por nombre',
                          hintText: 'Escribe nombre del estudiante...',
                          icon: Icons.search,
                          onChanged: (v) {
                            setState(() => _inSearchName = v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Botón escanear
                BlackButton(
                  label: 'Escanear Código QR',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () async {
                    await _openScanner(
                      title: 'Entrada - Escanear',
                      onCode: _handleQREntry,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Botón registro manual
                BlackButton(
                  label: 'Registrar Entrada Manual',
                  icon: Icons.person_add_outlined,
                  onPressed: () => _openManualEntryModal(),
                ),

                const SizedBox(height: 24),

                // Resumen de estudiantes que ya entraron
                if (_entryRegisteredToday.isNotEmpty) ...[
                  const Text(
                    'Estudiantes que ya entraron',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._entryRegisteredToday.take(5).map((student) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(
                                color: Colors.green[200]!, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student.studentName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (_entryRegisteredToday.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${_entryRegisteredToday.length - 5} más',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // -------- TAB SALIDA --------
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiTile(
                          label: 'Ya salieron',
                          value: '${_exitSummary?.present ?? 0}',
                          icon: Icons.logout_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiTile(
                          label: 'Quedan',
                          value: '${_exitSummary?.pending ?? 0}',
                          icon: Icons.home_work_outlined,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Filtros (Grado, Sección, Nombre) ocultables
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text('Filtros de Asistencia',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(
                                () => showOutFilters = !showOutFilters),
                            icon: const Icon(Icons.filter_alt_outlined),
                            label: Text(showOutFilters ? 'Ocultar' : 'Mostrar'),
                          ),
                        ],
                      ),
                      if (showOutFilters) ...[
                        const SizedBox(height: 8),
                        SelectField<Grade?>(
                          label: 'Filtrar por Grado',
                          placeholder: 'Todos los grados',
                          value: _selectedOutGrade,
                          items: [null, ..._grades],
                          itemLabel: (g) => g?.name ?? 'Todos',
                          onSelected: (v) {
                            setState(() => _selectedOutGrade = v);
                            _refreshSummaries();
                          },
                        ),
                        const SizedBox(height: 12),
                        InputField(
                          label: 'Buscar por nombre',
                          hintText: 'Escribe nombre del estudiante...',
                          icon: Icons.search,
                          onChanged: (v) {
                            setState(() => _outSearchName = v);
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                BlackButton(
                  label: 'Escanear Código QR',
                  icon: Icons.qr_code_scanner_rounded,
                  onPressed: () async {
                    await _openScanner(
                      title: 'Salida - Escanear',
                      onCode: _handleQRExit,
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Botón registro manual
                BlackButton(
                  label: 'Registrar Salida Manual',
                  icon: Icons.person_remove_outlined,
                  onPressed: () => _openManualExitModal(),
                ),

                const SizedBox(height: 24),

                // Resumen de estudiantes que ya salieron
                if (_exitRegisteredToday.isNotEmpty) ...[
                  const Text(
                    'Estudiantes que ya salieron',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._exitRegisteredToday.take(5).map((student) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            border: Border.all(
                                color: Colors.green[200]!, width: 1.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  student.studentName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (_exitRegisteredToday.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${_exitRegisteredToday.length - 5} más',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openManualEntryModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualEntryModal(
        grades: _grades,
        attendanceRepository: _attendanceRepository,
        onSuccess: () {
          _refreshSummaries();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _openManualExitModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualExitModal(
        grades: _grades,
        attendanceRepository: _attendanceRepository,
        onSuccess: () {
          _refreshSummaries();
          Navigator.pop(context);
        },
      ),
    );
  }
}

/// KPI compacto (valor grande + etiqueta)
class _KpiTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _KpiTile(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 78),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E9F2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFEFF4FF),
              child: Icon(icon, color: Colors.black87, size: 22),
            ),
            const SizedBox(width: 10),
            // <- lo que evita el overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Número grande que se reduce si no cabe
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Etiqueta en 1-2 líneas con elipsis
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
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

/// Bottom sheet con cámara abierta y ESCANEO CONTINUO.
/// - Lee múltiples códigos sin preguntar
/// - Evita duplicados muy seguidos
/// - Vibra en cada lectura
class _ContinuousScannerSheet extends StatefulWidget {
  final String title;
  final void Function(String code) onCode;
  const _ContinuousScannerSheet({required this.title, required this.onCode});

  @override
  State<_ContinuousScannerSheet> createState() =>
      _ContinuousScannerSheetState();
}

class _ContinuousScannerSheetState extends State<_ContinuousScannerSheet>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  // Anti-duplicados simple por ventana de tiempo
  final Map<String, DateTime> _recent = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal, // sigue leyendo continuamente
      // no ponemos noDuplicates porque queremos poder leer diferentes QR seguidos
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  bool _shouldAccept(String value) {
    final now = DateTime.now();
    final last = _recent[value];
    if (last == null || now.difference(last) > const Duration(seconds: 2)) {
      _recent[value] = now;
      return true;
    }
    return false; // ignorar duplicado reciente
  }

  void _onDetect(BarcodeCapture cap) async {
    final raw = cap.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    if (!_shouldAccept(raw)) return;

    // vibra suave
    HapticFeedback.lightImpact();

    // notificar arriba
    widget.onCode(raw);

    // Opcional: feedback visual mínimo
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.black.withOpacity(.9),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        content:
            Text('Leído: $raw', style: const TextStyle(color: Colors.white)),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header negro compacto
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _controller.switchCamera(),
                  icon: const Icon(Icons.cameraswitch_rounded,
                      color: Colors.white),
                ),
                IconButton(
                  onPressed: () => _controller.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on_rounded,
                      color: Colors.white),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),

          // Cámara + overlay
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (_, error, __) => Center(
                    child: Text(
                      'No se pudo iniciar la cámara.\n$error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const _OverlayView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayView extends StatelessWidget {
  const _OverlayView();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // borde central
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal para registrar entrada manual
class _ManualEntryModal extends StatefulWidget {
  final List<Grade> grades;
  final HttpAttendanceRepository attendanceRepository;
  final VoidCallback onSuccess;

  const _ManualEntryModal({
    required this.grades,
    required this.attendanceRepository,
    required this.onSuccess,
  });

  @override
  State<_ManualEntryModal> createState() => _ManualEntryModalState();
}

class _ManualEntryModalState extends State<_ManualEntryModal> {
  Grade? _selectedGrade;
  Attendance? _selectedStudent;
  List<Attendance> _allStudents = [];
  List<Attendance> _filteredStudents = [];
  List<Attendance> _registeredStudents = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.grades.isNotEmpty) {
      _selectedGrade = widget.grades.first;
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedGrade == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await widget.attendanceRepository.getTodayAttendance(
        gradeId: _selectedGrade!.id,
      );

      print('📚 [ENTRY] Estudiantes cargados: ${students.length}');
      for (var s in students.take(3)) {
        print('  - ${s.studentName} (${s.studentCode})');
      }

      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _registeredStudents = [];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [ENTRY] Error cargando estudiantes: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents
            .where((s) =>
                s.studentName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _registerEntry() async {
    if (_selectedStudent == null) return;

    try {
      final codeOrId = _selectedStudent!.studentCode.isNotEmpty
          ? _selectedStudent!.studentCode
          : _selectedStudent!.studentId.toString();

      await widget.attendanceRepository.registerManualEntry(codeOrId);

      if (mounted) {
        setState(() {
          _registeredStudents.add(_selectedStudent!);
          _selectedStudent = null;
          _searchQuery = '';
          _filteredStudents = _allStudents;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Entrada registrada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registrar Entrada Manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectField<Grade?>(
                    label: 'Grado',
                    placeholder: 'Selecciona un grado',
                    value: _selectedGrade,
                    items: widget.grades,
                    itemLabel: (g) => g?.name ?? '',
                    onSelected: (v) {
                      setState(() => _selectedGrade = v);
                      _loadStudents();
                    },
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Búsqueda
                  InputField(
                    label: 'Buscar estudiante',
                    hintText: 'Escribe el nombre...',
                    icon: Icons.search,
                    onChanged: _filterStudents,
                  ),
                  const SizedBox(height: 16),

                  // Lista de estudiantes
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay estudiantes'),
                    )
                  else
                    ..._filteredStudents.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              print(
                                  '✅ [ENTRY] Seleccionado: ${s.studentName} (${s.studentCode})');
                              setState(() => _selectedStudent = s);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    _selectedStudent?.studentId == s.studentId
                                        ? Colors.green[50]
                                        : Colors.white,
                                border: Border.all(
                                  color:
                                      _selectedStudent?.studentId == s.studentId
                                          ? Colors.green[300]!
                                          : Colors.grey[200]!,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.studentName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          s.studentCode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedStudent?.studentId ==
                                      s.studentId)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Botón registrar
                  BlackButton(
                    label: 'Registrar Entrada',
                    onPressed: _selectedStudent != null ? _registerEntry : null,
                  ),

                  const SizedBox(height: 24),

                  // Estudiantes que ya entraron
                  if (_registeredStudents.isNotEmpty) ...[
                    const Text(
                      'Ya registrados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._registeredStudents.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(
                                  color: Colors.green[200]!, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.studentName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        s.studentCode,
                                        style: const TextStyle(
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
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal para registrar salida manual
class _ManualExitModal extends StatefulWidget {
  final List<Grade> grades;
  final HttpAttendanceRepository attendanceRepository;
  final VoidCallback onSuccess;

  const _ManualExitModal({
    required this.grades,
    required this.attendanceRepository,
    required this.onSuccess,
  });

  @override
  State<_ManualExitModal> createState() => _ManualExitModalState();
}

class _ManualExitModalState extends State<_ManualExitModal> {
  Grade? _selectedGrade;
  Attendance? _selectedStudent;
  List<Attendance> _allStudents = [];
  List<Attendance> _filteredStudents = [];
  List<Attendance> _registeredStudents = [];
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.grades.isNotEmpty) {
      _selectedGrade = widget.grades.first;
      _loadStudents();
    }
  }

  Future<void> _loadStudents() async {
    if (_selectedGrade == null) return;

    setState(() => _isLoading = true);
    try {
      final students = await widget.attendanceRepository.getTodayAttendance(
        gradeId: _selectedGrade!.id,
      );

      setState(() {
        _allStudents = students;
        _filteredStudents = students;
        _registeredStudents = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterStudents(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredStudents = _allStudents;
      } else {
        _filteredStudents = _allStudents
            .where((s) =>
                s.studentName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _registerExit() async {
    if (_selectedStudent == null) return;

    try {
      final codeOrId = _selectedStudent!.studentCode.isNotEmpty
          ? _selectedStudent!.studentCode
          : _selectedStudent!.studentId.toString();

      await widget.attendanceRepository.registerManualExit(codeOrId);

      if (mounted) {
        setState(() {
          _registeredStudents.add(_selectedStudent!);
          _selectedStudent = null;
          _searchQuery = '';
          _filteredStudents = _allStudents;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Salida registrada'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Registrar Salida Manual',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectField<Grade?>(
                    label: 'Grado',
                    placeholder: 'Selecciona un grado',
                    value: _selectedGrade,
                    items: widget.grades,
                    itemLabel: (g) => g?.name ?? '',
                    onSelected: (v) {
                      setState(() => _selectedGrade = v);
                      _loadStudents();
                    },
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  // Búsqueda
                  InputField(
                    label: 'Buscar estudiante',
                    hintText: 'Escribe el nombre...',
                    icon: Icons.search,
                    onChanged: _filterStudents,
                  ),
                  const SizedBox(height: 16),

                  // Lista de estudiantes
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_filteredStudents.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay estudiantes'),
                    )
                  else
                    ..._filteredStudents.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedStudent = s),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    _selectedStudent?.studentId == s.studentId
                                        ? Colors.green[50]
                                        : Colors.white,
                                border: Border.all(
                                  color:
                                      _selectedStudent?.studentId == s.studentId
                                          ? Colors.green[300]!
                                          : Colors.grey[200]!,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.studentName,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          s.studentCode,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedStudent?.studentId ==
                                      s.studentId)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green),
                                ],
                              ),
                            ),
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Botón registrar
                  BlackButton(
                    label: 'Registrar Salida',
                    onPressed: _selectedStudent != null ? _registerExit : null,
                  ),

                  const SizedBox(height: 24),

                  // Estudiantes que ya salieron
                  if (_registeredStudents.isNotEmpty) ...[
                    const Text(
                      'Ya registrados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._registeredStudents.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              border: Border.all(
                                  color: Colors.green[200]!, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.studentName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        s.studentCode,
                                        style: const TextStyle(
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
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
