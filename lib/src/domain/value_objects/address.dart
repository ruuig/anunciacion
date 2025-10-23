// Value Object para Dirección
import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'Guatemala',
  });

  factory Address.fromString(String address) {
    // Formato básico: "Calle, Ciudad, Departamento, Código Postal"
    final parts = address.split(',').map((s) => s.trim()).toList();

    if (parts.length < 3) {
      throw ArgumentError('Formato de dirección inválido. Use: Calle, Ciudad, Departamento, Código Postal');
    }

    return Address(
      street: parts[0],
      city: parts[1],
      state: parts[2],
      zipCode: parts.length > 3 ? parts[3] : '',
    );
  }

  @override
  List<Object?> get props => [street, city, state, zipCode, country];

  @override
  String toString() => '$street, $city, $state $zipCode, $country';
}
