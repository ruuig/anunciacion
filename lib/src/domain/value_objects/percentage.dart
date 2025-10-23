// Value Object para Porcentaje
import 'package:equatable/equatable.dart';

class Percentage extends Equatable {
  final double value;

  const Percentage(this.value);

  factory Percentage.fromDouble(double value) {
    if (value < 0 || value > 100) {
      throw ArgumentError('El porcentaje debe estar entre 0 y 100');
    }
    return Percentage(value);
  }

  Percentage operator +(Percentage other) {
    return Percentage.fromDouble(value + other.value);
  }

  Percentage operator -(Percentage other) {
    return Percentage.fromDouble(value - other.value);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => '${value.toStringAsFixed(2)}%';
}
