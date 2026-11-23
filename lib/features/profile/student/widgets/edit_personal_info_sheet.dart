import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mentz/core/utils/snackbars.dart';
import 'package:mentz/models/bmi_info.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/user_profile_service.dart';
import 'package:mentz/widgets/app_button.dart';

class EditPersonalInfoSheet extends StatefulWidget {
  final String name;
  final String? phone;
  final DateTime? birthDate;
  final String? sex;

  const EditPersonalInfoSheet({
    super.key,
    required this.name,
    this.phone,
    this.birthDate,
    this.sex,
  });

  @override
  State<EditPersonalInfoSheet> createState() => _EditPersonalInfoSheetState();
}

class _EditPersonalInfoSheetState extends State<EditPersonalInfoSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  DateTime? _birthDate;
  BiologicalSex? _sex;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone ?? '');
    _birthDate = widget.birthDate;
    _sex = BiologicalSex.tryParse(widget.sex);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => Localizations.override(
        context: context,
        locale: const Locale('pt', 'BR'),
        delegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        child: child,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final name = _name.text.trim();
      final phone = _phone.text.trim();

      await UserProfileService().update(user.uid, {
        'name': name,
        'phone': phone.isEmpty ? FieldValue.delete() : phone,
        'birthDate': _birthDate == null
            ? FieldValue.delete()
            : Timestamp.fromDate(_birthDate!),
        'sex': _sex == null ? FieldValue.delete() : _sex!.label,
      });
      await user.updateDisplayName(name);

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        context.showSnack('Não foi possível salvar. Tente de novo.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  'Editar informações',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Informe seu nome'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone (opcional)',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.isEmpty) return null;
                    return digits.length < 10 || digits.length > 11
                        ? 'Telefone inválido'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickBirthDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      prefixIcon: Icon(Icons.cake_outlined),
                    ),
                    child: Text(
                      _birthDate == null
                          ? 'Não informado'
                          : formatDate(_birthDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<BiologicalSex>(
                  emptySelectionAllowed: true,
                  segments: [
                    for (final s in BiologicalSex.values)
                      ButtonSegment(value: s, label: Text(s.label)),
                  ],
                  selected: _sex == null ? const {} : {_sex!},
                  onSelectionChanged: (set) =>
                      setState(() => _sex = set.isEmpty ? null : set.first),
                ),
                const SizedBox(height: 20),
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

Future<bool?> showEditPersonalInfoSheet(
    BuildContext context, {
      required String name,
      String? phone,
      DateTime? birthDate,
      String? sex,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditPersonalInfoSheet(
      name: name,
      phone: phone,
      birthDate: birthDate,
      sex: sex,
    ),
  );
}