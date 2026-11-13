-- DEM-004 : délégation nominative de la saisie des résultats par épreuve.
-- Le responsable conserve la configuration, les départs, la validation et la publication.
begin;

create table if not exists public.coachs_epreuve_autorises(
  epreuve_id uuid not null references public.epreuves(id) on delete cascade,
  coach_id uuid not null references public.profils(id) on delete cascade,
  autorise_par uuid not null references public.profils(id) on delete cascade,
  date_creation timestamptz not null default now(),
  primary key(epreuve_id,coach_id),
  check(coach_id<>autorise_par)
);
create index if not exists coachs_epreuve_autorises_coach_idx
  on public.coachs_epreuve_autorises(coach_id,epreuve_id);
alter table public.coachs_epreuve_autorises enable row level security;
revoke all on table public.coachs_epreuve_autorises from public,anon,authenticated;

create or replace function public.coach_delegue_epreuve(p_epreuve_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide('coach') and exists(
    select 1 from public.coachs_epreuve_autorises a
    where a.epreuve_id=p_epreuve_id and a.coach_id=auth.uid()
  );
$$;
create or replace function public.saisie_resultats_epreuve_autorisee(p_epreuve_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.programme_epreuve_modifiable(p_epreuve_id)
    or public.coach_delegue_epreuve(p_epreuve_id);
$$;
revoke all on function public.coach_delegue_epreuve(uuid) from public,anon;
revoke all on function public.saisie_resultats_epreuve_autorisee(uuid) from public,anon;
grant execute on function public.coach_delegue_epreuve(uuid) to authenticated;
grant execute on function public.saisie_resultats_epreuve_autorisee(uuid) to authenticated;

create or replace function public.autoriser_coach_epreuve(
  p_epreuve_id uuid,p_pseudo text
) returns void language plpgsql security definer set search_path='' as $$
declare v_coach uuid;
begin
  if not public.programme_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut gérer ces accès.' using errcode='42501';
  end if;
  select p.id into v_coach from public.profils p
    where lower(p.pseudo)=lower(btrim(p_pseudo))
      and p.role='coach' and p.compte_id=p.id
      and not p.est_invite and not p.est_archive;
  if not found then
    raise exception 'Aucun coach actif ne correspond à ce pseudo.' using errcode='P0002';
  end if;
  if v_coach=auth.uid() then
    raise exception 'Le coach responsable possède déjà tous les droits.' using errcode='22023';
  end if;
  insert into public.coachs_epreuve_autorises(epreuve_id,coach_id,autorise_par)
    values(p_epreuve_id,v_coach,auth.uid())
    on conflict(epreuve_id,coach_id) do nothing;
end $$;

create or replace function public.retirer_coach_epreuve(
  p_epreuve_id uuid,p_coach_id uuid
) returns void language plpgsql security definer set search_path='' as $$
begin
  if not public.programme_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut gérer ces accès.' using errcode='42501';
  end if;
  delete from public.coachs_epreuve_autorises
    where epreuve_id=p_epreuve_id and coach_id=p_coach_id;
end $$;

create or replace function public.lister_coachs_epreuve(p_epreuve_id uuid)
returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if not public.programme_epreuve_modifiable(p_epreuve_id) then
    raise exception 'Seul le coach responsable peut voir ces accès.' using errcode='42501';
  end if;
  return query select jsonb_build_object('id',p.id,'pseudo',p.pseudo)
    from public.coachs_epreuve_autorises a
    join public.profils p on p.id=a.coach_id
    where a.epreuve_id=p_epreuve_id
    order by lower(p.pseudo),p.id;
end $$;

create or replace function public.lister_epreuves_partagees()
returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if not public.securite_identite_valide('coach') then
    raise exception 'Cette liste est réservée aux coachs actifs.' using errcode='42501';
  end if;
  return query
    select jsonb_build_object(
      'epreuve',to_jsonb(e),
      'competition',to_jsonb(c)-'image_path'
    )
    from public.coachs_epreuve_autorises a
    join public.epreuves e on e.id=a.epreuve_id
    join public.competitions c on c.id=e.competition_id
    where a.coach_id=auth.uid()
    order by c.date_competition desc,c.nom,e.ordre,e.id;
end $$;

create or replace function public.lister_participants_manche_delegue(p_manche_id uuid)
returns setof jsonb language plpgsql stable security definer set search_path='' as $$
declare v_epreuve uuid;
begin
  select m.epreuve_id into v_epreuve from public.manches m where m.id=p_manche_id;
  if not found or not public.saisie_resultats_epreuve_autorisee(v_epreuve) then
    raise exception 'Tu ne peux pas consulter les participants de cette manche.' using errcode='42501';
  end if;
  return query
    select jsonb_build_object(
      'id',i.id,'competition_id',i.competition_id,'athlete_id',i.athlete_id,
      'numero_dossard',i.numero_dossard,'date_inscription',i.date_inscription,
      'pseudo',p.pseudo
    )
    from public.participants_manche pm
    join public.profils p on p.id=pm.athlete_id
    join public.epreuves e on e.id=v_epreuve
    join public.inscriptions i on i.competition_id=e.competition_id
      and i.athlete_id=pm.athlete_id
    where pm.manche_id=p_manche_id
    order by pm.ordre_depart,p.id;
end $$;

revoke all on function public.autoriser_coach_epreuve(uuid,text) from public,anon;
revoke all on function public.retirer_coach_epreuve(uuid,uuid) from public,anon;
revoke all on function public.lister_coachs_epreuve(uuid) from public,anon;
revoke all on function public.lister_epreuves_partagees() from public,anon;
revoke all on function public.lister_participants_manche_delegue(uuid) from public,anon;
grant execute on function public.autoriser_coach_epreuve(uuid,text) to authenticated;
grant execute on function public.retirer_coach_epreuve(uuid,uuid) to authenticated;
grant execute on function public.lister_coachs_epreuve(uuid) to authenticated;
grant execute on function public.lister_epreuves_partagees() to authenticated;
grant execute on function public.lister_participants_manche_delegue(uuid) to authenticated;

-- Lecture minimale nécessaire au parcours de saisie déléguée.
create or replace function public.programme_epreuve_visible(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.epreuves e where e.id=p_id
    and public.programme_competition_visible(e.competition_id))
    or public.coach_delegue_epreuve(p_id);
$$;

create or replace function public.securite_profil_visible(p_profil_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide() and (
    p_profil_id=auth.uid()
    or (
      public.securite_identite_valide('coach') and (
        exists(
          select 1 from public.inscriptions i join public.competitions c on c.id=i.competition_id
          where i.athlete_id=p_profil_id and c.coach_id=auth.uid()
        )
        or exists(
          select 1 from public.participants_manche pm
          join public.manches m on m.id=pm.manche_id
          where pm.athlete_id=p_profil_id and public.coach_delegue_epreuve(m.epreuve_id)
        )
      )
    )
  );
$$;

create or replace function public.securite_resultat_visible(p_manche_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.manches m
    join public.epreuves e on e.id=m.epreuve_id
    where m.id=p_manche_id and (
      public.securite_coach_competition(e.competition_id)
      or public.coach_delegue_epreuve(e.id)
      or (public.securite_identite_valide('athlete') and m.resultats_publies
        and m.statut='terminee' and exists(
          select 1 from public.inscriptions i
          where i.competition_id=e.competition_id and i.athlete_id=auth.uid()
        ))
    )
  );
$$;

create or replace function public.securite_resultat_modifiable(p_manche_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(
    select 1 from public.manches m
    where m.id=p_manche_id and not m.resultats_publies
      and public.saisie_resultats_epreuve_autorisee(m.epreuve_id)
  );
$$;

-- Les policies restrictives existantes doivent autoriser la lecture de l'épreuve partagée.
drop policy if exists "Programme lecture epreuves" on public.epreuves;
create policy "Programme lecture epreuves" on public.epreuves as restrictive
  for select to public using(
    public.programme_competition_visible(competition_id)
    or public.coach_delegue_epreuve(id)
  );
drop policy if exists "Production plafond select" on public.epreuves;
create policy "Production plafond select" on public.epreuves as restrictive
  for select to authenticated using(
    public.securite_identite_valide()
    and (
      public.programme_competition_visible(competition_id)
      or public.coach_delegue_epreuve(id)
    )
  );
drop policy if exists "Production acces select" on public.epreuves;
create policy "Production acces select" on public.epreuves
  for select to authenticated using(
    public.securite_identite_valide()
    and (
      public.programme_competition_visible(competition_id)
      or public.coach_delegue_epreuve(id)
    )
  );

drop policy if exists participants_manche_lecture on public.participants_manche;
create policy participants_manche_lecture on public.participants_manche
  for select to authenticated using(
    exists(select 1 from public.manches m where m.id=manche_id
      and (
        public.programme_epreuve_modifiable(m.epreuve_id)
        or public.coach_delegue_epreuve(m.epreuve_id)
        or (athlete_id=auth.uid() and public.programme_epreuve_visible(m.epreuve_id))
      ))
  );

-- Opérations de chronométrage accessibles au responsable ou au coach délégué.
create or replace function public.enregistrer_arrivee_atomique(
  p_manche_id uuid,p_athlete_id uuid,p_heure_arrivee timestamptz
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_m public.manches; v_r public.resultats; v_position integer;
  v_duree integer; v_premiere timestamptz; v_reponse jsonb;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.saisie_resultats_epreuve_autorisee(v_m.epreuve_id) then
    raise exception 'Tu ne peux pas saisir cette arrivée.' using errcode='42501';
  end if;
  if v_m.statut<>'en_cours' or v_m.heure_depart is null or v_m.resultats_publies then
    raise exception 'La manche doit être en cours.';
  end if;
  if not exists(select 1 from public.participants_manche where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Cet athlète n’est pas affecté à cette manche.';
  end if;
  if p_heure_arrivee is null or p_heure_arrivee<v_m.heure_depart
    or p_heure_arrivee>clock_timestamp()+interval '2 minutes' then
    raise exception 'Horaire d’arrivée invalide. Vérifie l’horloge de l’appareil puis actualise.';
  end if;
  if v_m.heure_fin_delai is not null and
    (p_heure_arrivee>=v_m.heure_fin_delai or clock_timestamp()>=v_m.heure_fin_delai) then
    raise exception 'Le délai est écoulé : aucune nouvelle arrivée.';
  end if;
  if exists(select 1 from public.resultats where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Un résultat existe déjà pour cet athlète.';
  end if;
  select count(*)+1 into v_position from public.resultats where manche_id=p_manche_id and statut='arrive';
  select coalesce(v_m.duree_limite_secondes,e.duree_limite_secondes)
    into v_duree from public.epreuves e where e.id=v_m.epreuve_id;
  v_premiere:=coalesce(v_m.heure_premiere_arrivee,p_heure_arrivee);
  if v_m.heure_premiere_arrivee is null then
    update public.manches set heure_premiere_arrivee=v_premiere,
      heure_fin_delai=v_premiere+make_interval(secs=>v_duree),date_modification=now()
      where id=p_manche_id;
  end if;
  insert into public.resultats(manche_id,athlete_id,position,points,heure_arrivee,
    temps_total_millisecondes,ecart_premier_millisecondes,statut)
    values(p_manche_id,p_athlete_id,v_position,greatest(6-v_position,0),p_heure_arrivee,
      round(extract(epoch from (p_heure_arrivee-v_m.heure_depart))*1000),
      round(extract(epoch from (p_heure_arrivee-v_premiere))*1000),'arrive')
    returning * into v_r;
  select to_jsonb(v_r)||jsonb_build_object('profils',
    jsonb_build_object('id',p.id,'pseudo',p.pseudo))
    into v_reponse from public.profils p where p.id=p_athlete_id;
  return v_reponse;
end $$;

create or replace function public.declarer_statut_participant(
  p_manche_id uuid,p_athlete_id uuid,p_statut text,p_motif text
) returns void language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.saisie_resultats_epreuve_autorisee(v_m.epreuve_id) then
    raise exception 'Cette manche ne peut pas être modifiée.' using errcode='42501';
  end if;
  if v_m.statut<>'en_cours' or v_m.resultats_publies then
    raise exception 'La manche doit être en cours.';
  end if;
  if p_statut is null or p_statut not in ('abandon','disqualifie')
    or length(trim(coalesce(p_motif,''))) not between 1 and 800 then
    raise exception 'Choisis un statut et indique son motif.';
  end if;
  if not exists(select 1 from public.participants_manche where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Cet athlète n’est pas affecté à cette manche.';
  end if;
  if exists(select 1 from public.resultats where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Un résultat existe déjà : utilise la correction après la fin de la manche.';
  end if;
  insert into public.resultats(manche_id,athlete_id,points,statut,commentaire)
    values(p_manche_id,p_athlete_id,0,p_statut,trim(p_motif));
end $$;

create or replace function public.cloturer_delai_manche(p_manche_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.saisie_resultats_epreuve_autorisee(v_m.epreuve_id) then
    raise exception 'Cette manche ne peut pas être clôturée.' using errcode='42501';
  end if;
  return public.cloturer_manche_interne(p_manche_id);
end $$;

-- Les corrections sont déléguées ; validation et publication restent au responsable.
create or replace function public.verifier_edition_resultats(
  p_manche_id uuid,p_revision bigint
) returns public.manches language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select m.* into v_m from public.manches m
    where m.id=p_manche_id
      and public.saisie_resultats_epreuve_autorisee(m.epreuve_id)
    for update of m;
  if not found then
    raise exception 'Tu ne peux pas modifier les résultats de cette manche.' using errcode='42501';
  end if;
  if v_m.statut<>'terminee' or v_m.heure_depart is null then
    raise exception 'Termine la manche avant de saisir ou corriger un résultat.';
  end if;
  if v_m.resultats_publies
    and not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Seul le coach responsable peut corriger un classement publié.'
      using errcode='42501';
  end if;
  if p_revision is null or v_m.revision_resultats<>p_revision then
    raise exception 'Le classement a changé. Actualise la manche.' using errcode='40001';
  end if;
  return v_m;
end $$;

create or replace function public.valider_resultats_manche(
  p_manche_id uuid,p_revision bigint
) returns void language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Seul le coach responsable peut valider le classement.' using errcode='42501';
  end if;
  if v_m.resultats_publies then raise exception 'Ce classement est déjà publié.'; end if;
  if not exists(select 1 from public.resultats where manche_id=p_manche_id) then
    raise exception 'Aucun résultat à valider.';
  end if;
  if v_m.participants_definis and exists(
    select 1 from public.participants_manche p where p.manche_id=p_manche_id
      and not exists(select 1 from public.resultats r where r.manche_id=p_manche_id and r.athlete_id=p.athlete_id)
  ) then raise exception 'Chaque participant doit posséder un résultat avant validation.'; end if;
  if exists(select 1 from(
    select position,points,temps_total_millisecondes,row_number() over(order by position,id) rang
    from public.resultats where manche_id=p_manche_id and statut='arrive'
  ) r where position is distinct from rang or points<>greatest(6-rang,0)
    or temps_total_millisecondes is null or temps_total_millisecondes not between 0 and 604800000)
  then raise exception 'Les places, temps et points doivent être corrigés avant validation.'; end if;
  update public.manches set revision_validation_resultats=p_revision,date_modification=now()
    where id=p_manche_id;
end $$;

create or replace function public.publier_resultats_manche_verifies(
  p_manche_id uuid,p_revision bigint
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Seul le coach responsable peut publier le classement.' using errcode='42501';
  end if;
  if v_m.revision_validation_resultats is distinct from p_revision then
    raise exception 'Valide le classement actuel avant publication.';
  end if;
  return public.publier_resultats_manche_base(p_manche_id,p_revision);
end $$;

revoke all on function public.enregistrer_arrivee_atomique(uuid,uuid,timestamptz) from public,anon;
revoke all on function public.declarer_statut_participant(uuid,uuid,text,text) from public,anon;
revoke all on function public.cloturer_delai_manche(uuid) from public,anon;
revoke all on function public.verifier_edition_resultats(uuid,bigint) from public,anon,authenticated;
revoke all on function public.valider_resultats_manche(uuid,bigint) from public,anon;
revoke all on function public.publier_resultats_manche_verifies(uuid,bigint) from public,anon;
grant execute on function public.enregistrer_arrivee_atomique(uuid,uuid,timestamptz) to authenticated;
grant execute on function public.declarer_statut_participant(uuid,uuid,text,text) to authenticated;
grant execute on function public.cloturer_delai_manche(uuid) to authenticated;
grant execute on function public.valider_resultats_manche(uuid,bigint) to authenticated;
grant execute on function public.publier_resultats_manche_verifies(uuid,bigint) to authenticated;

commit;
