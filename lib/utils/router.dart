import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/admin/users_screen.dart';
import '../widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = auth.isLoggedIn;
      final isLoginPage = state.uri.path == '/login';
      
      // Auth guard
      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';

      // Admin-only routes
      if (state.uri.path.startsWith('/users') && !auth.isAdmin) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
          GoRoute(path: '/inventory', builder: (context, state) => const InventoryScreen()),
          GoRoute(path: '/inventory/add', builder: (context, state) => const InventoryScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
        ],
      ),
    ],
  );
});
