-- Supprime les doublons de trigger Auth qui appellent la même fonction.
-- À appliquer après 202611050003_creation_compte_pseudo.sql.
begin;

do $$
declare
  v_trigger record;
begin
  for v_trigger in
    select t.tgname
    from pg_catalog.pg_trigger t
    where t.tgrelid = 'auth.users'::regclass
      and not t.tgisinternal
      and t.tgfoid = 'public.handle_new_user()'::regprocedure
      and t.tgname <> 'on_auth_user_created'
  loop
    execute format(
      'drop trigger if exists %I on auth.users',
      v_trigger.tgname
    );
  end loop;
end;
$$;

-- Garantit qu'il ne reste qu'un seul trigger utilisant handle_new_user.
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
    and t.tgfoid = 'public.handle_new_user()'::regprocedure;

  if v_nombre <> 1 then
    raise exception 'Nombre inattendu de triggers handle_new_user : %', v_nombre;
  end if;
end;
$$;

commit;
