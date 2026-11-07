begin;

create or replace function public.verifier_configuration_competition(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null or not exists (
    select 1 from public.profils where id = auth.uid() and role = 'coach'
  ) then raise exception 'Seul un coach peut configurer une compétition.'; end if;
  perform 1 from public.competitions
    where id = p_id and coach_id = auth.uid() and statut = 'brouillon' for update;
  if not found then
    raise exception 'La compétition doit être en brouillon et appartenir au coach connecté.';
  end if;
end $$;
revoke all on function public.verifier_configuration_competition(uuid) from public, anon, authenticated;

create or replace function public.verifier_epreuve_sans_depart(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.manches where epreuve_id = p_id for update;
  if exists (
    select 1 from public.manches m where m.epreuve_id = p_id
    and (m.statut <> 'a_venir' or m.heure_depart is not null
      or m.heure_premiere_arrivee is not null or m.resultats_publies
      or exists (select 1 from public.resultats r where r.manche_id = m.id))
  ) then
    raise exception 'Cette épreuve possède des manches démarrées ou des résultats : modification interdite.';
  end if;
end $$;
revoke all on function public.verifier_epreuve_sans_depart(uuid) from public, anon, authenticated;

create or replace function public.enregistrer_epreuve_configuree(
  p_id uuid, p_competition_id uuid, p_nom text, p_discipline text,
  p_distance_metres integer, p_nombre_manches integer,
  p_ordre integer, p_duree_limite_secondes integer
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare v_epreuve public.epreuves;
begin
  perform public.verifier_configuration_competition(p_competition_id);
  if p_nom is null or length(btrim(p_nom)) not between 3 and 100
    or p_discipline is null or p_discipline not in ('natation', 'velo', 'course_a_pied')
    or p_distance_metres is null or p_distance_metres <= 0
    or p_nombre_manches is null or p_nombre_manches not between 1 and 1000
    or p_ordre is null or p_ordre <= 0
    or p_duree_limite_secondes is null or p_duree_limite_secondes <= 0 then
    raise exception 'Les informations de l’épreuve sont invalides.';
  end if;
  if p_id is null then
    -- jsonb_populate_record prend en charge discipline même si la colonne est un enum.
    insert into public.epreuves (
      competition_id, nom, discipline, distance_metres, nombre_manches, ordre, duree_limite_secondes
    ) select p_competition_id, btrim(p_nom), x.discipline,
      p_distance_metres, p_nombre_manches, p_ordre, p_duree_limite_secondes
      from jsonb_populate_record(null::public.epreuves,
        jsonb_build_object('discipline', p_discipline)) x
      returning * into v_epreuve;
  else
    perform 1 from public.epreuves where id = p_id
      and competition_id = p_competition_id for update;
    if not found then raise exception 'Épreuve introuvable.'; end if;
    perform public.verifier_epreuve_sans_depart(p_id);
    update public.epreuves e set
      nom = btrim(p_nom),
      discipline = x.discipline,
      distance_metres = p_distance_metres, nombre_manches = p_nombre_manches,
      ordre = p_ordre, duree_limite_secondes = p_duree_limite_secondes,
      date_modification = now()
    from jsonb_populate_record(null::public.epreuves,
      jsonb_build_object('discipline', p_discipline)) x
    where e.id = p_id returning e.* into v_epreuve;
    -- Aucun résultat ne peut être perdu : le contrôle précédent refuse toute manche avec résultat.
    delete from public.manches where epreuve_id = p_id and numero > p_nombre_manches;
  end if;
  insert into public.manches (epreuve_id, numero, statut, resultats_publies)
    select v_epreuve.id, n, 'a_venir', false
    from generate_series(1, p_nombre_manches) n
    where not exists (
      select 1 from public.manches m where m.epreuve_id = v_epreuve.id and m.numero = n
    );
  return to_jsonb(v_epreuve);
end $$;

create or replace function public.supprimer_epreuve_configuree(p_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare v_competition uuid;
begin
  select competition_id into v_competition from public.epreuves where id = p_id;
  if not found then raise exception 'Épreuve introuvable.'; end if;
  perform public.verifier_configuration_competition(v_competition);
  perform 1 from public.epreuves where id = p_id for update;
  if not found then raise exception 'Épreuve introuvable.'; end if;
  perform public.verifier_epreuve_sans_depart(p_id);
  delete from public.manches where epreuve_id = p_id;
  delete from public.epreuves where id = p_id;
end $$;

create or replace function public.reordonner_epreuves_configurees(
  p_competition_id uuid, p_ids uuid[]
) returns void language plpgsql security definer set search_path = '' as $$
declare v_id uuid; v_max bigint; v_index integer := 0; v_nombre integer;
begin
  perform public.verifier_configuration_competition(p_competition_id);
  select count(*), coalesce(max(ordre), 0) into v_nombre, v_max
    from public.epreuves where competition_id = p_competition_id;
  if p_ids is null or cardinality(p_ids) <> v_nombre
    or (select count(distinct requested.id) from unnest(p_ids) as requested(id)) <> v_nombre
    or exists (
      select 1 from unnest(p_ids) as requested(id) where not exists (
        select 1 from public.epreuves e where e.id = requested.id and e.competition_id = p_competition_id
      )
    ) then raise exception 'La liste doit contenir toutes les épreuves exactement une fois.'; end if;
  if v_max + v_nombre > 2147483647 then
    raise exception 'Les numéros d’ordre sont trop élevés pour être réorganisés.';
  end if;
  foreach v_id in array p_ids loop
    perform public.verifier_epreuve_sans_depart(v_id);
  end loop;
  -- Deux passages évitent les collisions avec unique(competition_id, ordre).
  foreach v_id in array p_ids loop
    v_index := v_index + 1;
    update public.epreuves set ordre = (v_max + v_index)::integer,
      date_modification = now() where id = v_id;
  end loop;
  v_index := 0;
  foreach v_id in array p_ids loop
    v_index := v_index + 1;
    update public.epreuves set ordre = v_index where id = v_id;
  end loop;
end $$;

revoke all on function public.enregistrer_epreuve_configuree(uuid,uuid,text,text,integer,integer,integer,integer) from public, anon;
grant execute on function public.enregistrer_epreuve_configuree(uuid,uuid,text,text,integer,integer,integer,integer) to authenticated;
revoke all on function public.supprimer_epreuve_configuree(uuid) from public, anon;
grant execute on function public.supprimer_epreuve_configuree(uuid) to authenticated;
revoke all on function public.reordonner_epreuves_configurees(uuid,uuid[]) from public, anon;
grant execute on function public.reordonner_epreuves_configurees(uuid,uuid[]) to authenticated;

-- Restrictions additionnelles aux policies existantes, sans élargir les droits.
create or replace function public.competition_configurable_par_coach(p_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.competitions c join public.profils p on p.id = c.coach_id
    where c.id = p_id and c.coach_id = auth.uid()
      and c.statut = 'brouillon' and p.role = 'coach'
  );
$$;
revoke all on function public.competition_configurable_par_coach(uuid) from public, anon;
grant execute on function public.competition_configurable_par_coach(uuid) to authenticated;
drop policy if exists "Configuration epreuves insertion" on public.epreuves;
create policy "Configuration epreuves insertion" on public.epreuves as restrictive
  for insert to authenticated with check (public.competition_configurable_par_coach(competition_id));
drop policy if exists "Configuration epreuves modification" on public.epreuves;
create policy "Configuration epreuves modification" on public.epreuves as restrictive
  for update to authenticated using (public.competition_configurable_par_coach(competition_id))
  with check (public.competition_configurable_par_coach(competition_id));
drop policy if exists "Configuration epreuves suppression" on public.epreuves;
create policy "Configuration epreuves suppression" on public.epreuves as restrictive
  for delete to authenticated using (public.competition_configurable_par_coach(competition_id));
commit;
