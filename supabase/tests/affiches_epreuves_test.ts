import { PGlite } from "npm:@electric-sql/pglite@0.5.14";

const migration = await Deno.readTextFile(
  new URL("../migrations/202611130001_affiches_epreuves.sql", import.meta.url),
);
const id = (n: number) =>
  "83000000-0000-4000-8000-" + n.toString().padStart(12, "0");
const path = (objet: number, extension = "jpg") =>
  `${id(10)}/${id(20)}/${id(objet)}.${extension}`;

function assert(ok: unknown, message = "Assertion échouée"): asserts ok {
  if (!ok) throw new Error(message);
}
async function refuse(action: () => Promise<unknown>) {
  let refusee = false;
  try {
    await action();
  } catch {
    refusee = true;
  }
  assert(refusee, "L’opération devait être refusée");
}

async function fixture() {
  const db = new PGlite();
  await db.exec(`
    create role anon;
    create role authenticated;
    create role service_role bypassrls;
    create schema auth;
    create schema storage;

    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
    $$;
    grant usage on schema auth,storage to authenticated,anon,service_role;

    create table public.profils(
      id uuid primary key,
      compte_id uuid,
      role text not null,
      est_invite boolean not null default false,
      est_archive boolean not null default false
    );
    create table public.competitions(
      id uuid primary key,
      coach_id uuid not null references public.profils(id),
      statut text not null
    );
    create table public.epreuves(
      id uuid primary key,
      competition_id uuid not null references public.competitions(id),
      nom text not null
    );
    create table public.inscriptions(
      id uuid primary key,
      competition_id uuid references public.competitions(id),
      athlete_id uuid references public.profils(id)
    );
    create table public.resultats(
      id uuid primary key,
      athlete_id uuid references public.profils(id)
    );
    create table public.participants_manche(
      id uuid primary key,
      athlete_id uuid references public.profils(id) on delete cascade
    );
    create table public.categories_athletes(
      athlete_id uuid primary key references public.profils(id) on delete cascade
    );
    create table public.groupes_athletes(
      id uuid primary key,
      coach_id uuid references public.profils(id) on delete cascade
    );
    create table public.groupe_athletes_membres(
      groupe_id uuid references public.groupes_athletes(id) on delete cascade,
      athlete_id uuid references public.profils(id) on delete cascade
    );

    create table storage.buckets(
      id text primary key,
      name text not null,
      public boolean not null default false,
      file_size_limit bigint,
      allowed_mime_types text[]
    );
    create table storage.objects(
      id uuid primary key,
      bucket_id text not null references storage.buckets(id),
      name text not null,
      metadata jsonb,
      created_at timestamptz not null default now(),
      unique(bucket_id,name)
    );
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    grant select on storage.objects to anon;
    grant select,insert,update,delete on storage.objects to service_role;

    create function public.securite_identite_valide(p_role text default null)
    returns boolean language sql stable security definer set search_path='' as $$
      select exists(select 1 from public.profils p
        where p.id=auth.uid() and p.compte_id=p.id
          and not p.est_invite and not p.est_archive
          and (p_role is null or p.role=p_role))
    $$;
    create function public.programme_competition_visible(p_id uuid)
    returns boolean language sql stable security definer set search_path='' as $$
      select public.securite_identite_valide() and exists(
        select 1 from public.competitions c where c.id=p_id and (
          c.coach_id=auth.uid() or (
            c.statut<>'brouillon' and exists(
              select 1 from public.inscriptions i
              where i.competition_id=c.id and i.athlete_id=auth.uid()
            )
          )
        )
      )
    $$;
    create function public.competition_configurable_par_coach(p_id uuid)
    returns boolean language sql stable security definer set search_path='' as $$
      select public.securite_identite_valide('coach') and exists(
        select 1 from public.competitions c
        where c.id=p_id and c.coach_id=auth.uid() and c.statut='brouillon')
    $$;

    create function public.preparer_suppression_compte()
    returns trigger language plpgsql as $$ begin return old; end $$;
    create trigger preparer_suppression_compte before delete on auth.users
      for each row execute function public.preparer_suppression_compte();

    insert into auth.users values ('${id(1)}'),('${id(2)}'),('${id(3)}');
    insert into profils values
      ('${id(1)}','${id(1)}','coach',false,false),
      ('${id(2)}','${id(2)}','coach',false,false),
      ('${id(3)}','${id(3)}','athlete',false,false);
    insert into competitions values
      ('${id(10)}','${id(1)}','brouillon'),
      ('${id(11)}','${id(2)}','brouillon'),
      ('${id(12)}','${id(1)}','ouverte');
    insert into epreuves values
      ('${id(20)}','${id(10)}','Épreuve propriétaire'),
      ('${id(21)}','${id(11)}','Épreuve autre coach'),
      ('${id(22)}','${id(12)}','Épreuve ouverte');
    insert into inscriptions values
      ('${id(30)}','${id(12)}','${id(3)}');
  `);
  await db.exec(migration);
  return db;
}

async function utilisateur(
  db: PGlite,
  n: number | null,
  role = "authenticated",
) {
  await db.exec("reset role");
  await db.query(
    "select set_config('request.jwt.claim.sub',$1,false)",
    [n == null ? "" : id(n)],
  );
  await db.exec("set role " + role);
}

async function televerser(
  db: PGlite,
  objet: number,
  extension = "jpg",
  mime = "image/jpeg",
  taille = 120000,
  date = "now()",
) {
  const nom = path(objet, extension);
  await db.query(
    `insert into storage.objects(id,bucket_id,name,metadata,created_at)
     values($1,'affiches-epreuves',$2,
       jsonb_build_object('mimetype',$3::text,'size',$4::bigint),${date})`,
    [id(objet + 100), nom, mime, taille],
  );
  return nom;
}

async function finaliser(
  db: PGlite,
  objet: number,
  position = 1,
  extension = "jpg",
  mime = "image/jpeg",
  taille = 120000,
  alt = "Affiche officielle de l’épreuve",
) {
  return await db.query<{ data: Record<string, unknown> }>(
    `select enregistrer_affiche_epreuve(
      $1,$2,$3,$4,$5,1200,1800,$6
    ) data`,
    [id(20), position, path(objet, extension), mime, taille, alt],
  );
}

Deno.test("affiches : bucket privé et migration réexécutable", async () => {
  const db = await fixture();
  try {
    const bucket = await db.query<{
      public: boolean;
      file_size_limit: number;
      allowed_mime_types: string[];
    }>("select public,file_size_limit,allowed_mime_types from storage.buckets");
    assert(bucket.rows.length === 1);
    assert(!bucket.rows[0].public);
    assert(Number(bucket.rows[0].file_size_limit) === 5242880);
    assert(bucket.rows[0].allowed_mime_types.length === 3);
    await db.exec(migration);
  } finally {
    await db.close();
  }
});

Deno.test("affiches : objet temporaire privé puis finalisation lisible", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 40);
    assert((await db.query("select * from storage.objects")).rows.length === 0);
    const resultat = await finaliser(db, 40);
    assert(resultat.rows[0].data.position === 1);
    assert(resultat.rows[0].data.ancien_objet_path === null);
    assert((await db.query("select * from affiches_epreuve")).rows.length === 1);
    assert((await db.query("select * from storage.objects")).rows.length === 1);

    await utilisateur(db, 3);
    assert((await db.query("select * from affiches_epreuve")).rows.length === 0);
    assert((await db.query("select * from storage.objects")).rows.length === 0);
  } finally {
    await db.close();
  }
});

Deno.test("affiches : autre coach, athlète et compétition ouverte ne peuvent écrire", async () => {
  const db = await fixture();
  try {
    for (const n of [2, 3]) {
      await utilisateur(db, n);
      await refuse(() =>
        db.query(
          `insert into storage.objects(id,bucket_id,name,metadata)
           values($1,'affiches-epreuves',$2,
             '{"mimetype":"image/jpeg","size":"120000"}')`,
          [id(90 + n), path(50 + n)],
        )
      );
      await refuse(() => finaliser(db, 50 + n));
    }
    await utilisateur(db, 1);
    const cheminOuvert = `${id(12)}/${id(22)}/${id(60)}.jpg`;
    await refuse(() =>
      db.query(
        `insert into storage.objects(id,bucket_id,name,metadata)
         values($1,'affiches-epreuves',$2,
           '{"mimetype":"image/jpeg","size":"120000"}')`,
        [id(160), cheminOuvert],
      )
    );
  } finally {
    await db.close();
  }
});

Deno.test("affiches : validations format, taille, dimensions, texte et position", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 70);
    await refuse(() => finaliser(db, 70, 3));
    await refuse(() => finaliser(db, 70, 1, "jpg", "image/jpeg", 120000, "x"));
    await refuse(() =>
      db.query(
        "select enregistrer_affiche_epreuve($1,1,$2,'image/jpeg',120000,4097,100,'Texte valide')",
        [id(20), path(70)],
      )
    );
    await refuse(() => finaliser(db, 70, 1, "jpg", "image/png"));
    await refuse(() =>
      db.query(
        "select enregistrer_affiche_epreuve($1,1,$2,'image/jpeg',5242881,100,100,'Texte valide')",
        [id(20), path(70)],
      )
    );
    assert((await db.query("select * from affiches_epreuve")).rows.length === 0);
  } finally {
    await db.close();
  }
});

Deno.test("affiches : remplacement sûr, réordre et promotion de la deuxième", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 80);
    await finaliser(db, 80, 1);
    await televerser(db, 81, "png", "image/png");
    await finaliser(db, 81, 2, "png", "image/png");

    await televerser(db, 82, "webp", "image/webp");
    const remplace = await finaliser(db, 82, 1, "webp", "image/webp");
    assert(remplace.rows[0].data.ancien_objet_path === path(80));
    const premiere = await db.query<{ objet_path: string; version: number }>(
      "select objet_path,version from affiches_epreuve where position=1",
    );
    assert(premiere.rows[0].objet_path === path(82, "webp"));
    assert(premiere.rows[0].version === 2);

    await db.query("select reordonner_affiches_epreuve($1)", [id(20)]);
    const ordre = await db.query<{ position: number; objet_path: string }>(
      "select position,objet_path from affiches_epreuve order by position",
    );
    assert(ordre.rows[0].objet_path === path(81, "png"));
    assert(ordre.rows[1].objet_path === path(82, "webp"));

    const supprime = await db.query<{ path: string }>(
      "select supprimer_affiche_epreuve($1,1) path",
      [id(20)],
    );
    assert(supprime.rows[0].path === path(81, "png"));
    const restante = await db.query<{ position: number }>(
      "select position from affiches_epreuve",
    );
    assert(restante.rows.length === 1 && restante.rows[0].position === 1);
  } finally {
    await db.close();
  }
});

Deno.test("affiches : objet invalide ne remplace pas l'affiche existante", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 100);
    await finaliser(db, 100);
    await televerser(db, 101, "png", "image/png", 200000);
    await refuse(() => finaliser(db, 101, 1, "png", "image/png", 120000));
    const affiche = await db.query<{ objet_path: string; version: number }>(
      "select objet_path,version from affiches_epreuve",
    );
    assert(affiche.rows[0].objet_path === path(100));
    assert(affiche.rows[0].version === 1);
  } finally {
    await db.close();
  }
});

Deno.test("affiches : texte alternatif modifiable seulement par le propriétaire en brouillon", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 105);
    await finaliser(db, 105);
    const affiche = await db.query<{ id: string }>(
      "select id from affiches_epreuve",
    );
    const modifiee = await db.query<{ data: { texte_alternatif: string } }>(
      "select modifier_texte_alternatif_affiche_epreuve($1,$2,$3) data",
      [affiche.rows[0].id, id(20), "  Nouvelle description accessible  "],
    );
    assert(
      modifiee.rows[0].data.texte_alternatif ===
        "Nouvelle description accessible",
    );
    await refuse(() =>
      db.query(
        "select modifier_texte_alternatif_affiche_epreuve($1,$2,'x')",
        [affiche.rows[0].id, id(20)],
      )
    );
    await utilisateur(db, 2);
    await refuse(() =>
      db.query(
        "select modifier_texte_alternatif_affiche_epreuve($1,$2,'Interdit')",
        [affiche.rows[0].id, id(20)],
      )
    );
  } finally {
    await db.close();
  }
});

Deno.test("affiches : orphelins réservés au serveur et suppression compte compatible", async () => {
  const db = await fixture();
  try {
    await utilisateur(db, 1);
    await televerser(db, 110, "jpg", "image/jpeg", 120000, "now()-interval '2 days'");
    await televerser(db, 111);
    await finaliser(db, 111);

    await refuse(() => db.query("select * from lister_objets_affiches_orphelins()"));
    await utilisateur(db, null, "service_role");
    const orphelins = await db.query<{ objet_path: string }>(
      "select * from lister_objets_affiches_orphelins()",
    );
    assert(orphelins.rows.length === 1 && orphelins.rows[0].objet_path === path(110));
    await db.query("select verifier_schema_suppression_compte()");
  } finally {
    await db.close();
  }
});
