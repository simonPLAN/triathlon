import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const programme = await Deno.readTextFile(new URL("../migrations/202611020006_programme_athlete.sql", import.meta.url));
const migration = await Deno.readTextFile(new URL("../migrations/202611040030_policies_production.sql", import.meta.url));
const id = (n: number) => "50000000-0000-4000-8000-" + n.toString().padStart(12, "0");
function assert(ok: unknown, message = "Assertion échouée"): asserts ok { if (!ok) throw new Error(message); }
async function refuse(action: () => Promise<unknown>) {
  let interdit = false;
  try { await action(); } catch { interdit = true; }
  assert(interdit, "L’opération doit être refusée");
}
async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    grant usage on schema auth to authenticated,anon,service_role;
    create table profils(id uuid primary key,compte_id uuid,prenom text,nom text,role text,
      est_invite boolean default false,est_archive boolean default false);
    create table competitions(id uuid primary key,coach_id uuid references profils,statut text);
    create table inscriptions(id uuid primary key,competition_id uuid references competitions,
      athlete_id uuid references profils,numero_dossard integer);
    create table epreuves(id uuid primary key,competition_id uuid references competitions,
      nom text,discipline text,distance_metres integer,ordre integer);
    create table manches(id uuid primary key,epreuve_id uuid references epreuves,
      numero integer,statut text,resultats_publies boolean default false);
    create table resultats(id uuid primary key,manche_id uuid references manches,
      athlete_id uuid references profils,position integer,points integer);
    insert into profils values
      ('${id(1)}','${id(1)}','Coach','Un','coach',false,false),
      ('${id(2)}','${id(2)}','Coach','Deux','coach',false,false),
      ('${id(3)}','${id(3)}','Athlète','Un','athlete',false,false),
      ('${id(4)}','${id(4)}','Athlète','Deux','athlete',false,false),
      ('${id(5)}',null,'Invité','Un','athlete',true,false),
      ('${id(6)}',null,'Invité','Deux','athlete',true,false);
    insert into competitions values
      ('${id(10)}','${id(1)}','ouverte'),('${id(11)}','${id(2)}','brouillon');
    insert into inscriptions values
      ('${id(50)}','${id(10)}','${id(3)}',10),
      ('${id(51)}','${id(10)}','${id(5)}',11),
      ('${id(52)}','${id(11)}','${id(4)}',12),
      ('${id(53)}','${id(11)}','${id(6)}',13);
    insert into epreuves values
      ('${id(20)}','${id(10)}','Course','course_a_pied',5000,1),
      ('${id(21)}','${id(11)}','Vélo','velo',20000,1);
    insert into manches values
      ('${id(30)}','${id(20)}',1,'terminee',false),
      ('${id(31)}','${id(20)}',2,'terminee',true),
      ('${id(32)}','${id(21)}',1,'a_venir',false);
    insert into resultats values
      ('${id(40)}','${id(30)}','${id(3)}',1,100),
      ('${id(41)}','${id(31)}','${id(5)}',1,100),
      ('${id(42)}','${id(32)}','${id(4)}',1,100);
    -- Modèle volontairement trop permissif : les plafonds doivent le borner.
    do $$ declare t text; begin
      foreach t in array array['profils','competitions','inscriptions','epreuves','manches','resultats'] loop
        execute format('create policy ancienne_large on %I for all to authenticated,anon using(true) with check(true)',t);
        execute format('grant select,insert,update,delete on %I to authenticated,anon',t);
      end loop;
    end $$;
    create function public.ancienne_rpc_dangereuse(uuid) returns void
      language sql security definer set search_path='' as $$
        update public.profils set role='coach' where id=$1
      $$;
    grant execute on function public.ancienne_rpc_dangereuse(uuid) to authenticated;
  `);
  await db.exec(programme);
  await db.exec(migration);
  return db;
}
async function utilisateur(db: PGlite, n: number | null, role = "authenticated") {
  await db.exec("reset role");
  await db.query("select set_config('request.jwt.claim.sub',$1,false),set_config('request.jwt.claim.role',$2,false)",
    [n == null ? "" : id(n), role]);
  await db.exec("set role " + role);
}
Deno.test("RLS : athlète ne voit que son profil/inscription et les résultats publiés de sa compétition", async () => {
  const db = await fixture();
  try {
    await utilisateur(db,3);
    assert((await db.query<{id:string}>("select id from profils")).rows.map(p=>p.id).join()===id(3));
    assert((await db.query("select id from inscriptions")).rows.length===1);
    const resultats=await db.query<{id:string}>("select id from resultats");
    assert(resultats.rows.length===1 && resultats.rows[0].id===id(41));
    assert((await db.query("update resultats set points=999 returning id")).rows.length===0);
    assert((await db.query("delete from resultats returning id")).rows.length===0);
    await refuse(()=>db.query("insert into resultats values($1,$2,$3,3,999)",[id(99),id(30),id(3)]));
    assert((await db.query("update inscriptions set numero_dossard=999 returning id")).rows.length===0);
    assert((await db.query("update epreuves set nom='Interdit' returning id")).rows.length===0);
    assert((await db.query("delete from manches returning id")).rows.length===0);
  } finally { await db.close(); }
});
Deno.test("RLS : inscription personnelle ouverte, dossard interdit et fermeture protège la désinscription", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,4);
    await refuse(()=>db.query("insert into inscriptions values($1,$2,$3,99)",[id(60),id(10),id(4)]));
    await refuse(()=>db.query("insert into inscriptions values($1,$2,$3,null)",[id(60),id(10),id(5)]));
    await db.query("insert into inscriptions values($1,$2,$3,null)",[id(60),id(10),id(4)]);
    assert((await db.query("delete from inscriptions where id=$1 returning id",[id(60)])).rows.length===1);
    await utilisateur(db,1);
    await db.query("update competitions set statut='en_cours' where id=$1",[id(10)]);
    await utilisateur(db,3);
    assert((await db.query("delete from inscriptions where id=$1 returning id",[id(50)])).rows.length===0);
    await refuse(()=>db.query("insert into inscriptions values($1,$2,$3,null)",[id(61),id(10),id(3)]));
  } finally { await db.close(); }
});
Deno.test("RLS : coach propriétaire seulement, annuaire limité aux noms et invités de ses compétitions", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,1);
    const profils=await db.query<{id:string}>("select id from profils order by id");
    assert(profils.rows.map(p=>p.id).join()===[id(1),id(3),id(5)].join());
    assert((await db.query("select id from resultats")).rows.length===2);
    assert((await db.query("update manches set numero=9 where id=$1 returning id",[id(30)])).rows.length===1);
    assert((await db.query("update manches set numero=9 where id=$1 returning id",[id(32)])).rows.length===0);
    assert((await db.query("update resultats set points=80 where id=$1 returning id",[id(40)])).rows.length===1);
    assert((await db.query("update resultats set points=80 where id=$1 returning id",[id(41)])).rows.length===0,"Publié : correction via RPC uniquement");
    await refuse(()=>db.query("update inscriptions set competition_id=$1 where id=$2",[id(11),id(50)]));
    await refuse(()=>db.query("update resultats set athlete_id=$1 where id=$2",[id(5),id(40)]));
    await refuse(()=>db.query("update competitions set coach_id=$1 where id=$2",[id(2),id(10)]));
    assert((await db.query("delete from competitions where id=$1 returning id",[id(10)])).rows.length===0);
    const annuaire=await db.query<{data:Array<Record<string,unknown>>}>("select annuaire_athletes_coach() data");
    assert(annuaire.rows[0].data.map(p=>p.id).sort().join()===[id(3),id(4),id(5)].sort().join());
    assert(annuaire.rows[0].data.every(p=>Object.keys(p).sort().join()==="id,nom,prenom"));
  } finally { await db.close(); }
});
Deno.test("Rôle : aucune élévation directe ou via une ancienne RPC, attribution réservée au serveur", async () => {
  const db=await fixture();
  try {
    await utilisateur(db,3);
    await refuse(()=>db.query("update profils set role='coach' where id=$1",[id(3)]));
    await refuse(()=>db.query("update profils set compte_id=$1 where id=$2",[id(4),id(3)]));
    await refuse(()=>db.query("update profils set est_invite=true where id=$1",[id(3)]));
    await refuse(()=>db.query("select ancienne_rpc_dangereuse($1)",[id(3)]));
    await refuse(()=>db.query("select attribuer_role_coach($1)",[id(3)]));
    await refuse(()=>db.query("select annuaire_athletes_coach()"));
    await db.query("update profils set prenom='Nouveau' where id=$1",[id(3)]);
    await utilisateur(db,null,"service_role");
    await db.query("select attribuer_role_coach($1)",[id(3)]);
    await utilisateur(db,3);
    assert((await db.query<{role:string}>("select role from profils where id=$1",[id(3)])).rows[0].role==="coach");
  } finally { await db.close(); }
});
Deno.test("Naissance d’un compte : rôle athlete imposé ; migration réexécutable et accès anonyme refusé", async () => {
  const db=await fixture();
  try {
    await db.query("insert into profils(id,prenom,nom,role) values($1,'Nouveau','Compte','coach')",[id(7)]);
    const profil=await db.query<{role:string,compte_id:string}>("select role,compte_id from profils where id=$1",[id(7)]);
    assert(profil.rows[0].role==="athlete" && profil.rows[0].compte_id===id(7));
    await db.exec(migration);
    await utilisateur(db,null,"anon");
    await refuse(()=>db.query("select * from profils"));
    await refuse(()=>db.query("select * from resultats"));
    await refuse(()=>db.query("select annuaire_athletes_coach()"));
    await refuse(()=>db.query("select attribuer_role_coach($1)",[id(7)]));
  } finally { await db.close(); }
});
