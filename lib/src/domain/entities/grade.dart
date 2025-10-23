// Entidad Grade (Grado)
import 'package:equatable/equatable.dart';

class Grade extends Equatable {
  final int id;
  final String name;
  final int educationalLevelId;
  final String? ageRange;
  final String academicYear;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Grade({
    required this.id,
    required this.name,
    required this.educationalLevelId,
    this.ageRange,
    required this.academicYear,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor para crear un nuevo grado
  factory Grade.create({
    required String name,
    required int educationalLevelId,
    String? ageRange,
    required String academicYear,
  }) {
    return Grade(
      id: 0, // ID temporal
      name: name,
      educationalLevelId: educationalLevelId,
      ageRange: ageRange,
      academicYear: academicYear,
      active: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        educationalLevelId,
        ageRange,
        academicYear,
        active,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'Grade(id: $id, name: $name, year: $academicYear)';
}
