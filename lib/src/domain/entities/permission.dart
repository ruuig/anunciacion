// Entidad Permission (Permiso)
import 'package:equatable/equatable.dart';

class Permission extends Equatable {
  final int id;
  final String code;
  final String module;
  final String description;
  final DateTime createdAt;

  const Permission({
    required this.id,
    required this.code,
    required this.module,
    required this.description,
    required this.createdAt,
  });

  // Constructor para crear un nuevo permiso (sin ID)
  factory Permission.create({
    required String code,
    required String module,
    required String description,
  }) {
    return Permission(
      id: 0, // ID temporal, se asignará en la base de datos
      code: code,
      module: module,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, code, module, description, createdAt];

  @override
  String toString() => 'Permission(id: $id, code: $code, module: $module)';
}
