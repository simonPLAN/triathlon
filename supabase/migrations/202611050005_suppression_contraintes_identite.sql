-- Retire les validations d'identité civile devenues incompatibles avec le pseudo.
-- À appliquer après 202611050004_dedoublonnage_trigger_auth.sql.
begin;

alter table public.profils
  drop constraint if exists profils_nom_non_vide,
  drop constraint if exists profils_prenom_non_vide;

-- Certaines installations ont utilisé les noms générés par PostgreSQL.
alter table public.profils
  drop constraint if exists profils_nom_check,
  drop constraint if exists profils_prenom_check;

-- La seule identité publique requise est désormais le pseudo.
alter table public.profils drop constraint if exists profils_pseudo_format_check;
alter table public.profils add constraint profils_pseudo_format_check
  check (pseudo ~ '^[A-Za-z0-9_.-]{3,30}$');

commit;
