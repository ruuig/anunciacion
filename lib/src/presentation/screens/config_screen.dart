import 'package:anunciacion/src/presentation/widgets/input_field.dart';
import 'package:flutter/material.dart';
import '../widgets/widgets.dart';

/// Modelo simple de usuario admin (ajústalo a tu modelo real)
class AdminUser {
  final String name;
  final String role;
  final List<String>
      permissions; // e.g. ['manage_users','manage_grades','edit_students','view_all']
  const AdminUser(
      {required this.name, required this.role, required this.permissions});
}

/// Pantalla principal de Administración
class AdministrationPage extends StatefulWidget {
  final AdminUser user;
  const AdministrationPage({super.key, required this.user});

  @override
  State<AdministrationPage> createState() => _AdministrationPageState();
}

class _AdministrationPageState extends State<AdministrationPage> {
  // Estado: módulo activo
  String _active = 'dashboard';

  // Catálogo de módulos (similar al arreglo de React)
  late final List<_AdminModule> _modules = [
    _AdminModule(
      id: 'users',
      title: 'Gestión de Usuarios',
      description: 'Administrar usuarios y roles',
      icon: Icons.group_outlined,
      color: const Color(0xFF2563EB), // azul
      requiredPermission: 'manage_users',
    ),
    _AdminModule(
      id: 'grades_config',
      title: 'Configurar Grados',
      description: 'Administrar grados y secciones',
      icon: Icons.school_outlined,
      color: const Color(0xFF16A34A), // verde
      requiredPermission: 'manage_grades',
    ),
    _AdminModule(
      id: 'student_admin',
      title: 'Administrar Estudiantes',
      description: 'Crear, editar y asignar estudiantes',
      icon: Icons.menu_book_outlined,
      color: const Color(0xFF7C3AED), // morado
      requiredPermission: 'edit_students',
    ),
    _AdminModule(
      id: 'system',
      title: 'Configuración del Sistema',
      description: 'Ajustes generales del sistema',
      icon: Icons.settings_outlined,
      color: const Color(0xFF6B7280), // gris
      requiredPermission: 'manage_users',
    ),
  ];

  bool _hasPermission(String p) =>
      widget.user.permissions.contains(p) ||
      widget.user.permissions.contains('view_all');

  List<_AdminModule> get _available =>
      _modules.where((m) => _hasPermission(m.requiredPermission)).toList();

  void _goBackToDashboard() => setState(() => _active = 'dashboard');

  @override
  Widget build(BuildContext context) {
    final isDashboard = _active == 'dashboard';
    final title = isDashboard
        ? 'Administración'
        : (_modules
            .firstWhere(
              (m) => m.id == _active,
              orElse: () => _AdminModule(
                  id: 'x',
                  title: 'Administración',
                  description: '',
                  icon: Icons.shield_outlined,
                  color: Colors.black,
                  requiredPermission: ''),
            )
            .title);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .5,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () {
            if (!isDashboard) {
              _goBackToDashboard();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isDashboard ? _buildDashboard() : _buildSubmodule(_active),
        ),
      ),
    );
  }

  /// DASHBOARD principal con header de usuario y grid de módulos disponibles
  Widget _buildDashboard() {
    return ListView(
      key: const ValueKey('dashboard'),
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_outlined, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Panel de Administración',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Usuario: ${widget.user.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text('Rol: ${widget.user.role}',
                              style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Grid (como lista vertical de botones)
        if (_available.isEmpty)
          const EmptyState(
            title: 'Sin permisos administrativos',
            description: 'No tienes permisos para acceder a los módulos.',
            icon: Icon(Icons.shield_outlined, size: 48, color: Colors.black45),
          )
        else
          Column(
            children: [
              for (final m in _available) ...[
                InkWell(
                  onTap: () => setState(() => _active = m.id),
                  borderRadius: BorderRadius.circular(18),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: m.color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(m.icon, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                m.description,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999)),
                          child: const Icon(Icons.edit_outlined,
                              color: Colors.black54, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
      ],
    );
  }

  /// Renderiza el submódulo activo
  Widget _buildSubmodule(String id) {
    switch (id) {
      case 'users':
        return _UsersManagementView(onBack: _goBackToDashboard);
      case 'grades_config':
        return _GradesManagementView(onBack: _goBackToDashboard);
      case 'student_admin':
        return _StudentManagementView(onBack: _goBackToDashboard);
      case 'system':
        return _SystemSettingsView(onBack: _goBackToDashboard);
      default:
        return _buildDashboard();
    }
  }
}

/// ---------------- SUBMÓDULOS (stubs funcionales de UI) ----------------

class _UsersManagementView extends StatefulWidget {
  final VoidCallback onBack;
  const _UsersManagementView({required this.onBack});

  @override
  State<_UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<_UsersManagementView> {
  final roles = const ['Administrador', 'Docente', 'Secretaria'];
  String? roleFilter;

  final List<Map<String, String>> users = [
    {
      'name': 'Marcos García',
      'email': 'marcos@colegio.com',
      'role': 'Administrador'
    },
    {'name': 'Lucía Pérez', 'email': 'lucia@colegio.com', 'role': 'Docente'},
    {'name': 'Sofía Díaz', 'email': 'sofia@colegio.com', 'role': 'Secretaria'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = users
        .where((u) => roleFilter == null || u['role'] == roleFilter)
        .toList();

    return ListView(
      key: const ValueKey('users'),
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Usuarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectField<String>(
                      label: 'Rol',
                      placeholder: 'Todos',
                      value: roleFilter ?? '',
                      items: [''] + roles,
                      itemLabel: (v) => v.isEmpty ? 'Todos' : v,
                      onSelected: (v) =>
                          setState(() => roleFilter = v.isEmpty ? null : v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  BlackButton(
                    label: 'Nuevo Usuario',
                    icon: Icons.add,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Crear usuario (stub)')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'Sin usuarios',
            description: 'No hay usuarios con ese filtro.',
            icon: Icon(Icons.person_off_outlined,
                size: 48, color: Colors.black45),
          )
        else
          ...filtered.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(
                          _initials(u['name']!),
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(u['email']!,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('Rol: ${u['role']!}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Editar ${u['name']} (stub)')),
                        ),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Eliminar ${u['name']} (stub)')),
                        ),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _GradesManagementView extends StatefulWidget {
  final VoidCallback onBack;
  const _GradesManagementView({required this.onBack});

  @override
  State<_GradesManagementView> createState() => _GradesManagementViewState();
}

class _GradesManagementViewState extends State<_GradesManagementView> {
  final List<_GradeItem> grades = [
    _GradeItem('1ro Primaria', sections: ['A', 'B']),
    _GradeItem('2do Primaria', sections: ['A']),
    _GradeItem('3ro Primaria', sections: ['A', 'B', 'C']),
  ];

  void _addGrade() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Agregar grado (stub)')));
  }

  void _addSection(_GradeItem g) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agregar sección a ${g.name} (stub)')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('grades'),
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Grados y Secciones',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              BlackButton(
                  label: 'Nuevo Grado', icon: Icons.add, onPressed: _addGrade),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...grades.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(g.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: g.sections
                          .map(
                            (s) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Sección $s',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        BlackButton(
                            label: 'Agregar Sección',
                            onPressed: () => _addSection(g)),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Editar ${g.name} (stub)')),
                          ),
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.black),
                        ),
                        IconButton(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Eliminar ${g.name} (stub)')),
                          ),
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class _StudentManagementView extends StatefulWidget {
  final VoidCallback onBack;
  const _StudentManagementView({required this.onBack});

  @override
  State<_StudentManagementView> createState() => _StudentManagementViewState();
}

class _StudentManagementViewState extends State<_StudentManagementView> {
  final grades = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria'
  ];
  final sections = const ['A', 'B', 'C'];
  String? gradeFilter;
  String? sectionFilter;
  String? nameQuery;

  final List<Map<String, String>> students = [
    {'name': 'Ana María López', 'grade': '3ro Primaria', 'section': 'A'},
    {'name': 'Carlos Roberto Méndez', 'grade': '3ro Primaria', 'section': 'A'},
    {'name': 'María José Hernández', 'grade': '4to Primaria', 'section': 'B'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = students.where((s) {
      final okG = gradeFilter == null || s['grade'] == gradeFilter;
      final okS = sectionFilter == null || s['section'] == sectionFilter;
      final q = (nameQuery ?? '').trim().toLowerCase();
      final okN = q.isEmpty || (s['name'] ?? '').toLowerCase().contains(q);
      return okG && okS && okN;
    }).toList();

    return ListView(
      key: const ValueKey('students'),
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Estudiantes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectField<String>(
                      label: 'Grado',
                      placeholder: 'Todos',
                      value: gradeFilter ?? '',
                      items: [''] + grades,
                      itemLabel: (v) => v.isEmpty ? 'Todos' : v,
                      onSelected: (v) =>
                          setState(() => gradeFilter = v.isEmpty ? null : v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectField<String>(
                      label: 'Sección',
                      placeholder:
                          gradeFilter == null ? 'Selecciona un grado' : 'Todas',
                      value: sectionFilter ?? '',
                      items: gradeFilter == null ? [''] : [''] + sections,
                      itemLabel: (v) => v.isEmpty ? 'Todas' : v,
                      onSelected: (v) =>
                          setState(() => sectionFilter = v.isEmpty ? null : v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Input de nombre (como pediste)
              InputField(
                label: 'Nombre',
                hintText: 'Buscar por nombre…',
                icon: Icons.search,
                onChanged: (v) => setState(() => nameQuery = v),
              ),
              const SizedBox(height: 12),
              BlackButton(
                label: 'Nuevo Estudiante',
                icon: Icons.add,
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Crear estudiante (stub)')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          const EmptyState(
            title: 'Sin estudiantes',
            description: 'Ajusta los filtros o prueba otra búsqueda.',
            icon: Icon(Icons.person_search_outlined,
                size: 48, color: Colors.black45),
          )
        else
          ...filtered.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(_initials(s['name']!),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('${s['grade']} • Sección ${s['section']}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Editar ${s['name']} (stub)')),
                        ),
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Eliminar ${s['name']} (stub)')),
                        ),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _SystemSettingsView extends StatefulWidget {
  final VoidCallback onBack;
  const _SystemSettingsView({required this.onBack});

  @override
  State<_SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<_SystemSettingsView> {
  bool attendanceEnabled = true;
  bool pushNotifications = true;
  bool qrScannerSound = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('system'),
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configuración del Sistema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              _SwitchTile(
                title: 'Asistencia habilitada',
                value: attendanceEnabled,
                onChanged: (v) => setState(() => attendanceEnabled = v),
              ),
              _SwitchTile(
                title: 'Notificaciones push',
                value: pushNotifications,
                onChanged: (v) => setState(() => pushNotifications = v),
              ),
              _SwitchTile(
                title: 'Sonido al escanear QR',
                value: qrScannerSound,
                onChanged: (v) => setState(() => qrScannerSound = v),
              ),
              const SizedBox(height: 12),
              BlackButton(
                label: 'Guardar cambios',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Configuración guardada (stub)')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// -------------------- Helpers / Models internos --------------------

class _AdminModule {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final String requiredPermission;
  _AdminModule({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredPermission,
  });
}

class _GradeItem {
  final String name;
  final List<String> sections;
  _GradeItem(this.name, {required this.sections});
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(
      {required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          Switch(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: Colors.black,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.black26,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Iniciales para avatar
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final take = parts.length >= 2 ? parts.take(2) : parts.take(1);
  return take.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
}
