import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/staggered_column.dart';
import '../home/home_page.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/password_strength_bar.dart';
import 'widgets/terms_checkbox_field.dart';

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

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: trocar pelo cadastro real (ex: Firebase Auth)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

    // Limpa a pilha (login + cadastro) e abre a home.
    Navigator.of(context).pushAndRemoveUntil(
      fadeSlideRoute(HomePage(userEmail: _emailCtrl.text.trim())),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(_passCtrl),
            ),
            TermsCheckboxField(),
            AppButton(label: 'Cadastrar', loading: _loading, onPressed: _submit),
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