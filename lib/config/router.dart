import 'package:go_router/go_router.dart';
import 'package:medlens_mobile/features/home/view/home_screen.dart';
import 'package:medlens_mobile/features/session/view/session_screen.dart';
import 'package:medlens_mobile/features/summary/view/summary_screen.dart';
import 'package:medlens_mobile/features/history/view/history_screen.dart';

/// App router using GoRouter.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/session',
        name: 'session',
        builder: (context, state) => const SessionScreen(),
      ),
      GoRoute(
        path: '/summary',
        name: 'summary',
        builder: (context, state) => const SummaryScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
    ],
  );
}
