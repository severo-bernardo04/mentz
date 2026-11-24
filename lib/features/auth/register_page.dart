import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../core/utils/validators.dart';
import '../../models/bmi_info.dart';
import '../../models/profile_models.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/staggered_column.dart';
import 'terms_of_use_page.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_strength_bar.dart';
import 'widgets/terms_checkbox_field.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();

  DateTime? _birthDate;
  BiologicalSex? _sex;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  final _auth = AuthService();

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('pt', 'BR'),
          delegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          child: child,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final height =
          double.tryParse(_heightCtrl.text.replaceAll(',', '.').trim());
      final weight =
          double.tryParse(_weightCtrl.text.replaceAll(',', '.').trim());

      await _auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        birthDate: _birthDate,
        sex: _sex?.label,
        heightCm: height,
        weight: weight,
        // O formulário só chega aqui com os termos aceitos (validator)
        termsVersion: TermsOfUseContent.version,
      );
      if (!mounted) return;

      // O AuthGate já colocou a Home na raiz; fecha a tela de cadastro.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) context.showSnack(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AuthScaffold(
      showBackButton: true,
      form: Form(
        key: _formKey,
        child: StaggeredColumn(
          children: [
            const AuthHeader(
              title: 'Criar conta',
              subtitle: 'Preencha os dados para se cadastrar.',
            ),
            AppTextField(
              controller: _nameCtrl,
              label: 'Nome',
              icon: Icons.person_outline,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: Validators.name,
            ),
            AppTextField(
              controller: _emailCtrl,
              label: 'E-mail',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: Validators.email,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _passCtrl,
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.newPassword,
                ),
                PasswordStrengthBar(controller: _passCtrl),
              ],
            ),
            AppTextField(
              controller: _confirmCtrl,
              label: 'Confirmar senha',
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              textInputAction: TextInputAction.next,
              validator: Validators.confirmPassword(_passCtrl),
            ),
            // Data de nascimento (para idade e fórmulas corporais)
            InkWell(
              key: const Key('register_birth_date_picker'),
              borderRadius: BorderRadius.circular(12),
              onTap: _pickBirthDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(90),
                  border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.cake_outlined, color: cs.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _birthDate == null
                            ? 'Data de nascimento (opcional)'
                            : '${formatDate(_birthDate!)} (${ageFrom(_birthDate!)} anos)',
                        style: TextStyle(
                          color: _birthDate == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                          fontWeight: _birthDate == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_month_outlined,
                        size: 20, color: cs.primary),
                  ],
                ),
              ),
            ),
            // Sexo biológico (para Deurenberg e TMB)
            Row(
              children: [
                Text(
                  'Sexo:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SegmentedButton<BiologicalSex>(
                    key: const Key('register_sex_segmented_button'),
                    segments: const [
                      ButtonSegment(
                        value: BiologicalSex.male,
                        label: Text('Masculino'),
                        icon: Icon(Icons.male, size: 16),
                      ),
                      ButtonSegment(
                        value: BiologicalSex.female,
                        label: Text('Feminino'),
                        icon: Icon(Icons.female, size: 16),
                      ),
                    ],
                    selected: _sex == null ? const {} : {_sex!},
                    emptySelectionAllowed: true,
                    onSelectionChanged: (newSet) {
                      setState(() {
                        _sex = newSet.isEmpty ? null : newSet.first;
                      });
                    },
                  ),
                ),
              ],
            ),
            // Altura e Peso opcionais para cálculo automático imediato
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    key: const Key('register_height_field'),
                    controller: _heightCtrl,
                    label: 'Altura (cm)',
                    icon: Icons.height,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppTextField(
                    key: const Key('register_weight_field'),
                    controller: _weightCtrl,
                    label: 'Peso (kg)',
                    icon: Icons.scale_rounded,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            TermsCheckboxField(),
            AppButton(
              label: 'Cadastrar',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
      footer: AuthFooterLink(
        question: 'Já tem conta?',
        action: 'Entrar',
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
