import 'package:flutter/material.dart';
import 'package:mentz/features/profile/trainer/widgets/student_card.dart';
import 'package:mentz/features/profile/trainer/widgets/student_sheet.dart';
import 'package:mentz/features/profile/widgets/profile_tab_page.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/widgets/app_text_field.dart';
import 'package:mentz/widgets/empty_hint.dart';

/// Aba 2: lista de alunos com busca por nome.
class StudentsTab extends StatefulWidget {
  final TrainerProfile trainer;

  const StudentsTab({super.key, required this.trainer});

  @override
  State<StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<StudentsTab> {
  String _query = '';

  List<StudentSummary> get _filtered {
    final q = _query.trim().toLowerCase();

    return [
      for (final s in widget.trainer.students)
        if (q.isEmpty || s.name.toLowerCase().contains(q)) s,
    ];
  }

  void _openStudent(StudentSummary s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StudentSheet(
        student: s,
        canViewBilling: widget.trainer.canViewBilling,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = _filtered;

    return ProfileTabPage(
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: appInputDecoration(
            context,
            label: 'Buscar aluno por nome',
            icon: Icons.search,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '${list.length} '
            '${list.length == 1 ? 'aluno vinculado' : 'alunos vinculados'}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (list.isEmpty) const EmptyHint('Nenhum aluno encontrado.'),
        for (final s in list)
          StudentCard(
            student: s,
            showBilling: widget.trainer.canViewBilling,
            onTap: () => _openStudent(s),
          ),
      ],
    );
  }
}