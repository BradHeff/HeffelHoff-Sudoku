import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/sudoku/domain/difficulty.dart';
import 'features/sudoku/presentation/difficulty_select_screen.dart';
import 'features/sudoku/presentation/game_screen.dart';
import 'features/sudoku/presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DifficultySelectScreen(),
      ),
      GoRoute(
        path: '/game/:difficulty',
        builder: (context, state) {
          final raw = state.pathParameters['difficulty'] ?? 'easy';
          final tier = Difficulty.values.firstWhere(
            (d) => d.id == raw,
            orElse: () => Difficulty.easy,
          );
          return GameScreen(difficulty: tier);
        },
      ),
    ],
  );
});
