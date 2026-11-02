begin;
alter table public.manches add column if not exists revision_resultats bigint not null default 0;

-- Un classement arbitré peut avoir un écart signé par rapport au premier classé.
-- Ne remplacer que les anciens contrôles simples connus ; un contrôle combiné
-- inconnu nécessite un audit, sans suppression aveugle de ses autres règles.
do $$
declare c record; v_definition text;
begin
  for c in select conname,pg_get_constraintdef(oid) definition
    from pg_catalog.pg_constraint where conrelid='public.resultats'::regclass
      and contype='c' and conname<>'resultats_ecart_classement_check'
      and pg_get_constraintdef(oid) like '%ecart_premier_millisecondes%'
  loop
    v_definition:=lower(regexp_replace(c.definition,'[[:space:]()]','','g'));
    if v_definition not in ('checkecart_premier_millisecondes>=0',
      'checkecart_premier_millisecondesisnullorecart_premier_millisecondes>=0') then
      raise exception 'Contrôle des écarts non reconnu (%) : vérifier le schéma avant migration.',c.conname;
    end if;
    execute format('alter table public.resultats drop constraint %I',c.conname);
  end loop;
end $$;
alter table public.resultats drop constraint if exists resultats_ecart_classement_check;
alter table public.resultats add constraint resultats_ecart_classement_check
  check(ecart_premier_millisecondes is null or
    ecart_premier_millisecondes between -604800000 and 604800000) not valid;

-- Échouer si les données existantes nécessitent une reprise explicite.
do $$
declare u record;
begin
  if exists(select 1 from public.resultats where position is not null
    group by manche_id, position having count(*) > 1) then
    raise exception 'Positions dupliquées existantes : corriger les données avant la migration.';
  end if;
  -- Remplacer les uniques sur (manche_id, position), y compris un index partiel,
  -- par une contrainte différable, sans toucher à l'unique athlète/manche.
  for u in select c.conname from pg_catalog.pg_constraint c
    where c.conrelid = 'public.resultats'::regclass and c.contype='u'
      and (select array_agg(a.attname::text order by a.attname)
        from unnest(c.conkey) k join pg_catalog.pg_attribute a
        on a.attrelid=c.conrelid and a.attnum=k) = array['manche_id','position']
  loop execute format('alter table public.resultats drop constraint %I',u.conname); end loop;
  for u in select ic.relname from pg_catalog.pg_index i
    join pg_catalog.pg_class ic on ic.oid=i.indexrelid
    where i.indrelid='public.resultats'::regclass and i.indisunique and not i.indisprimary
      and not exists(select 1 from pg_catalog.pg_constraint c where c.conindid=i.indexrelid)
      and (select array_agg(a.attname::text order by a.attname)
        from unnest(i.indkey) k join pg_catalog.pg_attribute a
        on a.attrelid=i.indrelid and a.attnum=k) = array['manche_id','position']
  loop execute format('drop index public.%I',u.relname); end loop;
end $$;
alter table public.resultats add constraint resultats_manche_position_unique
  unique (manche_id, position) deferrable initially immediate;

-- Tous les auteurs, y compris les arrivées directes, prennent le verrou parent.
create or replace function public.revision_ecriture_resultat()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_id uuid; v_publie boolean;
begin
  if tg_op='UPDATE' and (new.manche_id <> old.manche_id or new.athlete_id <> old.athlete_id) then
    raise exception 'L’identité d’un résultat ne peut pas être déplacée.';
  end if;
  if tg_op='DELETE' then v_id:=old.manche_id; else v_id:=new.manche_id; end if;
  select resultats_publies into v_publie from public.manches where id=v_id for update;
  if v_publie then
    if tg_op<>'DELETE' then
      raise exception 'Résultats publiés : utiliser la correction avec retrait de publication.';
    end if;
    -- La suppression d'un compte doit rester possible. Retirer la publication
    -- avant son résultat, sans toucher aux performances des autres athlètes.
    update public.manches set resultats_publies=false where id=v_id;
    update public.resultats set date_publication=null
      where manche_id=v_id and id<>old.id and date_publication is not null;
  end if;
  update public.manches set revision_resultats=revision_resultats+1 where id=v_id;
  if tg_op='DELETE' then return old; else return new; end if;
end $$;
revoke all on function public.revision_ecriture_resultat() from public,anon,authenticated;
drop trigger if exists revision_ecriture_resultat on public.resultats;
create trigger revision_ecriture_resultat before insert or update or delete on public.resultats
  for each row execute function public.revision_ecriture_resultat();

create or replace function public.revision_publication_resultats()
returns trigger language plpgsql set search_path='' as $$
begin
  if new.resultats_publies and not old.resultats_publies and current_user in ('anon','authenticated') then
    raise exception 'Utilise la publication vérifiée des résultats.' using errcode='42501';
  end if;
  if new.resultats_publies is distinct from old.resultats_publies then
    new.revision_resultats:=old.revision_resultats+1;
  end if;
  return new;
end $$;
drop trigger if exists revision_publication_resultats on public.manches;
create trigger revision_publication_resultats before update of resultats_publies on public.manches
  for each row execute function public.revision_publication_resultats();

-- Contrôle de propriétaire commun aux deux RPC. Verrou conservé jusqu'au commit.
create or replace function public.verifier_edition_resultats(p_manche_id uuid, p_revision bigint)
returns public.manches language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  select m.* into v_m from public.manches m
    join public.epreuves e on e.id=m.epreuve_id
    join public.competitions c on c.id=e.competition_id
    join public.profils p on p.id=c.coach_id
    where m.id=p_manche_id and c.coach_id=auth.uid() and p.role='coach'
    for update of m;
  if not found then raise exception 'Tu ne peux pas modifier les résultats de cette manche.' using errcode='42501'; end if;
  if v_m.statut<>'terminee' or v_m.heure_depart is null then
    raise exception 'Termine la manche avant de saisir ou corriger un résultat.';
  end if;
  if p_revision is null or v_m.revision_resultats<>p_revision then
    raise exception 'Le classement a changé. Actualise la manche.' using errcode='40001';
  end if;
  return v_m;
end $$;
revoke all on function public.verifier_edition_resultats(uuid,bigint) from public,anon,authenticated;

create or replace function public.editer_resultat_manche(
  p_manche_id uuid, p_athlete_id uuid, p_resultat_id uuid, p_revision bigint,
  p_statut text, p_mode text, p_position integer, p_temps_ms bigint,
  p_commentaire text, p_accepter_depublication boolean
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_m public.manches; v_cible public.resultats; v_id uuid; v_competition uuid;
  v_avant uuid[]; v_liste uuid[]; v_ancien integer; v_index integer;
  v_leader bigint; v_reponse jsonb; v_revision bigint; v_arrivee timestamptz;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if p_statut is null or p_statut not in ('arrive','hors_delai','abandon','disqualifie')
    or p_mode is null or p_mode not in ('decaler','echanger','temps')
    or length(coalesce(p_commentaire,''))>1000 then
    raise exception 'Statut, mode ou commentaire invalide.' using errcode='22023';
  end if;
  if v_m.resultats_publies and p_accepter_depublication is distinct from true then
    raise exception 'Confirme le retrait de publication de toute la manche.';
  end if;
  perform 1 from public.resultats where manche_id=p_manche_id for update;
  if p_resultat_id is not null then
    select * into v_cible from public.resultats
      where id=p_resultat_id and manche_id=p_manche_id and athlete_id=p_athlete_id;
    if not found then raise exception 'Résultat introuvable. Actualise le classement.'; end if;
    v_id:=v_cible.id;
  else
    select competition_id into v_competition from public.epreuves where id=v_m.epreuve_id;
    if not exists(select 1 from public.inscriptions where competition_id=v_competition and athlete_id=p_athlete_id) then
      raise exception 'Cet athlète n’est pas inscrit à cette compétition.';
    end if;
    if exists(select 1 from public.resultats where manche_id=p_manche_id and athlete_id=p_athlete_id) then
      raise exception 'Un résultat existe déjà pour cet athlète. Actualise le classement.';
    end if;
    v_id:=gen_random_uuid();
  end if;
  select coalesce(array_agg(id order by position nulls last,id),'{}'::uuid[])
    into v_avant from public.resultats where manche_id=p_manche_id and statut='arrive';
  v_ancien:=array_position(v_avant,v_id);
  if p_statut='arrive' then
    if p_temps_ms is null or p_temps_ms<0 or p_temps_ms>604800000 then
      raise exception 'Saisis un temps compris entre zéro et sept jours.' using errcode='22023';
    end if;
    v_arrivee:=v_m.heure_depart+p_temps_ms*interval '1 millisecond';
    if v_m.heure_fin_delai is not null and v_arrivee>=v_m.heure_fin_delai then
      raise exception 'Ce temps atteint le délai limite. Utilise le statut Hors délai.';
    end if;
    v_index:=cardinality(v_avant)+case when v_ancien is null then 1 else 0 end;
    if p_mode<>'temps' and (p_position is null or p_position<1 or p_position>v_index) then
      raise exception 'La position doit être comprise entre 1 et %.',v_index using errcode='22023';
    end if;
    if p_mode='echanger' and v_ancien is null then
      raise exception 'L’échange nécessite un athlète déjà classé.';
    end if;
  elsif p_temps_ms is not null or p_position is not null then
    raise exception 'Un statut sans arrivée ne possède ni place ni temps.' using errcode='22023';
  end if;
  -- Le retrait est atomique avec le classement ; aucun état intermédiaire public.
  update public.manches set resultats_publies=false where id=p_manche_id;
  set constraints public.resultats_manche_position_unique deferred;
  if p_resultat_id is null then
    insert into public.resultats(id,manche_id,athlete_id,position,points,statut,
      heure_arrivee,temps_total_millisecondes,ecart_premier_millisecondes,commentaire)
    select v_id,p_manche_id,p_athlete_id,
      case when p_statut='arrive' then coalesce(p_position,cardinality(v_avant)+1) end,0,x.statut,
      v_arrivee,case when p_statut='arrive' then p_temps_ms end,
      case when p_statut='arrive' then 0 end,nullif(btrim(p_commentaire),'')
      from jsonb_populate_record(null::public.resultats,jsonb_build_object('statut',p_statut)) x;
  else
    update public.resultats r set
      statut=x.statut,
      position=case when p_statut='arrive' then coalesce(p_position,r.position,cardinality(v_avant)+1) end,
      points=0,heure_arrivee=v_arrivee,
      temps_total_millisecondes=case when p_statut='arrive' then p_temps_ms end,
      ecart_premier_millisecondes=case when p_statut='arrive' then 0 end,
      commentaire=nullif(btrim(p_commentaire),''),date_modification=now()
      from jsonb_populate_record(null::public.resultats,jsonb_build_object('statut',p_statut)) x
      where r.id=v_id;
  end if;
  if p_statut='arrive' and p_mode='temps' then
    select coalesce(array_agg(id order by temps_total_millisecondes,position nulls last,id),'{}'::uuid[])
      into v_liste from public.resultats where manche_id=p_manche_id and statut='arrive';
  elsif p_statut='arrive' and p_mode='echanger' then
    v_liste:=v_avant; v_liste[v_ancien]:=v_avant[p_position]; v_liste[p_position]:=v_id;
  else
    select coalesce(array_agg(id order by position nulls last,id),'{}'::uuid[])
      into v_liste from public.resultats where manche_id=p_manche_id and statut='arrive' and id<>v_id;
    if p_statut='arrive' then
      v_liste:=coalesce(v_liste[1:p_position-1],'{}'::uuid[]) ||
        array[v_id] || coalesce(v_liste[p_position:cardinality(v_liste)],'{}'::uuid[]);
    end if;
  end if;
  if cardinality(v_liste)>0 then
    select temps_total_millisecondes into v_leader from public.resultats where id=v_liste[1];
    for v_index in 1..cardinality(v_liste) loop
      update public.resultats set position=v_index,points=greatest(6-v_index,0),
        ecart_premier_millisecondes=temps_total_millisecondes-v_leader,
        date_publication=null,date_modification=now()
        where id=v_liste[v_index];
    end loop;
  end if;
  update public.resultats set position=null,points=0,heure_arrivee=null,
    temps_total_millisecondes=null,ecart_premier_millisecondes=null,
    date_publication=null,date_modification=now()
    where manche_id=p_manche_id and statut<>'arrive';
  update public.resultats set date_publication=null where manche_id=p_manche_id and date_publication is not null;
  set constraints public.resultats_manche_position_unique immediate;
  select revision_resultats into v_revision from public.manches where id=p_manche_id;
  select coalesce(jsonb_agg(to_jsonb(r)||jsonb_build_object('profils',
    jsonb_build_object('id',p.id,'prenom',p.prenom,'nom',p.nom))
    order by r.position nulls last,r.id),'[]'::jsonb)
    into v_reponse from public.resultats r join public.profils p on p.id=r.athlete_id where manche_id=p_manche_id;
  return jsonb_build_object('resultats',v_reponse,'revision',v_revision,'depublies',v_m.resultats_publies);
end $$;
revoke all on function public.editer_resultat_manche(uuid,uuid,uuid,bigint,text,text,integer,bigint,text,boolean) from public,anon;
grant execute on function public.editer_resultat_manche(uuid,uuid,uuid,bigint,text,text,integer,bigint,text,boolean) to authenticated;

create or replace function public.publier_resultats_manche_verifies(p_manche_id uuid,p_revision bigint)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_m public.manches;
begin
  v_m:=public.verifier_edition_resultats(p_manche_id,p_revision);
  if v_m.resultats_publies then raise exception 'Les résultats sont déjà publiés.'; end if;
  if not exists(select 1 from public.resultats where manche_id=p_manche_id) then
    raise exception 'Aucun résultat à publier.';
  end if;
  if exists(select 1 from (
    select position,points,temps_total_millisecondes,
      row_number() over(order by position,id) rang
    from public.resultats where manche_id=p_manche_id and statut='arrive'
  ) r where position is distinct from rang or points<>greatest(6-rang,0)
    or temps_total_millisecondes is null or temps_total_millisecondes<0
    or temps_total_millisecondes>604800000) then
    raise exception 'Le classement doit être corrigé avant publication.';
  end if;
  update public.resultats r set date_publication=now(),
    ecart_premier_millisecondes=case when r.statut='arrive' then
      r.temps_total_millisecondes-(select temps_total_millisecondes from public.resultats
        where manche_id=p_manche_id and position=1) end
    where r.manche_id=p_manche_id;
  update public.manches set resultats_publies=true,date_modification=now() where id=p_manche_id returning * into v_m;
  return to_jsonb(v_m);
end $$;
revoke all on function public.publier_resultats_manche_verifies(uuid,bigint) from public,anon;
grant execute on function public.publier_resultats_manche_verifies(uuid,bigint) to authenticated;

-- Les corrections de manches terminées ne passent plus par des UPDATE directs.
create or replace function public.resultats_saisie_directe(p_id uuid)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.manches m join public.epreuves e on e.id=m.epreuve_id
    join public.competitions c on c.id=e.competition_id
    join public.profils p on p.id=c.coach_id and p.role='coach'
    where m.id=p_id and m.statut='en_cours' and not m.resultats_publies
      and c.coach_id=auth.uid());
$$;
revoke all on function public.resultats_saisie_directe(uuid) from public,anon;
grant execute on function public.resultats_saisie_directe(uuid) to authenticated;
drop policy if exists "Resultats saisie insertion" on public.resultats;
create policy "Resultats saisie insertion" on public.resultats as restrictive for insert to authenticated
  with check(public.resultats_saisie_directe(manche_id));
drop policy if exists "Resultats saisie modification" on public.resultats;
create policy "Resultats saisie modification" on public.resultats as restrictive for update to authenticated
  using(public.resultats_saisie_directe(manche_id)) with check(public.resultats_saisie_directe(manche_id));
drop policy if exists "Resultats saisie suppression" on public.resultats;
create policy "Resultats saisie suppression" on public.resultats as restrictive for delete to authenticated
  using(public.resultats_saisie_directe(manche_id));
commit;
