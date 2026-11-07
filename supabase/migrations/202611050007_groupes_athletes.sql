-- Groupes d'athlètes privés par coach.
begin;

create table if not exists public.groupes_athletes (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.profils(id) on delete cascade,
  nom text not null,
  date_creation timestamptz not null default now(),
  date_modification timestamptz not null default now(),
  constraint groupes_athletes_nom_check check (length(btrim(nom)) between 2 and 60)
);

create unique index if not exists groupes_athletes_coach_nom_unique
  on public.groupes_athletes(coach_id,lower(nom));

create table if not exists public.groupe_athletes_membres (
  groupe_id uuid not null references public.groupes_athletes(id) on delete cascade,
  athlete_id uuid not null references public.profils(id) on delete cascade,
  date_ajout timestamptz not null default now(),
  primary key (groupe_id,athlete_id)
);

alter table public.groupes_athletes enable row level security;
alter table public.groupe_athletes_membres enable row level security;

revoke all on public.groupes_athletes from anon,authenticated;
revoke all on public.groupe_athletes_membres from anon,authenticated;
grant select on public.groupes_athletes to authenticated;
grant select on public.groupe_athletes_membres to authenticated;

drop policy if exists "Coach lit ses groupes" on public.groupes_athletes;
create policy "Coach lit ses groupes" on public.groupes_athletes
for select to authenticated using (
  coach_id=auth.uid() and public.securite_identite_valide('coach')
);

drop policy if exists "Coach lit les membres de ses groupes" on public.groupe_athletes_membres;
create policy "Coach lit les membres de ses groupes" on public.groupe_athletes_membres
for select to authenticated using (
  exists(select 1 from public.groupes_athletes g
    where g.id=groupe_id and g.coach_id=auth.uid())
  and public.securite_identite_valide('coach')
);

create or replace function public.enregistrer_groupe_athletes(
  p_groupe_id uuid,
  p_nom text,
  p_athlete_ids uuid[]
) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
  v_groupe public.groupes_athletes;
  v_nom text := btrim(p_nom);
begin
  if not public.securite_identite_valide('coach') then
    raise exception 'Cette action est réservée aux coachs.' using errcode='42501';
  end if;
  if length(v_nom) not between 2 and 60 then
    raise exception 'Le nom du groupe doit contenir entre 2 et 60 caractères.'
      using errcode='22023';
  end if;
  if coalesce(cardinality(p_athlete_ids),0)=0
    or cardinality(p_athlete_ids) <> (
      select count(distinct u.athlete_id)
      from unnest(p_athlete_ids) as u(athlete_id)
    ) then
    raise exception 'La liste des athlètes est vide ou contient des doublons.'
      using errcode='22023';
  end if;
  if exists(
    select 1 from unnest(p_athlete_ids) as u(athlete_id)
    where not exists(
      select 1 from public.profils p
      where p.id=u.athlete_id and p.role='athlete' and not p.est_archive and (
        (not p.est_invite and p.compte_id=p.id)
        or (p.est_invite and exists(
          select 1 from public.inscriptions i
          join public.competitions c on c.id=i.competition_id
          where i.athlete_id=p.id and c.coach_id=auth.uid()
        ))
      )
    )
  ) then
    raise exception 'Un athlète ne peut pas être ajouté à ce groupe.'
      using errcode='42501';
  end if;

  if p_groupe_id is null then
    insert into public.groupes_athletes(coach_id,nom)
      values(auth.uid(),v_nom) returning * into v_groupe;
  else
    update public.groupes_athletes
      set nom=v_nom,date_modification=now()
      where id=p_groupe_id and coach_id=auth.uid()
      returning * into v_groupe;
    if not found then
      raise exception 'Groupe introuvable.' using errcode='42501';
    end if;
  end if;

  delete from public.groupe_athletes_membres where groupe_id=v_groupe.id;
  insert into public.groupe_athletes_membres(groupe_id,athlete_id)
    select v_groupe.id,u.athlete_id
    from unnest(p_athlete_ids) as u(athlete_id);

  return jsonb_build_object(
    'id',v_groupe.id,
    'nom',v_groupe.nom,
    'athlete_ids',to_jsonb(p_athlete_ids)
  );
end $$;
revoke all on function public.enregistrer_groupe_athletes(uuid,text,uuid[])
  from public,anon;
grant execute on function public.enregistrer_groupe_athletes(uuid,text,uuid[])
  to authenticated;

create or replace function public.supprimer_groupe_athletes(p_groupe_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.securite_identite_valide('coach') then
    raise exception 'Cette action est réservée aux coachs.' using errcode='42501';
  end if;
  delete from public.groupes_athletes
    where id=p_groupe_id and coach_id=auth.uid();
  if not found then
    raise exception 'Groupe introuvable.' using errcode='42501';
  end if;
end $$;
revoke all on function public.supprimer_groupe_athletes(uuid) from public,anon;
grant execute on function public.supprimer_groupe_athletes(uuid) to authenticated;

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
grant execute on function public.verifier_schema_suppression_compte() to service_role;

commit;
