// Entidad Section (Sección)
import 'package:equatable/equatable.dart';

class Section extends Equatable {
  final int id;
  final int gradeId;
  final String name;
  final int? capacity;
  final int studentCount;
  final bool active;
  final DateTime createdAt;

  const Section({
    required this.id,
    required this.gradeId,
    required this.name,
    this.capacity,
    required this.studentCount,
    required this.active,
    required this.createdAt,
  });

  // Constructor para crear una nueva sección
  factory Section.create({
    required int gradeId,
    required String name,
    int? capacity,
  }) {
    return Section(
      id: 0, // ID temporal
      gradeId: gradeId,
      name: name,
      capacity: capacity,
      studentCount: 0,
      active: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        gradeId,
        name,
        capacity,
        studentCount,
        active,
        createdAt,
      ];

  @override
  String toString() => 'Section(id: $id, name: $name, gradeId: $gradeId)';
}
