import 'role_utilisateur.dart';

class ProfilUtilisateur {
  const ProfilUtilisateur({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.role,
  });

  final String id;
  final String prenom;
  final String nom;
  final RoleUtilisateur role;

  String get nomComplet => '$prenom $nom';

  bool get estCoach => role == RoleUtilisateur.coach;

  bool get estAthlete => role == RoleUtilisateur.athlete;
}
