import '../domain/models.dart';

DateTime dt(dynamic v) => DateTime.parse(v as String).toLocal();
DateTime? dtn(dynamic v) =>
    v == null ? null : DateTime.parse(v as String).toLocal();

RoleUtilisateur roleFrom(String v) =>
    v == 'coach' ? RoleUtilisateur.coach : RoleUtilisateur.athlete;
StatutCompetition competitionStatutFrom(String v) => switch (v) {
  'ouverte' => StatutCompetition.ouverte,
  'en_cours' => StatutCompetition.enCours,
  'terminee' => StatutCompetition.terminee,
  'annulee' => StatutCompetition.annulee,
  _ => StatutCompetition.brouillon,
};
String competitionStatutTo(StatutCompetition v) => switch (v) {
  StatutCompetition.ouverte => 'ouverte',
  StatutCompetition.enCours => 'en_cours',
  StatutCompetition.terminee => 'terminee',
  StatutCompetition.annulee => 'annulee',
  _ => 'brouillon',
};
Discipline disciplineFrom(String v) => switch (v) {
  'velo' => Discipline.velo,
  'course_a_pied' => Discipline.courseAPied,
  _ => Discipline.natation,
};
String disciplineTo(Discipline v) => switch (v) {
  Discipline.velo => 'velo',
  Discipline.courseAPied => 'course_a_pied',
  _ => 'natation',
};
StatutManche mancheStatutFrom(String v) => switch (v) {
  'en_cours' => StatutManche.enCours,
  'terminee' => StatutManche.terminee,
  'annulee' => StatutManche.annulee,
  _ => StatutManche.aVenir,
};
String mancheStatutTo(StatutManche v) => switch (v) {
  StatutManche.enCours => 'en_cours',
  StatutManche.terminee => 'terminee',
  StatutManche.annulee => 'annulee',
  _ => 'a_venir',
};
StatutResultat resultatStatutFrom(String v) => switch (v) {
  'hors_delai' => StatutResultat.horsDelai,
  'abandon' => StatutResultat.abandon,
  'disqualifie' => StatutResultat.disqualifie,
  _ => StatutResultat.arrive,
};
