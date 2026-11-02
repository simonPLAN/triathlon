-- À appliquer dans Supabase avant d'utiliser l'inscription des invités.
-- Réexécutable : les objets propres à cette migration sont recréés en transaction.
begin;

alter table public.profils add column if not exists compte_id uuid;
alter table public.profils add column if not exists est_invite boolean not null default false;
update public.profils set compte_id = id where not est_invite and compte_id is null;

-- Le compte reste soumis à une clé étrangère ; seul le profil invité
-- peut ne pas posséder de compte.
do $$
declare fk record;
begin
  for fk in
    select conname from pg_constraint
    where conrelid = 'public.profils'::regclass
      and confrelid = 'auth.users'::regclass and contype = 'f'
  loop
    execute format('alter table public.profils drop constraint %I', fk.conname);
  end loop;
end $$;

-- La clé étrangère a été retirée par le bloc précédent.
-- Recréer également la contrainte de cohérence si la migration a déjà été lancée.
alter table public.profils drop constraint if exists profils_identite_check;

alter table public.profils
  add constraint profils_compte_id_fkey foreign key (compte_id)
  references auth.users(id) on delete cascade,
  add constraint profils_identite_check check (
    (est_invite and compte_id is null and role = 'athlete')
    or (not est_invite and compte_id is not null and compte_id = id)
  );

-- Les créations de comptes existantes continuent à alimenter compte_id.
create or replace function public.initialiser_compte_profil()
returns trigger language plpgsql set search_path = '' as $$
begin
  if not new.est_invite then new.compte_id := new.id; end if;
  return new;
end $$;
drop trigger if exists initialiser_compte_profil on public.profils;
create trigger initialiser_compte_profil
before insert on public.profils
for each row execute function public.initialiser_compte_profil();

create or replace function public.inscrire_invite(
  p_competition_id uuid,
  p_prenom text,
  p_nom text,
  p_numero_dossard integer default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_athlete_id uuid := gen_random_uuid();
  v_inscription public.inscriptions;
begin
  if auth.uid() is null or not exists (
    select 1 from public.profils where id = auth.uid()
      and role = 'coach' and not est_invite
  ) then
    raise exception 'Seul un coach peut inscrire un invité.';
  end if;
  perform 1 from public.competitions
    where id = p_competition_id and coach_id = auth.uid()
      and statut in ('brouillon', 'ouverte') for update;
  if not found then
    raise exception 'Compétition inaccessible ou inscriptions fermées.';
  end if;
  if p_prenom is null or p_nom is null
    or length(btrim(p_prenom)) not between 1 and 100
    or length(btrim(p_nom)) not between 1 and 100 then
    raise exception 'Le prénom et le nom sont obligatoires (100 caractères maximum).';
  end if;
  if p_numero_dossard is not null and p_numero_dossard <= 0 then
    raise exception 'Le dossard doit être supérieur à zéro.';
  end if;
  insert into public.profils (id, prenom, nom, role, est_invite)
    values (v_athlete_id, btrim(p_prenom), btrim(p_nom), 'athlete', true);
  insert into public.inscriptions (competition_id, athlete_id, numero_dossard)
    values (p_competition_id, v_athlete_id, p_numero_dossard)
    returning * into v_inscription;
  return to_jsonb(v_inscription);
end $$;

revoke all on function public.inscrire_invite(uuid, text, text, integer) from public, anon;
grant execute on function public.inscrire_invite(uuid, text, text, integer) to authenticated;

-- Fonction isolée pour éviter une récursion entre les policies profils/inscriptions.
create or replace function public.coach_peut_lire_invite(p_profil_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.inscriptions i
    join public.competitions c on c.id = i.competition_id
    where i.athlete_id = p_profil_id and c.coach_id = auth.uid()
  );
$$;
revoke all on function public.coach_peut_lire_invite(uuid) from public, anon;
grant execute on function public.coach_peut_lire_invite(uuid) to authenticated;

drop policy if exists "Coach lit les invites inscrits" on public.profils;
create policy "Coach lit les invites inscrits"
on public.profils for select to authenticated
using (est_invite and public.coach_peut_lire_invite(id));

commit;
