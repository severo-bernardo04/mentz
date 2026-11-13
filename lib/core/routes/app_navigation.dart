import 'package:flutter/material.dart';

/// Navegação global do app, usada por quem fica fora da árvore de telas
/// (como o cronômetro flutuante) e precisa abrir ou localizar uma tela.

/// Chave do Navigator principal (registrada no MaterialApp).
final appNavigatorKey = GlobalKey<NavigatorState>();

/// Observador de rotas (registrado no MaterialApp). As telas que precisam
/// saber se estão visíveis se inscrevem nele com [RouteAware].
final appRouteObserver = RouteObserver<PageRoute<dynamic>>();

/// Nome da rota da tela de um treino, único por planilha e dia.
String workoutRouteName(String chartId, String dayId) =>
    'workout_session/$chartId/$dayId';

/// Nome da rota de treino que está visível agora (no topo), ou null.
/// O cronômetro flutuante se esconde quando o treino em andamento já está
/// na tela.
final visibleWorkoutRoute = ValueNotifier<String?>(null);

/// Nomes das telas de treino abertas na pilha, visíveis ou não. Serve para
/// voltar a uma tela já aberta em vez de abrir outra por cima.
final openWorkoutRoutes = <String>{};
