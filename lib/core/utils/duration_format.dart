/// Formata um tempo de cronômetro como "MM:SS", ou "H:MM:SS" a partir de 1 hora.
String formatStopwatch(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes % 60);
  final seconds = twoDigits(duration.inSeconds % 60);

  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
