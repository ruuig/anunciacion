import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Página principal: dos apartados -> Entrada / Salida
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Mock de catálogo (reemplaza con tu data real)
  final grades = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria',
  ];
  final sections = const ['A', 'B', 'C'];

  // Filtros ENTRADA
  String? inGrade;
  String? inSection;

  // Filtros SALIDA
  String? outGrade;
  String? outSection;
  String? outName;

  bool showInFilters = true;
  bool showOutFilters = true;

  // Estado de conteos (mock). Actualiza al escanear
  int totalInAssigned = 28; // total esperados hoy (entrada)
  int arrived = 5;
  int get pendingIn => (totalInAssigned - arrived).clamp(0, totalInAssigned);

  int totalOutAssigned = 28; // total del día (salida)
  int left = 2;
  int get pendingOut => (totalOutAssigned - left).clamp(0, totalOutAssigned);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
                          value: '$arrived',
                          icon: Icons.groups_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiTile(
                          label: 'Faltan por llegar',
                          value: '$pendingIn',
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
                        Row(
                          children: [
                            Expanded(
                              child: SelectField<String>(
                                label: 'Filtrar por Grado',
                                placeholder: 'Todos los grados',
                                value: inGrade,
                                items: ['', ...grades],
                                itemLabel: (v) => v ?? 'Todos',
                                onSelected: (v) => setState(() => inGrade = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectField<String>(
                                label: 'Filtrar por Sección',
                                placeholder: inGrade == null
                                    ? 'Selecciona un grado'
                                    : 'Todas las secciones',
                                value: inSection,
                                items: outGrade == null
                                    ? const ['']
                                    : ['', ...sections],
                                itemLabel: (v) => v ?? 'Todas',
                                onSelected: (v) =>
                                    setState(() => inSection = v),
                              ),
                            ),
                          ],
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
                      onCode: (code) {
                        // TODO: validar código, consultar API y registrar ENTRADA
                        // Simulamos conteo:
                        setState(() =>
                            arrived = (arrived + 1).clamp(0, totalInAssigned));
                      },
                    );
                  },
                ),
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
                          value: '$left',
                          icon: Icons.logout_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiTile(
                          label: 'Quedan',
                          value: '$pendingOut',
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
                        Row(
                          children: [
                            Expanded(
                              child: SelectField<String>(
                                label: 'Filtrar por Grado',
                                placeholder: 'Todos los grados',
                                value: outGrade,
                                items: ['', ...grades],
                                itemLabel: (v) => v ?? 'Todos',
                                onSelected: (v) => setState(() => outGrade = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SelectField<String>(
                                label: 'Filtrar por Sección',
                                placeholder: outGrade == null
                                    ? 'Selecciona un grado'
                                    : 'Todas las secciones',
                                value: outSection ?? '',
                                items: outGrade == null
                                    ? const ['']
                                    : ['', ...sections],
                                itemLabel: (v) => v.isEmpty ? 'Todas' : v,
                                onSelected: (v) => setState(
                                    () => outSection = v.isEmpty ? null : v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SelectField<String>(
                          label: 'Filtrar por Nombre',
                          placeholder: 'Todos los estudiantes',
                          value: outName,
                          items: const [
                            '',
                            'Ana López',
                            'Carlos Méndez',
                            'María Hernández',
                            'Diego Ruiz'
                          ],
                          itemLabel: (v) => v ?? 'Todos',
                          onSelected: (v) => setState(() => outName = v),
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
                      onCode: (code) {
                        // TODO: validar código, consultar API y registrar SALIDA
                        setState(
                            () => left = (left + 1).clamp(0, totalOutAssigned));
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
