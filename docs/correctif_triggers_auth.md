# Correctif des triggers Auth en double

Exécuter `202611050004_dedoublonnage_trigger_auth.sql` après les migrations
002 et 003.

La migration supprime uniquement les autres triggers de `auth.users` qui
appellent exactement `public.handle_new_user()`, puis recrée une seule
instance nommée `on_auth_user_created`. Le trigger
`preparer_suppression_compte` n'est pas concerné.

Tester ensuite avec une nouvelle adresse e-mail et un nouveau pseudo.

Si l'inscription échoue encore, exécuter la requête suivante et transmettre
toutes ses lignes :

```sql
select
  t.tgname,
  n.nspname as schema_fonction,
  p.proname,
  pg_get_triggerdef(t.oid) as definition
from pg_trigger t
join pg_proc p on p.oid = t.tgfoid
join pg_namespace n on n.oid = p.pronamespace
where t.tgrelid = 'auth.users'::regclass
  and not t.tgisinternal
order by t.tgname;
```

Consulter aussi les journaux Auth dans Supabase, car le message visible dans
Flutter masque le message PostgreSQL exact.
