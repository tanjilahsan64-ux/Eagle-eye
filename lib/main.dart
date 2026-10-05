import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'models/app_models.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FieldTrackerApp());
}

class FieldTrackerApp extends StatelessWidget {
  const FieldTrackerApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Field Tracker',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override Widget build(BuildContext context) => StreamBuilder(
    stream: AuthService().authStateChanges,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (!snap.hasData) return const LoginScreen();
      return FutureBuilder<AppUser?>(
        future: AuthService().getProfile(snap.data!.uid),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (profile.data == null) return const LoginScreen();
          return DashboardScreen(user: profile.data!);
        },
      );
    },
  );
}
