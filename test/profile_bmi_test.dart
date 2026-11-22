import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mentz/features/auth/register_page.dart';
import 'package:mentz/features/profile/student/tabs/physical_tab.dart';
import 'package:mentz/features/profile/student/widgets/bmi_card.dart';
import 'package:mentz/features/profile/student/widgets/edit_physical_measures_sheet.dart';
import 'package:mentz/models/bmi_info.dart';
import 'package:mentz/models/profile_models.dart';
import 'package:mentz/services/training_history_service.dart';

void main() {
  setUp(() => TrainingHistoryService().clearForTest());

  Future<void> pumpWidget(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: widget),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('BmiCard Widget Tests', () {
    testWidgets('exibe estado vazio quando não há altura ou peso', (tester) async {
      bool editTapped = false;
      await pumpWidget(
        tester,
        BmiCard(
          heightCm: null,
          weightKg: null,
          onEdit: () => editTapped = true,
        ),
      );

      expect(find.text('Medidas e IMC'), findsOneWidget);
      expect(find.text('Cadastre suas medidas'), findsOneWidget);
      expect(find.byKey(const Key('empty_add_measures_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('empty_add_measures_button')));
      expect(editTapped, isTrue);
    });

    testWidgets('exibe IMC calculado, categoria e faixa de peso ideal', (tester) async {
      await pumpWidget(
        tester,
        const BmiCard(
          heightCm: 175,
          weightKg: 70,
        ),
      );

      // 70 / (1.75 * 1.75) = 22.9 (Peso normal)
      expect(find.text('22.9'), findsOneWidget);
      expect(find.text('Peso normal'), findsWidgets);
      expect(
        find.textContaining('Faixa de peso saudável (175 cm): 56.7 kg – 76.3 kg'),
        findsOneWidget,
      );
    });

    testWidgets('exibe contexto de sexo/idade e % de gordura de Deurenberg', (
      tester,
    ) async {
      final now = DateTime.now();
      final birth = DateTime(now.year - 25, now.month, now.day);

      await pumpWidget(
        tester,
        BmiCard(
          heightCm: 175,
          weightKg: 70,
          birthDate: birth,
          sex: 'Masculino',
        ),
      );

      expect(find.text('Homem • 25 anos'), findsOneWidget);
      expect(find.byKey(const Key('body_fat_text')), findsOneWidget);
      expect(find.text('ESTIMATIVA'), findsOneWidget);
      expect(find.textContaining('Deurenberg (1991)'), findsOneWidget);
      expect(find.textContaining('ACE'), findsWidgets);
    });

    testWidgets('aplica critérios geriátricos de Lipschitz para idosos', (
      tester,
    ) async {
      final now = DateTime.now();
      final birth = DateTime(now.year - 68, now.month, now.day);

      await pumpWidget(
        tester,
        BmiCard(
          heightCm: 170,
          weightKg: 62,
          birthDate: birth,
          sex: 'Feminino',
        ),
      );

      // IMC 21.5 em idoso é baixo peso (< 22.0)
      expect(find.text('21.5'), findsOneWidget);
      expect(find.text('Abaixo do peso'), findsWidgets);
      expect(find.textContaining('Lipschitz'), findsOneWidget);
    });

    testWidgets('oculta os valores quando a privacidade estiver ativa', (tester) async {
      await pumpWidget(
        tester,
        const BmiCard(
          heightCm: 175,
          weightKg: 70,
          hidden: true,
        ),
      );

      expect(find.text('22.9'), findsNothing);
      expect(find.text('•••'), findsWidgets);
    });
  });

  group('PhysicalTab IMC Integration', () {
    testWidgets('exibe card de IMC dentro da PhysicalTab e abre edição', (tester) async {
      final student = StudentProfile(
        name: 'Carlos',
        email: 'carlos@mentz.com',
        heightCm: 180,
        birthDate: DateTime(2000, 1, 1),
        sex: 'Masculino',
        weightHistory: [
          WeightEntry(DateTime(2026, 1, 1), 80.0),
        ],
      );

      await pumpWidget(
        tester,
        PhysicalTab(student: student, isOwnerView: true),
      );

      // IMC para 80 kg e 180 cm => 80 / (1.8 * 1.8) = 24.7 (Peso normal)
      expect(find.text('Medidas e IMC'), findsOneWidget);
      expect(find.text('24.7'), findsOneWidget);
      expect(find.text('Peso normal'), findsWidgets);
      expect(find.text('180 cm'), findsOneWidget);
      expect(find.text('80.0 kg'), findsOneWidget);

      // Botão de editar medidas abre o modal
      expect(find.byKey(const Key('edit_measures_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('edit_measures_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EditPhysicalMeasuresSheet), findsOneWidget);
      expect(find.text('Medidas Corporais'), findsOneWidget);

      // Altera a altura para 170 cm e peso para 85 kg
      await tester.enterText(find.byKey(const Key('height_input_field')), '170');
      await tester.enterText(find.byKey(const Key('weight_input_field')), '85');
      await tester.pumpAndSettle();

      // Salva no modal
      await tester.tap(find.byKey(const Key('save_measures_button')));
      await tester.pumpAndSettle();

      // Verifica que a PhysicalTab recalculou o IMC instantaneamente (85 / 1.7^2 = 29.4 Sobrepeso)
      expect(find.text('29.4'), findsOneWidget);
      expect(find.text('Sobrepeso'), findsWidgets);
      expect(find.text('170 cm'), findsOneWidget);
      expect(find.text('85.0 kg'), findsOneWidget);
    });
  });

  group('EditPhysicalMeasuresSheet Tests', () {
    testWidgets('recalcula preview de IMC em tempo real e chama onSave ao salvar', (
      tester,
    ) async {
      double? savedHeight;
      double? savedWeight;
      DateTime? savedBirth;
      String? savedSex;

      await pumpWidget(
        tester,
        EditPhysicalMeasuresSheet(
          initialHeightCm: 170,
          initialWeightKg: 65,
          initialBirthDate: DateTime(2000, 5, 10),
          initialSex: 'Feminino',
          onSave: ({heightCm, weightKg, birthDate, sex}) async {
            savedHeight = heightCm;
            savedWeight = weightKg;
            savedBirth = birthDate;
            savedSex = sex;
          },
        ),
      );

      // Preview inicial: 65 kg / 1.7^2 = 22.5
      expect(find.text('IMC Estimado: 22.5'), findsOneWidget);
      expect(find.text('Peso normal'), findsWidgets);
      expect(find.textContaining('Gordura estimada'), findsOneWidget);

      // Altera o peso para 85 kg (Sobrepeso: 85 / 1.7^2 = 29.4)
      await tester.enterText(find.byKey(const Key('weight_input_field')), '85');
      await tester.pumpAndSettle();

      expect(find.text('IMC Estimado: 29.4'), findsOneWidget);
      expect(find.text('Sobrepeso'), findsWidgets);

      // Salva
      await tester.tap(find.byKey(const Key('save_measures_button')));
      await tester.pumpAndSettle();

      expect(savedHeight, 170.0);
      expect(savedWeight, 85.0);
      expect(savedBirth, DateTime(2000, 5, 10));
      expect(savedSex, 'Feminino');
    });

    testWidgets('valida entradas inválidas no formulário', (tester) async {
      await pumpWidget(
        tester,
        const EditPhysicalMeasuresSheet(),
      );

      await tester.tap(find.byKey(const Key('save_measures_button')));
      await tester.pumpAndSettle();

      expect(find.text('Informe a altura'), findsOneWidget);
      expect(find.text('Informe o peso'), findsOneWidget);
    });

    testWidgets('abre o seletor de data em português BR com botões e cabeçalhos traduzidos', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        const EditPhysicalMeasuresSheet(),
      );

      await tester.tap(find.byKey(const Key('pick_birth_date_button')));
      await tester.pumpAndSettle();

      expect(find.text('Selecione sua data de nascimento'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
    });
  });

  group('RegisterPage New Physical Fields Tests', () {
    testWidgets('renderiza os novos campos opcionais de nascimento, sexo e medidas', (
      tester,
    ) async {
      await pumpWidget(
        tester,
        const RegisterPage(),
      );

      expect(find.text('Criar conta'), findsOneWidget);
      expect(find.byKey(const Key('register_birth_date_picker')), findsOneWidget);
      expect(find.byKey(const Key('register_sex_segmented_button')), findsOneWidget);
      expect(find.byKey(const Key('register_height_field')), findsOneWidget);
      expect(find.byKey(const Key('register_weight_field')), findsOneWidget);
    });
  });
}
