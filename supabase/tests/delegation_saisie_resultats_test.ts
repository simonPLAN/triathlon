import { PGlite } from "npm:@electric-sql/pglite@0.5.14";

const migration = await Deno.readTextFile(
  new URL("../migrations/202611130007_delegation_saisie_resultats.sql", import.meta.url),
);
const id = (n: number) =>
  "97000000-0000-4000-8000-" + n.toString().padStart(12, "0");
function assert(ok: unknown, message = "Assertion échouée"): asserts ok {
  if (!ok) throw new Error(message);
}
async function refuse(action: () => Promise<unknown>) {
  let refusee = false;
  try { await action(); } catch { refusee = true; }
  assert(refusee, "L’opération devait être refusée");
}
async function utilisateur(db: PGlite, n: number) {
  await db.exec("reset role");
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id(n)]);
  await db.exec("set role authenticated");
}
async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table profils(
      id uuid primary key,compte_id uuid,role text,pseudo text,
      est_invite boolean default false,est_archive boolean default false
    );
    create table competitions(
      id uuid primary key,nom text,description text,lieu text,date_competition date,
      coach_id uuid references profils,statut text,date_creation timestamptz default now(),
      date_modification timestamptz default now(),
      demarrage_automatique_manche_suivante boolean default false
    );
    create table epreuves(
      id uuid primary key,competition_id uuid references competitions,nom text,
      discipline text,distance_metres integer,nombre_manches integer,ordre integer,
      duree_limite_secondes integer,date_creation timestamptz default now(),
      date_modification timestamptz default now()
    );
    create table manches(
      id uuid primary key,epreuve_id uuid references epreuves,numero integer,statut text,
      heure_depart timestamptz,heure_premiere_arrivee timestamptz,heure_fin_delai timestamptz,
      resultats_publies boolean default false,revision_resultats bigint default 0,
      revision_validation_resultats bigint,participants_definis boolean default true,
      duree_limite_secondes integer,date_creation timestamptz default now(),
      date_modification timestamptz default now()
    );
    create table inscriptions(
      id uuid primary key default gen_random_uuid(),competition_id uuid references competitions,
      athlete_id uuid references profils,numero_dossard integer,
      date_inscription timestamptz default now()
    );
    create table participants_manche(
      manche_id uuid references manches,athlete_id uuid references profils,
      ordre_depart integer,primary key(manche_id,athlete_id)
    );
    create table resultats(
      id uuid primary key default gen_random_uuid(),manche_id uuid references manches,
      athlete_id uuid references profils,position integer,points integer default 0,
      heure_arrivee timestamptz,temps_total_millisecondes bigint,
      ecart_premier_millisecondes bigint,statut text,commentaire text,
      date_publication timestamptz,date_creation timestamptz default now(),
      date_modification timestamptz default now(),unique(manche_id,athlete_id)
    );
    insert into profils values
      ('${id(1)}','${id(1)}','coach','responsable',false,false),
      ('${id(2)}','${id(2)}','coach','delegue',false,false),
      ('${id(3)}','${id(3)}','coach','autre',false,false),
      ('${id(4)}','${id(4)}','athlete','athlete',false,false);
    insert into competitions(id,nom,date_competition,coach_id,statut)
      values('${id(10)}','Compétition',current_date,'${id(1)}','en_cours');
    insert into epreuves(id,competition_id,nom,discipline,distance_metres,nombre_manches,ordre,duree_limite_secondes)
      values('${id(20)}','${id(10)}','Natation','natation',500,1,1,60);
    insert into manches(id,epreuve_id,numero,statut,heure_depart)
      values('${id(30)}','${id(20)}',1,'en_cours',now()-interval '10 seconds');
    insert into inscriptions(competition_id,athlete_id,numero_dossard)
      values('${id(10)}','${id(4)}',4);
    insert into participants_manche values('${id(30)}','${id(4)}',1);

    create function securite_identite_valide(p_role text default null)
    returns boolean language sql stable as $$
      select exists(select 1 from profils p where p.id=auth.uid()
        and p.compte_id=p.id and not p.est_invite and not p.est_archive
        and (p_role is null or p.role=p_role)) $$;
    create function programme_competition_visible(p_id uuid)
    returns boolean language sql stable as $$
      select exists(select 1 from competitions where id=p_id and coach_id=auth.uid()) $$;
    create function programme_epreuve_visible(p_id uuid)
    returns boolean language sql stable as $$
      select exists(select 1 from epreuves e where e.id=p_id
        and programme_competition_visible(e.competition_id)) $$;
    create function programme_epreuve_modifiable(p_id uuid)
    returns boolean language sql stable as $$
      select exists(select 1 from epreuves e join competitions c on c.id=e.competition_id
        where e.id=p_id and c.coach_id=auth.uid()) $$;
    create function securite_coach_competition(p_id uuid)
    returns boolean language sql stable as $$
      select exists(select 1 from competitions where id=p_id and coach_id=auth.uid()) $$;
    create function securite_profil_visible(p_id uuid) returns boolean language sql stable as $$select p_id=auth.uid()$$;
    create function securite_resultat_visible(p_id uuid) returns boolean language sql stable as $$select false$$;
    create function securite_resultat_modifiable(p_id uuid) returns boolean language sql stable as $$select false$$;
    create function cloturer_manche_interne(p_id uuid) returns uuid language sql as $$select p_id$$;
    create function publier_resultats_manche_base(p_id uuid,p_revision bigint)
      returns jsonb language sql as $$select '{}'::jsonb$$;

    alter table epreuves enable row level security;
    alter table manches enable row level security;
    alter table resultats enable row level security;
    alter table profils enable row level security;
    alter table participants_manche enable row level security;
    create policy "Programme lecture epreuves" on epreuves for select to public using(programme_competition_visible(competition_id));
    create policy "Production plafond select" on epreuves as restrictive for select to authenticated using(true);
    create policy "Production acces select" on epreuves for select to authenticated using(true);
    create policy "Programme lecture manches" on manches for select to public using(programme_epreuve_visible(epreuve_id));
    create policy resultats_select on resultats for select to authenticated using(securite_resultat_visible(manche_id));
    create policy resultats_insert on resultats for insert to authenticated with check(securite_resultat_modifiable(manche_id));
    create policy profils_select on profils for select to authenticated using(securite_profil_visible(id));
    create policy participants_manche_lecture on participants_manche for select to authenticated using(false);
    grant usage on schema auth to authenticated;
    grant select on epreuves,manches,resultats,profils,participants_manche to authenticated;
    grant insert on resultats to authenticated;
  `);
  await db.exec(migration);
  return db;
}

Deno.test("le responsable choisit un coach et celui-ci voit uniquement l’épreuve partagée", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await db.query("select autoriser_coach_epreuve($1,$2)", [id(20), "delegue"]);
    const liste = await db.query<{id:string}>("select (x->'epreuve'->>'id') id from lister_epreuves_partagees() x");
    assert(liste.rows.length === 0, "Le responsable ne doit pas recevoir ses propres partages");
    await utilisateur(db, 2);
    const partagees = await db.query<{id:string}>("select (x->'epreuve'->>'id') id from lister_epreuves_partagees() x");
    assert(partagees.rows.length === 1 && partagees.rows[0].id === id(20));
    const participants = await db.query("select * from lister_participants_manche_delegue($1)", [id(30)]);
    assert(participants.rows.length === 1);
    await utilisateur(db, 3);
    assert((await db.query("select * from lister_epreuves_partagees()")).rows.length === 0);
    await refuse(() => db.query("select * from lister_participants_manche_delegue($1)", [id(30)]));
  } finally { await db.close(); }
});

Deno.test("le coach délégué saisit une arrivée mais ne valide ni ne publie", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await db.query("select autoriser_coach_epreuve($1,$2)", [id(20), "delegue"]);
    await utilisateur(db, 2);
    const arrivee = await db.query<{data:{position:number}}>(
      "select enregistrer_arrivee_atomique($1,$2,clock_timestamp()) data",
      [id(30), id(4)],
    );
    assert(arrivee.rows[0].data.position === 1);
    await db.query("update manches set statut='terminee' where id=$1", [id(30)]);
    await refuse(() => db.query("select valider_resultats_manche($1,0)", [id(30)]));
    await refuse(() => db.query("select publier_resultats_manche_verifies($1,0)", [id(30)]));
  } finally { await db.close(); }
});

Deno.test("le retrait bloque immédiatement les nouvelles saisies", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await db.query("select autoriser_coach_epreuve($1,$2)", [id(20), "delegue"]);
    await db.query("select retirer_coach_epreuve($1,$2)", [id(20), id(2)]);
    await utilisateur(db, 2);
    await refuse(() => db.query(
      "select enregistrer_arrivee_atomique($1,$2,clock_timestamp())",
      [id(30), id(4)],
    ));
  } finally { await db.close(); }
});
