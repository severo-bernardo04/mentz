import 'package:flutter/material.dart';

import '../terms_of_use_page.dart';

/// Checkbox de termos de uso integrado ao [Form] (valida junto com os campos).
/// O texto "termos de uso" abre a leitura completa; ao aceitar lá, o
/// checkbox é marcado automaticamente.
class TermsCheckboxField extends FormField<bool> {
  TermsCheckboxField({super.key})
      : super(
          initialValue: false,
          validator: (accepted) =>
              accepted == true ? null : 'Aceite os termos para continuar.',
          builder: (state) {
            final cs = Theme.of(state.context).colorScheme;

            Future<void> openTerms() async {
              final accepted = await Navigator.of(state.context).push<bool>(
                MaterialPageRoute(builder: (_) => const TermsOfUsePage()),
              );
              if (accepted == true) state.didChange(true);
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: state.value ?? false,
                      onChanged: state.didChange,
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Li e aceito os ',
                            style: TextStyle(fontSize: 14),
                          ),
                          InkWell(
                            key: const Key('terms_link'),
                            onTap: openTerms,
                            child: Text(
                              'termos de uso',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                                decoration: TextDecoration.underline,
                                decorationColor: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(color: cs.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        );
}
