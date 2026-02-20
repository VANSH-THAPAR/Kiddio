import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/login_screen.dart';
import 'package:frontend/features/auth/presentation/signup_screen.dart'; // Import signup screen
import 'package:frontend/features/navigation/main_scaffold.dart';
import 'package:frontend/features/auth/providers/auth_controller.dart';
import 'package:frontend/features/profile/presentation/profile_screen.dart'; // Import Profile Screen
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/bookings/presentation/bookings_screen.dart'; 
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/auth/models/user_model.dart';

// Placeholder screens for Shell



final _rootNavigatorKey = GlobalKey<NavigatorState>();

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

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier, 
    redirect: (context, state) {
      final currentAuth = ref.read(authControllerProvider);
      final isLoggedIn = currentAuth.user != null;
      final isLoggingIn = state.uri.toString() == '/auth';
      final isSigningUp = state.uri.toString() == '/signup';

      if (!isLoggedIn) {
        return (isLoggingIn || isSigningUp) ? null : '/auth';
      }

      if (isLoggingIn || isSigningUp) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
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
                builder: (context, state) => const ChatListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final otherUser = state.extra as UserModel;
                      return ChatScreen(otherUser: otherUser);
                    },
                  ),
                ],
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
