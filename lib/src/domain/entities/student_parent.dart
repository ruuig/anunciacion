// Entidad StudentParent (Relación Estudiante-Padre)
import 'package:equatable/equatable.dart';

class StudentParent extends Equatable {
  final int id;
  final int studentId;
  final int parentId;
  final bool isPrimaryContact;
  final bool isEmergencyContact;
  final DateTime createdAt;

  const StudentParent({
    required this.id,
    required this.studentId,
    required this.parentId,
    required this.isPrimaryContact,
    required this.isEmergencyContact,
    required this.createdAt,
  });

  // Constructor para crear una nueva relación
  factory StudentParent.create({
    required int studentId,
    required int parentId,
    bool isPrimaryContact = false,
    bool isEmergencyContact = false,
  }) {
    return StudentParent(
      id: 0, // ID temporal
      studentId: studentId,
      parentId: parentId,
      isPrimaryContact: isPrimaryContact,
      isEmergencyContact: isEmergencyContact,
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        studentId,
        parentId,
        isPrimaryContact,
        isEmergencyContact,
        createdAt,
      ];

  @override
  String toString() =>
      'StudentParent(studentId: $studentId, parentId: $parentId, primary: $isPrimaryContact)';
}
