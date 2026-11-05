begin;
-- Même verrou parent pour deux coachs : rang, première arrivée et délai sont atomiques.
create or replace function public.enregistrer_arrivee_atomique(
  p_manche_id uuid,p_athlete_id uuid,p_heure_arrivee timestamptz)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_m public.manches; v_r public.resultats; v_position integer;
  v_duree integer; v_premiere timestamptz; v_reponse jsonb;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Tu ne peux pas saisir cette arrivée.' using errcode='42501';
  end if;
  if v_m.statut <> 'en_cours' or v_m.heure_depart is null or v_m.resultats_publies then
    raise exception 'La manche doit être en cours.';
  end if;
  if not exists(select 1 from public.participants_manche where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Cet athlète n’est pas affecté à cette manche.';
  end if;
  if p_heure_arrivee is null or p_heure_arrivee < v_m.heure_depart
    or p_heure_arrivee > clock_timestamp()+interval '2 minutes' then
    raise exception 'Horaire d’arrivée invalide. Vérifie l’horloge de l’appareil puis actualise.';
  end if;
  if v_m.heure_fin_delai is not null and
    (p_heure_arrivee >= v_m.heure_fin_delai or clock_timestamp() >= v_m.heure_fin_delai) then
    raise exception 'Le délai est écoulé : aucune nouvelle arrivée.';
  end if;
  if exists(select 1 from public.resultats where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Un résultat existe déjà pour cet athlète.';
  end if;
  select count(*)+1 into v_position from public.resultats where manche_id=p_manche_id and statut='arrive';
  select coalesce(v_m.duree_limite_secondes,e.duree_limite_secondes)
    into v_duree from public.epreuves e where e.id=v_m.epreuve_id;
  v_premiere:=coalesce(v_m.heure_premiere_arrivee,p_heure_arrivee);
  if v_m.heure_premiere_arrivee is null then
    update public.manches set heure_premiere_arrivee=v_premiere,
      heure_fin_delai=v_premiere+make_interval(secs=>v_duree),date_modification=now()
      where id=p_manche_id;
  end if;
  insert into public.resultats(manche_id,athlete_id,position,points,heure_arrivee,
    temps_total_millisecondes,ecart_premier_millisecondes,statut)
    values(p_manche_id,p_athlete_id,v_position,greatest(6-v_position,0),p_heure_arrivee,
      round(extract(epoch from (p_heure_arrivee-v_m.heure_depart))*1000),
      round(extract(epoch from (p_heure_arrivee-v_premiere))*1000),'arrive')
    returning * into v_r;
  select to_jsonb(v_r)||jsonb_build_object('profils',
    jsonb_build_object('id',p.id,'prenom',p.prenom,'nom',p.nom))
    into v_reponse from public.profils p where p.id=p_athlete_id;
  return v_reponse;
end $$;
revoke all on function public.enregistrer_arrivee_atomique(uuid,uuid,timestamptz) from public,anon;
grant execute on function public.enregistrer_arrivee_atomique(uuid,uuid,timestamptz) to authenticated;

create or replace function public.declarer_statut_participant(
  p_manche_id uuid,p_athlete_id uuid,p_statut text,p_motif text)
returns void language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Cette manche ne peut pas être modifiée.' using errcode='42501';
  end if;
  if v_m.statut <> 'en_cours' or v_m.resultats_publies then raise exception 'La manche doit être en cours.'; end if;
  if p_statut is null or p_statut not in ('abandon','disqualifie')
    or length(trim(coalesce(p_motif,''))) not between 1 and 800 then
    raise exception 'Choisis un statut et indique son motif.';
  end if;
  if not exists(select 1 from public.participants_manche where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Cet athlète n’est pas affecté à cette manche.';
  end if;
  if exists(select 1 from public.resultats where manche_id=p_manche_id and athlete_id=p_athlete_id) then
    raise exception 'Un résultat existe déjà : utilise la correction après la fin de la manche.';
  end if;
  if p_statut='abandon' then
    insert into public.resultats(manche_id,athlete_id,points,statut,commentaire)
      values(p_manche_id,p_athlete_id,0,'abandon',trim(p_motif));
  else
    insert into public.resultats(manche_id,athlete_id,points,statut,commentaire)
      values(p_manche_id,p_athlete_id,0,'disqualifie',trim(p_motif));
  end if;
end $$;
revoke all on function public.declarer_statut_participant(uuid,uuid,text,text) from public,anon;
grant execute on function public.declarer_statut_participant(uuid,uuid,text,text) to authenticated;

-- Fonction interne non exposée. La prochaine manche n'est jamais démarrée sans affectations.
create or replace function public.cloturer_manche_interne(p_manche_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_m public.manches; v_suivante public.manches; v_automatique boolean;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found then raise exception 'Manche introuvable.'; end if;
  if v_m.statut='terminee' then return v_m.id; end if;
  if v_m.statut<>'en_cours' or v_m.heure_fin_delai is null
    or clock_timestamp()<v_m.heure_fin_delai then raise exception 'Le délai n’est pas écoulé.'; end if;
  insert into public.resultats(manche_id,athlete_id,points,statut,commentaire)
    select v_m.id,p.athlete_id,0,'hors_delai','Délai dépassé à la fin de la manche.'
    from public.participants_manche p where p.manche_id=v_m.id
      and not exists(select 1 from public.resultats r where r.manche_id=v_m.id and r.athlete_id=p.athlete_id);
  update public.manches set statut='terminee',date_modification=now() where id=v_m.id;
  select c.demarrage_automatique_manche_suivante into v_automatique from public.competitions c
    join public.epreuves e on e.competition_id=c.id where e.id=v_m.epreuve_id;
  if v_automatique then
    select * into v_suivante from public.manches
      where epreuve_id=v_m.epreuve_id and numero>v_m.numero and statut='a_venir'
      order by numero,id limit 1 for update;
    if found and v_suivante.participants_definis and exists(
      select 1 from public.participants_manche where manche_id=v_suivante.id)
      and not exists(select 1 from public.manches where epreuve_id=v_m.epreuve_id and statut='en_cours') then
      update public.manches set statut='en_cours',heure_depart=clock_timestamp(),date_modification=now()
        where id=v_suivante.id;
      return v_suivante.id;
    end if;
  end if;
  return v_m.id;
end $$;
revoke all on function public.cloturer_manche_interne(uuid) from public,anon,authenticated;

create or replace function public.cloturer_delai_manche(p_manche_id uuid)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select * into v_m from public.manches where id=p_manche_id for update;
  if not found or not public.programme_epreuve_modifiable(v_m.epreuve_id) then
    raise exception 'Cette manche ne peut pas être clôturée.' using errcode='42501';
  end if;
  return public.cloturer_manche_interne(p_manche_id);
end $$;
revoke all on function public.cloturer_delai_manche(uuid) from public,anon;
grant execute on function public.cloturer_delai_manche(uuid) to authenticated;

-- À planifier avec pg_cron en staging puis production ; jamais appeler depuis Flutter.
create or replace function public.cloturer_delais_expires()
returns integer language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_total integer:=0;
begin
  for v_id in select id from public.manches
    where statut='en_cours' and heure_fin_delai<=clock_timestamp()
    order by heure_fin_delai for update skip locked
  loop
    perform public.cloturer_manche_interne(v_id);
    v_total:=v_total+1;
  end loop;
  return v_total;
end $$;
revoke all on function public.cloturer_delais_expires() from public,anon,authenticated;
grant execute on function public.cloturer_delais_expires() to service_role;
commit;
