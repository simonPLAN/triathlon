-- Remplace l'identité civile par un pseudo public tout en conservant l'e-mail Auth.
-- À exécuter après 202611050001_creation_competition_rls.sql.
begin;

alter table public.profils add column if not exists pseudo text;

-- Ne pas transformer les anciens nom/prénom en pseudo : cela conserverait une donnée
-- personnelle sans consentement explicite. Un identifiant neutre est attribué.
update public.profils
set pseudo = case
  when est_archive then 'compte_archive'
  else 'athlete_' || substr(replace(id::text, '-', ''), 1, 20)
end
where pseudo is null or btrim(pseudo) = '';

alter table public.profils alter column pseudo set not null;
alter table public.profils drop constraint if exists profils_pseudo_format_check;
alter table public.profils add constraint profils_pseudo_format_check
  check (pseudo ~ '^[A-Za-z0-9_.-]{3,30}$');

create unique index if not exists profils_pseudo_unique_ci
  on public.profils (lower(pseudo))
  where not est_archive;

-- Les valeurs civiles historiques sont supprimées. Ces colonnes restent uniquement
-- pour les anciennes fonctions SQL déjà déployées et contiennent le pseudo, jamais
-- un prénom ou un nom réel.
alter table public.profils alter column prenom drop not null;
alter table public.profils alter column nom drop not null;
alter table public.profils
  drop constraint if exists profils_nom_non_vide,
  drop constraint if exists profils_prenom_non_vide,
  drop constraint if exists profils_nom_check,
  drop constraint if exists profils_prenom_check;
update public.profils set prenom = pseudo, nom = '';

create or replace function public.initialiser_compte_profil()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_pseudo text;
begin
  if not new.est_invite and not new.est_archive then
    new.compte_id := new.id;
  end if;
  v_pseudo := nullif(btrim(new.pseudo), '');
  if v_pseudo is null and not new.est_invite then
    select nullif(btrim(u.raw_user_meta_data ->> 'pseudo'), '')
      into v_pseudo from auth.users u where u.id = new.id;
  end if;
  new.pseudo := coalesce(
    v_pseudo,
    case when new.est_archive then 'compte_archive'
      else 'athlete_' || substr(replace(new.id::text, '-', ''), 1, 20) end
  );
  if new.pseudo !~ '^[A-Za-z0-9_.-]{3,30}$' then
    raise exception 'Le pseudo doit contenir 3 à 30 caractères valides.'
      using errcode = '22023';
  end if;
  -- Compatibilité avec les fonctions historiques ; aucune identité civile.
  new.prenom := new.pseudo;
  new.nom := '';
  return new;
end $$;

drop function if exists public.inscrire_invite(uuid, text, text, integer);
create or replace function public.inscrire_invite(
  p_competition_id uuid,
  p_pseudo text,
  p_numero_dossard integer default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_athlete_id uuid := gen_random_uuid();
  v_inscription public.inscriptions;
  v_pseudo text := btrim(p_pseudo);
begin
  if auth.uid() is null or not exists (
    select 1 from public.profils where id = auth.uid()
      and role = 'coach' and not est_invite and not est_archive
  ) then
    raise exception 'Seul un coach peut inscrire un invité.' using errcode='42501';
  end if;
  perform 1 from public.competitions
    where id = p_competition_id and coach_id = auth.uid()
      and statut in ('brouillon', 'ouverte') for update;
  if not found then
    raise exception 'Compétition inaccessible ou inscriptions fermées.'
      using errcode='42501';
  end if;
  if v_pseudo is null or v_pseudo !~ '^[A-Za-z0-9_.-]{3,30}$' then
    raise exception 'Le pseudo doit contenir 3 à 30 caractères valides.'
      using errcode='22023';
  end if;
  if exists(select 1 from public.profils where lower(pseudo)=lower(v_pseudo)) then
    raise exception 'Ce pseudo est déjà utilisé.' using errcode='23505';
  end if;
  if p_numero_dossard is not null and p_numero_dossard <= 0 then
    raise exception 'Le dossard doit être supérieur à zéro.' using errcode='22023';
  end if;
  insert into public.profils (id, pseudo, prenom, nom, role, est_invite)
    values (v_athlete_id, v_pseudo, v_pseudo, '', 'athlete', true);
  insert into public.inscriptions (competition_id, athlete_id, numero_dossard)
    values (p_competition_id, v_athlete_id, p_numero_dossard)
    returning * into v_inscription;
  return to_jsonb(v_inscription);
end $$;
revoke all on function public.inscrire_invite(uuid,text,integer) from public,anon;
grant execute on function public.inscrire_invite(uuid,text,integer) to authenticated;

create or replace function public.annuaire_athletes_coach()
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_resultat jsonb;
begin
  if not public.securite_identite_valide('coach') then
    raise exception 'Cet annuaire est réservé aux coachs.' using errcode='42501';
  end if;
  select coalesce(jsonb_agg(
    jsonb_build_object('id',p.id,'pseudo',p.pseudo)
    order by lower(p.pseudo),p.id
  ),'[]'::jsonb) into v_resultat
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

commit;
