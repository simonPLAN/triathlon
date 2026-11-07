-- Lecture seule : seules les inscriptions de auth.uid() sont consultables.
begin;
create or replace function public.mes_competitions_inscrites()
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(to_jsonb(c) order by c.date_competition desc), '[]'::jsonb)
  from public.competitions c
  where auth.uid() is not null and exists (
    select 1 from public.inscriptions i
    where i.competition_id = c.id and i.athlete_id = auth.uid()
  );
$$;
revoke all on function public.mes_competitions_inscrites() from public, anon;
grant execute on function public.mes_competitions_inscrites() to authenticated;

create or replace function public.resultats_publies_athlete(p_competition_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_resultats jsonb;
begin
  if auth.uid() is null or not exists (
    select 1 from public.inscriptions i
    where i.competition_id = p_competition_id and i.athlete_id = auth.uid()
  ) then
    raise exception 'Tu dois être inscrit à cette compétition pour consulter ses résultats.';
  end if;
  select coalesce(jsonb_agg(to_jsonb(ligne) order by ligne.ordre_epreuve,
    ligne.numero_manche, ligne.position nulls last, ligne.nom_athlete), '[]'::jsonb)
    into v_resultats
  from (
    select r.athlete_id, p.prenom || ' ' || p.nom as nom_athlete,
      e.id as epreuve_id, e.nom as nom_epreuve, e.ordre as ordre_epreuve,
      m.id as manche_id, m.numero as numero_manche,
      r.position, r.points, r.statut, r.temps_total_millisecondes
    from public.resultats r
    join public.manches m on m.id = r.manche_id
    join public.epreuves e on e.id = m.epreuve_id
    join public.profils p on p.id = r.athlete_id
    where e.competition_id = p_competition_id
      and m.resultats_publies = true and m.statut = 'terminee'
  ) ligne;
  return v_resultats;
end $$;
revoke all on function public.resultats_publies_athlete(uuid) from public, anon;
grant execute on function public.resultats_publies_athlete(uuid) to authenticated;
commit;
