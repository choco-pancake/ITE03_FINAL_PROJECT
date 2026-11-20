import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/profile.dart';
import 'package:frontend/screens/profile_list_screen.dart';
import 'package:frontend/services/profile_service.dart';

class FakeProfileService extends ProfileService {
  List<Profile> profiles = [];
  Object? loadError;
  Completer<List<Profile>>? loadCompleter;
  int loadCalls = 0;

  @override
  Future<List<Profile>> getProfiles() async {
    loadCalls++;
    if (loadCompleter != null) return loadCompleter!.future;
    if (loadError != null) throw loadError!;
    return profiles;
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

Widget appWith(FakeProfileService service) =>
    MaterialApp(home: ProfileListScreen(service: service));

void main() {
  testWidgets('shows a loading indicator while profiles are pending', (
    tester,
  ) async {
    final service = FakeProfileService()
      ..loadCompleter = Completer<List<Profile>>();
    await tester.pumpWidget(appWith(service));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders profiles without add or delete controls', (tester) async {
    final service = FakeProfileService()..profiles = [profile];
    await tester.pumpWidget(appWith(service));
    await tester.pumpAndSettle();
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
    expect(find.textContaining('Flutter, UI Design'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.byIcon(Icons.delete), findsNothing);
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
    service
      ..loadError = null
      ..profiles = [profile];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(service.loadCalls, 2);
    expect(find.text('Juan Dela Cruz'), findsOneWidget);
  });
}
