// Value Object para Género
import 'package:equatable/equatable.dart';

enum GenderValue { masculino, femenino, otro }

class Gender extends Equatable {
  final GenderValue value;

  const Gender(this.value);

  factory Gender.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'masculino':
      case 'm':
        return const Gender(GenderValue.masculino);
      case 'femenino':
      case 'f':
        return const Gender(GenderValue.femenino);
      case 'otro':
        return const Gender(GenderValue.otro);
      default:
        throw ArgumentError('Género inválido: $value');
    }
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() {
    switch (value) {
      case GenderValue.masculino:
        return 'masculino';
      case GenderValue.femenino:
        return 'femenino';
      case GenderValue.otro:
        return 'otro';
    }
  }
}
