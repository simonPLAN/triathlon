-- Audit en lecture seule : exécuter dans l'espace administrateur, conserver
-- les résultats hors des interfaces publiques. Les anciennes définitions de
-- fonctions peuvent contenir des paramètres sensibles : ne pas publier l'export.
begin transaction read only;

-- Tables publiques sans RLS et état des tables sensibles.
select n.nspname as schema, c.relname as table_name, c.relrowsecurity as rls,
  c.relforcerowsecurity as force_rls, pg_get_userbyid(c.relowner) as owner
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
order by c.relrowsecurity,c.relname;

-- Détecter les policies anciennes, permissives, restrictives et leurs rôles.
select schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check
from pg_policies where schemaname='public'
order by tablename,policyname;

-- Droits directs sur tables/colonnes : RLS n'efface pas les grants historiques.
select grantee,table_name,privilege_type
from information_schema.role_table_grants
where table_schema='public' and grantee in ('PUBLIC','anon','authenticated','service_role')
order by table_name,grantee,privilege_type;

select grantee,table_name,column_name,privilege_type
from information_schema.role_column_grants
where table_schema='public' and grantee in ('PUBLIC','anon','authenticated')
order by table_name,column_name,grantee;

-- Fonctions privilegiées : auditer corps, propriétaires, search_path et EXECUTE.
select p.oid::regprocedure as function_name, pg_get_userbyid(p.proowner) as owner,
  p.prosecdef as security_definer,p.proconfig,
  has_function_privilege('anon',p.oid,'execute') as anon_execute,
  has_function_privilege('authenticated',p.oid,'execute') as authenticated_execute,
  pg_get_functiondef(p.oid) as definition
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prosecdef
order by p.oid::regprocedure::text;

-- Relations/cascades et contraintes qui peuvent influer sur une suppression.
select c.conrelid::regclass as table_name,c.conname,pg_get_constraintdef(c.oid) as definition
from pg_constraint c join pg_namespace n on n.oid=c.connamespace
where n.nspname='public' order by c.conrelid::regclass::text,c.conname;

select t.tgrelid::regclass as table_name,t.tgname,t.tgenabled,pg_get_triggerdef(t.oid) as definition
from pg_trigger t where not t.tgisinternal
  and t.tgrelid in (select c.oid from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname in ('public','auth'))
order by t.tgrelid::regclass::text,t.tgname;

rollback;
