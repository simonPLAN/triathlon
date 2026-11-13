-- Image de couverture privée d'une compétition.
begin;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values(
  'images-competitions','images-competitions',false,5242880,
  array['image/jpeg','image/png','image/webp']
)
on conflict(id) do update set
  public=false,
  file_size_limit=excluded.file_size_limit,
  allowed_mime_types=excluded.allowed_mime_types;

alter table public.competitions
  add column if not exists image_path text,
  add column if not exists image_mime text,
  add column if not exists image_taille_octets bigint,
  add column if not exists image_largeur integer,
  add column if not exists image_hauteur integer;

create unique index if not exists competitions_image_path_unique
  on public.competitions(image_path) where image_path is not null;

create or replace function public.image_competition_modifiable(p_name text)
returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_competition_id uuid;
begin
  if p_name is null or p_name !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](jpg|jpeg|png|webp)$'
  then return false; end if;
  v_competition_id := split_part(p_name,'/',1)::uuid;
  return public.competition_configurable_par_coach(v_competition_id);
end $$;

create or replace function public.image_competition_visible(p_name text)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide() and exists(
    select 1 from public.competitions c
    where c.image_path=p_name
      and public.programme_competition_visible(c.id)
  );
$$;

revoke all on function public.image_competition_modifiable(text)
  from public,anon,authenticated;
revoke all on function public.image_competition_visible(text)
  from public,anon,authenticated;
grant execute on function public.image_competition_modifiable(text) to authenticated;
grant execute on function public.image_competition_visible(text) to authenticated;

drop policy if exists "Images competitions lecture" on storage.objects;
create policy "Images competitions lecture" on storage.objects
for select to authenticated using(
  bucket_id='images-competitions'
  and public.image_competition_visible(name)
);

drop policy if exists "Images competitions insertion" on storage.objects;
create policy "Images competitions insertion" on storage.objects
for insert to authenticated with check(
  bucket_id='images-competitions'
  and public.image_competition_modifiable(name)
);

drop policy if exists "Images competitions suppression" on storage.objects;
create policy "Images competitions suppression" on storage.objects
for delete to authenticated using(
  bucket_id='images-competitions'
  and public.image_competition_modifiable(name)
);

drop policy if exists "Images competitions modification" on storage.objects;

create or replace function public.enregistrer_image_competition(
  p_competition_id uuid,
  p_objet_path text,
  p_mime_type text,
  p_taille_octets bigint,
  p_largeur integer,
  p_hauteur integer
) returns text language plpgsql security definer set search_path='' as $$
declare
  v_objet storage.objects;
  v_ancienne_path text;
  v_taille bigint;
  v_mime text;
begin
  if not public.competition_configurable_par_coach(p_competition_id) then
    raise exception 'Seul le coach responsable peut modifier l’image d’une compétition en brouillon.'
      using errcode='42501';
  end if;
  if p_mime_type not in ('image/jpeg','image/png','image/webp')
    or p_taille_octets not between 1 and 5242880
    or p_largeur not between 1 and 4096
    or p_hauteur not between 1 and 4096
  then
    raise exception 'L’image doit être un JPEG, PNG ou WebP de 5 Mo et 4096 × 4096 maximum.'
      using errcode='22023';
  end if;
  if not public.image_competition_modifiable(p_objet_path)
    or split_part(p_objet_path,'/',1)<>p_competition_id::text
  then
    raise exception 'Chemin Storage invalide pour cette compétition.'
      using errcode='22023';
  end if;
  if (p_mime_type='image/jpeg' and p_objet_path !~ '[.](jpg|jpeg)$')
    or (p_mime_type='image/png' and p_objet_path !~ '[.]png$')
    or (p_mime_type='image/webp' and p_objet_path !~ '[.]webp$')
  then
    raise exception 'Le format déclaré ne correspond pas au fichier.'
      using errcode='22023';
  end if;

  select * into v_objet from storage.objects
  where bucket_id='images-competitions' and name=p_objet_path;
  if not found then
    raise exception 'Le fichier temporaire est absent du stockage.'
      using errcode='P0002';
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
  if v_mime<>p_mime_type or v_taille is null or v_taille<>p_taille_octets then
    raise exception 'Le type ou la taille Storage ne correspond pas à l’image.'
      using errcode='22023';
  end if;

  select image_path into v_ancienne_path
  from public.competitions where id=p_competition_id for update;

  update public.competitions set
    image_path=p_objet_path,
    image_mime=p_mime_type,
    image_taille_octets=p_taille_octets,
    image_largeur=p_largeur,
    image_hauteur=p_hauteur,
    date_modification=now()
  where id=p_competition_id;

  return v_ancienne_path;
end $$;

create or replace function public.supprimer_image_competition(
  p_competition_id uuid
) returns text language plpgsql security definer set search_path='' as $$
declare v_path text;
begin
  if not public.competition_configurable_par_coach(p_competition_id) then
    raise exception 'Seul le coach responsable peut supprimer l’image d’une compétition en brouillon.'
      using errcode='42501';
  end if;
  select image_path into v_path from public.competitions
    where id=p_competition_id for update;
  update public.competitions set
    image_path=null,image_mime=null,image_taille_octets=null,
    image_largeur=null,image_hauteur=null,date_modification=now()
  where id=p_competition_id;
  return v_path;
end $$;

revoke all on function public.enregistrer_image_competition(
  uuid,text,text,bigint,integer,integer
) from public,anon,authenticated;
grant execute on function public.enregistrer_image_competition(
  uuid,text,text,bigint,integer,integer
) to authenticated;
revoke all on function public.supprimer_image_competition(uuid)
  from public,anon,authenticated;
grant execute on function public.supprimer_image_competition(uuid)
  to authenticated;

commit;
