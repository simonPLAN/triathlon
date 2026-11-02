class LienRecuperation {
  const LienRecuperation(this.redirection);
  final Uri redirection;

  bool correspond(Uri lien) =>
      lien.scheme == redirection.scheme &&
      lien.host == redirection.host &&
      lien.path == redirection.path &&
      !lien.hasPort &&
      lien.userInfo.isEmpty;
}
