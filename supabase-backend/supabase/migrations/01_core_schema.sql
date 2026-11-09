-- =====================================================================
-- TMeet · 01 · Cấu trúc bảng chính / 핵심 테이블 구조
-- Người phụ trách / 담당: C (부이휘황) · C-2, C-3, C-13
--
-- VI: Tạo các bảng theo đúng chương 13 (danh sách trường dữ liệu) của bản kế hoạch,
--     cùng các hàm hỗ trợ và trigger.
-- KR: 기획서 13장(데이터 필드 체크리스트)에 맞춰 테이블, 도우미 함수, 트리거를 만든다.
-- =====================================================================


-- ---------------------------------------------------------------------
-- Từ điển tag / 태그 사전 (기획서 7장)
-- VI: Phải giống hệt src/constants/tags.js của A. Cột nào lưu tag sẽ bị CHECK theo danh sách này.
-- KR: A의 src/constants/tags.js 와 똑같아야 한다. 태그 컬럼은 이 목록으로 CHECK 한다.
-- ---------------------------------------------------------------------

-- VI: 16 sở thích / KR: 관심사 16개
create or replace function public.tmeet_interest_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['museum','cafe','food','market','nightlife','nature','hiking','beach',
               'shopping','photo','history','landmark','local','show','festival','activity']::text[]
$$;

-- VI: 6 hình thức gặp mặt / KR: 만남 형태 6개
create or replace function public.tmeet_meet_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['meal','cafe_chat','sightseeing','night_out','photo_mate','activity_mate']::text[]
$$;

-- VI: Ngôn ngữ giao tiếp được / KR: 대화 가능 언어
create or replace function public.tmeet_language_codes() returns text[]
language sql immutable set search_path = '' as $$
  select array['ko','en','ja','zh','es','fr','de','other']::text[]
$$;


-- ---------------------------------------------------------------------
-- Khoảng cách giữa hai tọa độ (km) / 두 좌표 사이 거리 (km)
-- VI: Công thức haversine, dùng cho tìm người gần và kiểm tra "đang ở gần" (NFR-20).
-- KR: haversine 공식. 주변 조회와 현지 확인(NFR-20)에 사용한다.
-- ---------------------------------------------------------------------
create or replace function public.tmeet_distance_km(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision)
returns double precision
language sql immutable set search_path = '' as $$
  select 2 * 6371 * asin(sqrt(
           power(sin(radians(lat2 - lat1) / 2), 2) +
           cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)))
$$;


-- ---------------------------------------------------------------------
-- Làm mờ tọa độ / 좌표 뭉개기 (기획서 12장, NFR-01)
-- VI: Làm tròn tới 2 chữ số thập phân (ô ~1,1 km) rồi cộng offset cố định theo id người dùng
--     (tối đa ~400 m). Offset cố định để không ai đo nhiều lần rồi lấy trung bình ra vị trí thật.
--     Offset nhỏ hơn nửa ô (0.005) nên làm mờ lại một tọa độ đã mờ vẫn ra đúng giá trị cũ.
-- KR: 소수점 둘째 자리로 반올림(약 1.1 km 격자)하고 사용자 id로 정한 고정 오프셋(최대 약 400 m)을 더한다.
--     오프셋이 고정이라 여러 번 관찰해 평균을 내도 실제 위치를 알 수 없다.
--     오프셋이 반 칸(0.005)보다 작아서 이미 뭉갠 좌표를 다시 넣어도 같은 값이 나온다(멱등).
-- ---------------------------------------------------------------------
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
-- profiles — Hồ sơ người dùng (mỗi người 1 dòng) / 사용자 프로필 (1명당 1줄)
-- =====================================================================
create table public.profiles (
  -- VI: Trùng với id tài khoản đăng nhập / KR: 로그인 계정 id와 같음
  id                  uuid primary key references auth.users (id) on delete cascade,
  -- VI: Biệt danh 2~12 ký tự, ảnh, tự giới thiệu (≤300, đầu vào của AI), giới thiệu 1 dòng (≤40)
  -- KR: 닉네임 2~12자, 사진, 자기소개(≤300, AI 분석 입력), 한 줄 소개(≤40)
  nickname            text check (nickname is null or char_length(nickname) between 2 and 12),
  photo_url           text,
  bio                 text check (bio is null or char_length(bio) <= 300),
  tagline             text check (tagline is null or char_length(tagline) <= 40),
  -- VI: Ngôn ngữ giao tiếp được, ngôn ngữ giao diện app / KR: 대화 가능 언어, 앱 화면 언어
  languages           text[] not null default '{}',
  app_language        text not null default 'ko' check (app_language in ('ko', 'en')),

  -- VI: Lựa chọn lúc onboarding / KR: 온보딩에서 고른 값
  interests           text[] not null default '{}',
  style_pace          smallint check (style_pace between 0 and 2),      -- VI: tốc độ lịch trình / KR: 일정 속도
  style_planning      smallint check (style_planning between 0 and 2),  -- VI: kiểu lên kế hoạch / KR: 계획 성향
  style_budget        smallint check (style_budget between 0 and 2),    -- VI: mức chi tiêu / KR: 예산 감각
  meet_types          text[] not null default '{}',
  group_size          text check (group_size in ('one_on_one', 'small_group', 'any')),

  -- VI: Kết quả AI phân tích tự giới thiệu / KR: AI 자기소개 분석 결과
  ai_interests        text[] not null default '{}',
  ai_meet_types       text[] not null default '{}',
  ai_style            jsonb,          -- {"pace":0|1|2|null,"planning":...,"budget":...}
  ai_keywords         jsonb,          -- {"ko":[...],"en":[...]}
  ai_status           text not null default 'none' check (ai_status in ('none', 'done', 'failed')),
  -- VI: Hash của bài đã phân tích — cùng bài thì không gọi AI lại (tiết kiệm, NFR-06)
  -- KR: 분석한 자기소개의 해시 — 같은 글이면 AI를 다시 부르지 않음 (비용, NFR-06)
  ai_bio_hash         text,
  ai_analyzed_at      timestamptz,

  -- VI: Vị trí đã làm mờ (không bao giờ lưu GPS chính xác) / KR: 뭉갠 위치 (정확한 GPS는 저장하지 않음)
  approx_lat          double precision check (approx_lat between -90 and 90),
  approx_lng          double precision check (approx_lng between -180 and 180),
  city_name           text check (city_name is null or char_length(city_name) <= 80),
  location_updated_at timestamptz,    -- VI: quá 24 giờ thì ẩn khỏi bản đồ / KR: 24시간 지나면 지도에서 숨김
  is_visible          boolean not null default true,   -- VI: ẩn vị trí của tôi / KR: 내 위치 숨기기
  is_demo             boolean not null default false,  -- VI: người giả lập ở Paris / KR: 파리 가상 여행자
  travel_until        date,                            -- VI: ngày kết thúc chuyến đi / KR: 여행 끝나는 날

  -- VI: Thời điểm đồng ý điều khoản và dùng vị trí / KR: 약관·위치정보 이용 동의 시각
  terms_agreed_at     timestamptz,
  location_agreed_at  timestamptz,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),

  -- VI: Chỉ chấp nhận mã tag có trong từ điển / KR: 태그 사전에 있는 코드만 허용
  constraint profiles_interests_valid    check (interests <@ public.tmeet_interest_codes() and cardinality(interests) <= 6),
  constraint profiles_ai_interests_valid check (ai_interests <@ public.tmeet_interest_codes() and cardinality(ai_interests) <= 5),
  constraint profiles_meet_types_valid   check (meet_types <@ public.tmeet_meet_codes()),
  constraint profiles_ai_meet_valid      check (ai_meet_types <@ public.tmeet_meet_codes()),
  constraint profiles_languages_valid    check (languages <@ public.tmeet_language_codes()),
  -- VI: Vĩ độ và kinh độ phải cùng có hoặc cùng trống / KR: 위도·경도는 함께 있거나 함께 비어야 함
  constraint profiles_coords_pair        check ((approx_lat is null) = (approx_lng is null))
);

comment on table public.profiles is 'TMeet 사용자 프로필. 정확한 GPS는 저장하지 않음 (NFR-01).';

-- VI: Chỉ mục cho tìm người gần / KR: 주변 조회용 인덱스
create index profiles_location_idx on public.profiles (approx_lat, approx_lng)
  where approx_lat is not null;


-- =====================================================================
-- connection_requests — Lời mời kết nối / 연결 요청
-- =====================================================================
create table public.connection_requests (
  id           uuid primary key default gen_random_uuid(),
  from_user    uuid not null references public.profiles (id) on delete cascade,  -- VI: người gửi / KR: 보낸 사람
  to_user      uuid not null references public.profiles (id) on delete cascade,  -- VI: người nhận / KR: 받은 사람
  message      text check (message is null or char_length(message) <= 200),     -- VI: lời nhắn kèm / KR: 한마디
  status       text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  constraint connection_requests_not_self check (from_user <> to_user)
);
-- VI: Mỗi cặp chỉ có 1 lời mời đang chờ (FR-19) / KR: 같은 상대에게 대기 중 요청 중복 금지 (FR-19)
create unique index connection_requests_one_pending
  on public.connection_requests (from_user, to_user) where status = 'pending';
create index connection_requests_to_idx on public.connection_requests (to_user, created_at desc);
create index connection_requests_from_idx on public.connection_requests (from_user, created_at desc);


-- =====================================================================
-- chat_rooms — Phòng chat 1-1 / 1:1 채팅방
-- =====================================================================
create table public.chat_rooms (
  id              uuid primary key default gen_random_uuid(),
  -- VI: Ai xóa tài khoản thì ô đó thành null → app hiện "người dùng đã rời"
  -- KR: 탈퇴하면 null → 앱에서 "탈퇴한 사용자"로 표시
  user_a          uuid references public.profiles (id) on delete set null,
  user_b          uuid references public.profiles (id) on delete set null,
  request_id      uuid unique references public.connection_requests (id) on delete set null,
  created_at      timestamptz not null default now(),
  last_message_at timestamptz   -- VI: để sắp xếp danh sách chat / KR: 채팅 목록 정렬용
);
-- VI: Mỗi cặp người chỉ có 1 phòng / KR: 두 사람 쌍마다 방은 하나
create unique index chat_rooms_pair_uniq
  on public.chat_rooms (least(user_a, user_b), greatest(user_a, user_b))
  where user_a is not null and user_b is not null;
create index chat_rooms_user_a_idx on public.chat_rooms (user_a);
create index chat_rooms_user_b_idx on public.chat_rooms (user_b);


-- =====================================================================
-- messages — Tin nhắn / 메시지
-- =====================================================================
create table public.messages (
  id         bigint generated always as identity primary key,
  room_id    uuid not null references public.chat_rooms (id) on delete cascade,
  -- VI: Tự điền là người đang đăng nhập / KR: 로그인한 본인으로 자동 입력
  sender_id  uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  content    text not null check (char_length(btrim(content)) between 1 and 1000),
  created_at timestamptz not null default now()
);
-- VI: Tải nhanh hội thoại của một phòng / KR: 한 방의 대화를 빠르게 불러오기
create index messages_room_created_idx on public.messages (room_id, created_at desc);


-- =====================================================================
-- reports — Báo cáo (ưu tiên 1, FR-43) / 신고 (1순위)
-- blocks  — Chặn (ưu tiên 2, FR-34) / 차단 (2순위)
-- =====================================================================
create table public.reports (
  id          bigint generated always as identity primary key,
  reporter_id uuid default auth.uid() references public.profiles (id) on delete set null,  -- VI: người báo cáo / KR: 신고한 사람
  reported_id uuid references public.profiles (id) on delete set null,                     -- VI: người bị báo cáo / KR: 신고당한 사람
  reason      text not null check (reason in ('spam', 'offensive', 'other')),              -- VI: spam · khó chịu · khác / KR: 스팸 · 불쾌 · 기타
  detail      text check (detail is null or char_length(detail) <= 500),
  room_id     uuid references public.chat_rooms (id) on delete set null,                   -- VI: nếu báo cáo từ phòng chat / KR: 채팅방에서 신고한 경우
  created_at  timestamptz not null default now()
);
create index reports_reported_idx on public.reports (reported_id);
create index reports_reporter_idx on public.reports (reporter_id);

create table public.blocks (
  blocker_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,  -- VI: người chặn / KR: 차단한 사람
  blocked_id uuid not null references public.profiles (id) on delete cascade,                     -- VI: người bị chặn / KR: 차단당한 사람
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);
create index blocks_blocked_idx on public.blocks (blocked_id);


-- =====================================================================
-- Trigger / 트리거
-- =====================================================================

-- VI: Tự cập nhật updated_at mỗi khi sửa hồ sơ / KR: 프로필을 고칠 때마다 updated_at 자동 갱신
create or replace function public.tmeet_touch_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end $$;

create trigger profiles_touch before update on public.profiles
  for each row execute function public.tmeet_touch_updated_at();

-- VI: (1) Đổi tự giới thiệu → ai_status về 'none' để app gọi analyze-bio lại (FR-26).
--     (2) Người dùng chỉ được XÓA tag AI (FR-09). Thêm tag AI chỉ Edge Function (service_role) làm được.
-- KR: (1) 자기소개가 바뀌면 ai_status 를 'none' 으로 → 앱이 analyze-bio 를 다시 호출 (FR-26).
--     (2) 사용자는 AI 태그를 "지우기"만 가능 (FR-09). 추가는 Edge Function(service_role)만.
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

-- VI: Đăng ký xong thì tự tạo 1 dòng profiles (C-3) và ghi thời điểm đồng ý điều khoản (C-13, FR-40).
--     App gửi: signUp({ options: { data: { terms_agreed: true, age_confirmed: true, app_language: 'ko' } } })
-- KR: 가입 시 profiles 한 줄 자동 생성 (C-3), 약관 동의 시각 기록 (C-13, FR-40).
--     앱은 signUp({ options: { data: { terms_agreed: true, age_confirmed: true, app_language: 'ko' } } }) 로 보낸다.
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

-- VI: Có tin nhắn mới thì cập nhật last_message_at của phòng / KR: 메시지가 오면 채팅방의 last_message_at 갱신
create or replace function public.tmeet_touch_room() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  update public.chat_rooms set last_message_at = new.created_at where id = new.room_id;
  return new;
end $$;

create trigger messages_touch_room after insert on public.messages
  for each row execute function public.tmeet_touch_room();
