-- DEM-003 : jusqu'à deux affiches privées par épreuve.
-- Prérequis : gestion des épreuves, programme athlète, sécurité production,
-- catégories et groupes d'athlètes.
-- Aucun objet existant n'est supprimé lors de l'application.
begin;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values(
  'affiches-epreuves',
  'affiches-epreuves',
  false,
  5242880,
  array['image/jpeg','image/png','image/webp']
)
on conflict(id) do update set
  public=false,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

create table if not exists public.affiches_epreuve(
  id uuid primary key default gen_random_uuid(),
  epreuve_id uuid not null references public.epreuves(id) on delete restrict,
  position smallint not null check(position between 1 and 2),
  objet_path text not null unique,
  mime_type text not null check(mime_type in ('image/jpeg','image/png','image/webp')),
  taille_octets bigint not null check(taille_octets between 1 and 5242880),
  largeur integer not null check(largeur between 1 and 4096),
  hauteur integer not null check(hauteur between 1 and 4096),
  texte_alternatif text not null
    check(length(btrim(texte_alternatif)) between 3 and 300),
  version integer not null default 1 check(version>0),
  cree_par uuid references public.profils(id) on delete set null,
  date_creation timestamptz not null default now(),
  date_modification timestamptz not null default now(),
  constraint affiches_epreuve_position_unique
    unique(epreuve_id,position) deferrable initially immediate
);

alter table public.affiches_epreuve enable row level security;
revoke all on table public.affiches_epreuve from public,anon,authenticated;
grant select on table public.affiches_epreuve to authenticated;

create or replace function public.affiche_epreuve_visible(p_epreuve_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide() and exists(
    select 1 from public.epreuves e
    where e.id=p_epreuve_id
      and public.programme_competition_visible(e.competition_id)
  );
$$;

create or replace function public.affiche_epreuve_modifiable(p_epreuve_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide('coach') and exists(
    select 1 from public.epreuves e
    where e.id=p_epreuve_id
      and public.competition_configurable_par_coach(e.competition_id)
  );
$$;

revoke all on function public.affiche_epreuve_visible(uuid)
  from public,anon,authenticated;
revoke all on function public.affiche_epreuve_modifiable(uuid)
  from public,anon,authenticated;
grant execute on function public.affiche_epreuve_visible(uuid) to authenticated;
grant execute on function public.affiche_epreuve_modifiable(uuid) to authenticated;

drop policy if exists "Affiches epreuve lecture" on public.affiches_epreuve;
create policy "Affiches epreuve lecture" on public.affiches_epreuve
  for select to authenticated
  using(public.affiche_epreuve_visible(epreuve_id));

-- Vérifie le chemin sans effectuer de cast avant la validation de sa forme.
create or replace function public.affiche_objet_modifiable(p_name text)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare
  v_competition_id uuid;
  v_epreuve_id uuid;
begin
  if p_name is null or p_name !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$'
  then return false; end if;
  v_competition_id := split_part(p_name,'/',1)::uuid;
  v_epreuve_id := split_part(p_name,'/',2)::uuid;
  return exists(
    select 1 from public.epreuves e
    where e.id=v_epreuve_id and e.competition_id=v_competition_id
      and public.affiche_epreuve_modifiable(e.id)
  );
end $$;

create or replace function public.affiche_objet_visible(p_name text)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.affiches_epreuve a
    where a.objet_path=p_name
      and public.affiche_epreuve_visible(a.epreuve_id)
  );
$$;

revoke all on function public.affiche_objet_modifiable(text)
  from public,anon,authenticated;
revoke all on function public.affiche_objet_visible(text)
  from public,anon,authenticated;
grant execute on function public.affiche_objet_modifiable(text) to authenticated;
grant execute on function public.affiche_objet_visible(text) to authenticated;

drop policy if exists "Affiches objets lecture" on storage.objects;
create policy "Affiches objets lecture" on storage.objects
  for select to authenticated
  using(
    bucket_id='affiches-epreuves'
    and public.affiche_objet_visible(name)
  );

drop policy if exists "Affiches objets insertion" on storage.objects;
create policy "Affiches objets insertion" on storage.objects
  for insert to authenticated
  with check(
    bucket_id='affiches-epreuves'
    and public.affiche_objet_modifiable(name)
  );

drop policy if exists "Affiches objets suppression" on storage.objects;
create policy "Affiches objets suppression" on storage.objects
  for delete to authenticated
  using(
    bucket_id='affiches-epreuves'
    and public.affiche_objet_modifiable(name)
  );

-- Aucun UPDATE Storage n'est accordé : un remplacement crée un objet immuable.
drop policy if exists "Affiches objets modification" on storage.objects;

create or replace function public.enregistrer_affiche_epreuve(
  p_epreuve_id uuid,
  p_position integer,
  p_objet_path text,
  p_mime_type text,
  p_taille_octets bigint,
  p_largeur integer,
  p_hauteur integer,
  p_texte_alternatif text
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_epreuve public.epreuves;
  v_objet storage.objects;
  v_affiche public.affiches_epreuve;
  v_ancienne_path text;
  v_mime text;
  v_taille bigint;
begin
  if not public.affiche_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut modifier les affiches d’une épreuve en brouillon.'
      using errcode='42501';
  end if;
  if p_position not between 1 and 2 then
    raise exception 'Deux affiches maximum par épreuve.' using errcode='22023';
  end if;
  if length(btrim(coalesce(p_texte_alternatif,''))) not between 3 and 300 then
    raise exception 'Le texte alternatif doit contenir entre 3 et 300 caractères.'
      using errcode='22023';
  end if;
  if p_mime_type not in ('image/jpeg','image/png','image/webp')
    or p_taille_octets not between 1 and 5242880
    or p_largeur not between 1 and 4096
    or p_hauteur not between 1 and 4096
  then
    raise exception 'L’affiche doit être un JPEG, PNG ou WebP de 5 Mo et 4096 × 4096 maximum.'
      using errcode='22023';
  end if;

  select * into v_epreuve from public.epreuves
  where id=p_epreuve_id for update;
  if not found then raise exception 'Épreuve introuvable.' using errcode='P0002'; end if;

  if not public.affiche_objet_modifiable(p_objet_path)
    or split_part(p_objet_path,'/',1)<>v_epreuve.competition_id::text
    or split_part(p_objet_path,'/',2)<>p_epreuve_id::text
  then
    raise exception 'Chemin Storage invalide pour cette épreuve.' using errcode='22023';
  end if;

  if (p_mime_type='image/jpeg' and p_objet_path !~ '\.(jpg|jpeg)$')
    or (p_mime_type='image/png' and p_objet_path !~ '\.png$')
    or (p_mime_type='image/webp' and p_objet_path !~ '\.webp$')
  then raise exception 'Le format déclaré ne correspond pas au fichier.'
    using errcode='22023'; end if;

  select * into v_objet from storage.objects
  where bucket_id='affiches-epreuves' and name=p_objet_path;
  if not found then
    raise exception 'Le fichier temporaire est absent du stockage.' using errcode='P0002';
  end if;
  v_mime := lower(coalesce(v_objet.metadata->>'mimetype',''));
  begin
    v_taille := coalesce(
      nullif(v_objet.metadata->>'size','')::bigint,
      nullif(v_objet.metadata->>'contentLength','')::bigint
    );
  exception when invalid_text_representation then
    raise exception 'Métadonnées Storage invalides.' using errcode='22023';
  end;
  if v_mime<>p_mime_type or v_taille is null or v_taille<>p_taille_octets
    or v_taille not between 1 and 5242880
  then
    raise exception 'Le type ou la taille Storage ne correspond pas à l’affiche.'
      using errcode='22023';
  end if;

  select objet_path into v_ancienne_path from public.affiches_epreuve
  where epreuve_id=p_epreuve_id and position=p_position for update;

  if found then
    update public.affiches_epreuve set
      objet_path=p_objet_path,
      mime_type=p_mime_type,
      taille_octets=p_taille_octets,
      largeur=p_largeur,
      hauteur=p_hauteur,
      texte_alternatif=btrim(p_texte_alternatif),
      version=version+1,
      date_modification=now()
    where epreuve_id=p_epreuve_id and position=p_position
    returning * into v_affiche;
  else
    insert into public.affiches_epreuve(
      epreuve_id,position,objet_path,mime_type,taille_octets,largeur,hauteur,
      texte_alternatif,cree_par
    ) values(
      p_epreuve_id,p_position,p_objet_path,p_mime_type,p_taille_octets,
      p_largeur,p_hauteur,btrim(p_texte_alternatif),auth.uid()
    ) returning * into v_affiche;
  end if;

  return to_jsonb(v_affiche)
    || jsonb_build_object('ancien_objet_path',v_ancienne_path);
end $$;

create or replace function public.reordonner_affiches_epreuve(p_epreuve_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.affiche_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut réordonner ces affiches.'
      using errcode='42501';
  end if;
  perform 1 from public.epreuves where id=p_epreuve_id for update;
  if (select count(*) from public.affiches_epreuve where epreuve_id=p_epreuve_id)<>2
  then raise exception 'Deux affiches sont nécessaires pour modifier leur ordre.'
    using errcode='22023'; end if;
  set constraints public.affiches_epreuve_position_unique deferred;
  update public.affiches_epreuve
  set position=case position when 1 then 2 else 1 end,
      date_modification=now()
  where epreuve_id=p_epreuve_id;
end $$;

create or replace function public.supprimer_affiche_epreuve(
  p_epreuve_id uuid,p_position integer
) returns text language plpgsql security definer set search_path='' as $$
declare v_path text;
begin
  if not public.affiche_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut supprimer cette affiche.'
      using errcode='42501';
  end if;
  perform 1 from public.epreuves where id=p_epreuve_id for update;
  delete from public.affiches_epreuve
  where epreuve_id=p_epreuve_id and position=p_position
  returning objet_path into v_path;
  if v_path is null then raise exception 'Affiche introuvable.' using errcode='P0002'; end if;
  if p_position=1 then
    update public.affiches_epreuve set position=1,date_modification=now()
    where epreuve_id=p_epreuve_id and position=2;
  end if;
  return v_path;
end $$;

create or replace function public.modifier_texte_alternatif_affiche_epreuve(
  p_affiche_id uuid,
  p_epreuve_id uuid,
  p_texte_alternatif text
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_affiche public.affiches_epreuve;
begin
  if not public.affiche_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut modifier le texte de cette affiche.'
      using errcode='42501';
  end if;
  if length(btrim(coalesce(p_texte_alternatif,''))) not between 3 and 300 then
    raise exception 'Le texte alternatif doit contenir entre 3 et 300 caractères.'
      using errcode='22023';
  end if;
  update public.affiches_epreuve set
    texte_alternatif=btrim(p_texte_alternatif),
    date_modification=now()
  where id=p_affiche_id and epreuve_id=p_epreuve_id
  returning * into v_affiche;
  if not found then raise exception 'Affiche introuvable.' using errcode='P0002'; end if;
  return to_jsonb(v_affiche);
end $$;

-- Cette liste est destinée à un traitement serveur qui supprime les objets via
-- l'API Storage. Supprimer une ligne storage.objects ne supprime pas le fichier physique.
create or replace function public.lister_objets_affiches_orphelins(
  p_avant timestamptz default now()-interval '24 hours'
) returns table(objet_path text)
language sql stable security definer set search_path='' as $$
  select o.name
  from storage.objects o
  where o.bucket_id='affiches-epreuves' and o.created_at<p_avant
    and not exists(
      select 1 from public.affiches_epreuve a where a.objet_path=o.name
    );
$$;

revoke all on function public.enregistrer_affiche_epreuve(
  uuid,integer,text,text,bigint,integer,integer,text
) from public,anon;
revoke all on function public.reordonner_affiches_epreuve(uuid)
  from public,anon;
revoke all on function public.supprimer_affiche_epreuve(uuid,integer)
  from public,anon;
revoke all on function public.modifier_texte_alternatif_affiche_epreuve(uuid,uuid,text)
  from public,anon;
revoke all on function public.lister_objets_affiches_orphelins(timestamptz)
  from public,anon,authenticated;
grant execute on function public.enregistrer_affiche_epreuve(
  uuid,integer,text,text,bigint,integer,integer,text
) to authenticated;
grant execute on function public.reordonner_affiches_epreuve(uuid)
  to authenticated;
grant execute on function public.supprimer_affiche_epreuve(uuid,integer)
  to authenticated;
grant execute on function public.modifier_texte_alternatif_affiche_epreuve(uuid,uuid,text)
  to authenticated;
grant execute on function public.lister_objets_affiches_orphelins(timestamptz)
  to service_role;

-- La table des affiches conserve l'historique de la compétition lors de la
-- suppression du compte coach. Seule la référence d'auteur devient nulle.
create or replace function public.verifier_schema_suppression_compte()
returns void language plpgsql security definer set search_path='' as $$
declare fk record;
begin
  for fk in
    select c.conrelid,c.confrelid,c.confdeltype,
      array(select a.attname::text from unnest(c.conkey) with ordinality k(num,ordre)
        join pg_catalog.pg_attribute a on a.attrelid=c.conrelid and a.attnum=k.num
        order by k.ordre) colonnes
    from pg_catalog.pg_constraint c
    join pg_catalog.pg_class t on t.oid=c.conrelid
    join pg_catalog.pg_namespace n on n.oid=t.relnamespace
    where c.contype='f' and n.nspname not in ('auth','storage')
      and c.confrelid in ('auth.users'::regclass,'public.profils'::regclass,
        'public.inscriptions'::regclass,'public.resultats'::regclass)
  loop
    if not (
      (fk.conrelid='public.profils'::regclass and fk.confrelid='auth.users'::regclass and fk.colonnes=array['compte_id'])
      or (fk.conrelid='public.competitions'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['coach_id'])
      or (fk.conrelid='public.inscriptions'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['athlete_id'])
      or (fk.conrelid='public.resultats'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['athlete_id'])
      or (fk.conrelid='public.participants_manche'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['athlete_id'] and fk.confdeltype='c')
      or (fk.conrelid='public.categories_athletes'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['athlete_id'] and fk.confdeltype='c')
      or (fk.conrelid='public.groupes_athletes'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['coach_id'] and fk.confdeltype='c')
      or (fk.conrelid='public.groupe_athletes_membres'::regclass and fk.confrelid='public.profils'::regclass and fk.colonnes=array['athlete_id'] and fk.confdeltype='c')
      or (fk.conrelid='public.affiches_epreuve'::regclass and fk.confrelid='public.profils'::regclass
        and fk.colonnes=array['cree_par'] and fk.confdeltype='n')
    ) then raise exception 'Relation non prise en charge : suppression suspendue pour audit.'; end if;
  end loop;
  if not exists(select 1 from pg_catalog.pg_trigger where tgrelid='auth.users'::regclass
    and tgname='preparer_suppression_compte' and tgenabled in ('O','A')
    and tgfoid='public.preparer_suppression_compte()'::regprocedure) then
    raise exception 'Protection de suppression non installée.';
  end if;
end $$;
revoke all on function public.verifier_schema_suppression_compte()
  from public,anon,authenticated;
grant execute on function public.verifier_schema_suppression_compte()
  to service_role;

comment on table public.affiches_epreuve is
  'Métadonnées des deux affiches maximum d’une épreuve ; objets privés dans le bucket affiches-epreuves.';

commit;
