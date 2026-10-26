import 'package:flutter/foundation.dart';
import '../models/profile_models.dart';

/// Serviço repositório com o catálogo oficial de exercícios e dados anatômicos de ativação muscular.
class ExerciseCatalogService extends ChangeNotifier {
  static final ExerciseCatalogService _instance =
      ExerciseCatalogService._internal();
  factory ExerciseCatalogService() => _instance;

  ExerciseCatalogService._internal() {
    _initDefaultCatalog();
  }

  final List<Exercise> _exercises = [];

  List<Exercise> get exercises => List.unmodifiable(_exercises);

  void _initDefaultCatalog() {
    if (_exercises.isNotEmpty) return;

    _exercises.addAll([
      Exercise(
        name: 'Supino reto',
        nameEn: 'Barbell Flat Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: ['Tríceps', 'Deltoide anterior'],
        secondaryMuscles: ['Serrátil anterior', 'Core'],
        sets: 4,
        reps: '8-10',
        load: '60 kg',
        restSeconds: 90,
        equipment: 'Barra e banco reto',
        instructions:
            'Deite no banco, mantenha os pés firmes no chão, desça a barra controladamente até o terço inferior do esterno e empurre estendendo os braços.',
      ),
      Exercise(
        name: 'Supino inclinado com halteres',
        nameEn: 'Incline Dumbbell Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral superior',
        highActivationMuscles: ['Deltoide anterior', 'Tríceps'],
        secondaryMuscles: ['Serrátil anterior', 'Core'],
        sets: 3,
        reps: '10-12',
        load: '24 kg',
        restSeconds: 75,
        equipment: 'Halteres e banco inclinado 30-45°',
        instructions:
            'Posicione os halteres na altura do peito superior com banco a 30-45 graus, empurre convergindo levemente no topo sem bater os halteres.',
      ),
      Exercise(
        name: 'Crucifixo na máquina',
        nameEn: 'Machine Chest Fly / Pec Deck',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: ['Deltoide anterior'],
        secondaryMuscles: ['Bíceps (cabeça curta)'],
        sets: 3,
        reps: '12',
        load: '40 kg',
        restSeconds: 60,
        equipment: 'Máquina Pec Deck',
        instructions:
            'Ajuste o assento para que as manoplas fiquem na altura do meio do peito. Aproxime os braços em arco focando na contração máxima.',
      ),
      Exercise(
        name: 'Tríceps testa',
        nameEn: 'Skull Crusher / Lying Triceps Extension',
        muscle: 'Tríceps',
        primaryMuscle: 'Tríceps',
        highActivationMuscles: ['Antebraço'],
        secondaryMuscles: ['Deltoide anterior'],
        sets: 3,
        reps: '12',
        load: '25 kg',
        restSeconds: 60,
        equipment: 'Barra W / Halteres e banco',
        instructions:
            'Deitado no banco com os braços verticais, flexione apenas os cotovelos descendo a barra até próximo à testa e estenda.',
      ),
      Exercise(
        name: 'Tríceps na polia',
        nameEn: 'Triceps Cable Pushdown',
        muscle: 'Tríceps',
        primaryMuscle: 'Tríceps',
        highActivationMuscles: ['Antebraço'],
        secondaryMuscles: ['Peitoral', 'Abdômen'],
        sets: 3,
        reps: '15',
        load: '30 kg',
        restSeconds: 45,
        equipment: 'Polia alta com barra reta ou corda',
        instructions:
            'Mantenha os cotovelos fixos junto ao tronco, empurre o cabo para baixo até a extensão completa dos cotovelos.',
      ),
      Exercise(
        name: 'Puxada frontal',
        nameEn: 'Lat Pulldown',
        muscle: 'Costas',
        primaryMuscle: 'Grande dorsal',
        highActivationMuscles: ['Bíceps', 'Redondo maior'],
        secondaryMuscles: ['Trapézio', 'Romboides', 'Antebraço'],
        sets: 4,
        reps: '10',
        load: '55 kg',
        restSeconds: 90,
        equipment: 'Polia alta com barra ampla',
        instructions:
            'Segure a barra com pegada pronada aberta, puxe em direção à parte superior do peito projetando o esterno para frente.',
      ),
      Exercise(
        name: 'Remada curvada',
        nameEn: 'Bent-Over Barbell Row',
        muscle: 'Costas',
        primaryMuscle: 'Costas',
        highActivationMuscles: ['Bíceps', 'Trapézio', 'Deltoide posterior'],
        secondaryMuscles: ['Lombar', 'Glúteos', 'Isquiotibiais'],
        sets: 4,
        reps: '8-10',
        load: '50 kg',
        restSeconds: 90,
        equipment: 'Barra com anilhas',
        instructions:
            'Incline o tronco a cerca de 45°, mantenha a coluna neutra e puxe a barra em direção ao umbigo contraindo as escápulas.',
      ),
      Exercise(
        name: 'Rosca direta',
        nameEn: 'Barbell Biceps Curl',
        muscle: 'Bíceps',
        primaryMuscle: 'Bíceps',
        highActivationMuscles: ['Braquial', 'Braquiorradial'],
        secondaryMuscles: ['Antebraço', 'Deltoide anterior'],
        sets: 3,
        reps: '12',
        load: '30 kg',
        restSeconds: 60,
        equipment: 'Barra reta ou W',
        instructions:
            'Em pé com postura ereta, flexione os cotovelos elevando a barra sem balançar o corpo, controlando a fase excêntrica.',
      ),
      Exercise(
        name: 'Rosca martelo',
        nameEn: 'Dumbbell Hammer Curl',
        muscle: 'Bíceps',
        primaryMuscle: 'Bíceps',
        highActivationMuscles: ['Braquiorradial (Antebraço)', 'Braquial'],
        secondaryMuscles: ['Antebraço'],
        sets: 3,
        reps: '12',
        load: '14 kg',
        restSeconds: 60,
        equipment: 'Halteres',
        instructions:
            'Segure os halteres com pegada neutra (palmas voltadas para dentro) e flexione os antebraços alternada ou simultaneamente.',
      ),
      Exercise(
        name: 'Agachamento livre',
        nameEn: 'Barbell Back Squat',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Isquiotibiais', 'Lombar', 'Panturrilha', 'Abdômen'],
        sets: 4,
        reps: '8',
        load: '80 kg',
        restSeconds: 120,
        equipment: 'Barra olímpica e suporte de agachamento',
        instructions:
            'Apoie a barra sobre o trapézio, pés alinhados aos ombros. Flexione quadris e joelhos até passar da linha paralela mantendo o peito erguido.',
      ),
      Exercise(
        name: 'Leg press 45°',
        nameEn: '45° Leg Press',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Isquiotibiais', 'Panturrilha'],
        sets: 4,
        reps: '12',
        load: '180 kg',
        restSeconds: 90,
        equipment: 'Aparelho Leg Press 45°',
        instructions:
            'Pés na plataforma na largura dos ombros, destrave a máquina e desça a plataforma até 90 graus de flexão nos joelhos sem arredondar a lombar.',
      ),
      Exercise(
        name: 'Desenvolvimento com halteres',
        nameEn: 'Dumbbell Shoulder Press',
        muscle: 'Ombros',
        primaryMuscle: 'Deltoides',
        highActivationMuscles: ['Tríceps', 'Trapézio'],
        secondaryMuscles: ['Peitoral superior', 'Core'],
        sets: 3,
        reps: '10',
        load: '20 kg',
        restSeconds: 75,
        equipment: 'Halteres e banco com encosto',
        instructions:
            'Sentado com encosto a 90°, inicie com os halteres na altura das orelhas e empurre verticalmente até a extensão dos braços.',
      ),
      Exercise(
        name: 'Elevação lateral',
        nameEn: 'Dumbbell Lateral Raise',
        muscle: 'Ombros',
        primaryMuscle: 'Deltoides',
        highActivationMuscles: ['Trapézio', 'Deltoide anterior'],
        secondaryMuscles: ['Deltoide posterior', 'Antebraço'],
        sets: 3,
        reps: '15',
        load: '8 kg',
        restSeconds: 45,
        equipment: 'Halteres',
        instructions:
            'Com leve flexão nos cotovelos, eleve os braços lateralmente até a altura dos ombros, controlando a descida.',
      ),
      Exercise(
        name: 'Levantamento terra',
        nameEn: 'Deadlift',
        muscle: 'Costas',
        primaryMuscle: 'Lombar',
        highActivationMuscles: ['Glúteos', 'Isquiotibiais', 'Costas'],
        secondaryMuscles: ['Quadríceps', 'Trapézio', 'Antebraço', 'Abdômen'],
        sets: 3,
        reps: '6-8',
        load: '100 kg',
        restSeconds: 120,
        equipment: 'Barra olímpica no chão',
        instructions:
            'Pés sob a barra na largura dos quadris, pegada pronada ou mista. Suba estendendo quadris e joelhos simultaneamente com a barra colada ao corpo.',
      ),
      Exercise(
        name: 'Mesa flexora',
        nameEn: 'Lying Leg Curl',
        muscle: 'Posterior',
        primaryMuscle: 'Isquiotibiais',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Panturrilha'],
        sets: 3,
        reps: '12',
        load: '45 kg',
        restSeconds: 60,
        equipment: 'Mesa flexora',
        instructions:
            'Deite de bruços com o rolo logo acima dos tornozelos. Flexione as pernas aproximando os calcanhares dos glúteos.',
      ),
      Exercise(
        name: 'Cadeira extensora',
        nameEn: 'Leg Extension',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Quadríceps'],
        secondaryMuscles: ['Core'],
        sets: 3,
        reps: '12-15',
        load: '50 kg',
        restSeconds: 60,
        equipment: 'Cadeira extensora',
        instructions:
            'Sentado com as costas no encosto, estenda os joelhos até a contração máxima do quadríceps no topo.',
      ),
      Exercise(
        name: 'Gêmeos sentado',
        nameEn: 'Seated Calf Raise',
        muscle: 'Panturrilha',
        primaryMuscle: 'Panturrilha',
        highActivationMuscles: ['Sóleo'],
        secondaryMuscles: ['Pés'],
        sets: 4,
        reps: '15',
        load: '40 kg',
        restSeconds: 45,
        equipment: 'Aparelho de panturrilha sentado',
        instructions:
            'Apoie a ponta dos pés na plataforma e o rolo sobre as coxas. Abaixe os calcanhares alongando e empurre para cima na ponta dos pés.',
      ),
      Exercise(
        name: 'Abdominal crunch',
        nameEn: 'Abdominal Crunch',
        muscle: 'Abdômen',
        primaryMuscle: 'Abdômen',
        highActivationMuscles: ['Oblíquos'],
        secondaryMuscles: ['Transverso do abdômen'],
        sets: 3,
        reps: '20',
        load: 'Corporal',
        restSeconds: 45,
        equipment: 'Colchonete',
        instructions:
            'Deitado de costas com joelhos dobrados, flexione o tronco aproximando as costelas dos quadris sem puxar a cabeça com as mãos.',
      ),
    ]);
  }

  Future<List<Exercise>> loadExercises() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return exercises;
  }

  List<Exercise> search({String? query, String? muscleGroup}) {
    return _exercises.where((e) {
      final matchesQuery = query == null ||
          query.trim().isEmpty ||
          e.name.toLowerCase().contains(query.trim().toLowerCase()) ||
          (e.nameEn?.toLowerCase().contains(query.trim().toLowerCase()) ?? false);

      final matchesMuscle = muscleGroup == null ||
          muscleGroup.isEmpty ||
          muscleGroup == 'Todos' ||
          e.muscle.toLowerCase() == muscleGroup.toLowerCase() ||
          (e.primaryMuscle?.toLowerCase().contains(muscleGroup.toLowerCase()) ??
              false);

      return matchesQuery && matchesMuscle;
    }).toList();
  }

  List<String> getAvailableMuscleGroups() {
    final groups = <String>{'Todos'};
    for (final e in _exercises) {
      if (e.muscle.isNotEmpty) {
        groups.add(e.muscle);
      }
    }
    return groups.toList();
  }

  @visibleForTesting
  void clearForTest() {
    _exercises.clear();
    notifyListeners();
  }

  @visibleForTesting
  void setExercisesForTest(List<Exercise> list) {
    _exercises.clear();
    _exercises.addAll(list);
    notifyListeners();
  }
}
