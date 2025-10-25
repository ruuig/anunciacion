import 'package:anunciacion/src/presentation/screens/homescreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anunciacion/src/presentation/providers/providers.dart';

class LoginFrame extends ConsumerStatefulWidget {
  const LoginFrame({super.key, this.onLogin, this.logoUrl});

  final void Function(String user, String pass)? onLogin;
  final String? logoUrl;

  @override
  ConsumerState<LoginFrame> createState() => _LoginFrameState();
}

class _LoginFrameState extends ConsumerState<LoginFrame> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // ✅ Dispara tu lógica de autenticación vía Riverpod
    await ref.read(userProvider.notifier).authenticate(
          _userCtrl.text.trim(),
          _passCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    final state = ref.read(userProvider);
    if (state.isAuthenticated) {
      // opcional: callback externo
      widget.onLogin?.call(_userCtrl.text, _passCtrl.text);

      // ✅ Navega y reemplaza el login por la Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeLuxuryPage()),
      );
    } else {
      // Muestra el error que venga del provider o uno genérico
      final msg = state.error ?? 'Usuario o contraseña inválidos';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores aproximados al diseño
    const colorPrimary = Color(0xFF2563EB); // azul del botón/enlace
    final colorTextDark = Colors.grey.shade900;
    final colorTextLight = Colors.grey.shade600;

    return Scaffold(
      // Fondo degradado suave como en la captura
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFAFAFA), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== Logo circular con anillo azul claro =====
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                              color: const Color(0xFFE5F0FF), width: 6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.07),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              widget.logoUrl == null || widget.logoUrl!.isEmpty
                                  ? Icon(Icons.image_outlined,
                                      size: 42, color: Colors.grey.shade500)
                                  : Image.network(
                                      widget.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                          Icons.image_outlined,
                                          size: 42,
                                          color: Colors.grey.shade500),
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ===== Títulos =====
                    Text(
                      'Nuestra Señora de la Anunciación',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorTextDark,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sistema de Gestión Escolar',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorTextLight),
                    ),

                    const SizedBox(height: 28),

                    // ===== Encabezado del formulario =====
                    Text(
                      'Iniciar Sesión',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorTextDark,
                              ),
                    ),

                    const SizedBox(height: 18),

                    // ===== Form =====
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _RoundedInput(
                            controller: _userCtrl,
                            hintText: 'Usuario',
                            leading: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Ingresa tu usuario'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _RoundedInput(
                            controller: _passCtrl,
                            hintText: 'Contraseña',
                            leading: Icons.lock_outline,
                            obscureText: !_showPassword,
                            trailing: IconButton(
                              onPressed: () => setState(
                                  () => _showPassword = !_showPassword),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Ingresa tu contraseña'
                                : null,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ===== Botón principal =====
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(22), // radio pill
                          ),
                        ),
                        child: Text(
                            _loading ? 'Iniciando sesión…' : 'Iniciar Sesión'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Enlace =====
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: _loading ? null : () {},
                        style: TextButton.styleFrom(
                          foregroundColor: colorPrimary,
                          textStyle:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto redondeado estilo "pill" con icono a la izquierda
class _RoundedInput extends StatelessWidget {
  const _RoundedInput({
    required this.controller,
    required this.hintText,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? leading;
  final Widget? trailing;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), // similar a rounded-xl grande
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
    );

    return SizedBox(
      height: 52,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        validator: validator,
        onFieldSubmitted: onSubmitted,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hintText,
          prefixIcon: leading != null
              ? Icon(leading, color: Colors.grey.shade500, size: 22)
              : null,
          suffixIcon: trailing,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.2),
          ),
        ),
      ),
    );
  }
}
