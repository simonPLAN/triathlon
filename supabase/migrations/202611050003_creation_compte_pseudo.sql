-- Correctif de création Auth après le passage prénom/nom -> pseudo.
-- À appliquer après 202611050002_profils_pseudo.sql.
begin;

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

  insert into public.profils (
    id,
    pseudo,
    prenom,
    nom,
    role,
    compte_id,
    est_invite,
    est_archive
  ) values (
    new.id,
    v_pseudo,
    v_pseudo,
    '',
    'athlete',
    new.id,
    false,
    false
  );

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

-- Le nom standard Supabase est recréé. Le trigger BEFORE DELETE
-- preparer_suppression_compte reste inchangé.
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

commit;
