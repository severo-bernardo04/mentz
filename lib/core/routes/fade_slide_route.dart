import 'package:flutter/material.dart';

/// Transição de tela com fade + leve deslize.
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

extension FadeNavigation on BuildContext {
  /// Abre [page] com a transição fade + deslize.
  Future<T?> pushFade<T>(Widget page) =>
      Navigator.of(this).push<T>(fadeSlideRoute<T>(page));

  /// Abre [page] e remove todas as telas anteriores (ex: login/logout).
  Future<T?> pushFadeAndClear<T>(Widget page) => Navigator.of(this)
      .pushAndRemoveUntil<T>(fadeSlideRoute<T>(page), (_) => false);
}