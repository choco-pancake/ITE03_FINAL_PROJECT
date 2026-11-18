import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'screens/landing_page.dart';
import 'screens/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final appState = AppState();
  runApp(GroupMeMaybeApp(appState: appState));
}

class GroupMeMaybeApp extends StatelessWidget {
  final AppState appState;

  const GroupMeMaybeApp({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'GroupMeMaybe - Smart Team Formation Platform',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Active Blue Theme
              primary: const Color(0xFF2563EB),
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            fontFamily: 'Segoe UI',
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          home: appState.isAuthenticated
              ? MainShell(appState: appState, initialIndex: 2)
              : LandingPage(appState: appState),
        );
      },
    );
  }
}
