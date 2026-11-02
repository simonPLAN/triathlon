// PostgreSQL embarqué : valide la migration réelle sur un schéma contractuel.
// Ce test ne remplace pas une recette sur le schéma Supabase déployé.
import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const migration = await Deno.readTextFile(new URL("../migrations/202611020004_suppression_compte.sql", import.meta.url));
const coach = "10000000-0000-4000-8000-000000000001";
const athlete = "10000000-0000-4000-8000-000000000002";
const invite = "10000000-0000-4000-8000-000000000003";
const competition = "20000000-0000-4000-8000-000000000001";
const archive = "00000000-0000-4000-8000-000000000001";
function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth;
    create table auth.users(id uuid primary key);
    create type public.role_utilisateur as enum ('athlete','coach');
    create type public.statut_competition as enum ('brouillon','ouverte','en_cours','terminee','annulee');
    create table public.profils(
      id uuid primary key, prenom text not null, nom text not null,
      role public.role_utilisateur not null,
      compte_id uuid constraint profils_compte_id_fkey references auth.users(id) on delete cascade,
      est_invite boolean not null default false,
      constraint profils_identite_check check(
        (est_invite and compte_id is null and role='athlete') or
        (not est_invite and compte_id is not null and compte_id=id))
    );
    create table public.competitions(
      id uuid primary key, coach_id uuid not null references public.profils(id) on delete cascade,
      nom text not null, description text, lieu text,
      statut public.statut_competition not null, date_modification timestamptz not null default now()
    );
    create table public.epreuves(id int primary key, competition_id uuid references public.competitions(id) on delete cascade);
    create table public.manches(id int primary key, epreuve_id int references public.epreuves(id) on delete cascade);
    create table public.inscriptions(id int primary key,
      competition_id uuid references public.competitions(id) on delete cascade,
      athlete_id uuid references public.profils(id) on delete cascade);
    create table public.resultats(id int primary key,
      manche_id int references public.manches(id) on delete cascade,
      athlete_id uuid references public.profils(id) on delete cascade);
    create or replace function public.initialiser_compte_profil() returns trigger language plpgsql as $$
    begin if not new.est_invite then new.compte_id := new.id; end if; return new; end $$;
    create trigger initialiser_compte_profil before insert on public.profils
      for each row execute function public.initialiser_compte_profil();
  `);
  await db.exec(migration);
  await db.exec(`
    insert into auth.users values ('${coach}'), ('${athlete}');
    insert into public.profils(id,prenom,nom,role) values
      ('${coach}','Coach','Personnel','coach'), ('${athlete}','Athlète','Personnel','athlete');
    insert into public.profils(id,prenom,nom,role,est_invite) values ('${invite}','Invité','Autre','athlete',true);
    insert into public.competitions values ('${competition}','${coach}','Nom personnel','Description personnelle','Lieu personnel','en_cours',now());
    insert into public.epreuves values (1,'${competition}');
    insert into public.manches values (1,1);
    insert into public.inscriptions values (1,'${competition}','${coach}'), (2,'${competition}','${athlete}'), (3,'${competition}','${invite}');
    insert into public.resultats values (1,1,'${coach}'), (2,1,'${athlete}'), (3,1,'${invite}');
  `);
  return db;
}
async function nombre(db: PGlite, table: string) {
  const { rows } = await db.query<{ n: number }>(`select count(*)::int n from ${table}`);
  return rows[0].n;
}
Deno.test("SQL coach : Auth/profil et données propres supprimés, autres sportifs préservés", async () => {
  const db = await fixture();
  try {
    await db.query("delete from auth.users where id=$1", [coach]);
    assert(await nombre(db, "auth.users") === 1, "Compte Auth supprimé");
    assert(await nombre(db, "public.resultats") === 2, "Résultats des autres préservés");
    assert(await nombre(db, "public.inscriptions") === 2, "Inscriptions des autres préservées");
    assert(await nombre(db, "public.manches") === 1, "Manche conservée");
    const { rows } = await db.query<{ coach_id: string; nom: string; description: string | null; lieu: string | null; statut: string }>("select * from public.competitions");
    assert(rows[0].coach_id === archive && rows[0].statut === "annulee", "Transfert et annulation");
    assert(rows[0].nom === "Compétition archivée" && rows[0].description === null && rows[0].lieu === null, "Champs personnels effacés");
    const profils = await db.query("select id from public.profils where id=$1", [coach]);
    assert(profils.rows.length === 0, "Profil réellement supprimé");
    assert(await nombre(db, "public.profils") === 3, "Archive, autre athlète et invité conservés");
  } finally { await db.close(); }
});
Deno.test("SQL athlète : seules ses lignes sont effacées", async () => {
  const db = await fixture();
  try {
    await db.query("delete from auth.users where id=$1", [athlete]);
    assert(await nombre(db, "public.resultats") === 2, "Deux résultats préservés");
    const { rows } = await db.query<{ coach_id: string; statut: string }>("select * from public.competitions");
    assert(rows[0].coach_id === coach && rows[0].statut === "en_cours", "Compétition inchangée");
  } finally { await db.close(); }
});
Deno.test("SQL relation nouvelle : suppression bloquée sans cascade", async () => {
  const db = await fixture();
  try {
    await db.exec("create table public.relation_inconnue(profil_id uuid references public.profils(id) on delete cascade)");
    let refuse = false;
    try { await db.query("delete from auth.users where id=$1", [coach]); } catch { refuse = true; }
    assert(refuse, "Relation inconnue refusée");
    assert(await nombre(db, "auth.users") === 2 && await nombre(db, "public.resultats") === 3, "Toutes les données conservées");
  } finally { await db.close(); }
});
Deno.test("SQL erreur en fin de nettoyage : rollback des transferts et suppressions", async () => {
  const db = await fixture();
  try {
    await db.exec(`
      create function public.refuser_test() returns trigger language plpgsql as $$
      begin raise exception 'Simulation panne'; end $$;
      create trigger refuser_test before delete on public.profils for each row execute function public.refuser_test();
    `);
    let refuse = false;
    try { await db.query("delete from auth.users where id=$1", [coach]); } catch { refuse = true; }
    assert(refuse, "Erreur simulée");
    assert(await nombre(db, "auth.users") === 2 && await nombre(db, "public.resultats") === 3, "Rollback total");
    const { rows } = await db.query<{ coach_id: string }>("select coach_id from public.competitions");
    assert(rows[0].coach_id === coach, "Transfert annulé");
  } finally { await db.close(); }
});
Deno.test("SQL migration réexécutable et fonctions non accessibles aux clients", async () => {
  const db = await fixture();
  try {
    await db.exec(migration);
    const { rows } = await db.query<{ autorise: boolean }>(
      "select has_function_privilege('authenticated','public.verifier_schema_suppression_compte()','execute') autorise");
    assert(!rows[0].autorise, "Pas d'exécution client privilégiée");
    assert(await nombre(db, "public.profils") === 4, "Archive unique");
  } finally { await db.close(); }
});
