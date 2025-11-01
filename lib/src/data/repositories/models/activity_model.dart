import 'package:anunciacion/src/domain/entities/activity.dart';

class ActivityModel extends Activity {
  ActivityModel({
    required super.id,
    required super.name,
    required super.subject,
    required super.grade,
    required super.section,
    required super.period,
    required super.type,
    required super.points,
    required super.date,
    required super.status,
    required super.studentsGraded,
    required super.totalStudents,
    super.averageGrade,
    super.isGroupWork,
    super.description,
    super.groups,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id'],
      name: json['name'],
      subject: json['subject'],
      grade: json['grade'],
      section: json['section'],
      period: json['period'],
      type: json['type'],
      points: json['points'],
      date: DateTime.parse(json['date']),
      status: json['status'],
      studentsGraded: json['studentsGraded'],
      totalStudents: json['totalStudents'],
      averageGrade: json['averageGrade']?.toDouble(),
      isGroupWork: json['isGroupWork'] ?? false,
      description: json['description'],
      groups: (json['groups'] as List?)
              ?.map((g) => ActivityGroup(
                    name: g['name'],
                    members: List<String>.from(g['members']),
                    grade: (g['grade'] as num?)?.toDouble(),
                  ))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subject': subject,
      'grade': grade,
      'section': section,
      'period': period,
      'type': type,
      'points': points,
      'date': date.toIso8601String(),
      'status': status,
      'studentsGraded': studentsGraded,
      'totalStudents': totalStudents,
      'averageGrade': averageGrade,
      'isGroupWork': isGroupWork,
      'description': description,
      'groups': groups
          .map((g) => {
                'name': g.name,
                'members': g.members,
                'grade': g.grade,
              })
          .toList(),
    };
  }
}
