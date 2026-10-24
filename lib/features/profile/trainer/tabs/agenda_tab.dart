import 'package:flutter/material.dart';
import 'package:mentz/features/profile/trainer/widgets/appointment_list.dart';
import 'package:mentz/features/profile/trainer/widgets/day_pill.dart';
import 'package:mentz/features/profile/trainer/widgets/new_students_card.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';
import 'package:mentz/widgets/section_card.dart';

/// Aba 4: agenda (dia/semana), lembretes de reavaliação e faltas.
class AgendaTab extends StatefulWidget {
  final TrainerProfile trainer;
  final List<Appointment> appointments;
  final List<String> newStudents;
  final VoidCallback onChanged;
  final ValueChanged<String> onDismissNewStudent;

  const AgendaTab({
    super.key,
    required this.trainer,
    required this.appointments,
    required this.newStudents,
    required this.onChanged,
    required this.onDismissNewStudent,
  });

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  bool _weekly = false;
  int _day = (DateTime.now().weekday - 1).clamp(0, 6);

  List<Appointment> _forDay(int d) {
    return widget.appointments.where((a) => a.day == d).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  void _setStatus(Appointment a, AppointmentStatus s) {
    setState(() => a.status = s);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final missed = widget.appointments
        .where((a) => a.status == AppointmentStatus.missed)
        .toList();
    final reassess =
        widget.trainer.students.where((s) => s.needsReassessment).toList();

    return ProfileTabPage(
      children: [
        if (widget.newStudents.isNotEmpty)
          NewStudentsCard(
            students: widget.newStudents,
            onDismiss: widget.onDismissNewStudent,
          ),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.today_outlined),
              label: Text('Dia'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.date_range_outlined),
              label: Text('Semana'),
            ),
          ],
          selected: {_weekly},
          onSelectionChanged: (v) => setState(() => _weekly = v.first),
        ),
        const SizedBox(height: 14),
        if (!_weekly) ...[
          SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: DayPill(
                        label: weekdayShort[i],
                        count: _forDay(i).length,
                        selected: _day == i,
                        onTap: () => setState(() => _day = i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: weekdayShort[_day],
            icon: Icons.event_note_outlined,
            child: AppointmentList(items: _forDay(_day), onStatus: _setStatus),
          ),
        ] else
          for (var i = 0; i < 7; i++)
            if (_forDay(i).isNotEmpty)
              SectionCard(
                title: weekdayShort[i],
                icon: Icons.event_note_outlined,
                child: AppointmentList(items: _forDay(i), onStatus: _setStatus),
              ),
        SectionCard(
          title: 'Lembretes de reavaliação',
          icon: Icons.alarm_outlined,
          child: reassess.isEmpty
              ? const EmptyHint('Nenhuma reavaliação pendente.')
              : Column(
                  children: [
                    for (final s in reassess)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFEF6C00),
                        ),
                        title: Text(s.name),
                        subtitle: Text(
                          'Última avaliação: ${formatDate(s.lastAssessment)}',
                        ),
                      ),
                  ],
                ),
        ),
        SectionCard(
          title: 'Registro de faltas',
          icon: Icons.person_off_outlined,
          child: missed.isEmpty
              ? const EmptyHint('Nenhuma falta registrada.')
              : Column(
                  children: [
                    for (final a in missed)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Icon(Icons.cancel_outlined, color: cs.error),
                        title: Text(a.student),
                        subtitle: Text(
                          '${weekdayShort[a.day]} às ${a.time} • ${a.type.label}',
                        ),
                        trailing: TextButton(
                          onPressed: () =>
                              _setStatus(a, AppointmentStatus.scheduled),
                          child: const Text('Desfazer'),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}