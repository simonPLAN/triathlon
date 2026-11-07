-- Correctif de SELECT pour INSERT ... RETURNING utilisé par PostgREST.
-- La nouvelle ligne ne doit pas être recherchée dans la table via un helper STABLE.
begin;
drop policy if exists "Production plafond select" on public.competitions;
create policy "Production plafond select" on public.competitions as restrictive
for select to authenticated using (public.securite_identite_valide() and ((public.securite_identite_valide('coach') and coach_id=auth.uid()) or (public.securite_identite_valide('athlete') and public.programme_competition_visible(id))));
drop policy if exists "Production acces select" on public.competitions;
create policy "Production acces select" on public.competitions as permissive
for select to authenticated using (public.securite_identite_valide() and ((public.securite_identite_valide('coach') and coach_id=auth.uid()) or (public.securite_identite_valide('athlete') and public.programme_competition_visible(id))));
commit;
