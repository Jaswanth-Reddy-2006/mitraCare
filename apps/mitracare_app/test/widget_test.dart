import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitracare_app/main.dart';
import 'package:mitracare_app/features/patient/patient_providers.dart';
import 'package:mitracare_app/features/patient/patient_repository.dart';
import 'package:mitracare_app/features/patient/activities_screen.dart';
import 'package:mitracare_app/features/patient/my_day_screen.dart';
import 'package:mitracare_app/features/patient/reminders_screen.dart';
import 'package:mitracare_app/features/patient/help_screen.dart';

class FakeActivityRepository implements ActivityRepository {
  @override
  Future<List<dynamic>> getActivities() async => [
        {
          "id": "1",
          "title": "Remember Pictures",
          "description": "Look, remember and recall",
          "icon": "image",
          "difficulty": "MEDIUM",
          "estimated_duration": 300,
          "language": "en",
          "is_active": true
        }
      ];

  @override
  Future<List<dynamic>> getHistory() async => [];

  @override
  Future<Map<String, dynamic>> startSession(String activityId, {String? difficulty}) async => {"id": "session_123"};

  @override
  Future<Map<String, dynamic>> submitResult({
    required String sessionId,
    required int score,
    required double accuracy,
    int? responseTime,
    int mistakes = 0,
    int hintsUsed = 0,
    String? metadata,
  }) async => {"id": "result_123"};
}

class FakeDailyTaskRepository implements DailyTaskRepository {
  @override
  Future<List<dynamic>> getMyDay(String dateStr) async => [
        {
          "id": "task_1",
          "title": "Drink Water",
          "scheduled_time": "10:30",
          "status": "PENDING",
          "task_type": "HYDRATION"
        }
      ];

  @override
  Future<Map<String, dynamic>> completeTask(String taskId) async => {};
  @override
  Future<Map<String, dynamic>> skipTask(String taskId) async => {};
  @override
  Future<Map<String, dynamic>> snoozeTask(String taskId) async => {};
}

class FakeReminderRepository implements ReminderRepository {
  @override
  Future<List<dynamic>> getRemindersForToday() async => [
        {
          "id": "rem_1",
          "title": "Morning Medicine",
          "type": "MEDICINE",
          "scheduled_at": "2026-08-28T09:00:00Z",
          "status": "PENDING",
          "is_active": true
        }
      ];

  @override
  Future<Map<String, dynamic>> completeReminder(String reminderId) async => {};
  @override
  Future<Map<String, dynamic>> snoozeReminder(String reminderId) async => {};
}

void main() {
  testWidgets('MitraCare app runs smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MitraCareApp(),
      ),
    );
    expect(find.text('MitraCare'), findsOneWidget);
  });

  testWidgets('ActivitiesScreen mounts and loads activities list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activityRepositoryProvider.overrideWithValue(FakeActivityRepository()),
        ],
        child: const MaterialApp(home: ActivitiesScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Play Game'), findsOneWidget);
    expect(find.text('Remember Pictures'), findsOneWidget);
  });

  testWidgets('MyDayScreen mounts and loads daily schedule tasks', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyTaskRepositoryProvider.overrideWithValue(FakeDailyTaskRepository()),
        ],
        child: const MaterialApp(home: MyDayScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Day'), findsOneWidget);
    expect(find.text('Drink Water'), findsOneWidget);
  });

  testWidgets('RemindersScreen mounts and displays list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reminderRepositoryProvider.overrideWithValue(FakeReminderRepository()),
        ],
        child: const MaterialApp(home: RemindersScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Morning Medicine'), findsOneWidget);
  });

  testWidgets('HelpScreen mounts and shows caregiver dials', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HelpScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Help'), findsNWidgets(2));
    expect(find.text('Call My Caregiver'), findsOneWidget);
    
    // Scroll down to reveal Voice Help button
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    
    expect(find.text('Voice Help'), findsOneWidget);
  });
}
