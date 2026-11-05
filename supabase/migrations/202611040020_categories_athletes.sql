begin;
create table if not exists public.categories_athletes(
  athlete_id uuid primary key references public.profils(id) on delete cascade,
  categorie text check(categorie in (
    'M 18-24','F 18-24','M 25-29','F 25-29','M 30-34','F 30-34',
    'M 40-44','F 40-44','M 50-54','F 50-54','M 60-64','F 60-64')),
  date_modification timestamptz not null default now()
);
alter table public.categories_athletes enable row level security;
-- Accès seulement par RPC pour éviter de dépendre de policies permissives du profil.
revoke all on public.categories_athletes from anon,authenticated;

create or replace function public.categorie_athlete_modifiable(p_athlete_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select auth.uid() is not null and exists(
    select 1 from public.profils p where p.id=p_athlete_id and p.role='athlete' and(
      (p.id=auth.uid() and p.compte_id=p.id and not p.est_invite)
      or (p.est_invite and public.coach_peut_lire_invite(p.id) and exists(
        select 1 from public.profils c where c.id=auth.uid() and c.role='coach' and c.compte_id=c.id and not c.est_invite))
    ));
$$;

create or replace function public.consulter_categorie_athlete(p_athlete_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_modifiable boolean;
begin
 v_modifiable:=public.categorie_athlete_modifiable(p_athlete_id);
 if not v_modifiable and not exists(
   select 1 from public.inscriptions i join public.competitions c on c.id=i.competition_id
   where i.athlete_id=p_athlete_id and c.coach_id=auth.uid()
     and public.programme_competition_modifiable(c.id)
 ) then
   raise exception 'Catégorie non accessible.' using errcode='42501';
 end if;
 return jsonb_build_object('categorie',(select categorie from public.categories_athletes where athlete_id=p_athlete_id),'modifiable',v_modifiable);
end $$;

create or replace function public.configurer_categorie_athlete(p_athlete_id uuid,p_categorie text)
returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.categorie_athlete_modifiable(p_athlete_id) then
   raise exception 'Modification non autorisée.' using errcode='42501';
 end if;
 insert into public.categories_athletes(athlete_id,categorie) values(p_athlete_id,p_categorie)
 on conflict(athlete_id) do update set categorie=excluded.categorie,date_modification=now();
end $$;

revoke all on function public.categorie_athlete_modifiable(uuid) from public,anon,authenticated;
revoke all on function public.consulter_categorie_athlete(uuid) from public,anon;
revoke all on function public.configurer_categorie_athlete(uuid,text) from public,anon;
grant execute on function public.consulter_categorie_athlete(uuid) to authenticated;
grant execute on function public.configurer_categorie_athlete(uuid,text) to authenticated;
comment on table public.categories_athletes is 'Catégorie déclarée facultative ; ne modifie pas les classements et ne conserve pas de date de naissance.';
-- Étendre uniquement les FK reconnues : la suppression des catégories ne
-- supprime aucun historique des autres athlètes.
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
      or (fk.conrelid='public.participants_manche'::regclass and fk.confrelid='public.profils'::regclass
        and fk.colonnes=array['athlete_id'] and fk.confdeltype='c')
      or (fk.conrelid='public.categories_athletes'::regclass and fk.confrelid='public.profils'::regclass
        and fk.colonnes=array['athlete_id'] and fk.confdeltype='c')
    ) then raise exception 'Relation non prise en charge : suppression suspendue pour audit.'; end if;
  end loop;
  if not exists(select 1 from pg_catalog.pg_trigger where tgrelid='auth.users'::regclass
    and tgname='preparer_suppression_compte' and tgenabled in ('O','A')
    and tgfoid='public.preparer_suppression_compte()'::regprocedure) then
    raise exception 'Protection de suppression non installée.';
  end if;
end $$;
revoke all on function public.verifier_schema_suppression_compte() from public,anon,authenticated;
grant execute on function public.verifier_schema_suppression_compte() to service_role;
commit;
