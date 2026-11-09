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
        id: 'supino-reto',
        name: 'Supino reto',
        nameEn: 'Barbell Flat Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: ['Tríceps', 'Deltoide anterior'],
        secondaryMuscles: ['Serrátil anterior', 'Core'],
        equipment: 'Barra e banco reto',
        instructions:
            'Deite no banco, mantenha os pés firmes no chão, desça a barra controladamente até o terço inferior do esterno e empurre estendendo os braços.',
      ),
      Exercise(
        id: 'supino-inclinado-com-halteres',
        name: 'Supino inclinado com halteres',
        nameEn: 'Incline Dumbbell Bench Press',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral superior',
        highActivationMuscles: ['Deltoide anterior', 'Tríceps'],
        secondaryMuscles: ['Serrátil anterior', 'Core'],
        equipment: 'Halteres e banco inclinado 30-45°',
        instructions:
            'Posicione os halteres na altura do peito superior com banco a 30-45 graus, empurre convergindo levemente no topo sem bater os halteres.',
      ),
      Exercise(
        id: 'crucifixo-na-maquina',
        name: 'Crucifixo na máquina',
        nameEn: 'Machine Chest Fly / Pec Deck',
        muscle: 'Peito',
        primaryMuscle: 'Peitoral maior',
        highActivationMuscles: ['Deltoide anterior'],
        secondaryMuscles: ['Bíceps (cabeça curta)'],
        equipment: 'Máquina Pec Deck',
        instructions:
            'Ajuste o assento para que as manoplas fiquem na altura do meio do peito. Aproxime os braços em arco focando na contração máxima.',
      ),
      Exercise(
        id: 'triceps-testa',
        name: 'Tríceps testa',
        nameEn: 'Skull Crusher / Lying Triceps Extension',
        muscle: 'Tríceps',
        primaryMuscle: 'Tríceps',
        highActivationMuscles: ['Antebraço'],
        secondaryMuscles: ['Deltoide anterior'],
        equipment: 'Barra W / Halteres e banco',
        instructions:
            'Deitado no banco com os braços verticais, flexione apenas os cotovelos descendo a barra até próximo à testa e estenda.',
      ),
      Exercise(
        id: 'triceps-na-polia',
        name: 'Tríceps na polia',
        nameEn: 'Triceps Cable Pushdown',
        muscle: 'Tríceps',
        primaryMuscle: 'Tríceps',
        highActivationMuscles: ['Antebraço'],
        secondaryMuscles: ['Peitoral', 'Abdômen'],
        equipment: 'Polia alta com barra reta ou corda',
        instructions:
            'Mantenha os cotovelos fixos junto ao tronco, empurre o cabo para baixo até a extensão completa dos cotovelos.',
      ),
      Exercise(
        id: 'puxada-frontal',
        name: 'Puxada frontal',
        nameEn: 'Lat Pulldown',
        muscle: 'Costas',
        primaryMuscle: 'Grande dorsal',
        highActivationMuscles: ['Bíceps', 'Redondo maior'],
        secondaryMuscles: ['Trapézio', 'Romboides', 'Antebraço'],
        equipment: 'Polia alta com barra ampla',
        instructions:
            'Segure a barra com pegada pronada aberta, puxe em direção à parte superior do peito projetando o esterno para frente.',
      ),
      Exercise(
        id: 'remada-curvada',
        name: 'Remada curvada',
        nameEn: 'Bent-Over Barbell Row',
        muscle: 'Costas',
        primaryMuscle: 'Costas',
        highActivationMuscles: ['Bíceps', 'Trapézio', 'Deltoide posterior'],
        secondaryMuscles: ['Lombar', 'Glúteos', 'Isquiotibiais'],
        equipment: 'Barra com anilhas',
        instructions:
            'Incline o tronco a cerca de 45°, mantenha a coluna neutra e puxe a barra em direção ao umbigo contraindo as escápulas.',
      ),
      Exercise(
        id: 'rosca-direta',
        name: 'Rosca direta',
        nameEn: 'Barbell Biceps Curl',
        muscle: 'Bíceps',
        primaryMuscle: 'Bíceps',
        highActivationMuscles: ['Braquial', 'Braquiorradial'],
        secondaryMuscles: ['Antebraço', 'Deltoide anterior'],
        equipment: 'Barra reta ou W',
        instructions:
            'Em pé com postura ereta, flexione os cotovelos elevando a barra sem balançar o corpo, controlando a fase excêntrica.',
      ),
      Exercise(
        id: 'rosca-martelo',
        name: 'Rosca martelo',
        nameEn: 'Dumbbell Hammer Curl',
        muscle: 'Bíceps',
        primaryMuscle: 'Bíceps',
        highActivationMuscles: ['Braquiorradial (Antebraço)', 'Braquial'],
        secondaryMuscles: ['Antebraço'],
        equipment: 'Halteres',
        instructions:
            'Segure os halteres com pegada neutra (palmas voltadas para dentro) e flexione os antebraços alternada ou simultaneamente.',
      ),
      Exercise(
        id: 'agachamento-livre',
        name: 'Agachamento livre',
        nameEn: 'Barbell Back Squat',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Isquiotibiais', 'Lombar', 'Panturrilha', 'Abdômen'],
        equipment: 'Barra olímpica e suporte de agachamento',
        instructions:
            'Apoie a barra sobre o trapézio, pés alinhados aos ombros. Flexione quadris e joelhos até passar da linha paralela mantendo o peito erguido.',
      ),
      Exercise(
        id: 'leg-press-45',
        name: 'Leg press 45°',
        nameEn: '45° Leg Press',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Isquiotibiais', 'Panturrilha'],
        equipment: 'Aparelho Leg Press 45°',
        instructions:
            'Pés na plataforma na largura dos ombros, destrave a máquina e desça a plataforma até 90 graus de flexão nos joelhos sem arredondar a lombar.',
      ),
      Exercise(
        id: 'desenvolvimento-com-halteres',
        name: 'Desenvolvimento com halteres',
        nameEn: 'Dumbbell Shoulder Press',
        muscle: 'Ombros',
        primaryMuscle: 'Deltoides',
        highActivationMuscles: ['Tríceps', 'Trapézio'],
        secondaryMuscles: ['Peitoral superior', 'Core'],
        equipment: 'Halteres e banco com encosto',
        instructions:
            'Sentado com encosto a 90°, inicie com os halteres na altura das orelhas e empurre verticalmente até a extensão dos braços.',
      ),
      Exercise(
        id: 'elevacao-lateral',
        name: 'Elevação lateral',
        nameEn: 'Dumbbell Lateral Raise',
        muscle: 'Ombros',
        primaryMuscle: 'Deltoides',
        highActivationMuscles: ['Trapézio', 'Deltoide anterior'],
        secondaryMuscles: ['Deltoide posterior', 'Antebraço'],
        equipment: 'Halteres',
        instructions:
            'Com leve flexão nos cotovelos, eleve os braços lateralmente até a altura dos ombros, controlando a descida.',
      ),
      Exercise(
        id: 'levantamento-terra',
        name: 'Levantamento terra',
        nameEn: 'Deadlift',
        muscle: 'Costas',
        primaryMuscle: 'Lombar',
        highActivationMuscles: ['Glúteos', 'Isquiotibiais', 'Costas'],
        secondaryMuscles: ['Quadríceps', 'Trapézio', 'Antebraço', 'Abdômen'],
        equipment: 'Barra olímpica no chão',
        instructions:
            'Pés sob a barra na largura dos quadris, pegada pronada ou mista. Suba estendendo quadris e joelhos simultaneamente com a barra colada ao corpo.',
      ),
      Exercise(
        id: 'mesa-flexora',
        name: 'Mesa flexora',
        nameEn: 'Lying Leg Curl',
        muscle: 'Posterior',
        primaryMuscle: 'Isquiotibiais',
        highActivationMuscles: ['Glúteos'],
        secondaryMuscles: ['Panturrilha'],
        equipment: 'Mesa flexora',
        instructions:
            'Deite de bruços com o rolo logo acima dos tornozelos. Flexione as pernas aproximando os calcanhares dos glúteos.',
      ),
      Exercise(
        id: 'cadeira-extensora',
        name: 'Cadeira extensora',
        nameEn: 'Leg Extension',
        muscle: 'Quadríceps',
        primaryMuscle: 'Quadríceps',
        highActivationMuscles: ['Quadríceps'],
        secondaryMuscles: ['Core'],
        equipment: 'Cadeira extensora',
        instructions:
            'Sentado com as costas no encosto, estenda os joelhos até a contração máxima do quadríceps no topo.',
      ),
      Exercise(
        id: 'gemeos-sentado',
        name: 'Gêmeos sentado',
        nameEn: 'Seated Calf Raise',
        muscle: 'Panturrilha',
        primaryMuscle: 'Panturrilha',
        highActivationMuscles: ['Sóleo'],
        secondaryMuscles: ['Pés'],
        equipment: 'Aparelho de panturrilha sentado',
        instructions:
            'Apoie a ponta dos pés na plataforma e o rolo sobre as coxas. Abaixe os calcanhares alongando e empurre para cima na ponta dos pés.',
      ),
      Exercise(
        id: 'abdominal-crunch',
        name: 'Abdominal crunch',
        nameEn: 'Abdominal Crunch',
        muscle: 'Abdômen',
        primaryMuscle: 'Abdômen',
        highActivationMuscles: ['Oblíquos'],
        secondaryMuscles: ['Transverso do abdômen'],
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

  /// Busca um exercício pelo identificador fixo; null se não existir.
  Exercise? findById(String id) {
    for (final exercise in _exercises) {
      if (exercise.id == id) return exercise;
    }
    return null;
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
