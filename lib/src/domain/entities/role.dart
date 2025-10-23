// Entidad Role (Rol de usuario)
import 'package:equatable/equatable.dart';

class Role extends Equatable {
  final int id;
  final String name;
  final String description;
  final int level;
  final DateTime createdAt;

  const Role({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.createdAt,
  });

  // Constructor para crear un nuevo rol (sin ID)
  factory Role.create({
    required String name,
    required String description,
    required int level,
  }) {
    return Role(
      id: 0, // ID temporal, se asignará en la base de datos
      name: name,
      description: description,
      level: level,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, level, createdAt];

  @override
  String toString() => 'Role(id: $id, name: $name, level: $level)';
}
