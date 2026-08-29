import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitracare_app/features/caregiver/dashboard_screen.dart';
import 'package:mitracare_app/services/api_service.dart';

class FakeApiService extends ApiService {
  @override
  Future<List<dynamic>> getConnections() async => [];

  @override
  Future<List<dynamic>> getCaregiverAlerts() async => [];

  @override
  Future<String?> getToken() async => "fake-token";

  @override
  Future<String?> getRole() async => "CAREGIVER";

  @override
  Future<String?> getName() async => "Priya";
}

void main() {
  testWidgets('CaregiverDashboardScreen mounts and shows pairing screen when not connected', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(FakeApiService()),
        ],
        child: const MaterialApp(
          home: CaregiverDashboardScreen(),
        ),
      ),
    );

    // Let the async initState calls complete and render the final screen
    await tester.pumpAndSettle();

    expect(find.text('Connect to Patient'), findsOneWidget);
    expect(find.text('Enter Code'), findsOneWidget);
    expect(find.text('Connect Now'), findsOneWidget);
  });
}
