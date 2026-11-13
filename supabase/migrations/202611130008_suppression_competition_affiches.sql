-- Corrige la suppression d'une compétition contenant des affiches d'épreuve.
-- Les métadonnées d'affiche suivent désormais le cycle de vie de leur épreuve.
-- Les objets Storage devenus orphelins restent éligibles au nettoyage prévu par
-- lister_objets_affiches_orphelins().
begin;

alter table public.affiches_epreuve
  drop constraint if exists affiches_epreuve_epreuve_id_fkey;

alter table public.affiches_epreuve
  add constraint affiches_epreuve_epreuve_id_fkey
  foreign key (epreuve_id)
  references public.epreuves(id)
  on delete cascade;

commit;
