// TMeet · Lời mời kết nối / 연결 요청
// (FR-19, FR-20, NFR-20) — Màn hình / 화면: A (M4), B (R1)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// VI: Gửi lời mời. Các mã lỗi có thể gặp → hiện thông báo bằng toErrorKey():
// KR: 요청 보내기. 나올 수 있는 오류 코드 → toErrorKey() 로 문구 표시:
//   too_far (VI: không ở gần / KR: 현지 아님), location_required, duplicate_pending, incoming_pending,
//   already_connected, blocked, rate_limited (VI: quá 30 lời mời/ngày / KR: 하루 30건 초과)
export async function sendRequest(toUserId, message) {
  return unwrap(await supabase.rpc('send_request', { p_to: toUserId, p_message: message ?? null }));
}

// VI: Chấp nhận → trả về id phòng chat (chuyển thẳng sang C2 được). Từ chối → null.
// KR: 수락하면 채팅방 id 반환 → 바로 C2로 이동 가능. 거절하면 null.
export async function respondRequest(requestId, accept) {
  return unwrap(await supabase.rpc('respond_request', { p_request_id: requestId, p_accept: accept }));
}

// VI: Hộp lời mời R1, tách thành đã nhận / đã gửi
// KR: R1 요청함, 받은 것 / 보낸 것으로 나눔
export async function getMyRequests() {
  const rows = unwrap(await supabase.rpc('get_my_requests'));
  return {
    received: rows.filter((r) => r.direction === 'received'),
    sent: rows.filter((r) => r.direction === 'sent'),
  };
}
