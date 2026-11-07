# Correctif création de compétition — 5 novembre 2026

Après la migration 202611040030, exécuter le fichier complet `supabase/migrations/202611050001_creation_competition_rls.sql` dans SQL Editor du projet concerné, d'abord en staging.

L'insertion Flutter utilise INSERT avec RETURNING. L'ancienne policy SELECT recherchait la compétition dans une fonction STABLE avant que la nouvelle ligne soit visible dans son snapshot. La nouvelle policy vérifie directement coach_id sur la ligne pour le coach authentifié. Les droits de création restent inchangés ; un autre coach et les athlètes ne peuvent pas lire ce brouillon.

Aucune donnée n'est supprimée et RLS reste activée. Aucun changement Flutter ni nouvel APK nécessaire. Après application, réessayer la création. Ne pas relancer 030 après ce correctif sans réappliquer celui-ci.
