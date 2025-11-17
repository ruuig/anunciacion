import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import 'usuarios/create_edit_user_page.dart';
import 'grados/grades_subjects_management_page.dart';
import 'estudiantes/create_edit_student_page.dart';
import 'padres/create_edit_parent_page.dart';
import '../../infrastructure/http/http_user_repository.dart';
import '../../infrastructure/repositories/http_student_repository.dart';
import '../../infrastructure/repositories/http_grade_repository.dart';
import '../../infrastructure/repositories/http_section_repository.dart';
import '../../infrastructure/repositories/http_parent_repository.dart';
import '../../domain/entities/entities.dart';

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
      id: 'parent_admin',
      title: 'Administrar Padres',
      description: 'Gestionar padres y encargados',
      icon: Icons.family_restroom_outlined,
      color: const Color(0xFFEA580C), // naranja
      requiredPermission: 'edit_students',
    ),
  ];

  bool _hasPermission(String p) =>
      widget.user.permissions.contains(p) ||
      widget.user.permissions.contains('view_all');

  List<_AdminModule> get _available =>
      _modules.where((m) => _hasPermission(m.requiredPermission)).toList();

  void _goBackToDashboard() => setState(() => _active = 'dashboard');

  void _navigateToModule(BuildContext context, String moduleId) {
    Widget? page;
    switch (moduleId) {
      case 'users':
        // Abrir vista intermedia de administración de usuarios
        setState(() => _active = moduleId);
        return;
      case 'grades_config':
        page = const GradesSubjectsManagementPage();
        break;
      case 'student_admin':
        // Abrir vista intermedia de administración de estudiantes
        setState(() => _active = moduleId);
        return;
      case 'parent_admin':
        // Abrir vista intermedia de administración de padres
        setState(() => _active = moduleId);
        return;
    }
    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDashboard = _active == 'dashboard';
    final title = isDashboard ? 'Administración' : 'Configuración del Sistema';

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
                  onTap: () => _navigateToModule(context, m.id),
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
      case 'student_admin':
        return _StudentManagementView(onBack: _goBackToDashboard);
      case 'parent_admin':
        return _ParentManagementView(onBack: _goBackToDashboard);
      default:
        return _buildDashboard();
    }
  }
}

class _UsersManagementView extends StatefulWidget {
  final VoidCallback onBack;
  const _UsersManagementView({required this.onBack});

  @override
  State<_UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<_UsersManagementView> {
  final _userRepository = HttpUserRepository();

  List<User> _allUsers = [];
  String _searchName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final users = await _userRepository.findAll();

      setState(() {
        _allUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<User> get _filteredUsers {
    return _allUsers.where((user) {
      if (_searchName.isNotEmpty &&
          !user.name.toLowerCase().contains(_searchName.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
              InputField(
                label: 'Nombre',
                hintText: 'Buscar por nombre…',
                icon: Icons.search,
                onChanged: (v) => setState(() => _searchName = v),
              ),
              const SizedBox(height: 12),
              BlackButton(
                label: 'Nuevo Usuario',
                icon: Icons.add,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEditUserPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredUsers.isEmpty)
          const EmptyState(
            title: 'Sin usuarios',
            description: 'Ajusta los filtros o prueba otra búsqueda.',
            icon: Icon(Icons.person_search_outlined,
                size: 48, color: Colors.black45),
          )
        else
          ...(_filteredUsers.map((u) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(_initials(u.name),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(u.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(u.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateEditUserPage(initialUser: u),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Eliminar ${u.name} (stub)')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )))
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
  final _studentRepository = HttpStudentRepository();
  final _gradeRepository = HttpGradeRepository();
  final _sectionRepository = HttpSectionRepository();

  List<Student> _allStudents = [];
  List<Grade> _grades = [];
  List<Section> _sections = [];
  Grade? _selectedGrade;
  Section? _selectedSection;
  String _searchName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final grades = await _gradeRepository.findActiveGrades();
      final students = await _studentRepository.findAll();
      final sections = await _sectionRepository.findAll();

      setState(() {
        _grades = grades;
        _allStudents = students;
        _sections = sections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<Student> get _filteredStudents {
    return _allStudents.where((student) {
      if (_selectedGrade != null && student.gradeId != _selectedGrade!.id) {
        return false;
      }
      if (_selectedSection != null &&
          student.sectionId != _selectedSection!.id) {
        return false;
      }
      if (_searchName.isNotEmpty &&
          !student.name.toLowerCase().contains(_searchName.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SelectField<Grade?>(
                      label: 'Grado',
                      placeholder: 'Todos',
                      value: _selectedGrade,
                      items: [null, ..._grades],
                      itemLabel: (g) => g?.name ?? 'Todos',
                      onSelected: (v) {
                        setState(() {
                          _selectedGrade = v;
                          _selectedSection = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectField<Section?>(
                      label: 'Sección',
                      placeholder: 'Todas',
                      value: _selectedSection,
                      items: [null, ..._sections],
                      itemLabel: (s) => s?.name ?? 'Todas',
                      onSelected: (v) => setState(() => _selectedSection = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InputField(
                label: 'Nombre',
                hintText: 'Buscar por nombre…',
                icon: Icons.search,
                onChanged: (v) => setState(() => _searchName = v),
              ),
              const SizedBox(height: 12),
              BlackButton(
                label: 'Nuevo Estudiante',
                icon: Icons.add,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEditStudentPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredStudents.isEmpty)
          const EmptyState(
            title: 'Sin estudiantes',
            description: 'Ajusta los filtros o prueba otra búsqueda.',
            icon: Icon(Icons.person_search_outlined,
                size: 48, color: Colors.black45),
          )
        else
          ...(_filteredStudents.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(_initials(s.name),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(s.dpi.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEditStudentPage(student: s),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Eliminar ${s.name} (stub)')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )))
      ],
    );
  }
}

class _ParentManagementView extends StatefulWidget {
  final VoidCallback onBack;
  const _ParentManagementView({required this.onBack});

  @override
  State<_ParentManagementView> createState() => _ParentManagementViewState();
}

class _ParentManagementViewState extends State<_ParentManagementView> {
  final _parentRepository = HttpParentRepository();

  List<Parent> _allParents = [];
  String _searchName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final parents = await _parentRepository.findAll();

      setState(() {
        _allParents = parents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<Parent> get _filteredParents {
    return _allParents.where((parent) {
      if (_searchName.isNotEmpty &&
          !parent.name.toLowerCase().contains(_searchName.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('parents'),
      padding: const EdgeInsets.all(16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Padres y Encargados',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              InputField(
                label: 'Nombre',
                hintText: 'Buscar por nombre…',
                icon: Icons.search,
                onChanged: (v) => setState(() => _searchName = v),
              ),
              const SizedBox(height: 12),
              BlackButton(
                label: 'Nuevo Padre/Encargado',
                icon: Icons.add,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateEditParentPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredParents.isEmpty)
          const EmptyState(
            title: 'Sin padres',
            description: 'Ajusta los filtros o prueba otra búsqueda.',
            icon: Icon(Icons.person_search_outlined,
                size: 48, color: Colors.black45),
          )
        else
          ...(_filteredParents.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(_initials(p.name),
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.black)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(p.phone.value,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateEditParentPage(parent: p),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined,
                            color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Eliminar ${p.name} (stub)')),
                          );
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.black),
                      ),
                    ],
                  ),
                ),
              )))
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
