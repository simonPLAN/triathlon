-- Autorise un dépôt temporaire privé appartenant à l'utilisateur connecté.
-- La publication reste protégée par enregistrer_image_competition.
begin;

drop policy if exists "Images competitions insertion" on storage.objects;
create policy "Images competitions insertion" on storage.objects
as permissive
for insert to authenticated
with check(
  bucket_id='images-competitions'
  and owner_id=auth.uid()::text
  and name ~
    '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}[.](jpg|jpeg|png|webp)$'
);

drop policy if exists "Images competitions suppression" on storage.objects;
create policy "Images competitions suppression" on storage.objects
as permissive
for delete to authenticated
using(
  bucket_id='images-competitions'
  and owner_id=auth.uid()::text
);

commit;
