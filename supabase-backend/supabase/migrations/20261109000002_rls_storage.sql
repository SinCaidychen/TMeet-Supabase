-- =====================================================================
-- TMeet · 002 RLS · 권한 · 사진 저장소
-- 담당: C (부이휘황) · C-4 (NFR-04), C-14 (NFR-13), C-16 (FR-43)
-- 원칙: 앱(anon/authenticated)은 표를 직접 많이 건드리지 않는다.
--       요청·채팅방 생성 같은 "규칙이 있는 쓰기"는 003의 RPC 함수로만 한다.
-- =====================================================================

-- ---------- RLS 안에서 쓰는 도우미 (security definer: 상대 쪽 차단 행도 확인해야 하므로) ----------
create or replace function public.tmeet_is_blocked(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.blocks
    where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
$$;

create or replace function public.tmeet_has_relation(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
           select 1 from public.connection_requests
           where (from_user = a and to_user = b) or (from_user = b and to_user = a))
      or exists (
           select 1 from public.chat_rooms
           where (user_a = a and user_b = b) or (user_a = b and user_b = a))
$$;

create or replace function public.tmeet_is_room_member(p_room uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chat_rooms
    where id = p_room and (select auth.uid()) in (user_a, user_b))
$$;

-- 보낼 수 있는 방: 내가 멤버, 상대가 탈퇴하지 않음, 서로 차단하지 않음
create or replace function public.tmeet_can_post(p_room uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.chat_rooms r
    where r.id = p_room
      and (select auth.uid()) in (r.user_a, r.user_b)
      and r.user_a is not null and r.user_b is not null
      and not public.tmeet_is_blocked(r.user_a, r.user_b))
$$;

revoke all on function public.tmeet_is_blocked(uuid, uuid)   from public, anon;
revoke all on function public.tmeet_has_relation(uuid, uuid) from public, anon;
revoke all on function public.tmeet_is_room_member(uuid)     from public, anon;
revoke all on function public.tmeet_can_post(uuid)           from public, anon;
grant execute on function public.tmeet_is_blocked(uuid, uuid)   to authenticated;
grant execute on function public.tmeet_has_relation(uuid, uuid) to authenticated;
grant execute on function public.tmeet_is_room_member(uuid)     to authenticated;
grant execute on function public.tmeet_can_post(uuid)           to authenticated;

-- ---------- RLS 켜기 ----------
alter table public.profiles            enable row level security;
alter table public.connection_requests enable row level security;
alter table public.chat_rooms          enable row level security;
alter table public.messages            enable row level security;
alter table public.reports             enable row level security;
alter table public.blocks              enable row level security;

-- ---------- 표 권한 (anon은 아무것도 못 함) ----------
revoke all on public.profiles, public.connection_requests, public.chat_rooms,
              public.messages, public.reports, public.blocks from anon, authenticated;

grant select on public.profiles to authenticated;
-- 사용자가 직접 고칠 수 있는 칸만 열어둠. 좌표·AI 결과·is_demo·동의 시각은 RPC/Edge Function으로만.
grant update (nickname, photo_url, bio, tagline, languages, app_language,
              interests, style_pace, style_planning, style_budget, meet_types, group_size,
              ai_interests, ai_meet_types, is_visible, travel_until)
  on public.profiles to authenticated;

grant select on public.connection_requests to authenticated;
grant select on public.chat_rooms to authenticated;
grant select, insert on public.messages to authenticated;
grant select, insert on public.reports to authenticated;
grant select, insert, delete on public.blocks to authenticated;
grant usage on sequence public.messages_id_seq to authenticated;
grant usage on sequence public.reports_id_seq  to authenticated;

-- ---------- profiles ----------
-- 내 프로필 / 지도에 보이는(숨김 아님) 사람 중 차단 관계가 아닌 사람 / 요청·채팅 상대
create policy profiles_select on public.profiles for select to authenticated
using (
  id = (select auth.uid())
  or (is_visible and not public.tmeet_is_blocked((select auth.uid()), id))
  or public.tmeet_has_relation((select auth.uid()), id)
);

create policy profiles_update_own on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- ---------- connection_requests: 보낸 사람과 받은 사람만 본다. 쓰기는 RPC만 ----------
create policy requests_select_party on public.connection_requests for select to authenticated
using ((select auth.uid()) in (from_user, to_user));

-- ---------- chat_rooms: 두 사람만. 생성은 respond_request RPC만 ----------
create policy rooms_select_member on public.chat_rooms for select to authenticated
using ((select auth.uid()) in (user_a, user_b));

-- ---------- messages: 그 방의 두 사람만 읽고 쓴다 ----------
create policy messages_select_member on public.messages for select to authenticated
using (public.tmeet_is_room_member(room_id));

create policy messages_insert_member on public.messages for insert to authenticated
with check (sender_id = (select auth.uid()) and public.tmeet_can_post(room_id));

-- ---------- reports: 본인 이름으로만 쓰고, 내가 쓴 것만 본다. 관리자 화면 없음 ----------
create policy reports_insert_own on public.reports for insert to authenticated
with check (reporter_id = (select auth.uid()) and reported_id is not null and reported_id <> (select auth.uid()));

create policy reports_select_own on public.reports for select to authenticated
using (reporter_id = (select auth.uid()));

-- ---------- blocks: 내가 한 차단만 보고, 추가하고, 푼다 ----------
create policy blocks_select_own on public.blocks for select to authenticated
using (blocker_id = (select auth.uid()));

create policy blocks_insert_own on public.blocks for insert to authenticated
with check (blocker_id = (select auth.uid()));

create policy blocks_delete_own on public.blocks for delete to authenticated
using (blocker_id = (select auth.uid()));

-- ---------- 실시간 채팅 (2순위, FR-33): messages 변경을 Realtime으로 보냄 (RLS 그대로 적용) ----------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;

-- =====================================================================
-- Storage: avatars/{사용자 id}/photo.jpg — 본인 폴더만 올리고 지움, jpg·png 5 MB 이하
-- =====================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 5242880, array['image/jpeg', 'image/png'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy avatars_select_own on storage.objects for select to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy avatars_insert_own on storage.objects for insert to authenticated
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy avatars_update_own on storage.objects for update to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text)
with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy avatars_delete_own on storage.objects for delete to authenticated
using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
