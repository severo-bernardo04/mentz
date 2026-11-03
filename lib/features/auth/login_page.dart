import 'package:flutter/material.dart';

import '../../core/routes/fade_slide_route.dart';
import '../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/staggered_column.dart';
import '../home/home_page.dart';
import 'register_page.dart';
import 'widgets/auth_footer_link.dart';
import 'widgets/auth_header.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: trocar pela autenticação real (ex: Firebase Auth)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      fadeSlideRoute(HomePage(userEmail: _emailCtrl.text.trim())),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      form: Form(
        key: _formKey,
        child: StaggeredColumn(
          children: [
            const AuthHeader(
              title: 'Bem-vindo de volta',
              subtitle: 'Use seu e-mail e senha para entrar.',
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
            AppTextField(
              controller: _passCtrl,
              label: 'Senha',
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) => Validators.notEmpty(v, 'Digite sua senha.'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Esqueci a senha'),
              ),
            ),
            AppButton(label: 'Entrar', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
      footer: AuthFooterLink(
        question: 'Não tem conta?',
        action: 'Cadastre-se',
        onPressed: () => Navigator.push(
          context,
          fadeSlideRoute(const RegisterPage()),
        ),
      ),
    );
  }
}