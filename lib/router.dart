import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/history/order_detail_screen.dart';
import 'screens/history/orders_list_screen.dart';
import 'screens/main_shell.dart';
import 'screens/orders/lyrics_review_screen.dart';
import 'screens/orders/music_screen.dart';
import 'screens/orders/new_order_screen.dart';
import 'screens/orders/video_preview_screen.dart';
import 'screens/settings/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/orders',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/orders', builder: (_, __) => const OrdersListScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/new', builder: (_, __) => const NewOrderScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
          ]),
        ],
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, s) => OrderDetailScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/lyrics',
        builder: (_, s) => LyricsReviewScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/music',
        builder: (_, s) => MusicScreen(orderId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id/video',
        builder: (_, s) => VideoPreviewScreen(orderId: s.pathParameters['id']!),
      ),
    ],
  );
});
