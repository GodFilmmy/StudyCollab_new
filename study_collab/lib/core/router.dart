import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/session/screens/create_session_screen.dart';
import '../features/session/screens/edit_session_screen.dart';
import '../features/session/screens/session_detail_screen.dart';
import '../features/session/screens/members_list_screen.dart';
import '../features/session/screens/chat_screen.dart';
import '../features/session/screens/notes_screen.dart';
import '../features/session/screens/requests_screen.dart';
import '../features/calendar/screens/calendar_screen.dart';
import '../features/my_sessions/screens/my_sessions_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/other_user_profile_screen.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/messaging/screens/messages_screen.dart';
import '../features/messaging/screens/dm_screen.dart';
import '../features/settings/screens/settings_screen.dart';
import 'widgets/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (c,s) => const SplashScreen()),
    GoRoute(path: '/login',  builder: (c,s) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (c,s) => const SignupScreen()),
    ShellRoute(
      builder: (c,s,child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/home',        builder: (c,s) => const DashboardScreen()),
        GoRoute(path: '/calendar',    builder: (c,s) => const CalendarScreen()),
        GoRoute(path: '/messages',    builder: (c,s) => const MessagesScreen()),
        GoRoute(path: '/my-sessions', builder: (c,s) => const MySessionsScreen()),
        GoRoute(path: '/profile',     builder: (c,s) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/create-session', builder: (c,s) => CreateSessionScreen(initialDate: s.extra is DateTime ? s.extra as DateTime : null)),
    GoRoute(path: '/session/:id',    builder: (c,s) => SessionDetailScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/session/:id/edit',    builder: (c,s) => EditSessionScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/session/:id/members', builder: (c,s) => MembersListScreen(id: s.pathParameters['id']!)),
    GoRoute(path: '/session/:id/chat',    builder: (c,s) => ChatScreen(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/session/:id/notes',   builder: (c,s) => NotesScreen(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/session/:id/requests',builder: (c,s) => RequestsScreen(sessionId: s.pathParameters['id']!)),
    GoRoute(path: '/user/:id', builder: (c,s) => OtherUserProfileScreen(userId: s.pathParameters['id']!)),
    GoRoute(path: '/notifications', builder: (c,s) => const NotificationsScreen()),
    GoRoute(path: '/messages/:id',  builder: (c,s) => DmScreen(userId: s.pathParameters['id']!)),
    GoRoute(path: '/settings',      builder: (c,s) => const SettingsScreen()),
  ],
);
