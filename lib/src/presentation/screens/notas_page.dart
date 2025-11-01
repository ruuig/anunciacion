import 'package:anunciacion/src/presentation/screens/activities_manager.dart';
import 'package:flutter/material.dart';
import '../widgets/widgets.dart';
import '../widgets/grades_tab_body.dart';

class NotasPage extends StatefulWidget {
  final String userRole; // 'Docente' | 'Secretaria'
  final List<String> assignedGrades; // p.ej. ['3ro Primaria','4to Primaria']
  const NotasPage(
      {super.key, required this.userRole, this.assignedGrades = const []});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

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

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.userRole == 'Docente';
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
        title: Text(
          isTeacher ? 'Gestión Académica' : 'Calificaciones',
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
        ),
        bottom: SegmentedTabs(
            labels: const ['Calificaciones', 'Actividades'], controller: _tab),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          GradesTabBody(
              userRole: widget.userRole, assignedGrades: widget.assignedGrades),
          ActivitiesTabBody(
              userRole: widget.userRole, assignedGrades: widget.assignedGrades),
        ],
      ),
    );
  }
}
