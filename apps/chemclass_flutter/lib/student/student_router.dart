import 'package:go_router/go_router.dart';

import '../app_config.dart';
import '../shared/screens/login_screen.dart';
import '../shared/screens/profile_screen.dart';
import '../shared/screens/schedule_screen.dart';
import '../shared/screens/signup_screen.dart';
import '../shared/screens/splash_screen.dart';
import '../state/auth_state.dart';
import 'screens/class_detail_screen.dart';
import 'screens/classes_list_screen.dart';
import 'screens/messages_screen.dart';
import 'student_shell.dart';

GoRouter buildStudentRouter(AuthState authState) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authState,
    redirect: (context, state) {
      final loading = authState.loading;
      final loggedIn = authState.session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (loading) return isSplash ? null : '/splash';
      if (isSplash) return loggedIn ? '/' : '/login';
      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          config: studentAppConfig,
          onGoToSignup: () => context.go('/signup'),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupScreen(
          config: studentAppConfig,
          onGoToLogin: () => context.go('/login'),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const ClassesListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/schedule', builder: (context, state) => const ScheduleScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen(config: studentAppConfig)),
          ]),
        ],
      ),
      GoRoute(
        path: '/class/:classId',
        builder: (context, state) => ClassDetailScreen(classId: state.pathParameters['classId']!),
        routes: [
          GoRoute(
            path: 'messages',
            builder: (context, state) => MessagesScreen(classId: state.pathParameters['classId']!),
          ),
        ],
      ),
    ],
  );
}
