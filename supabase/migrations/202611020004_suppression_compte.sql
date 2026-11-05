-- Prérequis : migrations invités, suivi athlète et gestion des épreuves.
-- Aucun effacement lors de l'application de la migration.
begin;
alter table public.profils add column if not exists est_archive boolean not null default false;
alter table public.profils drop constraint if exists profils_identite_check;
alter table public.profils add constraint profils_identite_check check (
  (est_archive and not est_invite and compte_id is null and role = 'coach'
    and id = '00000000-0000-4000-8000-000000000001'::uuid)
  or (not est_archive and (
    (est_invite and compte_id is null and role = 'athlete')
    or (not est_invite and compte_id is not null and compte_id = id)
  ))
);
-- Plus de cascade aveugle Auth -> profils : le trigger ci-dessous prépare les relations.
alter table public.profils drop constraint if exists profils_compte_id_fkey;
alter table public.profils add constraint profils_compte_id_fkey
  foreign key (compte_id) references auth.users(id) on delete restrict;

create or replace function public.initialiser_compte_profil()
returns trigger language plpgsql set search_path = '' as $$
begin
  if not new.est_invite and not new.est_archive then new.compte_id := new.id; end if;
  return new;
end $$;

-- Compte technique partagé sans adresse e-mail, sans compte Auth ni connexion.
insert into public.profils (id, prenom, nom, role, compte_id, est_invite, est_archive)
values ('00000000-0000-4000-8000-000000000001', 'Responsable', 'supprimé', 'coach', null, false, true)
on conflict (id) do nothing;
do $$ begin
  if not exists (select 1 from public.profils
    where id = '00000000-0000-4000-8000-000000000001' and est_archive
      and compte_id is null and role = 'coach') then
    raise exception 'Identifiant technique déjà utilisé : migration annulée.';
  end if;
end $$;

-- Les références non prévues bloquent la suppression, y compris une future
-- table qui cascaderait depuis une inscription ou un résultat.
create or replace function public.verifier_schema_suppression_compte()
returns void language plpgsql security definer set search_path = '' as $$
declare fk record;
begin
  for fk in
    select c.conrelid, c.confrelid,
      array(select a.attname::text from unnest(c.conkey) with ordinality k(num, ordre)
        join pg_catalog.pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.num
        order by k.ordre) as colonnes
    from pg_catalog.pg_constraint c
    join pg_catalog.pg_class t on t.oid = c.conrelid
    join pg_catalog.pg_namespace n on n.oid = t.relnamespace
    where c.contype = 'f' and n.nspname not in ('auth', 'storage')
      and c.confrelid in ('auth.users'::regclass, 'public.profils'::regclass,
        'public.inscriptions'::regclass, 'public.resultats'::regclass)
  loop
    if not (
      (fk.conrelid = 'public.profils'::regclass and fk.confrelid = 'auth.users'::regclass
        and fk.colonnes = array['compte_id'])
      or (fk.conrelid = 'public.competitions'::regclass and fk.confrelid = 'public.profils'::regclass
        and fk.colonnes = array['coach_id'])
      or (fk.conrelid = 'public.inscriptions'::regclass and fk.confrelid = 'public.profils'::regclass
        and fk.colonnes = array['athlete_id'])
      or (fk.conrelid = 'public.resultats'::regclass and fk.confrelid = 'public.profils'::regclass
        and fk.colonnes = array['athlete_id'])
    ) then
      raise exception 'Relation non prise en charge : suppression suspendue pour audit.';
    end if;
  end loop;
  if not exists (
    select 1 from pg_catalog.pg_trigger where tgrelid = 'auth.users'::regclass
      and tgname = 'preparer_suppression_compte' and tgenabled in ('O', 'A')
      and tgfoid = 'public.preparer_suppression_compte()'::regprocedure
  ) then raise exception 'Protection de suppression non installée.'; end if;
end $$;
revoke all on function public.verifier_schema_suppression_compte() from public, anon, authenticated;
grant execute on function public.verifier_schema_suppression_compte() to service_role;

-- Exécuté dans la transaction de l'API Auth admin.deleteUser.
-- Toute erreur annule AUSSI les suppressions et transferts déjà effectués.
create or replace function public.preparer_suppression_compte()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform public.verifier_schema_suppression_compte();
  -- Verrouiller les lignes parentes empêche l'ajout concurrent de références FK.
  perform 1 from public.profils where id = old.id for update;
  perform 1 from public.competitions where coach_id = old.id for update;

  update public.competitions set
    coach_id = '00000000-0000-4000-8000-000000000001',
    nom = 'Compétition archivée', description = null, lieu = null,
    statut = case when statut in ('brouillon', 'ouverte', 'en_cours')
      then 'annulee' else statut end,
    date_modification = now()
    where coach_id = old.id;

  delete from public.resultats where athlete_id = old.id;
  delete from public.inscriptions where athlete_id = old.id;
  delete from public.profils where id = old.id or compte_id = old.id;
  return old;
end $$;
revoke all on function public.preparer_suppression_compte() from public, anon, authenticated;
drop trigger if exists preparer_suppression_compte on auth.users;
create trigger preparer_suppression_compte before delete on auth.users
  for each row execute function public.preparer_suppression_compte();

-- Le profil technique ne doit jamais être réattribué à un compte client.
drop policy if exists "Profil archive immuable" on public.profils;
create policy "Profil archive immuable" on public.profils as restrictive
  for all to authenticated using (not est_archive) with check (not est_archive);

commit;
