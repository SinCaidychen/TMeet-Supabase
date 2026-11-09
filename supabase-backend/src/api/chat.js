// TMeet · Danh sách chat, tin nhắn / 채팅 목록·메시지
// (FR-21~23, FR-33) — Màn hình / 화면: B (C1, C2)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// VI: C1. partner_deleted = true → hiện "người dùng đã rời"; partner_blocked = true → khóa ô nhập.
// KR: C1. partner_deleted=true 면 "탈퇴한 사용자"로 표시, partner_blocked=true 면 입력창 잠금.
export async function getMyChatRooms() {
  return unwrap(await supabase.rpc('get_my_chat_rooms'));
}

// VI: C2 — 50 tin mới nhất, trả về theo thứ tự cũ → mới. Muốn tải thêm: truyền created_at của tin cũ nhất vào before.
// KR: C2 — 최신 50개 (오래된 → 최신 순으로 돌려줌). 더 불러오기는 before 에 가장 오래된 created_at.
export async function getMessages(roomId, { limit = 50, before } = {}) {
  let q = supabase.from('messages').select('id, room_id, sender_id, content, created_at')
    .eq('room_id', roomId).order('created_at', { ascending: false }).limit(limit);
  if (before) q = q.lt('created_at', before);
  return unwrap(await q).reverse();
}

// VI: Gửi tin (1~1000 ký tự) / KR: 메시지 보내기 (1~1000자)
export async function sendMessage(roomId, content) {
  const text = String(content ?? '').trim();
  if (!text) throw new Error('empty_message');
  return unwrap(await supabase.from('messages').insert({ room_id: roomId, content: text.slice(0, 1000) })
    .select().single());
}

// VI: Chat thời gian thực (ưu tiên 2, FR-33): có tin mới thì gọi onMessage(msg). Gọi hàm trả về để hủy.
// KR: 실시간 채팅 (2순위, FR-33): 새 메시지가 오면 onMessage(msg) 호출. 반환값으로 구독 해제.
export function subscribeMessages(roomId, onMessage) {
  const channel = supabase
    .channel(`room:${roomId}`)
    .on('postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'messages', filter: `room_id=eq.${roomId}` },
      (payload) => onMessage(payload.new))
    .subscribe();
  return () => { supabase.removeChannel(channel); };
}
