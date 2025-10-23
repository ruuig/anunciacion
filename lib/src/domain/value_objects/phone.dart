// Value Object para Teléfono
import 'package:equatable/equatable.dart';

class Phone extends Equatable {
  final String value;

  const Phone(this.value);

  factory Phone.fromString(String value) {
    // Remover espacios, guiones y paréntesis
    String cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Validar que sea un número de teléfono guatemalteco válido
    if (!RegExp(r'^(\+502)?[2-7]\d{7}$').hasMatch(cleanPhone)) {
      throw ArgumentError('Número de teléfono inválido para Guatemala');
    }

    // Si no tiene código de país, agregarlo
    if (!cleanPhone.startsWith('+502')) {
      cleanPhone = '+502$cleanPhone';
    }

    return Phone(cleanPhone);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
