begin;

alter table public.manches add column if not exists participants_definis boolean not null default false;
alter table public.manches add column if not exists duree_limite_secondes integer
  check(duree_limite_secondes between 1 and 86400);

create table if not exists public.participants_manche (
  manche_id uuid not null references public.manches(id) on delete cascade,
  athlete_id uuid not null references public.profils(id) on delete cascade,
  ordre_depart integer not null check(ordre_depart > 0),
  primary key(manche_id,athlete_id),
  unique(manche_id,ordre_depart) deferrable initially immediate
);
create index if not exists participants_manche_athlete_idx on public.participants_manche(athlete_id);
alter table public.participants_manche enable row level security;
revoke all on public.participants_manche from anon,authenticated;
grant select on public.participants_manche to authenticated;
drop policy if exists participants_manche_lecture on public.participants_manche;
create policy participants_manche_lecture on public.participants_manche for select to authenticated using(
  exists(select 1 from public.manches m where m.id=manche_id
    and (public.programme_epreuve_modifiable(m.epreuve_id)
      or (athlete_id=auth.uid() and public.programme_epreuve_visible(m.epreuve_id))))
);

-- Les manches déjà démarrées conservent leur population historique.
-- Les manches à venir restent explicitement à configurer.
insert into public.participants_manche(manche_id,athlete_id,ordre_depart)
select m.id,p.athlete_id,row_number() over(partition by m.id order by p.athlete_id)
from public.manches m join public.epreuves e on e.id=m.epreuve_id
cross join lateral (
  select i.athlete_id from public.inscriptions i where i.competition_id=e.competition_id
  union select r.athlete_id from public.resultats r where r.manche_id=m.id
) p where m.statut in ('en_cours','terminee') and not m.participants_definis
on conflict do nothing;
update public.manches set participants_definis=true
  where statut in ('en_cours','terminee') and not participants_definis;

create or replace function public.configurer_participants_manche(
  p_manche_id uuid,p_athlete_ids uuid[],p_duree_limite_secondes integer)
returns void language plpgsql security definer set search_path='' as $$
declare v_m public.manches; v_competition uuid; v_total integer;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Cette manche ne peut pas être configurée.' using errcode='42501';
  end if;
  if v_m.statut <> 'a_venir' then raise exception 'Les affectations et le délai sont figés après le départ.'; end if;
  v_total:=coalesce(cardinality(p_athlete_ids),0);
  if v_total=0 or exists(select 1 from unnest(p_athlete_ids) x where x is null)
    or (select count(distinct x) from unnest(p_athlete_ids) x) <> v_total then
    raise exception 'Choisis au moins un participant, sans doublon.';
  end if;
  if p_duree_limite_secondes is null or p_duree_limite_secondes not between 1 and 86400 then
    raise exception 'Le délai doit être compris entre 1 et 86400 secondes.';
  end if;
  select competition_id into v_competition from public.epreuves where id=v_m.epreuve_id;
  if exists(select 1 from unnest(p_athlete_ids) x where not exists(
      select 1 from public.inscriptions i where i.competition_id=v_competition and i.athlete_id=x)) then
    raise exception 'Tous les participants doivent être inscrits à cette compétition.';
  end if;
  delete from public.participants_manche where manche_id=p_manche_id;
  insert into public.participants_manche(manche_id,athlete_id,ordre_depart)
    select p_manche_id,x,position::integer from unnest(p_athlete_ids) with ordinality p(x,position);
  update public.manches set participants_definis=true,duree_limite_secondes=p_duree_limite_secondes,
    date_modification=now() where id=p_manche_id;
end $$;
revoke all on function public.configurer_participants_manche(uuid,uuid[],integer) from public,anon;
grant execute on function public.configurer_participants_manche(uuid,uuid[],integer) to authenticated;

create or replace function public.verifier_configuration_manche()
returns trigger language plpgsql set search_path='' as $$
begin
  if old.statut <> 'a_venir' and (new.participants_definis is distinct from old.participants_definis
      or new.duree_limite_secondes is distinct from old.duree_limite_secondes) then
    raise exception 'Les affectations et le délai sont figés après le départ.';
  end if;
  if current_user in ('anon','authenticated') and
    (new.participants_definis is distinct from old.participants_definis
      or new.duree_limite_secondes is distinct from old.duree_limite_secondes) then
    raise exception 'Utiliser la configuration vérifiée de la manche.' using errcode='42501';
  end if;
  if old.statut='a_venir' and new.statut='en_cours' then
    perform 1 from public.epreuves where id=new.epreuve_id for update;
    if exists(select 1 from public.manches where epreuve_id=new.epreuve_id and id<>new.id
        and (statut='en_cours' or (numero<new.numero and statut not in ('terminee','annulee')))) then
      raise exception 'Termine les manches précédentes et toute manche en cours avant ce départ.';
    end if;
    if not new.participants_definis or not exists(select 1 from public.participants_manche where manche_id=new.id) then
      raise exception 'Configurer les participants avant de démarrer la manche.';
    end if;
    if exists(select 1 from public.participants_manche p
      join public.epreuves e on e.id=new.epreuve_id
      where p.manche_id=new.id and not exists(select 1 from public.inscriptions i
        where i.competition_id=e.competition_id and i.athlete_id=p.athlete_id)) then
      raise exception 'Une inscription a changé. Vérifier les participants avant le départ.';
    end if;
  end if;
  return new;
end $$;
revoke all on function public.verifier_configuration_manche() from public,anon,authenticated;
drop trigger if exists verifier_configuration_manche on public.manches;
create trigger verifier_configuration_manche before update on public.manches
  for each row execute function public.verifier_configuration_manche();

create or replace function public.verifier_participant_resultat()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_definis boolean;
begin
  select participants_definis into v_definis from public.manches where id=new.manche_id for update;
  if v_definis and not exists(select 1 from public.participants_manche
      where manche_id=new.manche_id and athlete_id=new.athlete_id) then
    raise exception 'Cet athlète n’est pas affecté à cette manche.';
  end if;
  return new;
end $$;
revoke all on function public.verifier_participant_resultat() from public,anon,authenticated;
drop trigger if exists verifier_participant_resultat on public.resultats;
create trigger verifier_participant_resultat before insert or update on public.resultats
  for each row execute function public.verifier_participant_resultat();

create or replace function public.programme_competition_athlete(p_competition_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_epreuves jsonb;
begin
  if auth.uid() is null or not exists(
    select 1 from public.profils where id=auth.uid() and compte_id=id and not est_invite and role='athlete'
  ) or not public.programme_competition_visible(p_competition_id) then
    raise exception 'Ce programme n’est pas accessible.' using errcode='42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',e.id,'nom',e.nom,'discipline',e.discipline,'distance_metres',e.distance_metres,
    'ordre',e.ordre,'manches',(
      select coalesce(jsonb_agg(jsonb_build_object(
        'id',m.id,'numero',m.numero,'statut',m.statut,
        'participe',case when m.participants_definis then exists(
          select 1 from public.participants_manche p where p.manche_id=m.id and p.athlete_id=auth.uid()) else null end,
        'ordre_depart',(select p.ordre_depart from public.participants_manche p
          where p.manche_id=m.id and p.athlete_id=auth.uid())
      ) order by m.numero,m.id),'[]'::jsonb) from public.manches m where m.epreuve_id=e.id
    )
  ) order by e.ordre,e.id),'[]'::jsonb) into v_epreuves
  from public.epreuves e where e.competition_id=p_competition_id;
  return jsonb_build_object('epreuves',v_epreuves,'affectations_disponibles',true);
end $$;

-- La suppression de compte efface uniquement ses affectations via la FK,
-- sans supprimer les manches ni les autres participants.
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
