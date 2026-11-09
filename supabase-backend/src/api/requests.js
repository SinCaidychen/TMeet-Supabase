// 연결 요청 (FR-19, FR-20, NFR-20) — 화면은 A(M4), B(R1)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// 오류 코드: too_far(현지 아님), location_required, duplicate_pending, incoming_pending,
//            already_connected, blocked, rate_limited(하루 30건) → toErrorKey()로 문구 표시
export async function sendRequest(toUserId, message) {
  return unwrap(await supabase.rpc('send_request', { p_to: toUserId, p_message: message ?? null }));
}

// 수락하면 채팅방 id 반환 → 바로 C2로 이동 가능. 거절하면 null
export async function respondRequest(requestId, accept) {
  return unwrap(await supabase.rpc('respond_request', { p_request_id: requestId, p_accept: accept }));
}

// R1 요청함: direction 이 'received' | 'sent' 로 나뉘어 있음
export async function getMyRequests() {
  const rows = unwrap(await supabase.rpc('get_my_requests'));
  return {
    received: rows.filter((r) => r.direction === 'received'),
    sent: rows.filter((r) => r.direction === 'sent'),
  };
}
