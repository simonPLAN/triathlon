import 'resultat.dart';
import 'statut_resultat.dart';

enum ModeReclassement { decaler, echanger, temps }

class ModificationResultat {
  const ModificationResultat({
    required this.mancheId,
    required this.athleteId,
    required this.revision,
    required this.statut,
    required this.mode,
    this.resultatId,
    this.position,
    this.tempsMillisecondes,
    this.commentaire,
    this.accepterDepublication = false,
  });
  final String mancheId;
  final String athleteId;
  final String? resultatId;
  final int revision;
  final StatutResultat statut;
  final ModeReclassement mode;
  final int? position;
  final int? tempsMillisecondes;
  final String? commentaire;
  final bool accepterDepublication;
}

class EditionResultats {
  const EditionResultats({
    required this.resultats,
    required this.revision,
    required this.depublies,
  });
  final List<Resultat> resultats;
  final int revision;
  final bool depublies;
}
