import 'package:anunciacion/src/presentation/presentation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Overlay bonito para centrar el QR
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // sombreado
          Container(color: Colors.black.withOpacity(0.25)),
          // marco central
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8)
                ],
              ),
            ),
          ),
          // texto
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  /// Si quieres capturar el resultado para otra pantalla (opcional)
  final ValueChanged<String>? onDetect;

  const QrScannerPage({super.key, this.onDetect});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _pausedAfterDetect = false;
  String? _lastValue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates, // evita lecturas repetidas
      detectionTimeoutMs: 750,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Pausa/reanuda cámara en background/foreground para evitar bloqueos
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused) {
      _controller.stop();
    } else if (state == AppLifecycleState.resumed) {
      _controller.start();
    }
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_pausedAfterDetect) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    _pausedAfterDetect = true;
    _lastValue = code;

    // Pausar cámara para no leer múltiples veces
    await _controller.stop();

    if (!mounted) return;

    // Acción: notificar o mostrar diálogo
    widget.onDetect?.call(code);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('QR Detectado',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(code),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, code); // devolver resultado a quien navegó
            },
            child: const Text('Usar'),
          ),
        ],
      ),
    );

    // Si seguimos en esta pantalla, podemos reanudar si se quiere leer otro QR
    if (mounted) {
      _pausedAfterDetect = false;
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // para que la cámara “brille”
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context, _lastValue),
        ),
        title: const Text('Escanear QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Cambiar cámara',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
          ),
          IconButton(
            tooltip: 'Linterna',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Text(
                  'No se pudo iniciar la cámara.\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
          const _ScannerOverlay(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: BlackButton(
                  label: 'Pausar',
                  icon: Icons.pause_circle_filled_rounded,
                  onPressed: () async {
                    await _controller.stop();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlackButton(
                  label: 'Reanudar',
                  icon: Icons.play_circle_fill_rounded,
                  onPressed: () async {
                    await _controller.start();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
