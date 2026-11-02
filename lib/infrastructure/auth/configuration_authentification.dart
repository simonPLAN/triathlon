class ConfigurationAuthentification {
  ConfigurationAuthentification({
    required this.environnement,
    required this.urlSupabase,
    required this.clePublique,
  }) {
    if (!{'production', 'staging'}.contains(environnement)) {
      throw ArgumentError('APP_ENV doit être production ou staging.');
    }
    if (urlSupabase.isEmpty || clePublique.isEmpty) {
      throw ArgumentError(
        'Configurer SUPABASE_URL et SUPABASE_PUBLISHABLE_KEY.',
      );
    }
  }

  factory ConfigurationAuthentification.environnement() {
    const environnement = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'production',
    );
    const url = String.fromEnvironment('SUPABASE_URL');
    const cle = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    return ConfigurationAuthentification(
      environnement: environnement,
      urlSupabase: url.isNotEmpty
          ? url
          : (environnement == 'production'
                ? 'https://dgjtfhslcbrgsdczlvdg.supabase.co'
                : ''),
      clePublique: cle.isNotEmpty
          ? cle
          : (environnement == 'production'
                ? 'sb_publishable_YkkAvzFAOUZKJQwUxZKl-A_HJsJLBWT'
                : ''),
    );
  }

  final String environnement;
  final String urlSupabase;
  final String clePublique;

  Uri get redirection => Uri.parse(
    '${environnement == 'staging' ? 'triathlon-staging' : 'triathlon'}://auth/reset-password',
  );
}
