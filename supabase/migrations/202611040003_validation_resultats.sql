begin;
alter table public.manches add column if not exists revision_validation_resultats bigint;

create or replace function public.proteger_validation_resultats()
returns trigger language plpgsql set search_path='' as $$
begin
  if current_user in ('anon','authenticated') and
    new.revision_validation_resultats is distinct from old.revision_validation_resultats then
    raise exception 'Utiliser la validation vérifiée du classement.' using errcode='42501';
  end if;
  return new;
end $$;
revoke all on function public.proteger_validation_resultats() from public,anon,authenticated;
drop trigger if exists proteger_validation_resultats on public.manches;
create trigger proteger_validation_resultats before update on public.manches
  for each row execute function public.proteger_validation_resultats();

create or replace function public.valider_resultats_manche(p_manche_id uuid,p_revision bigint)
returns void language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if v_m.resultats_publies then raise exception 'Ce classement est déjà publié.'; end if;
  if not exists(select 1 from public.resultats where manche_id=p_manche_id) then
    raise exception 'Aucun résultat à valider.';
  end if;
  if v_m.participants_definis and exists(
    select 1 from public.participants_manche p where p.manche_id=p_manche_id
      and not exists(select 1 from public.resultats r where r.manche_id=p_manche_id and r.athlete_id=p.athlete_id)
  ) then raise exception 'Chaque participant doit posséder un résultat avant validation.'; end if;
  if exists(select 1 from(
    select position,points,temps_total_millisecondes,row_number() over(order by position,id) rang
    from public.resultats where manche_id=p_manche_id and statut='arrive'
  ) r where position is distinct from rang or points<>greatest(6-rang,0)
    or temps_total_millisecondes is null or temps_total_millisecondes not between 0 and 604800000)
  then raise exception 'Les places, temps et points doivent être corrigés avant validation.'; end if;
  update public.manches set revision_validation_resultats=p_revision,date_modification=now() where id=p_manche_id;
end $$;
revoke all on function public.valider_resultats_manche(uuid,bigint) from public,anon;
grant execute on function public.valider_resultats_manche(uuid,bigint) to authenticated;

-- Préserve le calcul de publication existant mais supprime tout accès direct à son implémentation.
do $$ begin
  if to_regprocedure('public.publier_resultats_manche_base(uuid,bigint)') is null then
    alter function public.publier_resultats_manche_verifies(uuid,bigint) rename to publier_resultats_manche_base;
  end if;
end $$;
revoke all on function public.publier_resultats_manche_base(uuid,bigint) from public,anon,authenticated;
create or replace function public.publier_resultats_manche_verifies(p_manche_id uuid,p_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if v_m.revision_validation_resultats is distinct from p_revision then
    raise exception 'Valide le classement actuel avant publication.';
  end if;
  return public.publier_resultats_manche_base(p_manche_id,p_revision);
end $$;
revoke all on function public.publier_resultats_manche_verifies(uuid,bigint) from public,anon;
grant execute on function public.publier_resultats_manche_verifies(uuid,bigint) to authenticated;
commit;
