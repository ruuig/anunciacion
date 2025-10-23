// Value Object para Estado de Usuario
import 'package:equatable/equatable.dart';

enum UserStatusValue { activo, inactivo, suspendido }

class UserStatus extends Equatable {
  final UserStatusValue value;

  const UserStatus(this.value);

  factory UserStatus.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'activo':
        return const UserStatus(UserStatusValue.activo);
      case 'inactivo':
        return const UserStatus(UserStatusValue.inactivo);
      case 'suspendido':
        return const UserStatus(UserStatusValue.suspendido);
      default:
        throw ArgumentError('Estado de usuario inválido: $value');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() {
    switch (value) {
      case UserStatusValue.activo:
        return 'activo';
      case UserStatusValue.inactivo:
        return 'inactivo';
      case UserStatusValue.suspendido:
        return 'suspendido';
    }
  }
}
