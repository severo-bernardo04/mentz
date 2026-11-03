import 'package:flutter/material.dart';

/// Checkbox de termos de uso integrado ao [Form] (valida junto com os campos).
class TermsCheckboxField extends FormField<bool> {
  TermsCheckboxField({super.key})
      : super(
          initialValue: false,
          validator: (accepted) =>
              accepted == true ? null : 'Aceite os termos para continuar.',
          builder: (state) {
            final cs = Theme.of(state.context).colorScheme;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: state.value ?? false,
                  onChanged: state.didChange,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'Li e aceito os termos de uso',
                    style: TextStyle(fontSize: 14),
                  ),
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