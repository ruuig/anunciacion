class Attendance {
  final int id;
  final int studentId;
  final String studentCode; // A123BCY
  final String studentName;
  final int gradeId;
  final String gradeName;
  final int sectionId;
  final String sectionName;
  final DateTime date;
  final DateTime? entryTime;
  final DateTime? exitTime;
  final String status; // 'present', 'absent', 'late', 'excused'

  Attendance({
    required this.id,
    required this.studentId,
    required this.studentCode,
    required this.studentName,
    required this.gradeId,
    required this.gradeName,
    required this.sectionId,
    required this.sectionName,
    required this.date,
    this.entryTime,
    this.exitTime,
    required this.status,
  });

  Attendance copyWith({
    int? id,
    int? studentId,
    String? studentCode,
    String? studentName,
    int? gradeId,
    String? gradeName,
    int? sectionId,
    String? sectionName,
    DateTime? date,
    DateTime? entryTime,
    DateTime? exitTime,
    String? status,
  }) {
    return Attendance(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentCode: studentCode ?? this.studentCode,
      studentName: studentName ?? this.studentName,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      sectionId: sectionId ?? this.sectionId,
      sectionName: sectionName ?? this.sectionName,
      date: date ?? this.date,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      status: status ?? this.status,
    );
  }
}
