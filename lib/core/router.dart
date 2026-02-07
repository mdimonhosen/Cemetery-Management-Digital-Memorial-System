import 'package:cemetry/features/admin/admin_dashboard.dart';
import 'package:cemetry/features/auth/auth_service.dart';
import 'package:cemetry/features/auth/login_screen.dart';
import 'package:cemetry/features/auth/register_screen.dart';
import 'package:cemetry/features/user/user_dashboard.dart';
import 'package:cemetry/main.dart'; // Import for supabase client
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) async {
      final session = authState.value?.session;
      final location = state.uri.toString();
      final isLoggingIn = location == '/login';
      final isRegistering = location == '/register';

      if (session == null) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // Fetch role dynamically to ensure up-to-date access control
      final role = await ref.read(authServiceProvider).getUserRole();

      // Redirect to appropriate dashboard if at login, register, or root
      if (isLoggingIn || isRegistering || location == '/') {
        return role == 1 ? '/admin' : '/user';
      }

      // Strict Role Guards
      // Prevent non-admins from accessing admin routes
      if (location.startsWith('/admin') && role != 1) {
        return '/user';
      }

      // Prevent admins from accessing user routes (strict separation)
      if (location.startsWith('/user') && role == 1) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/user',
        builder: (context, state) => const UserDashboard(),
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
