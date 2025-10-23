// Entidad Parent (Padre/Madre/Tutor)
import 'package:equatable/equatable.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';

class Parent extends Equatable {
  final int id;
  final DPI? dpi;
  final String name;
  final String relation;
  final Phone phone;
  final Phone? secondaryPhone;
  final Email? email;
  final Address? address;
  final String? occupation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parent({
    required this.id,
    this.dpi,
    required this.name,
    required this.relation,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.address,
    this.occupation,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor para crear un nuevo padre/tutor
  factory Parent.create({
    DPI? dpi,
    required String name,
    required String relation,
    required Phone phone,
    Phone? secondaryPhone,
    Email? email,
    Address? address,
    String? occupation,
  }) {
    return Parent(
      id: 0, // ID temporal
      dpi: dpi,
      name: name,
      relation: relation,
      phone: phone,
      secondaryPhone: secondaryPhone,
      email: email,
      address: address,
      occupation: occupation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        dpi,
        name,
        relation,
        phone,
        secondaryPhone,
        email,
        address,
        occupation,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Parent(id: $id, name: $name, relation: $relation)';
}
