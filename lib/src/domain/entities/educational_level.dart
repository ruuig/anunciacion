// Entidad EducationalLevel (Nivel Educativo)
import 'package:equatable/equatable.dart';

class EducationalLevel extends Equatable {
  final int id;
  final String name;
  final int order;
  final String? colorHex;
  final bool active;

  const EducationalLevel({
    required this.id,
    required this.name,
    required this.order,
    this.colorHex,
    required this.active,
  });

  // Constructor para crear un nuevo nivel educativo
  factory EducationalLevel.create({
    required String name,
    required int order,
    String? colorHex,
  }) {
    return EducationalLevel(
      id: 0, // ID temporal
      name: name,
      order: order,
      colorHex: colorHex,
      active: true,
    );
  }

  @override
  List<Object?> get props => [id, name, order, colorHex, active];

  @override
  String toString() => 'EducationalLevel(id: $id, name: $name, order: $order)';
}
