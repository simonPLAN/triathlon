// Noms des sports
const String sportNatation = 'Natation';
const String sportVelo = 'Vélo';
const String sportCourse = 'Course à pied';

const List<String> sports = [sportNatation, sportVelo, sportCourse];

// Classement de base (barème de points par position)
const List<int> defaultPointsByPosition = [5, 4, 3, 2, 1];

// Temps de base et manches de base
const int defaultNatationRounds = 5;
const int defaultVeloRounds = 5;
const int defaultCourseRounds = 5;
const int defaultRounds = 1;

const int defaultDurationSeconds = 180;
const int defaultRestSeconds = 0;

const int minRounds = 1;
const int maxRounds = 100;
const int minDurationSeconds = 1;
const int maxDurationSeconds = 86400;
const int minRestSeconds = 0;
const int maxRestSeconds = 86400;

// Clé de stockage et titre global
const String storageKey = 'triathlon_data_v1';
const String appTitle = 'LM Triathlon Series';

// Textes de l'application
class AppTexts {
  // Titres des pages et de la navigation
  static const String appBarHome = 'Gestion du triathlon';
  static const String appBarSettings = 'Réglages des épreuves';
  static const String appBarParticipants = 'Participants';
  static const String appBarResults = 'Résultats et classements';
  static const String appBarLogin = 'Connexion';

  // Page de connexion
  static const String labelEmail = 'Adresse e-mail';
  static const String labelPassword = 'Mot de passe';
  static const String labelLogin = 'Se connecter';
  static const String labelLoggingIn = 'Connexion...';
  static const String errorLoginPrefix = 'Erreur : ';

  // Page d'accueil
  static const String homeCardTitle = 'Le Mans Triathlon Séries Light';
  static const String homeSubtitleParticipants = 'Ajouter ou supprimer des participants';
  static const String homeSubtitleNatation = 'Configurer et lancer la natation';
  static const String homeSubtitleVelo = 'Configurer et lancer le vélo';
  static const String homeSubtitleCourse = 'Configurer et lancer la course à pied';
  static const String homeSubtitleResults = 'Classements par sport et général';
  static const String tooltipSettings = 'Réglages';

  static String participantsCount(int count) => '$count participant(s) inscrit(s)';

  // Page de réglages
  static const String settingsDescription =
      'Configure chaque épreuve et le barème de points par position. '
      'Le compte à rebours démarre à la première arrivée.';
  static const String labelRounds = 'Nombre de manches';
  static const String labelCountdown = 'Compte à rebours (secondes)';
  static const String labelRest = 'Repos entre les manches (secondes)';
  static const String titlePointsAttribution = 'Attribution des points par position';
  static const String subtitlePointsAttribution =
      'Définissez les points accordés selon le rang d\'arrivée (1er, 2ème, 3ème...).';
  static const String labelAdd = 'Ajouter';
  static const String labelDelete = 'Supprimer';
  static const String labelSaveSettings = 'Enregistrer les réglages';
  static const String tooltipCopyPoints = 'Copier ce barème sur tous les sports';
  static const String msgPointsCopied = 'Barème de points copié sur toutes les épreuves.';
  static const String msgSettingsSaved = 'Réglages enregistrés avec succès !';
  static const String msgSettingsSaveError = 'Erreur lors de la sauvegarde : ';
  static const String msgInvalidSettingsValues =
      'Vérifie les valeurs : manches entre 1 et 100, '
      'durée entre 1 et 86400 secondes et repos '
      'entre 0 et 86400 secondes.';

  static String minPointsPositionError(String sport) =>
      'Ajoute au moins une position de points pour $sport.';

  static String pointsPositionError(String sport, String position) =>
      'Vérifie les points pour $sport : la position $position doit être un nombre positif.';

  // Page de gestion des participants
  static const String labelParticipantName = 'Nom du participant';
  static const String labelCoefficient = 'Coefficient';
  static const String labelCoefficientHint = 'Ex: 1.5 (1.0 par défaut)';
  static const String msgParticipantAdded = 'Participant ajouté';
  static const String msgInvalidParticipant = 'Nom vide ou participant déjà présent';
  static const String msgInvalidCoefficient = 'Le coefficient doit être un nombre positif';
  static const String msgNoParticipants = 'Aucun participant enregistré';
  static const String dialogRemoveParticipantTitle = 'Supprimer le participant ?';
  static const String dialogEditParticipantTitle = 'Modifier le coefficient';
  static const String dialogCancel = 'Annuler';
  static const String dialogDelete = 'Supprimer';
  static const String dialogSave = 'Enregistrer';
  static const String tooltipAdd = 'Ajouter';
  static const String tooltipDelete = 'Supprimer';
  static const String tooltipEditParticipant = 'Modifier le coefficient';

  static String participantCoefficientLabel(double coef) =>
      'Coef : x${coef == coef.toInt() ? coef.toInt().toString() : coef.toString()}';

  static String removeParticipantContent(String name) =>
      'Supprimer $name et ses arrivées enregistrées ?';

  // Page d'une épreuve (SportPage)
  static const String statusFinished = 'Épreuve terminée';
  static const String statusResting = 'Repos avant la prochaine manche';
  static const String statusRunning = 'Temps restant pour les arrivées';
  static const String statusWaiting = 'En attente de la première arrivée';
  static const String countdownInfo = 'Le compte à rebours démarre à la première arrivée.';
  static const String instructionTapParticipant = 'Appuie sur le participant qui arrive';
  static const String labelUndoLastArrival = 'Annuler la dernière arrivée';
  static const String labelFinishRoundNow = 'Terminer la manche maintenant';
  static const String labelArrivalOrder = 'Ordre des arrivées';
  static const String msgNoArrivals = 'Aucune arrivée enregistrée.';
  static const String labelRestartSport = 'Recommencer cette épreuve';
  static const String tooltipResetSport = 'Réinitialiser cette épreuve';

  static String roundLabel(int currentRound, int totalRounds) =>
      'Manche $currentRound / $totalRounds';

  static String arrivalOrderWithCount(int count) => 'Ordre des arrivées ($count)';

  static String arrivalPositionLabel(int position) => 'Position $position';

  // Page des résultats
  static const String titleGeneralRanking = 'Classement général';
  static const String titleSportRankings = 'Classements par sport';
  static const String msgNoParticipantsInscribed = 'Aucun participant inscrit.';
  static const String resultsExplanation =
      'Les points dépendent de l’ordre des arrivées dans chaque manche selon le barème configuré et le coefficient éventuel de chaque participant. '
      'Le classement général additionne les points des trois sports.';

  static String ptsSuffix(int points) => '$points pts';

  static String sportSubtitle(int rounds, List<int> points) =>
      '$rounds manches • Barème : ${points.join("-")} pts';

  // Chargement / Erreurs globales
  static const String errorLoading = 'Erreur de chargement : ';
  static const String errorNoSupabaseUser = 'Aucun utilisateur Supabase connecté.';
}
