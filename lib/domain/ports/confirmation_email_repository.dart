abstract interface class ConfirmationEmailRepository {
  Future<void> renvoyer(String email);
  Future<void> confirmer(String code);
  bool get possedeSession;
}
