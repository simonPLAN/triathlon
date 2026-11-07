begin;

-- Périmètre de lecture : coach propriétaire, ou athlète authentifié dont
-- le profil possède un vrai compte, compétition ouverte ou inscription existante.
create or replace function public.programme_competition_visible(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists (
    select 1 from public.competitions c
    join public.profils p on p.id=auth.uid() and p.compte_id=p.id and not p.est_invite
    where c.id=p_id and (
      (p.role='coach' and c.coach_id=p.id)
      or (p.role='athlete' and (
        c.statut='ouverte'
        or (c.statut<>'brouillon' and exists(
          select 1 from public.inscriptions i where i.competition_id=c.id and i.athlete_id=p.id
        ))
      ))
    )
  );
$$;
create or replace function public.programme_epreuve_visible(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.epreuves e where e.id=p_id
    and public.programme_competition_visible(e.competition_id));
$$;
create or replace function public.programme_competition_modifiable(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.competitions c
    join public.profils p on p.id=c.coach_id
    where c.id=p_id and c.coach_id=auth.uid() and p.role='coach'
      and p.compte_id=p.id and not p.est_invite);
$$;
create or replace function public.programme_epreuve_modifiable(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.epreuves e where e.id=p_id
    and public.programme_competition_modifiable(e.competition_id));
$$;
revoke all on function public.programme_competition_visible(uuid) from public,anon;
revoke all on function public.programme_epreuve_visible(uuid) from public,anon;
revoke all on function public.programme_competition_modifiable(uuid) from public,anon;
revoke all on function public.programme_epreuve_modifiable(uuid) from public,anon;
grant execute on function public.programme_competition_visible(uuid) to authenticated,anon;
grant execute on function public.programme_epreuve_visible(uuid) to authenticated,anon;
grant execute on function public.programme_competition_modifiable(uuid) to authenticated,anon;
grant execute on function public.programme_epreuve_modifiable(uuid) to authenticated,anon;

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
        -- Ne pas déduire une affectation de l'inscription ou d'un résultat.
        -- Ces champs seront alimentés par la future gestion des participants.
        'participe',null,'ordre_depart',null
      ) order by m.numero,m.id),'[]'::jsonb)
      from public.manches m where m.epreuve_id=e.id
    )
  ) order by e.ordre,e.id),'[]'::jsonb) into v_epreuves
    from public.epreuves e where e.competition_id=p_competition_id;
  -- Aucune jointure vers resultats et aucun filtre de publication.
  -- Aucune identité d'un autre participant n'est retournée.
  return jsonb_build_object('epreuves',v_epreuves,'affectations_disponibles',false);
end $$;
revoke all on function public.programme_competition_athlete(uuid) from public,anon;
grant execute on function public.programme_competition_athlete(uuid) to authenticated;

alter table public.epreuves enable row level security;
alter table public.manches enable row level security;

-- Restrictions additionnelles : aucune policy ne crée de droits d'écriture.
-- Les policies du coach existantes restent nécessaires et ne sont pas élargies.
-- TO public applique aussi la restriction aux anciens droits anonymes :
-- les helpers ne retournent que false sans identité authentifiée.
drop policy if exists "Programme lecture epreuves" on public.epreuves;
create policy "Programme lecture epreuves" on public.epreuves as restrictive
  for select to public using(public.programme_competition_visible(competition_id));
drop policy if exists "Programme lecture manches" on public.manches;
create policy "Programme lecture manches" on public.manches as restrictive
  for select to public using(public.programme_epreuve_visible(epreuve_id));

drop policy if exists "Programme insertion epreuves" on public.epreuves;
create policy "Programme insertion epreuves" on public.epreuves as restrictive
  for insert to public with check(public.programme_competition_modifiable(competition_id));
drop policy if exists "Programme modification epreuves" on public.epreuves;
create policy "Programme modification epreuves" on public.epreuves as restrictive
  for update to public using(public.programme_competition_modifiable(competition_id))
  with check(public.programme_competition_modifiable(competition_id));
drop policy if exists "Programme suppression epreuves" on public.epreuves;
create policy "Programme suppression epreuves" on public.epreuves as restrictive
  for delete to public using(public.programme_competition_modifiable(competition_id));

drop policy if exists "Programme insertion manches" on public.manches;
create policy "Programme insertion manches" on public.manches as restrictive
  for insert to public with check(public.programme_epreuve_modifiable(epreuve_id));
drop policy if exists "Programme modification manches" on public.manches;
create policy "Programme modification manches" on public.manches as restrictive
  for update to public using(public.programme_epreuve_modifiable(epreuve_id))
  with check(public.programme_epreuve_modifiable(epreuve_id));
drop policy if exists "Programme suppression manches" on public.manches;
create policy "Programme suppression manches" on public.manches as restrictive
  for delete to public using(public.programme_epreuve_modifiable(epreuve_id));
commit;
