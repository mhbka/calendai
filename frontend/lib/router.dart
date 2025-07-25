import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/pages/ai_event_page.dart';
import 'package:namer_app/pages/recurring_events_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:namer_app/pages/login_page.dart';
import 'package:namer_app/pages/calendar_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) async {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/calendar';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) {
          final session = Supabase.instance.client.auth.currentSession;
          return session != null ? '/calendar' : '/login';
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(),
      ),
      GoRoute(
        path: '/calendar',
        name: 'calendar',
        builder: (context, state) => CalendarPage(),
      ),
      GoRoute(
        path: '/add_ai_event',
        name: 'add_ai_event',
        builder: (context, state) => AddAIEventPage()
      ),
      GoRoute(
        path: '/recurring_events',
        name: 'recurring_events',
        builder: (context, state) => RecurringEventGroupsPage()
      )
    ],
  );
}