import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';
import 'mappers.dart';

class AppRepository {
  AppRepository(this.client);
  final SupabaseClient client;
  String get uid =>
      client.auth.currentUser?.id ??
      (throw StateError('Aucun utilisateur connecté.'));

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({
    required String pseudo,
    required String email,
    required String password,
  }) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'pseudo': pseudo.trim()},
    );
  }

  Future<void> signOut() => client.auth.signOut();

  Future<ProfilUtilisateur> profilConnecte() async {
    final m = await client
        .from('profils')
        .select('id,pseudo,role')
        .eq('id', uid)
        .single();
    return ProfilUtilisateur(
      id: m['id'],
      prenom: m['pseudo'],
      nom: '',
      role: roleFrom(m['role']),
    );
  }

  Future<List<Competition>> competitionsCoach() async {
    final rows = await client
        .from('competitions')
        .select()
        .eq('coach_id', uid)
        .order('date_competition');
    return rows.map<Competition>(_competition).toList();
  }

  Future<List<Competition>> competitionsOuvertes() async {
    final rows = await client
        .from('competitions')
        .select()
        .eq('statut', 'ouverte')
        .order('date_competition');
    return rows.map<Competition>(_competition).toList();
  }

  Competition _competition(Map<String, dynamic> m) => Competition(
    id: m['id'],
    nom: m['nom'],
    description: m['description'],
    lieu: m['lieu'],
    dateCompetition: dt(m['date_competition']),
    coachId: m['coach_id'],
    statut: competitionStatutFrom(m['statut']),
    dateCreation: dt(m['date_creation']),
    dateModification: dt(m['date_modification']),
  );
  Future<Competition> creerCompetition({
    required String nom,
    required DateTime date,
    String? lieu,
    String? description,
  }) async {
    final m = await client
        .from('competitions')
        .insert({
          'nom': nom.trim(),
          'description': description?.trim(),
          'lieu': lieu?.trim(),
          'date_competition':
              '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'coach_id': uid,
          'statut': 'brouillon',
        })
        .select()
        .single();
    return _competition(m);
  }

  Future<Competition> changerStatut(Competition c, StatutCompetition s) async {
    final m = await client
        .from('competitions')
        .update({'statut': competitionStatutTo(s)})
        .eq('id', c.id)
        .select()
        .single();
    return _competition(m);
  }

  Future<void> supprimerCompetition(String id) async {
    await client.from('competitions').delete().eq('id', id);
  }

  Future<List<Epreuve>> epreuves(String competitionId) async {
    final rows = await client
        .from('epreuves')
        .select()
        .eq('competition_id', competitionId)
        .order('ordre');
    return rows.map<Epreuve>(_epreuve).toList();
  }

  Epreuve _epreuve(Map<String, dynamic> m) => Epreuve(
    id: m['id'],
    competitionId: m['competition_id'],
    discipline: disciplineFrom(m['discipline']),
    nom: m['nom'],
    distanceMetres: m['distance_metres'],
    nombreManches: m['nombre_manches'],
    ordre: m['ordre'],
    dureeLimiteSecondes: m['duree_limite_secondes'],
  );
  Future<Epreuve> creerEpreuve({
    required String competitionId,
    required Discipline discipline,
    required String nom,
    required int distance,
    required int nombreManches,
    required int ordre,
    required int delai,
  }) async {
    final m = await client
        .from('epreuves')
        .insert({
          'competition_id': competitionId,
          'discipline': disciplineTo(discipline),
          'nom': nom.trim(),
          'distance_metres': distance,
          'nombre_manches': nombreManches,
          'ordre': ordre,
          'duree_limite_secondes': delai,
        })
        .select()
        .single();
    return _epreuve(m);
  }

  Future<List<Manche>> manches(String epreuveId) async {
    final rows = await client
        .from('manches')
        .select()
        .eq('epreuve_id', epreuveId)
        .order('numero');
    return rows.map<Manche>(_manche).toList();
  }

  Manche _manche(Map<String, dynamic> m) => Manche(
    id: m['id'],
    epreuveId: m['epreuve_id'],
    numero: m['numero'],
    statut: mancheStatutFrom(m['statut']),
    heureDepart: dtn(m['heure_depart']),
    heurePremiereArrivee: dtn(m['heure_premiere_arrivee']),
    heureFinDelai: dtn(m['heure_fin_delai']),
    resultatsPublies: m['resultats_publies'],
  );
  Future<List<Manche>> genererManches(Epreuve e) async {
    final existing = await manches(e.id);
    if (existing.isNotEmpty) return existing;
    final payload = List.generate(
      e.nombreManches,
      (i) => {'epreuve_id': e.id, 'numero': i + 1, 'statut': 'a_venir'},
    );
    final rows = await client.from('manches').insert(payload).select();
    return rows.map<Manche>(_manche).toList()
      ..sort((a, b) => a.numero.compareTo(b.numero));
  }

  Future<Manche> majManche(
    Manche m, {
    StatutManche? statut,
    DateTime? depart,
    DateTime? premiere,
    DateTime? fin,
    bool? publies,
  }) async {
    final row = await client
        .from('manches')
        .update({
          'statut': mancheStatutTo(statut ?? m.statut),
          'heure_depart':
              depart?.toUtc().toIso8601String() ??
              m.heureDepart?.toUtc().toIso8601String(),
          'heure_premiere_arrivee':
              premiere?.toUtc().toIso8601String() ??
              m.heurePremiereArrivee?.toUtc().toIso8601String(),
          'heure_fin_delai':
              fin?.toUtc().toIso8601String() ??
              m.heureFinDelai?.toUtc().toIso8601String(),
          'resultats_publies': publies ?? m.resultatsPublies,
        })
        .eq('id', m.id)
        .select()
        .single();
    return _manche(row);
  }

  Future<Inscription?> monInscription(String competitionId) async {
    final row = await client
        .from('inscriptions')
        .select(
          'id,competition_id,numero_dossard,date_inscription,athlete:profils!inscriptions_athlete_id_fkey(id,prenom,nom,role)',
        )
        .eq('competition_id', competitionId)
        .eq('athlete_id', uid)
        .maybeSingle();
    return row == null ? null : _inscription(row);
  }

  Future<Inscription> inscrire(String competitionId) async {
    final row = await client
        .from('inscriptions')
        .insert({'competition_id': competitionId, 'athlete_id': uid})
        .select(
          'id,competition_id,numero_dossard,date_inscription,athlete:profils!inscriptions_athlete_id_fkey(id,prenom,nom,role)',
        )
        .single();
    return _inscription(row);
  }

  Future<void> desinscrire(String id) async {
    await client.from('inscriptions').delete().eq('id', id);
  }

  Future<List<Inscription>> inscriptions(String competitionId) async {
    final rows = await client
        .from('inscriptions')
        .select(
          'id,competition_id,numero_dossard,date_inscription,athlete:profils!inscriptions_athlete_id_fkey(id,prenom,nom,role)',
        )
        .eq('competition_id', competitionId)
        .order('numero_dossard');
    return rows.map<Inscription>(_inscription).toList();
  }

  Inscription _inscription(Map<String, dynamic> m) {
    final a = m['athlete'];
    return Inscription(
      id: m['id'],
      competitionId: m['competition_id'],
      numeroDossard: m['numero_dossard'],
      dateInscription: dt(m['date_inscription']),
      athlete: ProfilUtilisateur(
        id: a['id'],
        prenom: a['prenom'],
        nom: a['nom'],
        role: roleFrom(a['role']),
      ),
    );
  }

  Future<void> attribuerDossard(String id, int? numero) async {
    await client
        .from('inscriptions')
        .update({'numero_dossard': numero})
        .eq('id', id);
  }

  Future<List<Resultat>> resultats(String mancheId) async {
    final rows = await client
        .from('resultats')
        .select(
          'id,manche_id,position,points,heure_arrivee,statut,athlete:profils!resultats_athlete_id_fkey(id,prenom,nom,role)',
        )
        .eq('manche_id', mancheId)
        .order('position');
    return rows.map<Resultat>(_resultat).toList();
  }

  Resultat _resultat(Map<String, dynamic> m) {
    final a = m['athlete'];
    return Resultat(
      id: m['id'],
      mancheId: m['manche_id'],
      athlete: ProfilUtilisateur(
        id: a['id'],
        prenom: a['prenom'],
        nom: a['nom'],
        role: roleFrom(a['role']),
      ),
      position: m['position'],
      points: m['points'],
      statut: resultatStatutFrom(m['statut']),
      heureArrivee: dtn(m['heure_arrivee']),
    );
  }

  Future<Resultat> enregistrerArrivee({
    required Manche manche,
    required ProfilUtilisateur athlete,
  }) async {
    final exist = await resultats(manche.id);
    final position = exist.where((r) => r.position != null).length + 1;
    final points = position <= 5 ? 6 - position : 0;
    final now = DateTime.now();
    final total = now.difference(manche.heureDepart!).inMilliseconds;
    final first = manche.heurePremiereArrivee ?? now;
    final row = await client
        .from('resultats')
        .insert({
          'manche_id': manche.id,
          'athlete_id': athlete.id,
          'position': position,
          'points': points,
          'heure_arrivee': now.toUtc().toIso8601String(),
          'temps_total_millisecondes': total,
          'ecart_premier_millisecondes': now.difference(first).inMilliseconds,
          'statut': 'arrive',
        })
        .select(
          'id,manche_id,position,points,heure_arrivee,statut,athlete:profils!resultats_athlete_id_fkey(id,prenom,nom,role)',
        )
        .single();
    return _resultat(row);
  }
}
