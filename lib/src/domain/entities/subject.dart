// Entidad Subject (Materia)
import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final bool active;
  final DateTime createdAt;
  final List<Map<String, dynamic>>? teachers; // Docentes asignados

  const Subject({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.active,
    required this.createdAt,
    this.teachers,
  });

  // Constructor para crear una nueva materia
  factory Subject.create({
    required String name,
    String? code,
    String? description,
  }) {
    return Subject(
      id: 0, // ID temporal
      name: name,
      code: code,
      description: description,
      active: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props =>
      [id, name, code, description, active, createdAt, teachers];

  @override
  String toString() => 'Subject(id: $id, name: $name, code: $code)';
}
