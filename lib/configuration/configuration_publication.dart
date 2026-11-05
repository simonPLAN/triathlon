abstract final class ConfigurationPublication {
  static const politiqueConfidentialiteUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
  static const suppressionCompteUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
  );
  static const emailSupport = String.fromEnvironment('SUPPORT_EMAIL');

  static bool urlPubliqueValide(String valeur) {
    final uri = Uri.tryParse(valeur);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.contains('.') &&
        uri.userInfo.isEmpty &&
        !uri.hasFragment;
  }

  static bool get estComplete =>
      urlPubliqueValide(politiqueConfidentialiteUrl) &&
      urlPubliqueValide(suppressionCompteUrl) &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(emailSupport);
}
