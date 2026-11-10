-- =====================================================================
-- TMeet · 05 · Chặn thì ẩn luôn hồ sơ / 차단하면 프로필도 숨김 (FR-34)
--
-- VI: Lỗi tìm ra khi test toàn bộ luồng qua mạng (2026-11-10): sau khi B chặn A, A vẫn mở được
--     hồ sơ của B vì hai người đã có phòng chat (quy tắc "đã có lời mời/phòng chat thì xem được").
--     Sửa: chặn nhau thì không xem được hồ sơ của nhau trong mọi trường hợp (trừ hồ sơ của chính mình).
--     Danh sách chat vẫn hiện phòng đó với partner_blocked = true (qua RPC get_my_chat_rooms).
-- KR: 전체 흐름을 네트워크로 테스트하다 발견한 문제 (2026-11-10): B가 A를 차단해도 채팅방이 있으면
--     ("요청·채팅 상대는 볼 수 있음" 규칙 때문에) A가 B의 프로필을 볼 수 있었다.
--     수정: 차단 관계면 어떤 경우에도 서로의 프로필을 볼 수 없다 (내 프로필은 예외).
--     채팅 목록에는 그 방이 partner_blocked = true 로 계속 보인다 (get_my_chat_rooms RPC).
-- =====================================================================
drop policy profiles_select on public.profiles;
create policy profiles_select on public.profiles for select to authenticated
using (
  id = (select auth.uid())                                  -- VI: hồ sơ của mình / KR: 내 프로필
  or (
    not public.tmeet_is_blocked((select auth.uid()), id)    -- VI: không chặn nhau / KR: 차단 관계 아님
    and (is_visible                                         -- VI: không ẩn vị trí / KR: 위치 숨김 아님
         or public.tmeet_has_relation((select auth.uid()), id))  -- VI: hoặc đã mời/đang chat / KR: 또는 요청·채팅 상대
  )
);
