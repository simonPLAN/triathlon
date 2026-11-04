import {fixture,utilisateur,configurer,id,assert,refuse} from "./fixtures_manches.ts";
const migration=await Deno.readTextFile(new URL("../migrations/202611040001_participants_manches.sql",import.meta.url));
Deno.test("affectations : persistance, ordre et lecture personnelle sans autres identités",async()=>{
 const db=await fixture();try{
  await utilisateur(db,1);await configurer(db);
  const p=await db.query<{athlete_id:string;ordre_depart:number}>("select * from participants_manche order by ordre_depart");
  assert(p.rows.map(x=>x.athlete_id).join()===[id(4),id(3)].join());
  await utilisateur(db,3);
  assert((await db.query("select * from participants_manche")).rows.length===1);
  const {rows}=await db.query<{data:{epreuves:Array<{manches:Array<{participe:boolean;ordre_depart:number}>}>}}>(
    "select programme_competition_athlete($1) data",[id(10)]);
  assert(rows[0].data.epreuves[0].manches[0].participe);
  assert(rows[0].data.epreuves[0].manches[0].ordre_depart===2);
 }finally{await db.close();}
});
Deno.test("configuration : refuse autre coach, athlète, doublon, non inscrit et délai zéro",async()=>{
 const db=await fixture();try{
  for(const n of [2,3]){await utilisateur(db,n);await refuse(()=>configurer(db));}
  await utilisateur(db,1);
  for(const ids of [[],[3,3],[1]]) await refuse(()=>configurer(db,ids));
  await refuse(()=>db.query("select configurer_participants_manche($1,$2::uuid[],0)",[id(30),[id(3)]]));
  assert((await db.query("select * from participants_manche")).rows.length===0);
 }finally{await db.close();}
});
Deno.test("départ : configuration requise puis configuration figée et résultats bornés",async()=>{
 const db=await fixture();try{
  await utilisateur(db,1);
  await refuse(()=>db.query("update manches set statut='en_cours' where id=$1",[id(30)]));
  await configurer(db,[3]);
  await db.query("update manches set statut='en_cours' where id=$1",[id(30)]);
  await refuse(()=>configurer(db));
  await refuse(()=>db.query("insert into resultats values($1,$2,$3)",[id(50),id(30),id(4)]));
  await db.query("insert into resultats values($1,$2,$3)",[id(50),id(30),id(3)]);
 }finally{await db.close();}
});
Deno.test("configuration : changement d’inscription invalide le départ, réexécution migration",async()=>{
 const db=await fixture();try{
  await utilisateur(db,1);await configurer(db);
  await db.exec("reset role");
  await db.query("delete from inscriptions where athlete_id=$1",[id(4)]);
  await utilisateur(db,1);
  await refuse(()=>db.query("update manches set statut='en_cours' where id=$1",[id(30)]));
  await db.exec("reset role");await db.exec(migration);
 }finally{await db.close();}
});
