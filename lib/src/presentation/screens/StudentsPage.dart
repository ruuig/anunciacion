import 'package:flutter/material.dart';
import '../widgets/app_card.dart';
import '../widgets/select_field.dart';
import '../widgets/input_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/black_button.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  // Catálogos (conéctalo a tu backend)
  final grades = const [
    '1ro Primaria',
    '2do Primaria',
    '3ro Primaria',
    '4to Primaria',
    '5to Primaria',
    '6to Primaria'
  ];
  final sections = const ['A', 'B', 'C'];

  // Filtros
  String? selectedGrade;
  String? selectedSection;
  String? searchName; // input de texto

  // Mock de estudiantes (conecta a tu repo)
  final List<Student> _all = [
    Student(
      id: 1,
      cui: '1234567890101',
      nombre: 'Ana María López',
      fechaNacimiento: DateTime(2015, 3, 10),
      genero: 'Femenino',
      direccion: 'Col. San Miguel #34',
      telefono: '5551-2233',
      email: 'ana.lopez@mail.com',
      grado: '3ro Primaria',
      seccion: 'A',
      fechaInscripcion: DateTime(2024, 1, 5),
      estado: 'activo',
      madreNombre: 'María López',
      madreTelefono: '5556-7788',
      padreNombre: 'Carlos López',
      padreTelefono: '5559-9911',
      encargadoNombre: 'Tía: Sofía García',
      encargadoTelefono: '5550-1122',
    ),
    Student(
      id: 2,
      cui: '1234567890202',
      nombre: 'Carlos Roberto Méndez',
      fechaNacimiento: DateTime(2014, 11, 22),
      genero: 'Masculino',
      direccion: 'Res. Primavera Casa 12',
      telefono: '5552-3344',
      email: 'carlos.mendez@mail.com',
      grado: '3ro Primaria',
      seccion: 'A',
      fechaInscripcion: DateTime(2024, 1, 5),
      estado: 'activo',
      madreNombre: 'Elena Méndez',
      madreTelefono: '5557-8899',
      padreNombre: 'Roberto Méndez',
      padreTelefono: '5553-7788',
      encargadoNombre: 'Abuela: Carmen Ruiz',
      encargadoTelefono: '5558-6677',
    ),
    Student(
      id: 3,
      cui: '1234567890303',
      nombre: 'María José Hernández',
      fechaNacimiento: DateTime(2015, 6, 3),
      genero: 'Femenino',
      direccion: 'Barrio Centro 5-44',
      telefono: '5554-5566',
      email: 'maria.hdz@mail.com',
      grado: '4to Primaria',
      seccion: 'B',
      fechaInscripcion: DateTime(2024, 1, 7),
      estado: 'activo',
      madreNombre: 'Sandra Hernández',
      madreTelefono: '5556-0099',
      padreNombre: '—',
      padreTelefono: '—',
      encargadoNombre: 'Hermana: Luisa Hernández',
      encargadoTelefono: '5552-7788',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrado
    final filtered = _all.where((s) {
      final okGrade = selectedGrade == null || s.grado == selectedGrade;
      final okSection = selectedSection == null || s.seccion == selectedSection;
      final q = (searchName ?? '').trim().toLowerCase();
      final okName = q.isEmpty || s.nombre.toLowerCase().contains(q);
      return okGrade && okSection && okName;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: .5,
        title: const Text(
          'Estudiantes',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Filtros
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Filtros',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SelectField<String>(
                          label: 'Grado',
                          placeholder: 'Todos los grados',
                          value: selectedGrade ?? '',
                          items: [''] + grades,
                          itemLabel: (v) => v.isEmpty ? 'Todos' : v,
                          onSelected: (v) => setState(
                              () => selectedGrade = v.isEmpty ? null : v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SelectField<String>(
                          label: 'Sección',
                          placeholder: selectedGrade == null
                              ? 'Selecciona un grado'
                              : 'Todas las secciones',
                          value: selectedSection ?? '',
                          items: selectedGrade == null ? [''] : [''] + sections,
                          itemLabel: (v) => v.isEmpty ? 'Todas' : v,
                          onSelected: (v) => setState(
                              () => selectedSection = v.isEmpty ? null : v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InputField(
                    label: 'Nombre',
                    hintText: 'Buscar por nombre…',
                    icon: Icons.search,
                    onChanged: (v) => setState(() => searchName = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista
            if (filtered.isEmpty)
              const EmptyState(
                title: 'Sin resultados',
                description: 'Ajusta los filtros o intenta con otro nombre.',
                icon: Icon(Icons.person_search_rounded,
                    size: 48, color: Colors.black45),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final s = filtered[i];
                  return GestureDetector(
                    onDoubleTap: () => _openStudentDetail(s),
                    child: AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xFFEFF4FF),
                            child: Text(
                              _initials(s.nombre),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre grande (evita overflow)
                                Text(
                                  s.nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${s.grado}  •  Sección ${s.seccion}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                // CUI o teléfono breve
                                Text(
                                  s.cui,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.black38),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStudentDetail(Student s) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _StudentDetailSheet(student: s),
      ),
    );
  }
}

/// Modelo simple (ajústalo a tu entidad real)
class Student {
  final int id;
  final String cui;
  final String nombre;
  final DateTime fechaNacimiento;
  final String genero;
  final String direccion;
  final String telefono;
  final String email;
  final String grado;
  final String seccion;
  final DateTime fechaInscripcion;
  final String estado;

  // Contactos importantes (papás/encargado)
  final String madreNombre;
  final String madreTelefono;
  final String padreNombre;
  final String padreTelefono;
  final String encargadoNombre;
  final String encargadoTelefono;

  Student({
    required this.id,
    required this.cui,
    required this.nombre,
    required this.fechaNacimiento,
    required this.genero,
    required this.direccion,
    required this.telefono,
    required this.email,
    required this.grado,
    required this.seccion,
    required this.fechaInscripcion,
    required this.estado,
    required this.madreNombre,
    required this.madreTelefono,
    required this.padreNombre,
    required this.padreTelefono,
    required this.encargadoNombre,
    required this.encargadoTelefono,
  });
}

// ------------- MODAL DETALLE -------------
class _StudentDetailSheet extends StatelessWidget {
  final Student student;
  const _StudentDetailSheet({required this.student});

  @override
  Widget build(BuildContext context) {
    final edad = _edad(student.fechaNacimiento);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEFF4FF),
                child: Text(_initials(student.nombre),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, color: Colors.black)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  student.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Datos académicos y básicos
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Información General',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _InfoRow(label: 'CUI', value: student.cui),
                _InfoRow(
                    label: 'Grado / Sección',
                    value: '${student.grado}  •  ${student.seccion}'),
                _InfoRow(
                    label: 'Edad / Género',
                    value: '$edad años  •  ${student.genero}'),
                _InfoRow(label: 'Estado', value: student.estado),
              ],
            ),
          ),
          const SizedBox(height: 12),

          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contacto y Dirección',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _InfoRow(label: 'Dirección', value: student.direccion),
                _InfoRow(label: 'Teléfono', value: student.telefono),
                _InfoRow(label: 'Email', value: student.email),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 👨‍👩‍👧 Contactos de padres/encargado (lo más importante para llamar)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Contactos Familiares',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                _ContactLine(
                    title: 'Madre',
                    name: student.madreNombre,
                    phone: student.madreTelefono),
                const Divider(height: 18),
                _ContactLine(
                    title: 'Padre',
                    name: student.padreNombre,
                    phone: student.padreTelefono),
                const Divider(height: 18),
                _ContactLine(
                    title: 'Encargado',
                    name: student.encargadoNombre,
                    phone: student.encargadoTelefono),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Acción principal (si quisieras navegar a edición o ver historial)
          BlackButton(
            label: 'Cerrar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ---------- helpers visuales ----------
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  final String title;
  final String name;
  final String phone;
  const _ContactLine(
      {required this.title, required this.name, required this.phone});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(phone,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ],
          ),
        ),
        // Botones de acción (llamar / WhatsApp)
        Row(
          children: [
            _CircleIconButton(
                icon: Icons.call_rounded,
                onTap: () {/* TODO: launchUrl tel:phone */}),
            const SizedBox(width: 8),
            _CircleIconButton(
                icon: Icons.message_rounded,
                onTap: () {/* TODO: launchUrl wa.me/ */}),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 24,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

// ---------- util ----------
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  final take = parts.length >= 2 ? parts.take(2) : parts.take(1);
  return take.map((p) => p.isNotEmpty ? p[0] : '').join().toUpperCase();
}

int _edad(DateTime birth) {
  final now = DateTime.now();
  var years = now.year - birth.year;
  final m = now.month - birth.month;
  if (m < 0 || (m == 0 && now.day < birth.day)) years--;
  return years;
}
