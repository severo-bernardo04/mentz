import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'registerpage.dart';
import 'homepage.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: trocar pela autenticação real (ex: Firebase Auth)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

    Navigator.of(context).pushReplacement(
      fadeSlideRoute(Homepage(userEmail: _emailCtrl.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FadeSlideIn(child: AuthLogo()),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: AuthCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Bem-vindo de volta',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use seu e-mail e senha para entrar.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 300),
                                child: TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
                                  decoration: authInputDecoration(
                                    context,
                                    label: 'E-mail',
                                    icon: Icons.mail_outline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 400),
                                child: TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Digite sua senha.';
                                    }
                                    return null;
                                  },
                                  decoration: authInputDecoration(
                                    context,
                                    label: 'Senha',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        child: Icon(
                                          _obscure
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          key: ValueKey(_obscure),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: const Text('Esqueci a senha'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 500),
                                child: AuthButton(
                                  label: 'Entrar',
                                  loading: _loading,
                                  onPressed: _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 600),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Não tem conta?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                fadeSlideRoute(const Registerpage()),
                              );
                            },
                            child: const Text(
                              'Cadastre-se',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}