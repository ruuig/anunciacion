import 'package:flutter/material.dart';
import 'package:anunciacion/src/domain/entities/user.dart';
import 'package:anunciacion/src/presentation/widgets/widgets.dart';
import 'package:anunciacion/src/infrastructure/http/http_client.dart';

class CreateEditUserPage extends StatefulWidget {
  final User? initialUser;

  const CreateEditUserPage({
    super.key,
    this.initialUser,
  });

  @override
  State<CreateEditUserPage> createState() => _CreateEditUserPageState();
}

class _CreateEditUserPageState extends State<CreateEditUserPage> {
  final _httpClient = HttpClient();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _phoneCtrl;

  int? _selectedRoleId;
  bool _isLoading = false;

  final roles = const [
    {'id': 1, 'name': 'Administrador General'},
    {'id': 2, 'name': 'Docente'},
    {'id': 3, 'name': 'Director/Secretaria'},
    {'id': 4, 'name': 'Padre'},
  ];

  @override
  void initState() {
    super.initState();
    final user = widget.initialUser;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _passwordCtrl = TextEditingController();
    _phoneCtrl = TextEditingController(text: user?.phone?.value ?? '');
    _selectedRoleId = user?.roleId ?? 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Validaciones
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('El nombre es requerido');
      return;
    }
    if (_usernameCtrl.text.trim().isEmpty) {
      _showError('El nombre de usuario es requerido');
      return;
    }
    if (widget.initialUser == null && _passwordCtrl.text.isEmpty) {
      _showError('La contraseña es requerida');
      return;
    }
    if (_passwordCtrl.text.isNotEmpty && _passwordCtrl.text.length < 6) {
      _showError('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (_selectedRoleId == null) {
      _showError('Selecciona un rol');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.initialUser == null) {
        // Crear nuevo usuario via backend
        await _httpClient.post(
          '/users',
          {
            'name': _nameCtrl.text.trim(),
            'username': _usernameCtrl.text.trim(),
            'password': _passwordCtrl.text,
            'roleId': _selectedRoleId,
            'phone': _phoneCtrl.text.trim().isNotEmpty
                ? _phoneCtrl.text.trim()
                : null,
            'status': 'activo',
          },
        );
      } else {
        // Actualizar usuario existente via backend
        await _httpClient.put(
          '/users/${widget.initialUser!.id}',
          {
            'name': _nameCtrl.text.trim(),
            'username': _usernameCtrl.text.trim(),
            'password':
                _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
            'roleId': _selectedRoleId,
            'phone': _phoneCtrl.text.trim().isNotEmpty
                ? _phoneCtrl.text.trim()
                : null,
          },
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialUser == null
                ? '✓ Usuario creado exitosamente'
                : '✓ Usuario actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialUser != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
        title: Text(
          isEdit ? 'Editar Usuario' : 'Nuevo Usuario',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Datos principales
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre completo
                      const Text(
                        'Nombre Completo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameCtrl,
                        decoration: _input('Ej. Juan Pérez'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nombre de usuario
                      const Text(
                        'Nombre de Usuario',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usernameCtrl,
                        decoration: _input('Ej. jperez'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contraseña
                      Text(
                        isEdit ? 'Nueva Contraseña (opcional)' : 'Contraseña',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        decoration: _input(
                          isEdit
                              ? 'Dejar vacío para mantener actual'
                              : 'Mínimo 6 caracteres',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Teléfono
                      const Text(
                        'Teléfono (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _input('Ej. 50212345678'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Rol
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rol del Usuario',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: roles.map((role) {
                          return DropdownMenuItem<int>(
                            value: role['id'] as int,
                            child: Text(
                              role['name'] as String,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedRoleId = value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 80), // Espacio para el botón flotante
              ],
            ),

            // Botón de guardar flotante
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: BlackButton(
                label: isEdit ? 'Guardar Cambios' : 'Crear Usuario',
                icon: isEdit ? Icons.save : Icons.add,
                onPressed: _isLoading ? null : _save,
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
