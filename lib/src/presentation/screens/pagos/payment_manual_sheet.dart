import 'package:flutter/material.dart';

class PaymentManualPage extends StatefulWidget {
  final String grade;
  final String section;
  final List<Map<String, dynamic>> students;
  final void Function(Map<String, dynamic> student, Map<String, dynamic>)
      onSaved;

  const PaymentManualPage({
    super.key,
    required this.grade,
    required this.section,
    required this.students,
    required this.onSaved,
  });

  @override
  State<PaymentManualPage> createState() => _PaymentManualPageState();
}

class _PaymentManualPageState extends State<PaymentManualPage> {
  Map<String, dynamic>? _selectedStudent;
  final _amountCtrl = TextEditingController(text: '350');
  final _refCtrl = TextEditingController();
  String _month = 'Octubre 2025';

  final _months = const [
    'Enero 2025',
    'Febrero 2025',
    'Marzo 2025',
    'Abril 2025',
    'Mayo 2025',
    'Junio 2025',
    'Julio 2025',
    'Agosto 2025',
    'Septiembre 2025',
    'Octubre 2025',
    'Noviembre 2025',
    'Diciembre 2025',
  ];

  @override
  Widget build(BuildContext context) {
    // filtrar por grado y sección
    final filteredStudents = widget.students.where((s) {
      final sGrade = (s['grade'] ?? '').toString();
      final sSection = (s['section'] ?? '').toString();
      return sGrade == widget.grade && sSection == widget.section;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
        ),
        title: const Text(
          'Pago manual',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Grado: ${widget.grade} • Sección: ${widget.section}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text('Alumno', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedStudent,
            items: filteredStudents
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(s['name']),
                  ),
                )
                .toList(),
            decoration: _input(),
            onChanged: (v) => setState(() => _selectedStudent = v),
          ),
          const SizedBox(height: 12),
          if (filteredStudents.isNotEmpty) ...[
            const Text(
              'O elige de la lista',
              style:
                  TextStyle(fontWeight: FontWeight.w700, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ...filteredStudents.map((s) {
              final isSelected = _selectedStudent != null &&
                  _selectedStudent!['id'] == s['id'];
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedStudent = s);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: isSelected ? Colors.black : Colors.black12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.black,
                        child: Text(
                          s['name'].toString().substring(0, 1),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s['name'],
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            size: 18, color: Colors.black),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            const Text(
              'No hay alumnos para este grado y sección.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Mes / periodo',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _month,
            items: _months
                .map(
                  (m) => DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  ),
                )
                .toList(),
            decoration: _input(),
            onChanged: (v) => setState(() => _month = v ?? _month),
          ),
          const SizedBox(height: 12),
          const Text('Monto', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _input().copyWith(prefixText: 'Q '),
          ),
          const SizedBox(height: 12),
          const Text('Referencia / Nota (opcional)',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(
            controller: _refCtrl,
            decoration: _input().copyWith(
              hintText: 'No. boleta / banco / nota',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Guardar pago',
              style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () {
            if (_selectedStudent == null) return;
            widget.onSaved(_selectedStudent!, {
              'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
              'month': _month,
              'reference': _refCtrl.text.trim(),
              'grade': widget.grade,
              'section': widget.section,
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  InputDecoration _input() => InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}
