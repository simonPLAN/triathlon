-- Policy Storage directe pour les images de compétition.
begin;

drop policy if exists "Images competitions insertion" on storage.objects;
create policy "Images competitions insertion" on storage.objects
as permissive
for insert to authenticated
with check(
  bucket_id='images-competitions'
  and exists(
    select 1
    from public.competitions c
    where c.id::text=split_part(name,'/',1)
      and c.coach_id=auth.uid()
      and c.statut='brouillon'
  )
);

drop policy if exists "Images competitions suppression" on storage.objects;
create policy "Images competitions suppression" on storage.objects
as permissive
for delete to authenticated
using(
  bucket_id='images-competitions'
  and exists(
    select 1
    from public.competitions c
    where c.id::text=split_part(name,'/',1)
      and c.coach_id=auth.uid()
      and c.statut='brouillon'
  )
);

commit;

-- Diagnostic à consulter dans le résultat du SQL Editor.
select policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where schemaname='storage' and tablename='objects'
order by policyname;
