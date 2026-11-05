import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/staggered_column.dart';
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

  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  final _auth = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await _auth.register(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
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