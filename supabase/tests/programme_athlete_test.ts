import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const migration = await Deno.readTextFile(new URL("../migrations/202611020006_programme_athlete.sql", import.meta.url));
const id = (n: number) => "20000000-0000-4000-8000-" + n.toString().padStart(12, "0");
function assert(condition: unknown, message = "Assertion échouée"): asserts condition { if (!condition) throw new Error(message); }
async function refuse(action: () => Promise<unknown>) {
  let erreur = false;
  try { await action(); } catch { erreur = true; }
  assert(erreur, "La requête doit être refusée");
}
async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table profils(id uuid primary key,compte_id uuid,role text,est_invite boolean default false);
    create table competitions(id uuid primary key,coach_id uuid references profils,statut text);
    create table inscriptions(competition_id uuid references competitions,athlete_id uuid references profils);
    create table epreuves(id uuid primary key,competition_id uuid references competitions,
      nom text,discipline text,distance_metres int,ordre int);
    create table manches(id uuid primary key,epreuve_id uuid references epreuves,
      numero int,statut text,resultats_publies boolean default false);
    insert into profils values
      ('${id(1)}','${id(1)}','coach',false),('${id(2)}','${id(2)}','coach',false),
      ('${id(3)}','${id(3)}','athlete',false),('${id(4)}','${id(4)}','athlete',false),
      ('${id(5)}',null,'athlete',true);
    insert into competitions values
      ('${id(10)}','${id(1)}','ouverte'),('${id(11)}','${id(1)}','en_cours'),
      ('${id(12)}','${id(1)}','terminee'),('${id(13)}','${id(1)}','annulee'),
      ('${id(14)}','${id(1)}','brouillon'),('${id(15)}','${id(2)}','brouillon');
    insert into inscriptions select id,'${id(3)}' from competitions where id<>'${id(15)}';
    insert into epreuves values
      ('${id(20)}','${id(10)}','Vélo','velo',20000,2),
      ('${id(21)}','${id(10)}','Natation','natation',750,1),
      ('${id(22)}','${id(11)}','Course','course_a_pied',5000,1),
      ('${id(23)}','${id(12)}','Course','course_a_pied',5000,1),
      ('${id(24)}','${id(13)}','Course','course_a_pied',5000,1),
      ('${id(25)}','${id(14)}','Brouillon','natation',100,1),
      ('${id(26)}','${id(15)}','Autre coach','natation',100,1);
    insert into manches values
      ('${id(30)}','${id(21)}',4,'annulee',false),
      ('${id(31)}','${id(21)}',3,'terminee',false),
      ('${id(32)}','${id(21)}',2,'en_cours',false),
      ('${id(33)}','${id(21)}',1,'a_venir',false);
    -- Policies permissives volontairement larges pour tester les restrictions ajoutées.
    create policy base_epreuves on epreuves for all to authenticated,anon using(true) with check(true);
    create policy base_manches on manches for all to authenticated,anon using(true) with check(true);
    grant usage on schema auth to authenticated,anon;
    grant select on epreuves,manches to anon;
    grant select,insert,update,delete on epreuves,manches to authenticated;
  `);
  await db.exec(migration);
  return db;
}
async function utilisateur(db: PGlite, n: number | null) {
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[n == null ? "" : id(n)]);
}
async function programme(db: PGlite, competition: number) {
  const {rows} = await db.query<{data: {
    affectations_disponibles: boolean;
    epreuves: Array<{id: string; ordre: number; discipline: string; distance_metres: number;
      manches: Array<{numero: number; statut: string; participe: boolean | null; ordre_depart: number | null}>}>;
  }}>("select programme_competition_athlete($1) data",[id(competition)]);
  return rows[0].data;
}
Deno.test("programme avant publication : épreuves/manches triées sans table de résultats", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,3);
    const data=await programme(db,10);
    assert(data.epreuves.map(e=>e.ordre).join()==="1,2");
    assert(data.epreuves[0].discipline==="natation" && data.epreuves[0].distance_metres===750);
    assert(data.epreuves[0].manches.map(m=>m.statut).join()==="a_venir,en_cours,terminee,annulee");
    assert(!data.affectations_disponibles);
    assert(data.epreuves[0].manches.every(m=>m.participe===null && m.ordre_depart===null));
    assert(!JSON.stringify(data).includes("athlete_id"),"Aucune identité d'un autre participant");
  } finally { await db.close(); }
});
Deno.test("inscrit : programme des compétitions en cours, terminées et annulées, jamais des brouillons", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,3);
    for (const competition of [11,12,13]) assert((await programme(db,competition)).epreuves.length===1);
    await refuse(()=>programme(db,14));
    await refuse(()=>programme(db,999));
  } finally { await db.close(); }
});
Deno.test("non inscrit : compétition ouverte uniquement ; invité et absence de session refusés", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,4);
    assert((await programme(db,10)).epreuves.length===2);
    await refuse(()=>programme(db,11));
    for(const n of [5,null,1]) {
      await utilisateur(db,n);
      await refuse(()=>programme(db,10));
    }
  } finally { await db.close(); }
});
Deno.test("RLS athlète : lecture bornée et aucune écriture malgré les policies permissives de base", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,4);
    await db.exec("set role authenticated");
    assert((await db.query("select id from epreuves")).rows.length===2);
    assert((await db.query("select id from manches")).rows.length===4);
    assert((await db.query("update epreuves set nom='Interdit' returning id")).rows.length===0);
    assert((await db.query("update manches set numero=99 returning id")).rows.length===0);
    assert((await db.query("delete from manches returning id")).rows.length===0);
    assert((await db.query("delete from epreuves returning id")).rows.length===0);
    await refuse(()=>db.query("insert into epreuves values($1,$2,'Interdit','velo',100,3)",[id(98),id(10)]));
    await refuse(()=>db.query("insert into manches(id,epreuve_id,numero,statut) values($1,$2,5,'a_venir')",[id(99),id(21)]));
    assert((await programme(db,10)).epreuves.length===2);
  } finally { await db.close(); }
});
Deno.test("RLS coach : conserve ses accès, interdit l'accès au programme privé d'un autre coach", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,2);
    await db.exec("set role authenticated");
    const visible=await db.query<{id:string}>("select id from epreuves");
    assert(visible.rows.length===1 && visible.rows[0].id===id(26));
    assert((await db.query("update epreuves set nom='Autorisé' where id=$1 returning id",[id(26)])).rows.length===1);
    assert((await db.query("update epreuves set nom='Interdit' where id=$1 returning id",[id(21)])).rows.length===0);
  } finally { await db.close(); }
});
Deno.test("migration réexécutable et RPC inaccessible aux utilisateurs anonymes", async () => {
  const db=await fixture();
  try {
    await db.exec(migration);
    const {rows}=await db.query<{autorise:boolean}>(
      "select has_function_privilege('anon','public.programme_competition_athlete(uuid)','execute') autorise");
    assert(!rows[0].autorise);
    await utilisateur(db,null);
    await db.exec('set role anon');
    assert((await db.query('select id from epreuves')).rows.length===0);
    assert((await db.query('select id from manches')).rows.length===0);
  } finally { await db.close(); }
});
