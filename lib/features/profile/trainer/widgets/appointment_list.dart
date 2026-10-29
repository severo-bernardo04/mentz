import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/empty_hint.dart';

/// Lista de compromissos, com menu para marcar como realizado ou falta.
class AppointmentList extends StatelessWidget {
  final List<Appointment> items;
  final void Function(Appointment, AppointmentStatus) onStatus;

  const AppointmentList({
    super.key,
    required this.items,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyHint('Sem compromissos neste dia.');

    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final a in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                a.time,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              a.student,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                decoration: a.status == AppointmentStatus.done
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(a.type.icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(child: Text(a.type.label)),
              ],
            ),
            trailing: switch (a.status) {
              AppointmentStatus.done =>
                Icon(Icons.check_circle, color: Colors.green.shade600),
              AppointmentStatus.missed => Icon(Icons.cancel, color: cs.error),
              AppointmentStatus.scheduled =>
                PopupMenuButton<AppointmentStatus>(
                  tooltip: 'Ações',
                  onSelected: (s) => onStatus(a, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: AppointmentStatus.done,
                      child: Text('Marcar como realizado'),
                    ),
                    PopupMenuItem(
                      value: AppointmentStatus.missed,
                      child: Text('Registrar falta'),
                    ),
                  ],
                ),
            },
          ),
      ],
    );
  }
}