-- Nettoyage définitif des anciens triggers de création de profil.
-- À appliquer après 202611050005_suppression_contraintes_identite.sql.
begin;

-- Supprime seulement les triggers utilisateur exécutés après l'insertion Auth.
-- Le trigger BEFORE DELETE preparer_suppression_compte n'est pas concerné.
do $$
declare v_trigger record;
begin
  for v_trigger in
    select t.tgname
    from pg_catalog.pg_trigger t
    where t.tgrelid = 'auth.users'::regclass
      and not t.tgisinternal
      and pg_get_triggerdef(t.oid) ilike '%AFTER INSERT%'
      and t.tgname <> 'on_auth_user_created'
  loop
    execute format('drop trigger if exists %I on auth.users', v_trigger.tgname);
  end loop;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_pseudo text := nullif(btrim(new.raw_user_meta_data ->> 'pseudo'), '');
begin
  if v_pseudo is null or v_pseudo !~ '^[A-Za-z0-9_.-]{3,30}$' then
    raise exception 'Le pseudo doit contenir 3 à 30 caractères valides.'
      using errcode = '22023';
  end if;

  if exists (
    select 1 from public.profils p
    where lower(p.pseudo) = lower(v_pseudo) and not p.est_archive
  ) then
    raise exception 'Ce pseudo est déjà utilisé.' using errcode = '23505';
  end if;

  insert into public.profils (
    id, pseudo, prenom, nom, role, compte_id, est_invite, est_archive
  ) values (
    new.id, v_pseudo, v_pseudo, '', 'athlete', new.id, false, false
  );

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

do $$
declare v_nombre integer;
begin
  select count(*) into v_nombre
  from pg_catalog.pg_trigger t
  where t.tgrelid = 'auth.users'::regclass
    and not t.tgisinternal
    and pg_get_triggerdef(t.oid) ilike '%AFTER INSERT%';

  if v_nombre <> 1 then
    raise exception 'Il reste % triggers AFTER INSERT sur auth.users.', v_nombre;
  end if;
end;
$$;

commit;
