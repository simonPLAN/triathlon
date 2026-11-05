import { PGlite } from "npm:@electric-sql/pglite@0.5.14";
const migration=await Deno.readTextFile(new URL("../migrations/202611040020_categories_athletes.sql",import.meta.url));
const id=(n:number)=>"60000000-0000-4000-8000-"+n.toString().padStart(12,"0");
function assert(v:unknown,m="Assertion échouée"):asserts v{if(!v)throw new Error(m);}
async function refuse(f:()=>Promise<unknown>){let e=false;try{await f();}catch{e=true;}assert(e,"Accès à refuser");}
async function fixture(){
 const db=new PGlite();
 await db.exec(`
 create role anon;create role authenticated;create role service_role;
 create schema auth;create table auth.users(id uuid primary key);
 create function auth.uid() returns uuid language sql stable as $$
 select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
 create table profils(id uuid primary key,compte_id uuid references auth.users(id),role text,est_invite boolean);
 create table competitions(id uuid primary key,coach_id uuid references profils);
 create table inscriptions(competition_id uuid references competitions,athlete_id uuid references profils);
 create table resultats(athlete_id uuid references profils);
 create table participants_manche(athlete_id uuid references profils on delete cascade);
 create function public.preparer_suppression_compte() returns trigger language plpgsql as $$begin return old;end$$;
 create trigger preparer_suppression_compte before delete on auth.users for each row execute function preparer_suppression_compte();
 create function public.programme_competition_modifiable(p_id uuid) returns boolean language sql stable security definer as $$
 select exists(select 1 from public.competitions where id=p_id and coach_id=auth.uid()) $$;
 create function public.coach_peut_lire_invite(p_id uuid) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.inscriptions i join public.competitions c on c.id=i.competition_id where i.athlete_id=p_id and c.coach_id=auth.uid()) $$;
 insert into auth.users values('${id(1)}'),('${id(2)}'),('${id(3)}'),('${id(4)}');
 insert into profils values('${id(1)}','${id(1)}','coach',false),('${id(2)}','${id(2)}','coach',false),
 ('${id(3)}','${id(3)}','athlete',false),('${id(4)}','${id(4)}','athlete',false),('${id(5)}',null,'athlete',true);
 insert into competitions values('${id(10)}','${id(1)}');
 insert into inscriptions values('${id(10)}','${id(3)}'),('${id(10)}','${id(5)}');
 grant usage on schema public,auth to authenticated,anon;
 `);
 await db.exec(migration);return db;
}
async function asUser(db:PGlite,n:number|null){
 await db.exec("reset role");
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[n===null?"":id(n)]);
 await db.exec("set role authenticated");
}
Deno.test("catégorie personnelle, barème exact et suppression de la valeur",async()=>{
 const db=await fixture();try{
 await asUser(db,3);
 await db.query("select configurer_categorie_athlete($1,'F 60-64')",[id(3)]);
 const r=await db.query<{data:{categorie:string,modifiable:boolean}}>("select consulter_categorie_athlete($1) data",[id(3)]);
 assert(r.rows[0].data.categorie==="F 60-64"&&r.rows[0].data.modifiable);
 await refuse(()=>db.query("select configurer_categorie_athlete($1,'F 35-39')",[id(3)]));
 await db.query("select configurer_categorie_athlete($1,null)",[id(3)]);
 await refuse(()=>db.query("select * from categories_athletes"));
 }finally{await db.close();}
});
Deno.test("coach lit inscrit sans modifier compte ; invité sous sa responsabilité modifiable",async()=>{
 const db=await fixture();try{
 await asUser(db,1);
 const r=await db.query<{data:{modifiable:boolean}}>("select consulter_categorie_athlete($1) data",[id(3)]);
 assert(!r.rows[0].data.modifiable);
 await refuse(()=>db.query("select configurer_categorie_athlete($1,'M 18-24')",[id(3)]));
 await db.query("select configurer_categorie_athlete($1,'M 18-24')",[id(5)]);
 await asUser(db,2);await refuse(()=>db.query("select consulter_categorie_athlete($1)",[id(5)]));
 await asUser(db,4);await refuse(()=>db.query("select consulter_categorie_athlete($1)",[id(3)]));
 await asUser(db,null);await refuse(()=>db.query("select consulter_categorie_athlete($1)",[id(3)]));
 }finally{await db.close();}
});
Deno.test("suppression accepte uniquement la cascade connue des catégories",async()=>{
 const db=await fixture();try{
 await asUser(db,3);await db.query("select configurer_categorie_athlete($1,'F 30-34')",[id(3)]);
 await db.exec("reset role;select verifier_schema_suppression_compte()");
 await db.query("delete from inscriptions where athlete_id=$1",[id(3)]);
 await db.query("delete from profils where id=$1",[id(3)]);
 const r=await db.query("select * from categories_athletes");assert(r.rows.length===0);
 await db.exec("create table reference_inconnue(id uuid references profils on delete cascade)");
 await refuse(()=>db.exec("select verifier_schema_suppression_compte()"));
 }finally{await db.close();}
});
