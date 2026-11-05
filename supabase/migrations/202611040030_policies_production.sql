-- Pré-requis : schéma initial réel + migrations 001 à 006 et migrations sportives.
-- Aucun déploiement automatique. Exporter les policies et tester sur staging.
begin;

create or replace function public.securite_identite_valide(p_role text default null)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.profils p
    where p.id=auth.uid() and p.compte_id=p.id and not p.est_invite and not p.est_archive
      and (p_role is null or p.role::text=p_role));
$$;

create or replace function public.securite_coach_competition(p_competition_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide('coach') and exists(
    select 1 from public.competitions c where c.id=p_competition_id and c.coach_id=auth.uid());
$$;

create or replace function public.securite_inscription_ouverte(p_competition_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.competitions c where c.id=p_competition_id and c.statut='ouverte');
$$;

create or replace function public.securite_coach_inscriptions(p_competition_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_coach_competition(p_competition_id) and exists(
    select 1 from public.competitions c where c.id=p_competition_id and c.statut in ('brouillon','ouverte'));
$$;

create or replace function public.securite_profil_visible(p_profil_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select public.securite_identite_valide() and (
    p_profil_id=auth.uid() or (
      public.securite_identite_valide('coach') and exists(
        select 1 from public.inscriptions i join public.competitions c on c.id=i.competition_id
        where i.athlete_id=p_profil_id and c.coach_id=auth.uid()
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
      or (public.securite_identite_valide('athlete') and m.resultats_publies
        and m.statut='terminee' and exists(
          select 1 from public.inscriptions i where i.competition_id=e.competition_id and i.athlete_id=auth.uid()
        ))
    )
  );
$$;

create or replace function public.securite_resultat_modifiable(p_manche_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.manches m join public.epreuves e on e.id=m.epreuve_id
    where m.id=p_manche_id and not m.resultats_publies
      and public.securite_coach_competition(e.competition_id));
$$;

-- Protection des champs d'identité y compris si une ancienne RPC exécutée
-- par un JWT client tente une mise à jour privilégiée.
create or replace function public.securiser_identite_profil()
returns trigger language plpgsql set search_path='' as $$
declare v_role_jwt text;
begin
  v_role_jwt := coalesce(nullif(current_setting('request.jwt.claim.role',true),''),
    nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role','');
  if tg_op='INSERT' then
    -- Aucun rôle issu des métadonnées d'inscription n'accorde le rôle coach.
    -- L'attribution contrôlée se fait APRES création par l'administration.
    if not new.est_invite and not new.est_archive then
      new.role := 'athlete';
      new.compte_id := new.id;
    end if;
    return new;
  end if;
  if current_user in ('authenticated','anon') or v_role_jwt in ('authenticated','anon') then
    if (new.id,new.role,new.compte_id,new.est_invite,new.est_archive)
      is distinct from (old.id,old.role,old.compte_id,old.est_invite,old.est_archive) then
      raise exception 'Les champs d’identité et le rôle sont gérés uniquement par le serveur.' using errcode='42501';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists zz_securiser_identite_profil on public.profils;
create trigger zz_securiser_identite_profil before insert or update on public.profils
  for each row execute function public.securiser_identite_profil();
revoke all on function public.securiser_identite_profil() from public,anon,authenticated;

create or replace function public.attribuer_role_coach(p_profil_id uuid)
returns void language plpgsql security definer set search_path='' as $$
begin
  if not exists(select 1 from public.profils p
    where p.id=p_profil_id and p.compte_id=p.id and not p.est_invite and not p.est_archive) then
    raise exception 'Ce profil ne possède pas de compte utilisateur actif.';
  end if;
  update public.profils set role='coach' where id=p_profil_id;
end $$;
revoke all on function public.attribuer_role_coach(uuid) from public,anon,authenticated;
grant execute on function public.attribuer_role_coach(uuid) to service_role;

-- Seuls les noms des comptes athlètes sont dans l'annuaire destiné aux coachs.
-- Les invités d'autres compétitions et les autres champs de profils n'y figurent pas.
create or replace function public.annuaire_athletes_coach()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_resultat jsonb;
begin
  if not public.securite_identite_valide('coach') then
    raise exception 'Cet annuaire est réservé aux coachs.' using errcode='42501';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'prenom',p.prenom,'nom',p.nom)
    order by p.nom,p.prenom,p.id),'[]'::jsonb) into v_resultat
  from public.profils p where p.role='athlete' and not p.est_archive
    and ((not p.est_invite and p.compte_id=p.id) or (
      p.est_invite and exists(select 1 from public.inscriptions i
        join public.competitions c on c.id=i.competition_id
        where i.athlete_id=p.id and c.coach_id=auth.uid())
    ));
  return v_resultat;
end $$;
revoke all on function public.annuaire_athletes_coach() from public,anon;
grant execute on function public.annuaire_athletes_coach() to authenticated;

-- Verrouille les parents : impossible de déplacer une inscription/résultat vers
-- une autre compétition/manche en contournant les contrôles du client.
create or replace function public.securiser_parents_sportifs()
returns trigger language plpgsql set search_path='' as $$
begin
  if tg_table_name='inscriptions' then
    if (new.id,new.competition_id,new.athlete_id) is distinct from (old.id,old.competition_id,old.athlete_id) then
      raise exception 'Une inscription ne peut pas changer d’identité ni de compétition.' using errcode='42501';
    end if;
  elsif tg_table_name='resultats' then
    if (new.id,new.manche_id,new.athlete_id) is distinct from (old.id,old.manche_id,old.athlete_id) then
      raise exception 'Un résultat ne peut pas changer d’identité, de manche ni d’athlète.' using errcode='42501';
    end if;
  end if;
  return new;
end $$;
drop trigger if exists securiser_parent_inscription on public.inscriptions;
create trigger securiser_parent_inscription before update on public.inscriptions
  for each row execute function public.securiser_parents_sportifs();
drop trigger if exists securiser_parent_resultat on public.resultats;
create trigger securiser_parent_resultat before update on public.resultats
  for each row execute function public.securiser_parents_sportifs();
revoke all on function public.securiser_parents_sportifs() from public,anon,authenticated;

-- Les helpers ne sont pas publics ; aucune donnée n'est accessible sans identité.
revoke all on function public.securite_identite_valide(text) from public,anon;
revoke all on function public.securite_coach_competition(uuid) from public,anon;
revoke all on function public.securite_inscription_ouverte(uuid) from public,anon;
revoke all on function public.securite_coach_inscriptions(uuid) from public,anon;
revoke all on function public.securite_profil_visible(uuid) from public,anon;
revoke all on function public.securite_resultat_visible(uuid) from public,anon;
revoke all on function public.securite_resultat_modifiable(uuid) from public,anon;
grant execute on function public.securite_identite_valide(text) to authenticated;
grant execute on function public.securite_coach_competition(uuid) to authenticated;
grant execute on function public.securite_inscription_ouverte(uuid) to authenticated;
grant execute on function public.securite_coach_inscriptions(uuid) to authenticated;
grant execute on function public.securite_profil_visible(uuid) to authenticated;
grant execute on function public.securite_resultat_visible(uuid) to authenticated;
grant execute on function public.securite_resultat_modifiable(uuid) to authenticated;

-- Révoquer les anciens grants anonymes, activer RLS et ajouter à chaque commande
-- un plafond RESTRICTIVE. Une ancienne policy permissive trop large ne le contourne pas.
-- Une policy permissive correspondante rend ces droits indépendants de l'ancien schéma.
do $$
declare v_table text; v_operation text; v_expression text; v_nom text;
begin
  foreach v_table in array array['profils','competitions','inscriptions','epreuves','manches','resultats'] loop
    execute format('alter table public.%I enable row level security',v_table);
    execute format('revoke all on table public.%I from public,anon',v_table);
    execute format('grant select,insert,update,delete on table public.%I to authenticated',v_table);
    foreach v_operation in array array['select','insert','update','delete'] loop
      v_expression := case v_table
        when 'profils' then case v_operation
          when 'select' then 'public.securite_profil_visible(id)'
          when 'insert' then 'public.securite_identite_valide() and id=auth.uid() and compte_id=id and not est_invite and not est_archive and role=''athlete'''
          when 'update' then 'public.securite_identite_valide() and id=auth.uid() and not est_invite and not est_archive'
          else 'false' end
        when 'competitions' then case v_operation
          when 'select' then 'public.securite_identite_valide() and public.programme_competition_visible(id)'
          when 'insert' then 'public.securite_identite_valide(''coach'') and coach_id=auth.uid() and statut=''brouillon'''
          when 'delete' then 'public.securite_coach_competition(id) and statut=''brouillon'''
          else 'public.securite_coach_competition(id) and coach_id=auth.uid()' end
        when 'inscriptions' then case v_operation
          when 'select' then '(public.securite_identite_valide(''athlete'') and athlete_id=auth.uid()) or public.securite_coach_competition(competition_id)'
          when 'insert' then '(public.securite_identite_valide(''athlete'') and athlete_id=auth.uid() and numero_dossard is null and public.securite_inscription_ouverte(competition_id)) or public.securite_coach_inscriptions(competition_id)'
          when 'delete' then '(public.securite_identite_valide(''athlete'') and athlete_id=auth.uid() and public.securite_inscription_ouverte(competition_id)) or public.securite_coach_inscriptions(competition_id)'
          else 'public.securite_coach_competition(competition_id)' end
        when 'epreuves' then case v_operation
          when 'select' then 'public.securite_identite_valide() and public.programme_competition_visible(competition_id)'
          else 'public.securite_identite_valide(''coach'') and public.programme_competition_modifiable(competition_id)' end
        when 'manches' then case v_operation
          when 'select' then 'public.securite_identite_valide() and public.programme_epreuve_visible(epreuve_id)'
          else 'public.securite_identite_valide(''coach'') and public.programme_epreuve_modifiable(epreuve_id)' end
        when 'resultats' then case v_operation
          when 'select' then 'public.securite_resultat_visible(manche_id)'
          else 'public.securite_resultat_modifiable(manche_id)' end
      end;
      foreach v_nom in array array['Production plafond '||v_operation,'Production acces '||v_operation] loop
        execute format('drop policy if exists %I on public.%I',v_nom,v_table);
        execute format('create policy %I on public.%I as %s for %s to authenticated %s',
          v_nom,v_table,
          case when v_nom like 'Production plafond %' then 'restrictive' else 'permissive' end,
          v_operation,
          case when v_operation='insert' then format('with check (%s)',v_expression)
               when v_operation='update' then format('using (%s) with check (%s)',v_expression,v_expression)
               else format('using (%s)',v_expression) end);
      end loop;
    end loop;
  end loop;
end $$;

commit;
