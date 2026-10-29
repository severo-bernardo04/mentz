import 'package:flutter/material.dart';
import 'package:mentz/widgets/section_card.dart';

/// Aviso de novos alunos vinculados ao treinador.
class NewStudentsCard extends StatelessWidget {
  final List<String> students;
  final ValueChanged<String> onDismiss;

  const NewStudentsCard({
    super.key,
    required this.students,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SectionCard(
      title: 'Novos alunos',
      icon: Icons.notifications_active_outlined,
      trailing: Badge(label: Text('${students.length}')),
      child: Column(
        children: [
          for (final n in students)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: cs.tertiaryContainer,
                child: Icon(
                  Icons.person_add_alt_1,
                  color: cs.onTertiaryContainer,
                  size: 20,
                ),
              ),
              title: Text(
                n,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Novo aluno vinculado a você'),
              trailing: TextButton(
                onPressed: () => onDismiss(n),
                child: const Text('Ciente'),
              ),
            ),
        ],
      ),
    );
  }
}