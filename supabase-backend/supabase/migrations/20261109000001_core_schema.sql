-- =====================================================================
-- TMeet · 001 core schema (기획서 13장 데이터 필드 체크리스트 기준)
-- 담당: C (부이휘황) · C-2, C-3, C-13
-- =====================================================================

-- ---------- 태그 사전 (기획서 7장) — A의 src/constants/tags.js 와 같은 코드 ----------
create or replace function public.tmeet_interest_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['museum','cafe','food','market','nightlife','nature','hiking','beach',
               'shopping','photo','history','landmark','local','show','festival','activity']::text[]
$$;

create or replace function public.tmeet_meet_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['meal','cafe_chat','sightseeing','night_out','photo_mate','activity_mate']::text[]
$$;

create or replace function public.tmeet_language_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['ko','en','ja','zh','es','fr','de','other']::text[]
$$;

-- ---------- 거리 (km, haversine) ----------
create or replace function public.tmeet_distance_km(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision)
returns double precision
language sql immutable set search_path = '' as $$
  select 2 * 6371 * asin(sqrt(
           power(sin(radians(lat2 - lat1) / 2), 2) +
           cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)))
$$;

-- ---------- 좌표 뭉개기 (기획서 12장, NFR-01) ----------
-- 소수점 둘째 자리로 반올림(약 1.1 km 격자) + 사용자 id로 정한 고정 오프셋(최대 약 400 m).
-- 오프셋이 반 칸(0.005)보다 작아서, 이미 뭉갠 좌표를 다시 넣어도 같은 값이 나온다(멱등).
create or replace function public.tmeet_fuzz_coord(
  p_user uuid, p_lat double precision, p_lng double precision,
  out lat double precision, out lng double precision)
language plpgsql immutable set search_path = '' as $$
declare
  h  bytea := decode(md5(p_user::text), 'hex');
  oy double precision := ((get_byte(h, 0) * 256 + get_byte(h, 1))::double precision / 65536.0) * 2 - 1;
  ox double precision := ((get_byte(h, 2) * 256 + get_byte(h, 3))::double precision / 65536.0) * 2 - 1;
begin
  lat := round(p_lat::numeric, 2)::double precision + oy * 0.0036;
  lng := round(p_lng::numeric, 2)::double precision + ox * 0.0036;
end $$;

-- =====================================================================
-- profiles (사용자 1명당 1줄)
-- =====================================================================
create table public.profiles (
  id                  uuid primary key references auth.users (id) on delete cascade,
  nickname            text check (nickname is null or char_length(nickname) between 2 and 12),
  photo_url           text,
  bio                 text check (bio is null or char_length(bio) <= 300),
  tagline             text check (tagline is null or char_length(tagline) <= 40),
  languages           text[] not null default '{}',
  app_language        text not null default 'ko' check (app_language in ('ko', 'en')),

  interests           text[] not null default '{}',
  style_pace          smallint check (style_pace between 0 and 2),
  style_planning      smallint check (style_planning between 0 and 2),
  style_budget        smallint check (style_budget between 0 and 2),
  meet_types          text[] not null default '{}',
  group_size          text check (group_size in ('one_on_one', 'small_group', 'any')),

  ai_interests        text[] not null default '{}',
  ai_meet_types       text[] not null default '{}',
  ai_style            jsonb,          -- {"pace":0|1|2|null,"planning":...,"budget":...}
  ai_keywords         jsonb,          -- {"ko":[...],"en":[...]}
  ai_status           text not null default 'none' check (ai_status in ('none', 'done', 'failed')),
  ai_bio_hash         text,           -- 분석한 자기소개의 md5 (같은 글이면 AI를 다시 부르지 않음, NFR-06)
  ai_analyzed_at      timestamptz,

  approx_lat          double precision check (approx_lat between -90 and 90),
  approx_lng          double precision check (approx_lng between -180 and 180),
  city_name           text check (city_name is null or char_length(city_name) <= 80),
  location_updated_at timestamptz,
  is_visible          boolean not null default true,
  is_demo             boolean not null default false,
  travel_until        date,

  terms_agreed_at     timestamptz,
  location_agreed_at  timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  constraint profiles_interests_valid    check (interests <@ public.tmeet_interest_codes() and cardinality(interests) <= 6),
  constraint profiles_ai_interests_valid check (ai_interests <@ public.tmeet_interest_codes() and cardinality(ai_interests) <= 5),
  constraint profiles_meet_types_valid   check (meet_types <@ public.tmeet_meet_codes()),
  constraint profiles_ai_meet_valid      check (ai_meet_types <@ public.tmeet_meet_codes()),
  constraint profiles_languages_valid    check (languages <@ public.tmeet_language_codes()),
  constraint profiles_coords_pair        check ((approx_lat is null) = (approx_lng is null))
);

comment on table public.profiles is 'TMeet 사용자 프로필. 정확한 GPS는 저장하지 않음 (NFR-01).';

create index profiles_location_idx on public.profiles (approx_lat, approx_lng)
  where approx_lat is not null;

-- =====================================================================
-- connection_requests · chat_rooms · messages
-- =====================================================================
create table public.connection_requests (
  id           uuid primary key default gen_random_uuid(),
  from_user    uuid not null references public.profiles (id) on delete cascade,
  to_user      uuid not null references public.profiles (id) on delete cascade,
  message      text check (message is null or char_length(message) <= 200),
  status       text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  constraint connection_requests_not_self check (from_user <> to_user)
);
-- 같은 상대에게 대기 중 요청 중복 금지 (FR-19)
create unique index connection_requests_one_pending
  on public.connection_requests (from_user, to_user) where status = 'pending';
create index connection_requests_to_idx on public.connection_requests (to_user, created_at desc);
create index connection_requests_from_idx on public.connection_requests (from_user, created_at desc);

create table public.chat_rooms (
  id              uuid primary key default gen_random_uuid(),
  user_a          uuid references public.profiles (id) on delete set null,  -- 탈퇴하면 null → "탈퇴한 사용자"
  user_b          uuid references public.profiles (id) on delete set null,
  request_id      uuid unique references public.connection_requests (id) on delete set null,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz
);
create unique index chat_rooms_pair_uniq
  on public.chat_rooms (least(user_a, user_b), greatest(user_a, user_b))
  where user_a is not null and user_b is not null;
create index chat_rooms_user_a_idx on public.chat_rooms (user_a);
create index chat_rooms_user_b_idx on public.chat_rooms (user_b);

create table public.messages (
  id         bigint generated always as identity primary key,
  room_id    uuid not null references public.chat_rooms (id) on delete cascade,
  sender_id  uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  content    text not null check (char_length(btrim(content)) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index messages_room_created_idx on public.messages (room_id, created_at desc);

-- =====================================================================
-- reports (1순위, FR-43) · blocks (2순위, FR-34)
-- =====================================================================
create table public.reports (
  id          bigint generated always as identity primary key,
  reporter_id uuid default auth.uid() references public.profiles (id) on delete set null,
  reported_id uuid references public.profiles (id) on delete set null,
  reason      text not null check (reason in ('spam', 'offensive', 'other')),
  detail      text check (detail is null or char_length(detail) <= 500),
  room_id     uuid references public.chat_rooms (id) on delete set null,
  created_at  timestamptz not null default now()
);
create index reports_reported_idx on public.reports (reported_id);
create index reports_reporter_idx on public.reports (reporter_id);

create table public.blocks (
  blocker_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);

-- =====================================================================
-- Triggers
-- =====================================================================
create or replace function public.tmeet_touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.tmeet_touch_updated_at();

-- 자기소개가 바뀌면 AI 상태를 되돌림 (FR-26: 앱이 analyze-bio를 다시 호출)
-- 사용자는 AI 태그를 "지우기"만 할 수 있음 (FR-09). 추가는 Edge Function(service_role)만.
create or replace function public.tmeet_profiles_guard() returns trigger
language plpgsql set search_path = '' as $$
begin
  if new.bio is distinct from old.bio then
    new.ai_status := 'none';
  end if;
  if coalesce(auth.role(), '') = 'authenticated' then
    if not (new.ai_interests <@ old.ai_interests) or not (new.ai_meet_types <@ old.ai_meet_types) then
      raise exception 'ai_tags_remove_only' using errcode = 'P0001';
    end if;
  end if;
  return new;
end $$;

create trigger profiles_guard before update on public.profiles
  for each row execute function public.tmeet_profiles_guard();

-- 가입 시 profiles 한 줄 생성 (C-3). 약관 동의 시각 기록 (C-13, FR-40)
-- 앱은 signUp({ options: { data: { terms_agreed: true, age_confirmed: true, app_language: 'ko' } } }) 로 보냄
create or replace function public.tmeet_handle_new_user() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
  insert into public.profiles (id, app_language, terms_agreed_at)
  values (
    new.id,
    case when meta ->> 'app_language' in ('ko', 'en') then meta ->> 'app_language' else 'ko' end,
    case when (meta ->> 'terms_agreed') = 'true' and (meta ->> 'age_confirmed') = 'true' then now() end
  )
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.tmeet_handle_new_user();

-- 메시지가 오면 채팅방의 last_message_at 갱신
create or replace function public.tmeet_touch_room() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.chat_rooms set last_message_at = new.created_at where id = new.room_id;
  return new;
end $$;

create trigger messages_touch_room after insert on public.messages
  for each row execute function public.tmeet_touch_room();
