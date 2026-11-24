
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/services/user_profile_service.dart';
import 'package:mentz/widgets/app_button.dart';

class EditProfessionalInfoSheet extends StatefulWidget {
  final String? jobTitle;
  final String? cref;
  final int? experienceYears;

  const EditProfessionalInfoSheet({
    super.key,
    this.jobTitle,
    this.cref,
    this.experienceYears,
  });

  @override
  State<EditProfessionalInfoSheet> createState() =>
      _EditProfessionalInfoSheetState();
}

class _EditProfessionalInfoSheetState
    extends State<EditProfessionalInfoSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _jobTitle;
  late final TextEditingController _cref;
  late final TextEditingController _experience;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _jobTitle = TextEditingController(
      text: widget.jobTitle ?? '',
    );

    _cref = TextEditingController(
      text: widget.cref ?? '',
    );

    _experience = TextEditingController(
      text: widget.experienceYears?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _jobTitle.dispose();
    _cref.dispose();
    _experience.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_loading || !_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      context.showSnack(
        'Faça login novamente para editar seu perfil.',
      );
      return;
    }

    final rawExperience = _experience.text.trim();

    final experienceYears = rawExperience.isEmpty
        ? null
        : int.tryParse(rawExperience);

    setState(() => _loading = true);

    try {
      await UserProfileService().updateTrainerProfessionalInfo(
        user.uid,
        jobTitle: _jobTitle.text,
        cref: _cref.text,
        experienceYears: experienceYears,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      debugPrint('ERRO AO SALVAR DADOS PROFISSIONAIS: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() => _loading = false);

        context.showSnack(
          'Erro ao salvar: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bottomInset =
        MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        24 + bottomInset,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Editar dados profissionais',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Atualize suas informações profissionais.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 20),

                TextFormField(
                  key: const Key('trainer_job_title'),
                  controller: _jobTitle,
                  maxLength: 80,
                  textCapitalization:
                  TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Cargo profissional',
                    hintText: 'Ex.: Personal trainer',
                    prefixIcon:
                    Icon(Icons.work_outline),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();

                    if (text.isNotEmpty &&
                        text.length < 2) {
                      return 'Informe um cargo válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('trainer_cref'),
                  controller: _cref,
                  maxLength: 32,
                  textCapitalization:
                  TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'CREF (opcional)',
                    hintText: 'Ex.: 012345-G/RS',
                    prefixIcon:
                    Icon(Icons.verified_outlined),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  key: const Key('trainer_experience'),
                  controller: _experience,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tempo de experiência (anos)',
                    hintText: 'Ex.: 5',
                    prefixIcon: Icon(Icons.timelapse),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();

                    if (text.isEmpty) return null;

                    final years = int.tryParse(text);

                    if (years == null ||
                        years < 0 ||
                        years > 80) {
                      return 'Informe um valor entre 0 e 80';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                Text(
                  'O vínculo com a academia é gerenciado '
                      'pela administração.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                AppButton(
                  label: 'Salvar',
                  loading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool?> showEditProfessionalInfoSheet(
    BuildContext context, {
      String? jobTitle,
      String? cref,
      int? experienceYears,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditProfessionalInfoSheet(
      jobTitle: jobTitle,
      cref: cref,
      experienceYears: experienceYears,
    ),
  );
}
