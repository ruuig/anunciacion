class Activity {
  final int id;
  final String name;
  final String subject;
  final String grade;
  final String section;
  final String period;
  final String type;
  final int points;
  final DateTime date;
  final String status;
  final int studentsGraded;
  final int totalStudents;
  final double? averageGrade;
  final bool isGroupWork;
  final String? description;
  final List<ActivityGroup> groups;

  Activity({
    required this.id,
    required this.name,
    required this.subject,
    required this.grade,
    required this.section,
    required this.period,
    required this.type,
    required this.points,
    required this.date,
    required this.status,
    required this.studentsGraded,
    required this.totalStudents,
    this.averageGrade,
    this.isGroupWork = false,
    this.description,
    this.groups = const [],
  });

  Activity copyWith({
    int? id,
    String? name,
    String? subject,
    String? grade,
    String? section,
    String? period,
    String? type,
    int? points,
    DateTime? date,
    String? status,
    int? studentsGraded,
    int? totalStudents,
    double? averageGrade,
    bool? isGroupWork,
    String? description,
    List<ActivityGroup>? groups,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      period: period ?? this.period,
      type: type ?? this.type,
      points: points ?? this.points,
      date: date ?? this.date,
      status: status ?? this.status,
      studentsGraded: studentsGraded ?? this.studentsGraded,
      totalStudents: totalStudents ?? this.totalStudents,
      averageGrade: averageGrade ?? this.averageGrade,
      isGroupWork: isGroupWork ?? this.isGroupWork,
      description: description ?? this.description,
      groups: groups ?? this.groups,
    );
  }
}

class ActivityGroup {
  final String name;
  final List<String> members;
  final double? grade; // en puntos

  ActivityGroup({
    required this.name,
    required this.members,
    this.grade,
  });

  ActivityGroup copyWith({
    String? name,
    List<String>? members,
    double? grade,
  }) {
    return ActivityGroup(
      name: name ?? this.name,
      members: members ?? this.members,
      grade: grade,
    );
  }
}
