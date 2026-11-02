class TempsResultat {
  static int? lire(String texte) {
    final match = RegExp(r'^(\d{1,5}):([0-5]\d)(?:[.,](\d{1,3}))?$')
        .firstMatch(texte.trim());
    if (match == null) return null;
    final ms =
        (int.parse(match[1]!) * 60 + int.parse(match[2]!)) * 1000 +
        int.parse((match[3] ?? '').padRight(3, '0'));
    return ms <= 604800000 ? ms : null;
  }

  static String formater(int ms) {
    final valeur = ms.abs();
    final minutes = (valeur ~/ 60000).toString().padLeft(2, '0');
    final secondes = ((valeur ~/ 1000) % 60).toString().padLeft(2, '0');
    final milliemes = (valeur % 1000).toString().padLeft(3, '0');
    return '${ms < 0 ? '-' : ''}$minutes:$secondes.$milliemes';
  }
}
