# Correctif « Database error saving new user »

Ce correctif adapte le trigger Supabase Auth historique au nouveau profil fondé
sur un pseudo.

## Ordre d'exécution

1. `202611050001_creation_competition_rls.sql`
2. `202611050002_profils_pseudo.sql`
3. `202611050003_creation_compte_pseudo.sql`

Exécuter le troisième fichier entièrement dans le SQL Editor, puis créer un
compte avec une adresse e-mail encore jamais utilisée et un pseudo unique.

Le correctif recrée uniquement le trigger standard
`on_auth_user_created`. Il ne modifie ni les politiques RLS ni le trigger
`preparer_suppression_compte` utilisé lors de la suppression d'un compte.

## Si l'erreur demeure

Exécuter cette requête en lecture seule et relever le résultat :

```sql
select t.tgname, p.proname, pg_get_triggerdef(t.oid)
from pg_trigger t
join pg_proc p on p.oid = t.tgfoid
where t.tgrelid = 'auth.users'::regclass
  and not t.tgisinternal
order by t.tgname;
```

Un second trigger d'insertion personnalisé peut alors être encore actif sous
un autre nom. Ne pas le supprimer sans vérifier sa fonction, car le trigger
de suppression de compte doit rester installé.
