-- =====================================================================
-- TMeet · 003 RPC 함수 (앱에서 supabase.rpc('이름', {...}) 로 부름)
-- 담당: C (부이휘황) · C-8 주변 조회, C-10 연결 요청(+NFR-20 현지 확인), C-11 채팅방, C-13 동의 기록
-- 오류는 message 에 짧은 코드로 돌려준다 (예: 'too_far'). 앱은 코드를 번역 문구 키로 바꿔 보여준다.
-- =====================================================================

-- ---------- 동의 기록 (FR-40, FR-41, NFR-15) ----------
create or replace function public.agree_terms() returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare v timestamptz;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  update public.profiles set terms_agreed_at = coalesce(terms_agreed_at, now())
   where id = auth.uid() returning terms_agreed_at into v;
  return v;
end $$;

create or replace function public.agree_location() returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare v timestamptz;
begin
  if auth.uid() is null then raise exception 'not_authenticated'; end if;
  update public.profiles set location_agreed_at = coalesce(location_agreed_at, now())
   where id = auth.uid() returning location_agreed_at into v;
  return v;
end $$;

-- ---------- 위치 저장 (FR-13, 기획서 12장) ----------
-- 앱(B)은 소수점 둘째 자리로 반올림한 좌표를 보내면 된다. 서버가 다시 반올림 + 고정 오프셋을 적용하므로
-- 정확한 좌표를 보내도 정확한 값은 저장되지 않는다 (이중 안전장치).
create or replace function public.update_my_location(
  p_lat double precision, p_lng double precision, p_city text default null)
returns table (approx_lat double precision, approx_lng double precision,
               city_name text, location_updated_at timestamptz)
language plpgsql security definer set search_path = '' as $$
#variable_conflict use_column
declare
  me uuid := auth.uid();
  f  record;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if p_lat is null or p_lng is null or p_lat not between -90 and 90 or p_lng not between -180 and 180 then
    raise exception 'invalid_coordinates';
  end if;
  if not exists (select 1 from public.profiles p where p.id = me and p.location_agreed_at is not null) then
    raise exception 'location_consent_required';
  end if;

  select * into f from public.tmeet_fuzz_coord(me, p_lat, p_lng);

  return query
  update public.profiles p
     set approx_lat = f.lat,
         approx_lng = f.lng,
         city_name = nullif(left(btrim(coalesce(p_city, '')), 80), ''),
         location_updated_at = now()
   where p.id = me
  returning p.approx_lat, p.approx_lng, p.city_name, p.location_updated_at;
end $$;

-- ---------- 주변 여행자 조회 (FR-14, C-8) ----------
-- 반경 10 km(1~10), 최근 24시간 갱신, 본인·차단(양쪽)·위치 숨김 제외.
-- A의 matching.js 가 점수를 계산할 수 있도록 필요한 필드를 한 번에 돌려준다.
-- 시연 모드(FR-24)에서는 p_include_demo = true 로 파리 가상 여행자(is_demo)를 함께 받는다.
create or replace function public.get_nearby_travelers(
  p_radius_km double precision default 10,
  p_include_demo boolean default false)
returns table (
  id uuid, nickname text, photo_url text, tagline text, bio text,
  languages text[], interests text[],
  style_pace smallint, style_planning smallint, style_budget smallint,
  meet_types text[], group_size text,
  ai_interests text[], ai_meet_types text[], ai_style jsonb, ai_keywords jsonb,
  approx_lat double precision, approx_lng double precision, city_name text,
  travel_until date, is_demo boolean, distance_km double precision)
language plpgsql stable security definer set search_path = '' as $$
#variable_conflict use_column
declare
  me     uuid := auth.uid();
  my_lat double precision;
  my_lng double precision;
  r      double precision := least(greatest(coalesce(p_radius_km, 10), 1), 10);
  dlat   double precision;
  dlng   double precision;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  select p.approx_lat, p.approx_lng into my_lat, my_lng from public.profiles p where p.id = me;
  if my_lat is null then raise exception 'location_required'; end if;

  -- 사각형으로 먼저 거르고(인덱스 사용) 정확한 거리로 다시 거른다
  dlat := r / 111.0;
  dlng := r / (111.0 * greatest(cos(radians(my_lat)), 0.01));

  return query
  select p.id, p.nickname, p.photo_url, p.tagline, p.bio,
         p.languages, p.interests,
         p.style_pace, p.style_planning, p.style_budget,
         p.meet_types, p.group_size,
         p.ai_interests, p.ai_meet_types, p.ai_style, p.ai_keywords,
         p.approx_lat, p.approx_lng, p.city_name,
         p.travel_until, p.is_demo,
         round(public.tmeet_distance_km(my_lat, my_lng, p.approx_lat, p.approx_lng)::numeric, 1)::double precision
    from public.profiles p
   where p.id <> me
     and p.is_visible
     and p.nickname is not null
     and p.approx_lat between my_lat - dlat and my_lat + dlat
     and p.approx_lng between my_lng - dlng and my_lng + dlng
     and (p.is_demo = false or p_include_demo)
     and (p.is_demo or p.location_updated_at > now() - interval '24 hours')
     and not public.tmeet_is_blocked(me, p.id)
     and public.tmeet_distance_km(my_lat, my_lng, p.approx_lat, p.approx_lng) <= r
   order by 22
   limit 200;
end $$;

-- ---------- 연결 요청 보내기 (FR-19, C-10) ----------
-- 규칙: 본인 X, 차단 관계 X, 이미 채팅 중 X, 같은 상대 대기 중 요청 X, 상대가 이미 나에게 보낸 대기 요청이 있으면 X,
--       NFR-20 현지 확인: 내 위치(24시간 안)가 상대 위치에서 10 km 안. 하루 30건 제한.
create or replace function public.send_request(p_to uuid, p_message text default null)
returns public.connection_requests
language plpgsql security definer set search_path = '' as $$
declare
  me     uuid := auth.uid();
  mine   public.profiles;
  target public.profiles;
  msg    text := nullif(btrim(coalesce(p_message, '')), '');
  v_row  public.connection_requests;
begin
  if me is null then raise exception 'not_authenticated'; end if;
  if p_to is null or p_to = me then raise exception 'invalid_target'; end if;
  if msg is not null and char_length(msg) > 200 then raise exception 'message_too_long'; end if;

  select * into mine from public.profiles where id = me;
  select * into target from public.profiles where id = p_to;
  if target.id is null or target.nickname is null then raise exception 'target_not_found'; end if;
  if mine.nickname is null then raise exception 'profile_incomplete'; end if;
  if public.tmeet_is_blocked(me, p_to) then raise exception 'blocked'; end if;

  -- NFR-20 현지 확인 (좌표는 둘 다 약 1 km 단위로 뭉갠 값이라 1 km 여유를 둔다)
  if mine.approx_lat is null or mine.location_updated_at < now() - interval '24 hours' then
    raise exception 'location_required';
  end if;
  if target.approx_lat is null
     or public.tmeet_distance_km(mine.approx_lat, mine.approx_lng, target.approx_lat, target.approx_lng) > 11 then
    raise exception 'too_far';
  end if;

  if exists (select 1 from public.chat_rooms r
              where (r.user_a = me and r.user_b = p_to) or (r.user_a = p_to and r.user_b = me)) then
    raise exception 'already_connected';
  end if;
  if exists (select 1 from public.connection_requests c
              where c.from_user = me and c.to_user = p_to and c.status = 'pending') then
    raise exception 'duplicate_pending';
  end if;
  if exists (select 1 from public.connection_requests c
              where c.from_user = p_to and c.to_user = me and c.status = 'pending') then
    raise exception 'incoming_pending';
  end if;
  if (select count(*) from public.connection_requests c
       where c.from_user = me and c.created_at > now() - interval '24 hours') >= 30 then
    raise exception 'rate_limited';
  end if;

  insert into public.connection_requests (from_user, to_user, message)
  values (me, p_to, msg)
  returning * into v_row;
  return v_row;
end $$;

-- ---------- 요청 수락·거절 (FR-20, FR-21) — 받은 사람만. 수락하면 채팅방 자동 생성 ----------
create or replace function public.respond_request(p_request_id uuid, p_accept boolean)
returns uuid   -- 수락 시 채팅방 id, 거절 시 null
language plpgsql security definer set search_path = '' as $$
declare
  me   uuid := auth.uid();
  req  public.connection_requests;
  room uuid;
begin
  if me is null then raise exception 'not_authenticated'; end if;

  select * into req from public.connection_requests where id = p_request_id for update;
  if req.id is null or req.to_user <> me then raise exception 'request_not_found'; end if;
  if req.status <> 'pending' then raise exception 'already_responded'; end if;

  if not coalesce(p_accept, false) then
    update public.connection_requests set status = 'declined', responded_at = now() where id = req.id;
    return null;
  end if;

  if public.tmeet_is_blocked(req.from_user, req.to_user) then raise exception 'blocked'; end if;

  update public.connection_requests set status = 'accepted', responded_at = now() where id = req.id;

  select r.id into room from public.chat_rooms r
   where (r.user_a = req.from_user and r.user_b = req.to_user)
      or (r.user_a = req.to_user and r.user_b = req.from_user);
  if room is null then
    insert into public.chat_rooms (user_a, user_b, request_id)
    values (req.from_user, req.to_user, req.id)
    returning id into room;
  end if;
  return room;
end $$;

-- ---------- 요청함 (R1): 받은·보낸 요청 + 상대 요약 ----------
create or replace function public.get_my_requests()
returns table (
  id uuid, direction text, status text, message text, created_at timestamptz, responded_at timestamptz,
  other_id uuid, other_nickname text, other_photo_url text, other_tagline text,
  other_interests text[], other_languages text[])
language sql stable security definer set search_path = '' as $$
  select c.id,
         case when c.to_user = auth.uid() then 'received' else 'sent' end,
         c.status, c.message, c.created_at, c.responded_at,
         p.id, p.nickname, p.photo_url, p.tagline, p.interests, p.languages
    from public.connection_requests c
    join public.profiles p
      on p.id = case when c.to_user = auth.uid() then c.from_user else c.to_user end
   where auth.uid() in (c.from_user, c.to_user)
     and not public.tmeet_is_blocked(c.from_user, c.to_user)
   order by c.created_at desc
   limit 200
$$;

-- ---------- 채팅 목록 (C1): 상대 정보 + 마지막 메시지 ----------
create or replace function public.get_my_chat_rooms()
returns table (
  room_id uuid, partner_id uuid, partner_nickname text, partner_photo_url text,
  partner_deleted boolean, partner_blocked boolean,
  last_message text, last_sender_id uuid, last_message_at timestamptz, created_at timestamptz)
language sql stable security definer set search_path = '' as $$
  select r.id,
         p.id, p.nickname, p.photo_url,
         (case when r.user_a = auth.uid() then r.user_b else r.user_a end) is null,
         case when p.id is null then false else public.tmeet_is_blocked(auth.uid(), p.id) end,
         m.content, m.sender_id, coalesce(r.last_message_at, r.created_at), r.created_at
    from public.chat_rooms r
    left join public.profiles p
      on p.id = case when r.user_a = auth.uid() then r.user_b else r.user_a end
    left join lateral (
      select mm.content, mm.sender_id from public.messages mm
       where mm.room_id = r.id order by mm.created_at desc, mm.id desc limit 1) m on true
   where auth.uid() in (r.user_a, r.user_b)
   order by coalesce(r.last_message_at, r.created_at) desc
$$;

-- ---------- 권한: 로그인한 사용자만 호출 ----------
do $$
declare f text;
begin
  foreach f in array array[
    'public.agree_terms()',
    'public.agree_location()',
    'public.update_my_location(double precision, double precision, text)',
    'public.get_nearby_travelers(double precision, boolean)',
    'public.send_request(uuid, text)',
    'public.respond_request(uuid, boolean)',
    'public.get_my_requests()',
    'public.get_my_chat_rooms()'
  ] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;

-- 내부 도우미는 직접 호출 막기
revoke all on function public.tmeet_fuzz_coord(uuid, double precision, double precision) from public, anon, authenticated;
