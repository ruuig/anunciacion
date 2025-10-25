/// Student with grade information for display purposes
class StudentWithGrade {
  final int id;
  final String name;
  final double? grade;

  const StudentWithGrade({
    required this.id,
    required this.name,
    this.grade,
  });

  StudentWithGrade copyWith({double? grade}) =>
      StudentWithGrade(id: id, name: name, grade: grade ?? this.grade);
}
