// Entidad Student (Estudiante)
import 'package:equatable/equatable.dart';
import 'package:anunciacion/src/domain/value_objects/value_objects.dart';

class Student extends Equatable {
  final int id;
  final String? codigo;
  final DPI dpi;
  final String name;
  final DateTime birthDate;
  final Gender? gender;
  final Address? address;
  final Phone? phone;
  final Email? email;
  final String? avatarUrl;
  final int gradeId;
  final int sectionId;
  final DateTime enrollmentDate;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    this.codigo,
    required this.dpi,
    required this.name,
    required this.birthDate,
    this.gender,
    this.address,
    this.phone,
    this.email,
    this.avatarUrl,
    required this.gradeId,
    required this.sectionId,
    required this.enrollmentDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor para crear un nuevo estudiante
  factory Student.create({
    String? codigo,
    required DPI dpi,
    required String name,
    required DateTime birthDate,
    Gender? gender,
    Address? address,
    Phone? phone,
    Email? email,
    String? avatarUrl,
    required int gradeId,
    required int sectionId,
  }) {
    return Student(
      id: 0, // ID temporal
      codigo: codigo,
      dpi: dpi,
      name: name,
      birthDate: birthDate,
      gender: gender,
      address: address,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
      gradeId: gradeId,
      sectionId: sectionId,
      enrollmentDate: DateTime.now(),
      status: const UserStatus(UserStatusValue.activo),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Calcular edad del estudiante
  int get age {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [
        id,
        codigo,
        dpi,
        name,
        birthDate,
        gender,
        address,
        phone,
        email,
        avatarUrl,
        gradeId,
        sectionId,
        enrollmentDate,
        status,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Student(id: $id, name: $name, dpi: $dpi)';
}
