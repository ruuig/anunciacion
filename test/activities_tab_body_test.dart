import 'package:anunciacion/src/presentation/widgets/activities_tab_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calculates progress correctly for 14 of 28 students',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: ActivitiesTabBody(
          userRole: 'teacher',
          assignedGrades: [],
        ),
      ),
    ));

    final state = tester.state(find.byType(ActivitiesTabBody)) as dynamic;

    state.setState(() {
      state.activities = [
        {
          'name': 'Test Activity',
          'subject': 'Math',
          'grade': '1st Grade',
          'section': 'A',
          'period': 'First',
          'type': 'Exam',
          'points': 10,
          'date': '2025-01-01',
          'status': 'completed',
          'studentsGraded': 14,
          'totalStudents': 28,
          'averageGrade': 90.0,
        },
      ];
    });

    await tester.pump();

    final progressIndicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator).first,
    );

    expect(progressIndicator.value, closeTo(0.5, 0.0001));
  });
}
