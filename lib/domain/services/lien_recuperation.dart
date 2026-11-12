class LienRecuperation {
  const LienRecuperation(this.redirection);
  final Uri redirection;

  bool correspond(Uri lien) =>
      lien.scheme == redirection.scheme &&
      lien.host == redirection.host &&
      (lien.path == redirection.path ||
          ((redirection.scheme == 'https' || redirection.scheme == 'http') &&
              lien.path == '${redirection.path}/')) &&
      lien.port == redirection.port &&
      lien.userInfo.isEmpty;
}
