import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const migration = await Deno.readTextFile(new URL("../migrations/202611020005_corrections_resultats.sql", import.meta.url));
const id = (n: number) => "10000000-0000-4000-8000-" + n.toString().padStart(12, "0");
function assert(ok: unknown, message = "Assertion échouée"): asserts ok { if (!ok) throw new Error(message); }
async function fixture(avecCorrection = true) {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table public.profils(id uuid primary key,prenom text,nom text,role text);
    create table public.competitions(id uuid primary key,coach_id uuid references profils);
    create table public.epreuves(id uuid primary key,competition_id uuid references competitions);
    create type statut_manche as enum ('a_venir','en_cours','terminee','annulee');
    create table public.manches(id uuid primary key,epreuve_id uuid references epreuves,
      statut statut_manche,heure_depart timestamptz,heure_fin_delai timestamptz,
      resultats_publies boolean default false,date_modification timestamptz default now());
    create type statut_resultat as enum ('arrive','hors_delai','abandon','disqualifie');
    create table public.resultats(
      id uuid primary key default gen_random_uuid(),manche_id uuid references manches,
      athlete_id uuid references profils,position int,points int not null,statut statut_resultat,
      heure_arrivee timestamptz,temps_total_millisecondes int,ecart_premier_millisecondes int,
      commentaire text,date_publication timestamptz,date_creation timestamptz default now(),
      date_modification timestamptz default now(),
      unique(manche_id,athlete_id),unique(manche_id,position),
      check(ecart_premier_millisecondes>=0),
      check((statut='arrive' and position>0 and position is not null) or (statut<>'arrive' and position is null))
    );
    create table public.inscriptions(competition_id uuid references competitions,athlete_id uuid references profils);
    insert into profils values ('${id(1)}','Coach','Propriétaire','coach'),
      ('${id(2)}','Autre','Coach','coach'),('${id(3)}','A','Athlète','athlete'),
      ('${id(4)}','B','Athlète','athlete'),('${id(5)}','C','Athlète','athlete'),
      ('${id(6)}','D','Athlète','athlete');
    insert into competitions values ('${id(10)}','${id(1)}');
    insert into epreuves values ('${id(11)}','${id(10)}');
    insert into manches(id,epreuve_id,statut,heure_depart,heure_fin_delai)
      values ('${id(12)}','${id(11)}','terminee','2026-01-01T12:00Z','2026-01-01T13:00Z');
    insert into inscriptions select '${id(10)}',id from profils where role='athlete';
    insert into resultats(id,manche_id,athlete_id,position,points,statut,heure_arrivee,temps_total_millisecondes,ecart_premier_millisecondes)
      values ('${id(20)}','${id(12)}','${id(3)}',1,5,'arrive','2026-01-01T12:01Z',60000,0),
      ('${id(21)}','${id(12)}','${id(4)}',2,4,'arrive','2026-01-01T12:02Z',120000,60000),
      ('${id(22)}','${id(12)}','${id(5)}',3,3,'arrive','2026-01-01T12:03Z',180000,120000);
  `);
  if (avecCorrection) await db.exec(migration);
  await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id(1)]);
  return db;
}
async function revision(db: PGlite) {
  const { rows } = await db.query<{ revision_resultats: number }>("select revision_resultats from manches");
  return rows[0].revision_resultats;
}
async function editer(db: PGlite, options: {
  resultat?: string | null; athlete?: string; position?: number | null;
  temps?: number | null; mode?: string; statut?: string; revision?: number; accord?: boolean;
} = {}) {
  const { rows } = await db.query<{ data: { resultats: Array<{ id: string; position: number | null; points: number; temps_total_millisecondes: number | null; ecart_premier_millisecondes: number | null }>; revision: number; depublies: boolean } }>(
    "select public.editer_resultat_manche($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) data",
    [id(12), options.athlete ?? id(5), options.resultat === undefined ? id(22) : options.resultat,
      options.revision ?? await revision(db), options.statut ?? "arrive", options.mode ?? "decaler",
      options.position === undefined ? 1 : options.position,
      options.temps === undefined ? 180000 : options.temps, "Correction test", options.accord ?? false]);
  return rows[0].data;
}
async function refuse(action: () => Promise<unknown>) {
  let echec = false;
  try { await action(); } catch { echec = true; }
  assert(echec, "La requête doit être refusée");
}
Deno.test("SQL décalage : places continues, points et écarts recalculés sans changer les temps", async () => {
  const db=await fixture();
  try {
    const resultat=await editer(db);
    assert(resultat.resultats.map(r=>r.id).join() === [id(22),id(20),id(21)].join());
    assert(resultat.resultats.map(r=>r.points).join() === "5,4,3");
    assert(resultat.resultats.map(r=>r.ecart_premier_millisecondes).join() === "0,-120000,-60000");
    assert(resultat.resultats.map(r=>r.temps_total_millisecondes).join() === "180000,60000,120000");
  } finally { await db.close(); }
});
Deno.test("SQL échange : seules les places des deux athlètes sont échangées", async () => {
  const db=await fixture();
  try {
    const resultat=await editer(db,{mode:"echanger"});
    assert(resultat.resultats.map(r=>r.id).join() === [id(22),id(21),id(20)].join());
    assert(resultat.resultats.map(r=>r.position).join() === "1,2,3");
  } finally { await db.close(); }
});
Deno.test("SQL saisie manuelle et tri par temps, puis retrait par disqualification", async () => {
  const db=await fixture();
  try {
    const resultat=await editer(db,{resultat:null,athlete:id(6),mode:"temps",position:null,temps:90000});
    assert(resultat.resultats.map(r=>r.points).join() === "5,4,3,2");
    assert(resultat.resultats[1].temps_total_millisecondes === 90000);
    const retrait=await editer(db,{statut:"disqualifie",position:null,temps:null});
    const cible=retrait.resultats.find(r=>r.id===id(22))!;
    assert(cible.position===null && cible.points===0 && cible.temps_total_millisecondes===null);
    assert(retrait.resultats.filter(r=>r.position!=null).map(r=>r.position).join()==="1,2,3");
  } finally { await db.close(); }
});
Deno.test("SQL corrections publiées nécessitent accord puis retrait et republication explicite", async () => {
  const db=await fixture();
  try {
    await db.query("select publier_resultats_manche_verifies($1,$2)",[id(12),await revision(db)]);
    await refuse(()=>editer(db));
    const corrige=await editer(db,{accord:true});
    assert(corrige.depublies);
    const etat=await db.query<{ resultats_publies: boolean }>("select resultats_publies from manches");
    assert(!etat.rows[0].resultats_publies);
    const dates=await db.query("select id from resultats where date_publication is not null");
    assert(dates.rows.length===0);
    await db.query("select publier_resultats_manche_verifies($1,$2)",[id(12),corrige.revision]);
    assert((await db.query("select id from resultats where date_publication is null")).rows.length===0);
  } finally { await db.close(); }
});
Deno.test("SQL refuse le second coach, l'athlète et une révision périmée", async () => {
  const db=await fixture();
  try {
    for (const utilisateur of [id(2),id(3),""]) {
      await db.query("select set_config('request.jwt.claim.sub',$1,false)",[utilisateur]);
      await refuse(()=>editer(db));
    }
    await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id(1)]);
    const ancienne=await revision(db);
    await editer(db);
    await refuse(()=>editer(db,{revision:ancienne}));
  } finally { await db.close(); }
});
Deno.test("SQL validations et rollback d'une panne après le début des mises à jour", async () => {
  const db=await fixture();
  try {
    const avant=await revision(db);
    for (const options of [{position:8},{temps:-1},{temps:3600000},{mode:"invalide"},{athlete:id(2),resultat:null}]) {
      await refuse(()=>editer(db,options));
      assert(await revision(db)===avant,"Aucune écriture en cas de refus");
    }
    await db.exec(`
      create function refuser_test() returns trigger language plpgsql as $$
      begin if new.id='${id(20)}' then raise exception 'Panne simulée'; end if; return new; end $$;
      create trigger refuser_test before update on resultats for each row execute function refuser_test();
    `);
    await refuse(()=>editer(db));
    assert(await revision(db)===avant,"Révision annulée");
    assert((await db.query<{ id: string }>("select id from resultats order by position")).rows[0].id===id(20),"Places annulées");
  } finally { await db.close(); }
});
Deno.test("SQL suppression de compte après publication : compte supprimé et autres résultats préservés", async () => {
  const db=await fixture(false);
  try {
    await db.exec(`
      create role service_role;
      create table auth.users(id uuid primary key);
      insert into auth.users select id from profils;
      alter table profils add column compte_id uuid;
      alter table profils add column est_invite boolean not null default false;
      update profils set compte_id=id;
      alter table competitions add column nom text default 'Triathlon';
      alter table competitions add column description text;
      alter table competitions add column lieu text;
      alter table competitions add column statut text default 'terminee';
      alter table competitions add column date_modification timestamptz default now();
    `);
    await db.exec(await Deno.readTextFile(new URL("../migrations/202611020004_suppression_compte.sql",import.meta.url)));
    await db.exec(migration);
    await db.query("select publier_resultats_manche_verifies($1,$2)",[id(12),await revision(db)]);
    await db.query("delete from auth.users where id=$1",[id(3)]);
    assert((await db.query("select id from auth.users where id=$1",[id(3)])).rows.length===0);
    assert((await db.query("select id from resultats")).rows.length===2);
    assert((await db.query("select id from resultats where date_publication is not null")).rows.length===0);
    assert(!(await db.query<{resultats_publies:boolean}>("select resultats_publies from manches")).rows[0].resultats_publies);
  } finally { await db.close(); }
});
Deno.test("SQL rôle authenticated : écritures directes finales interdites, RPC du propriétaire autorisées", async () => {
  const db=await fixture();
  try {
    await db.exec(`
      grant usage on schema auth to authenticated;
      grant select,insert,update,delete on public.resultats to authenticated;
      grant select,update on public.manches to authenticated;
      alter table public.resultats enable row level security;
      create policy droits_test on public.resultats for all to authenticated using(true) with check(true);
      set role authenticated;
    `);
    const modifications=await db.query("update resultats set commentaire='interdit' returning id");
    assert(modifications.rows.length===0);
    await refuse(()=>db.exec("update manches set resultats_publies=true"));
    const corrige=await editer(db);
    assert(corrige.resultats[0].id===id(22));
    await db.query("select publier_resultats_manche_verifies($1,$2)",[id(12),corrige.revision]);
  } finally { await db.close(); }
});
Deno.test("SQL migration réexécutable, unicité des positions et absence de privilèges auxiliaires", async () => {
  const db=await fixture();
  try {
    await db.exec(migration);
    await refuse(()=>db.exec(`update resultats set position=1 where id='${id(21)}'`));
    const {rows}=await db.query<{ autorise: boolean }>(
      "select has_function_privilege('authenticated','public.verifier_edition_resultats(uuid,bigint)','execute') autorise");
    assert(!rows[0].autorise);
  } finally { await db.close(); }
});
