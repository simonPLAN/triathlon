-- Garantit l'enchaînement automatique même si seule la première manche
-- a été configurée : la suivante reprend participants, ordre et délai.
begin;

create or replace function public.cloturer_manche_interne(p_manche_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare
  v_m public.manches;
  v_suivante public.manches;
  v_automatique boolean;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found then raise exception 'Manche introuvable.'; end if;
  if v_m.statut='terminee' then return v_m.id; end if;
  if v_m.statut<>'en_cours' or v_m.heure_fin_delai is null
    or clock_timestamp()<v_m.heure_fin_delai then
    raise exception 'Le délai n’est pas écoulé.';
  end if;

  insert into public.resultats(manche_id,athlete_id,points,statut,commentaire)
    select v_m.id,p.athlete_id,0,'hors_delai',
      'Délai dépassé à la fin de la manche.'
    from public.participants_manche p
    where p.manche_id=v_m.id
      and not exists(
        select 1 from public.resultats r
        where r.manche_id=v_m.id and r.athlete_id=p.athlete_id
      );

  update public.manches
    set statut='terminee',date_modification=now()
    where id=v_m.id;

  select c.demarrage_automatique_manche_suivante
    into v_automatique
    from public.competitions c
    join public.epreuves e on e.competition_id=c.id
    where e.id=v_m.epreuve_id;

  if v_automatique then
    select * into v_suivante
      from public.manches
      where epreuve_id=v_m.epreuve_id
        and numero>v_m.numero
        and statut='a_venir'
      order by numero,id
      limit 1 for update;

    if found then
      if not v_suivante.participants_definis then
        insert into public.participants_manche(
          manche_id,athlete_id,ordre_depart
        )
          select v_suivante.id,p.athlete_id,p.ordre_depart
          from public.participants_manche p
          where p.manche_id=v_m.id
          order by p.ordre_depart;

        update public.manches
          set participants_definis=true,
              duree_limite_secondes=coalesce(
                v_suivante.duree_limite_secondes,
                v_m.duree_limite_secondes
              ),
              date_modification=now()
          where id=v_suivante.id
          returning * into v_suivante;
      end if;

      if v_suivante.participants_definis
        and v_suivante.duree_limite_secondes is not null
        and exists(
          select 1 from public.participants_manche
          where manche_id=v_suivante.id
        )
        and not exists(
          select 1 from public.manches
          where epreuve_id=v_m.epreuve_id and statut='en_cours'
        ) then
        update public.manches
          set statut='en_cours',
              heure_depart=clock_timestamp(),
              date_modification=now()
          where id=v_suivante.id;
        return v_suivante.id;
      end if;
    end if;
  end if;

  return v_m.id;
end $$;

revoke all on function public.cloturer_manche_interne(uuid)
  from public,anon,authenticated;

commit;
