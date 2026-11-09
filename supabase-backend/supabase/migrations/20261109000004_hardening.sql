-- =====================================================================
-- TMeet · 004 보안 점검 후 보강 (Supabase Security Advisor 결과 반영)
-- 1) 트리거 함수는 API(/rest/v1/rpc)로 부를 수 없게 막음
-- 2) 차단·관계 확인 함수는 "내가 포함된 쌍"만 답함 → 남의 차단 여부를 엿볼 수 없음
-- 3) 외래키 인덱스 추가 (Performance Advisor)
-- =====================================================================
revoke all on function public.tmeet_handle_new_user()  from public, anon, authenticated;
revoke all on function public.tmeet_touch_room()       from public, anon, authenticated;
revoke all on function public.tmeet_touch_updated_at() from public, anon, authenticated;
revoke all on function public.tmeet_profiles_guard()   from public, anon, authenticated;

create or replace function public.tmeet_is_blocked(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select (select auth.uid()) in (a, b)
     and exists (
       select 1 from public.blocks
       where (blocker_id = a and blocked_id = b) or (blocker_id = b and blocked_id = a))
$$;

create or replace function public.tmeet_has_relation(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select (select auth.uid()) in (a, b)
     and (exists (
            select 1 from public.connection_requests
            where (from_user = a and to_user = b) or (from_user = b and to_user = a))
       or exists (
            select 1 from public.chat_rooms
            where (user_a = a and user_b = b) or (user_a = b and user_b = a)))
$$;

create index if not exists messages_sender_idx on public.messages (sender_id);
create index if not exists reports_room_idx on public.reports (room_id);
