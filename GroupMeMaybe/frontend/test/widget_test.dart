import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/profile.dart';
import 'package:frontend/screens/profile_list_screen.dart';
import 'package:frontend/services/profile_service.dart';

class FakeProfileService extends ProfileService {
  List<Profile> profiles = [];
  Object? loadError;
  Object? createError;
  Object? deleteError;
  Completer<List<Profile>>? loadCompleter;
  Completer<Profile>? createCompleter;
  int loadCalls = 0;
  int createCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<Profile>> getProfiles() async {
    loadCalls++;
    if (loadCompleter != null) return loadCompleter!.future;
    if (loadError != null) throw loadError!;
    return profiles;
  }

  @override
  Future<Profile> createProfile(Profile profile) async {
    createCalls++;
    if (createCompleter != null) return createCompleter!.future;
    if (createError != null) throw createError!;
    return profile;
  }

  @override
  Future<void> deleteProfile(int id) async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }
}

final profile = Profile(
  id: 1,
  name: 'Juan Dela Cruz',
  email: 'juan@example.com',
  skills: const ['Flutter', 'UI Design'],
  preferredRole: 'Programmer',
  availability: 'Weekdays',
);

Widget appWith(FakeProfileService service) {
  return MaterialApp(home: ProfileListScreen(service: service));
}

void main() {
  testWidgets('shows a loading indicator while profiles are pending', (
    tester,
  ) async {
    final service = FakeProfileService()
      ..loadCompleter = Completer<List<Profile>>();

    await tester.pumpWidget(appWith(service));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders profiles returned by the service', (tester) async {
    final service = FakeProfileService()..profiles = [profile];

    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.text('Programmer • Flutter, UI Design'), findsOneWidget);
  });

  testWidgets('renders an empty state', (tester) async {
    await tester.pumpWidget(appWith(FakeProfileService()));
    await tester.pumpAndSettle();

    expect(find.text('No profiles yet.'), findsOneWidget);
  });

  testWidgets('retries after a load failure', (tester) async {
    final service = FakeProfileService()..loadError = Exception('offline');
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load profiles.'), findsOneWidget);
    expect(find.textContaining('offline'), findsNothing);

    service
      ..loadError = null
      ..profiles = [profile];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(service.loadCalls, 2);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });

  testWidgets('creates a profile and refreshes the list', (tester) async {
    final service = FakeProfileService()..profiles = [profile];
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(service.createCalls, 1);
    expect(service.loadCalls, 2);
  });

  testWidgets('prevents duplicate create actions while one is pending', (
    tester,
  ) async {
    final service = FakeProfileService()
      ..profiles = [profile]
      ..createCompleter = Completer<Profile>();
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    final button = tester.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    expect(button.onPressed, isNull);
    expect(service.createCalls, 1);
  });

  testWidgets('shows an error when creating a profile fails', (tester) async {
    final service = FakeProfileService()
      ..profiles = [profile]
      ..createError = Exception('failed');
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not add profile. Please try again.'),
      findsOneWidget,
    );
    expect(service.loadCalls, 1);
  });

  testWidgets('deletes a profile and refreshes the list', (tester) async {
    final service = FakeProfileService()..profiles = [profile];
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(service.deleteCalls, 1);
    expect(service.loadCalls, 2);
  });

  testWidgets('shows an error when deleting a profile fails', (tester) async {
    final service = FakeProfileService()
      ..profiles = [profile]
      ..deleteError = Exception('failed');
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not delete profile. Please try again.'),
      findsOneWidget,
    );
    expect(service.loadCalls, 1);
  });
}
