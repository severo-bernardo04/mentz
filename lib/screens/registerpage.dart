import 'package:flutter/material.dart';

import 'auth_widgets.dart';
import 'homepage.dart';


class Registerpage extends StatefulWidget {
  const Registerpage({super.key});

  @override
  State<Registerpage> createState() => _RegisterpageState();
}

class _RegisterpageState extends State<Registerpage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  static const _strengthLabels = [
    'Muito fraca',
    'Fraca',
    'Média',
    'Boa',
    'Forte',
  ];

  static const _strengthColors = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF7CB342),
    Color(0xFF2E7D32),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())) {
      return 'Digite um e-mail válido.';
    }
    return null;
  }

  int _strength(String p) {
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return score;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // TODO: trocar pelo cadastro real (ex: Firebase Auth)
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

     Navigator.of(context).pushReplacement(
      fadeSlideRoute(Homepage(userEmail: _emailCtrl.text.trim())),
    );

    Navigator.pop(context);
  }

  Widget _strengthIndicator() {
    final password = _passCtrl.text;
    final score = _strength(password);
    final color = _strengthColors[score];

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: password.isEmpty
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (score + 1) / 5),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: color,
                        backgroundColor: color.withAlpha(40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Força da senha: ${_strengthLabels[score]}',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
                                'Criar conta',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Preencha os dados para se cadastrar.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 250),
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.name],
                                  validator: (v) {
                                    if (v == null || v.trim().length < 2) {
                                      return 'Digite seu nome.';
                                    }
                                    return null;
                                  },
                                  decoration: authInputDecoration(
                                    context,
                                    label: 'Nome',
                                    icon: Icons.person_outline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 330),
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
                                delay: const Duration(milliseconds: 410),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextFormField(
                                      controller: _passCtrl,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (_) => setState(() {}),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Digite uma senha.';
                                        }
                                        if (v.length < 8) {
                                          return 'Mínimo de 8 caracteres.';
                                        }
                                        return null;
                                      },
                                      decoration: authInputDecoration(
                                        context,
                                        label: 'Senha',
                                        icon: Icons.lock_outline,
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () => _obscure = !_obscure,
                                          ),
                                          icon: Icon(
                                            _obscure
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                          ),
                                        ),
                                      ),
                                    ),
                                    _strengthIndicator(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 490),
                                child: TextFormField(
                                  controller: _confirmCtrl,
                                  obscureText: _obscureConfirm,
                                  textInputAction: TextInputAction.done,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirme sua senha.';
                                    }
                                    if (v != _passCtrl.text) {
                                      return 'As senhas não coincidem.';
                                    }
                                    return null;
                                  },
                                  decoration: authInputDecoration(
                                    context,
                                    label: 'Confirmar senha',
                                    icon: Icons.lock_reset_outlined,
                                    suffix: IconButton(
                                      onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm,
                                      ),
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 560),
                                child: FormField<bool>(
                                  initialValue: false,
                                  validator: (_) => _acceptedTerms
                                      ? null
                                      : 'Aceite os termos para continuar.',
                                  builder: (state) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CheckboxListTile(
                                          value: _acceptedTerms,
                                          onChanged: (v) {
                                            setState(
                                              () => _acceptedTerms = v ?? false,
                                            );
                                            state.didChange(v);
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: const Text(
                                            'Li e aceito os termos de uso',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        if (state.hasError)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              state.errorText!,
                                              style: TextStyle(
                                                color: cs.error,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              FadeSlideIn(
                                delay: const Duration(milliseconds: 630),
                                child: AuthButton(
                                  label: 'Cadastrar',
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
                      delay: const Duration(milliseconds: 700),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem conta?',
                            style: theme.textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Entrar',
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