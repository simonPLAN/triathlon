import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const programme = await Deno.readTextFile(new URL("../migrations/202611020006_programme_athlete.sql", import.meta.url));
const migration = await Deno.readTextFile(new URL("../migrations/202611040001_participants_manches.sql", import.meta.url));
export const id=(n:number)=>"40000000-0000-4000-8000-"+n.toString().padStart(12,"0");
export function assert(v:unknown):asserts v { if(!v) throw new Error("Assertion échouée"); }
export async function refuse(f:()=>Promise<unknown>) { let non=false;try{await f();}catch{non=true;}assert(non); }
export async function fixture(historique=false){
  const db=new PGlite();
  await db.exec(`
    create role anon; create role authenticated; create role service_role;
    create schema auth;
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create table auth.users(id uuid primary key);
    create table profils(id uuid primary key,compte_id uuid,role text,est_invite boolean default false);
    create table competitions(id uuid primary key,coach_id uuid references profils,statut text);
    create table inscriptions(competition_id uuid references competitions,athlete_id uuid references profils);
    create table epreuves(id uuid primary key,competition_id uuid references competitions,nom text,discipline text,distance_metres integer,ordre integer);
    create table manches(id uuid primary key,epreuve_id uuid references epreuves,numero integer,
      statut text,resultats_publies boolean default false,date_modification timestamptz default now());
    create table resultats(id uuid primary key,manche_id uuid references manches,athlete_id uuid references profils);
    insert into profils values
      ('${id(1)}','${id(1)}','coach',false),('${id(2)}','${id(2)}','coach',false),
      ('${id(3)}','${id(3)}','athlete',false),('${id(4)}','${id(4)}','athlete',false);
    insert into competitions values ('${id(10)}','${id(1)}','ouverte');
    insert into inscriptions values ('${id(10)}','${id(3)}'),('${id(10)}','${id(4)}');
    insert into epreuves values ('${id(20)}','${id(10)}','Natation','natation',100,1);
    insert into manches values ('${id(30)}','${id(20)}',1,'a_venir',false,now());
    create policy base_epreuves on epreuves for all to authenticated using(true) with check(true);
    create policy base_manches on manches for all to authenticated using(true) with check(true);
    grant usage on schema auth to authenticated;
    grant select on profils,inscriptions,competitions to authenticated;
    grant select,insert,update,delete on epreuves,manches,resultats to authenticated;
  `);
  await db.exec(programme);
  if (historique) await db.exec("update public.manches set statut='en_cours'");
  await db.exec(migration);
  return db;
}
export async function utilisateur(db:PGlite,n:number) {
  await db.exec("reset role");
  await db.query("select set_config('request.jwt.claim.sub',$1,false)",[id(n)]);
  await db.exec("set role authenticated");
}
export async function configurer(db:PGlite,ids:number[]=[4,3]){
  await db.query("select configurer_participants_manche($1,$2::uuid[],60)",[id(30),ids.map(id)]);
}
