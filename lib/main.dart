import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/models.dart';
import 'firebase_options.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_home.dart';
import 'screens/provider/provider_home.dart';
import 'services/app_state.dart';
import 'services/firestore_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(SetupErrorApp(error: e.toString()));
    return;
  }
  runApp(const AutoAidApp());
}

class AutoAidApp extends StatelessWidget {
  const AutoAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        ChangeNotifierProvider<AppState>(
          create: (ctx) => AppState(ctx.read<FirestoreService>()),
        ),
      ],
      child: MaterialApp(
        title: 'AutoAid',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFFE65100),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Decides which screen to show: login, loading, or the home of the user's role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.initializing) return const _Loading();
    if (state.firebaseUser == null) return const LoginScreen();

    final profile = state.profile;
    if (profile == null) {
      if (!state.profileChecked || state.registering) return const _Loading();
      return const _MissingProfile();
    }

    return switch (profile.role) {
      UserRole.customer => const CustomerHome(),
      UserRole.provider => const ProviderHome(),
      UserRole.admin => const AdminScreen(),
    };
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _MissingProfile extends StatelessWidget {
  const _MissingProfile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Your profile could not be found.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.read<AppState>().signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when Firebase has not been configured yet.
class SetupErrorApp extends StatelessWidget {
  const SetupErrorApp({super.key, required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firebase is not configured',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                    'Run `dart pub global activate flutterfire_cli` and then '
                    '`flutterfire configure` in the project folder. See the README.'),
                const SizedBox(height: 12),
                Text(error, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
