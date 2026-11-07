import {fixture,utilisateur,configurer,id,assert,refuse} from "./fixtures_manches.ts";
import type {PGlite} from "npm:@electric-sql/pglite@0.5.14";
const corrections=await Deno.readTextFile(new URL("../migrations/202611020005_corrections_resultats.sql",import.meta.url));
const cycle=await Deno.readTextFile(new URL("../migrations/202611040002_cycle_manche_atomique.sql",import.meta.url));
const enchainement=await Deno.readTextFile(new URL("../migrations/202611050008_enchainement_manches.sql",import.meta.url));
const validation=await Deno.readTextFile(new URL("../migrations/202611040003_validation_resultats.sql",import.meta.url));
async function complete(){
 const db=await fixture();
 await db.exec(`
   alter table profils add column prenom text default 'Prénom',add column nom text default 'Nom';
   alter table competitions add column demarrage_automatique_manche_suivante boolean default true;
   alter table epreuves add column duree_limite_secondes integer default 60;
   alter table manches add column heure_depart timestamptz,add column heure_premiere_arrivee timestamptz,
     add column heure_fin_delai timestamptz,add column date_creation timestamptz default now();
   alter table resultats alter column id set default gen_random_uuid();
   alter table resultats add column position integer,add column points integer not null default 0,
     add column heure_arrivee timestamptz,add column temps_total_millisecondes bigint,
     add column ecart_premier_millisecondes bigint,add column statut text not null default 'arrive',
     add column commentaire text,add column date_publication timestamptz,
     add column date_creation timestamptz default now(),add column date_modification timestamptz default now(),
     add unique(manche_id,athlete_id);
 `);
 await db.exec(corrections);await db.exec(cycle);await db.exec(enchainement);await db.exec(validation);return db;
}
async function depart(db:PGlite){
 await utilisateur(db,1);await configurer(db);
 await db.query("update manches set statut='en_cours',heure_depart=now()-interval '10 seconds' where id=$1",[id(30)]);
}
async function arrivee(db:PGlite,n:number){
 return db.query<{data:{id:string;position:number;athlete_id:string;temps_total_millisecondes:number}}>(
   "select enregistrer_arrivee_atomique($1,$2,clock_timestamp()) data",[id(30),id(n)]);
}
async function revision(db:PGlite){
 return (await db.query<{revision_resultats:number}>("select revision_resultats from manches where id=$1",[id(30)])).rows[0].revision_resultats;
}
Deno.test("arrivée atomique : initialise le délai, attribue les places et refuse doublon/non-participant",async()=>{
 const db=await complete();try{
   await depart(db);
   const a=await arrivee(db,3);assert(a.rows[0].data.position===1);
   const b=await arrivee(db,4);assert(b.rows[0].data.position===2);
   const {rows}=await db.query<{duree:number}>("select extract(epoch from heure_fin_delai-heure_premiere_arrivee) duree from manches where id=$1",[id(30)]);
   assert(Number(rows[0].duree)===60);
   await refuse(()=>arrivee(db,3));await refuse(()=>arrivee(db,1));
   await utilisateur(db,2);await refuse(()=>arrivee(db,3));
 }finally{await db.close();}
});
Deno.test("arrivée refusée : aucun chrono sans résultat, aucun effet après délai",async()=>{
 const db=await complete();try{
   await depart(db);await refuse(()=>arrivee(db,1));
   assert((await db.query<{h:unknown}>("select heure_premiere_arrivee h from manches")).rows[0].h===null);
   await arrivee(db,3);
   await db.query("update manches set heure_fin_delai=now()-interval '1 second' where id=$1",[id(30)]);
   await refuse(()=>arrivee(db,4));
   assert((await db.query("select * from resultats")).rows.length===1);
 }finally{await db.close();}
});
Deno.test("clôture : hors délai des affectés seulement, démarrage suivant et idempotence",async()=>{
 const db=await complete();try{
   await db.query("insert into manches(id,epreuve_id,numero,statut) values($1,$2,2,'a_venir')",[id(31),id(20)]);
   await utilisateur(db,1);
   await configurer(db,[3]);await db.query("update manches set statut='en_cours',heure_depart=now()-interval '10 seconds' where id=$1",[id(30)]);
   await arrivee(db,3);
   await db.query("update manches set heure_fin_delai=now()-interval '1 second' where id=$1",[id(30)]);
   const {rows}=await db.query<{id:string}>("select cloturer_delai_manche($1) id",[id(30)]);assert(rows[0].id===id(31));
   const suivante=await db.query<{n:number,s:string}>("select count(*)::int n,min(m.statut) s from participants_manche p join manches m on m.id=p.manche_id where p.manche_id=$1",[id(31)]);
   assert(suivante.rows[0].n===1&&suivante.rows[0].s==='en_cours');
   assert((await db.query("select * from resultats where athlete_id=$1",[id(4)])).rows.length===0);
   await db.query("select cloturer_delai_manche($1)",[id(30)]);
   assert((await db.query("select * from resultats")).rows.length===1);
   const droits=await db.query<{ok:boolean}>("select has_function_privilege('authenticated','public.cloturer_delais_expires()','EXECUTE') ok");
   assert(!droits.rows[0].ok);
 }finally{await db.close();}
});
Deno.test("statut avant arrivée : motif, refus de doublon et absence de première arrivée",async()=>{
 const db=await complete();try{
   await depart(db);
   await db.query("select declarer_statut_participant($1,$2,'abandon','Blessure')",[id(30),id(3)]);
   assert((await db.query<{h:unknown}>("select heure_premiere_arrivee h from manches")).rows[0].h===null);
   await refuse(()=>arrivee(db,3));
   await refuse(()=>db.query("select declarer_statut_participant($1,$2,'disqualifie','')",[id(30),id(4)]));
 }finally{await db.close();}
});
Deno.test("validation : tous les participants, publication distincte et correction invalide la validation",async()=>{
 const db=await complete();try{
   await depart(db);await arrivee(db,3);
   await db.query("update manches set statut='terminee' where id=$1",[id(30)]);
   let rev=await revision(db);
   await refuse(()=>db.query("select valider_resultats_manche($1,$2)",[id(30),rev]));
   await db.query("select editer_resultat_manche($1,$2,null,$3,'abandon','temps',null,null,'Blessure',false)",[id(30),id(4),rev]);
   rev=await revision(db);
   await refuse(()=>db.query("select publier_resultats_manche_verifies($1,$2)",[id(30),rev]));
   await db.query("select valider_resultats_manche($1,$2)",[id(30),rev]);
   const r=(await db.query<{id:string}>("select id from resultats where athlete_id=$1",[id(3)])).rows[0];
   await db.query("select editer_resultat_manche($1,$2,$3,$4,'arrive','temps',null,1000,'Correction',false)",[id(30),id(3),r.id,rev]);
   rev=await revision(db);
   await refuse(()=>db.query("select publier_resultats_manche_verifies($1,$2)",[id(30),rev]));
   await db.query("select valider_resultats_manche($1,$2)",[id(30),rev]);
   await db.query("select publier_resultats_manche_verifies($1,$2)",[id(30),rev]);
   assert((await db.query<{p:boolean}>("select resultats_publies p from manches")).rows[0].p);
   await db.exec("reset role");await db.exec(validation);
 }finally{await db.close();}
});
