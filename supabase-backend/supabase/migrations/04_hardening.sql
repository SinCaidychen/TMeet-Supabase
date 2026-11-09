-- =====================================================================
-- TMeet · 04 · Gia cố bảo mật / 보안 보강
-- VI: Sửa theo kết quả Supabase Security Advisor và Performance Advisor.
-- KR: Supabase Security Advisor · Performance Advisor 결과를 반영한다.
-- =====================================================================

-- VI: (1) Hàm trigger không được gọi qua API (/rest/v1/rpc)
-- KR: (1) 트리거 함수는 API(/rest/v1/rpc)로 부를 수 없게 막음
revoke all on function public.tmeet_handle_new_user()  from public, anon, authenticated;
revoke all on function public.tmeet_touch_room()       from public, anon, authenticated;
revoke all on function public.tmeet_touch_updated_at() from public, anon, authenticated;
revoke all on function public.tmeet_profiles_guard()   from public, anon, authenticated;

-- VI: (2) Hàm kiểm tra chặn / quan hệ chỉ trả lời khi chính mình nằm trong cặp
--     → không ai dò được hai người khác có chặn nhau hay không.
-- KR: (2) 차단·관계 확인 함수는 "내가 포함된 쌍"만 답함 → 남의 차단 여부를 엿볼 수 없음
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

-- VI: (3) Thêm chỉ mục cho khóa ngoại / KR: (3) 외래키 인덱스 추가
create index if not exists messages_sender_idx on public.messages (sender_id);
create index if not exists reports_room_idx on public.reports (room_id);
