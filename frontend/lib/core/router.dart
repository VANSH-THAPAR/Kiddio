import 'package:google_fonts/google_fonts.dart'; // import dependencies correctly
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/core/presentation/scaffold_with_navbar.dart';
import 'package:frontend/features/auth/providers/auth_controller.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';

// Placeholder screens for Shell
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("My Bookings")), body: const Center(child: Text("Bookings Content")));
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Messages")), body: const Center(child: Text("Chat Content")));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
       return Scaffold(
        appBar: AppBar(title: const Text("Profile")), 
        body: Center(
          child: ElevatedButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            child: const Text("Sign Out"),
          ),
        ),
      );
    });
  } 
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Use a listenable to refresh the router on auth state changes
  final authNotifier = ValueNotifier<AuthState>(const AuthState());
  
  ref.onDispose(() {
    authNotifier.dispose();
  });

  ref.listen<AuthState>(
    authControllerProvider,
    (_, next) {
      authNotifier.value = next;
    },
  );

  final authState = ref.read(authControllerProvider); // Initial state

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      // READ the current state from the NOTIFIER directly for consistency/debug or ref.read
      // Using ref.read(authControllerProvider) inside redirect is safe in GoRouter 8+ 
      // but let's be explicit:
      final currentAuth = ref.read(authControllerProvider);
      final isLoggedIn = currentAuth.user != null;
      final isLoggingIn = state.uri.toString() == '/auth';

      // debugPrint("Router Redirect: LoggedIn=$isLoggedIn, Path=${state.uri}, User=${currentAuth.user?.email}");

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/auth';
      }

      if (isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                builder: (context, state) => const BookingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                builder: (context, state) => const ChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
