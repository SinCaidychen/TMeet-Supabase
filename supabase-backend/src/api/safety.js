// TMeet · Báo cáo (ưu tiên 1, FR-43) · Chặn (ưu tiên 2, FR-34) / 신고 (1순위) · 차단 (2순위)
// Nút bấm / 버튼: A (M3), B (C2)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// VI: spam · hành vi khó chịu · khác / KR: 스팸 · 불쾌한 행동 · 기타
export const REPORT_REASONS = ['spam', 'offensive', 'other'];

// VI: Báo cáo một người. roomId: truyền vào nếu báo cáo từ trong phòng chat.
// KR: 신고하기. 채팅방에서 신고하면 roomId 도 넘긴다.
export async function reportUser(userId, reason, { detail, roomId } = {}) {
  if (!REPORT_REASONS.includes(reason)) throw new Error('invalid_reason');
  unwrap(await supabase.from('reports').insert({
    reported_id: userId, reason, detail: detail ?? null, room_id: roomId ?? null,
  }));
  return true;
}

// VI: Chặn: hai bên biến mất khỏi bản đồ và hộp lời mời của nhau, không gửi tin trong phòng cũ được nữa.
// KR: 차단하면 서로 지도·요청함에서 사라지고, 채팅방에 더 이상 메시지를 보낼 수 없다.
export async function blockUser(userId) {
  const { error } = await supabase.from('blocks').insert({ blocked_id: userId });
  if (error && error.code !== '23505') throw error; // VI: đã chặn rồi thì bỏ qua / KR: 이미 차단돼 있으면 무시
  return true;
}

// VI: Bỏ chặn / KR: 차단 해제
export async function unblockUser(userId) {
  unwrap(await supabase.from('blocks').delete().eq('blocked_id', userId));
  return true;
}

// VI: Danh sách người tôi đã chặn / KR: 내가 차단한 목록
export async function getMyBlocks() {
  return unwrap(await supabase.from('blocks').select('blocked_id, created_at').order('created_at', { ascending: false }));
}
