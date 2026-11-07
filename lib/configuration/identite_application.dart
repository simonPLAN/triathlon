class IdentiteApplication {
  static const _nom = String.fromEnvironment('APP_NAME');
  static const _flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');
  static String get nom => _nom.isNotEmpty
      ? _nom
      : (_flavor == 'staging'
          ? 'Le Mans Triathlon Series (test)'
          : 'Le Mans Triathlon Series');
}
