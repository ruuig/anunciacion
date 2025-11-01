import 'package:flutter/material.dart';

class PaymentUploadPage extends StatefulWidget {
  final String grade;
  final List<Map<String, dynamic>> students;
  final void Function(Map<String, dynamic> student, Map<String, dynamic>)
      onUploaded;

  const PaymentUploadPage({
    super.key,
    required this.grade,
    required this.students,
    required this.onUploaded,
  });

  @override
  State<PaymentUploadPage> createState() => _PaymentUploadPageState();
}

class _PaymentUploadPageState extends State<PaymentUploadPage> {
  Map<String, dynamic>? _selectedStudent;
  String _month = 'Octubre 2025';
  final _amountCtrl = TextEditingController(text: '350');
  String? _pickedFileName;

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

  void _fakePickFile() async {
    // aquí en real usas file_picker
    setState(() {
      _pickedFileName = 'comprobante_123.jpg';
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'Subir comprobante',
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
            'Grado: ${widget.grade}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          const Text('Alumno', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedStudent,
            items: widget.students
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
          const SizedBox(height: 14),
          const Text('Comprobante',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _fakePickFile,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.upload_file_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _pickedFileName ?? 'Tocar para seleccionar archivo',
                      style: TextStyle(
                        color: _pickedFileName == null
                            ? Colors.black54
                            : Colors.black,
                        fontWeight: _pickedFileName == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
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
          label: const Text('Asignar comprobante',
              style: TextStyle(fontWeight: FontWeight.w700)),
          onPressed: () {
            if (_selectedStudent == null) return;
            widget.onUploaded(_selectedStudent!, {
              'month': _month,
              'amount': double.tryParse(_amountCtrl.text) ?? 0.0,
              'fileName': _pickedFileName,
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
