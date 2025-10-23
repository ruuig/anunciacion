// Value Object para DPI (Documento Personal de Identificación)
import 'package:equatable/equatable.dart';

class DPI extends Equatable {
  final String value;

  const DPI(this.value);

  // Validación básica de DPI guatemalteco (13 dígitos)
  factory DPI.fromString(String value) {
    if (value.length != 13 || !RegExp(r'^\d{13}$').hasMatch(value)) {
      throw ArgumentError('DPI debe tener 13 dígitos numéricos');
    }
    return DPI(value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
