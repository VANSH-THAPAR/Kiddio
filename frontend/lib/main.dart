import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add dotenv
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env"); // Load .env
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
    // Optionally create a default empty map if load fails so access won't crash immediately 
    // but the app might still fail if env vars are critical.
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: KiddioApp()));
}

class KiddioApp extends ConsumerWidget {
  const KiddioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kiddio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
