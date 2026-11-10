import '../models/profile_models.dart';
import '../models/training_chart.dart';

/// Próximo treino de uma planilha: qual dia do ciclo e em que data.
class NextWorkout {
  final TrainingDay day;

  /// Data prevista; null quando a planilha de dias fixos não tem dia marcado.
  final DateTime? date;

  const NextWorkout(this.day, this.date);
}

/// Calcula o próximo treino do ciclo a partir do histórico, sem guardar estado.
///
/// O ciclo não precisa ter o tamanho da semana: com 4 treinos e 3 dias
/// marcados, o 4º cai no primeiro dia marcado da semana seguinte e o ciclo
/// continua. Se o usuário faltar, o treino passa para o próximo dia possível,
/// sem pular nenhum treino do ciclo.
abstract final class WorkoutScheduleService {
  static NextWorkout? nextWorkout(
    TrainingChart chart,
    List<CompletedWorkout> sessions, {
    DateTime? now,
  }) {
    if (chart.days.isEmpty) return null;

    final days = [...chart.days]..sort((a, b) => a.order.compareTo(b.order));
    final today = _dateOnly(now ?? DateTime.now());

    // Último treino realizado desta planilha (define a posição no ciclo) e o
    // último dia em que se treinou nela, contando treinos completados depois
    CompletedWorkout? last;
    DateTime? latestActivity;
    for (final session in sessions) {
      if (session.chartId != chart.id) continue;
      if (last == null || session.date.isAfter(last.date)) last = session;
      if (latestActivity == null || session.lastActivity.isAfter(latestActivity)) {
        latestActivity = session.lastActivity;
      }
    }

    // Sem histórico, ou com um dia que saiu da planilha, começa pelo primeiro
    final lastIndex = last == null
        ? -1
        : days.indexWhere((d) => d.id == last!.dayId);
    final nextDay = days[(lastIndex + 1) % days.length];

    if (last == null) return NextWorkout(nextDay, _scheduleFrom(chart, today));

    final lastDate = _dateOnly(last.date);
    final config = chart.frequencyConfig;

    // Nunca no mesmo dia em que se treinou, nem no passado
    final dayAfterActivity = _addDays(_dateOnly(latestActivity!), 1);
    final earliest = dayAfterActivity.isBefore(today) ? today : dayAfterActivity;

    if (config.type == WorkoutFrequencyType.intervalDays) {
      final rest = lastIndex >= 0 && lastIndex < config.intervalRestDays.length
          ? config.intervalRestDays[lastIndex]
          : 0;
      final planned = _addDays(lastDate, rest + 1);
      return NextWorkout(nextDay, planned.isBefore(earliest) ? earliest : planned);
    }

    return NextWorkout(nextDay, _scheduleFrom(chart, earliest));
  }

  /// Primeira data possível a partir de [start], inclusive.
  static DateTime? _scheduleFrom(TrainingChart chart, DateTime start) {
    final config = chart.frequencyConfig;
    if (config.type == WorkoutFrequencyType.intervalDays) return start;

    // Dias fixos: primeiro dia marcado (1 = segunda ... 7 = domingo)
    for (var offset = 0; offset < 7; offset++) {
      final date = _addDays(start, offset);
      if (config.fixedWeekdays.contains(date.weekday)) return date;
    }
    return null;
  }

  /// Texto curto para exibição (ex: "TREINO B • hoje" ou "TREINO A • sex, 13/11").
  static String label(NextWorkout next, {DateTime? now}) {
    final date = next.date;
    if (date == null) return next.day.name;

    final today = _dateOnly(now ?? DateTime.now());
    final when = date == today
        ? 'hoje'
        : date == _addDays(today, 1)
        ? 'amanhã'
        : '${weekdayShort[date.weekday - 1].toLowerCase()}, ${formatShort(date)}';

    return '${next.day.name} • $when';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Soma dias pelo calendário, sem depender de horário de verão.
  static DateTime _addDays(DateTime d, int days) =>
      DateTime(d.year, d.month, d.day + days);
}
