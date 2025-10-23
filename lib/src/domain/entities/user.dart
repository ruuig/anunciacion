// Entidad User (Usuario)
import 'package:equatable/equatable.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';

class User extends Equatable {
  final int id;
  final String name;
  final String username;
  final Password passwordHash;
  final Phone? phone;
  final int roleId;
  final UserStatus status;
  final String? avatarUrl;
  final DateTime? lastAccess;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.passwordHash,
    this.phone,
    required this.roleId,
    required this.status,
    this.avatarUrl,
    this.lastAccess,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor para crear un nuevo usuario
  factory User.create({
    required String name,
    required String username,
    required String plainPassword,
    Phone? phone,
    required int roleId,
    String? avatarUrl,
  }) {
    return User(
      id: 0, // ID temporal
      name: name,
      username: username,
      passwordHash: Password.fromPlainText(plainPassword),
      phone: phone,
      roleId: roleId,
      status: const UserStatus(UserStatusValue.activo),
      avatarUrl: avatarUrl,
      lastAccess: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Método para verificar contraseña
  bool verifyPassword(String plainPassword) {
    return passwordHash.verify(plainPassword);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        passwordHash,
        phone,
        roleId,
        status,
        avatarUrl,
        lastAccess,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'User(id: $id, username: $username, roleId: $roleId)';
}
