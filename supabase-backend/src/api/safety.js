// 신고 (FR-43, 1순위) · 차단 (FR-34, 2순위) — 버튼은 A(M3), B(C2)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

export const REPORT_REASONS = ['spam', 'offensive', 'other']; // 스팸 · 불쾌한 행동 · 기타

export async function reportUser(userId, reason, { detail, roomId } = {}) {
  if (!REPORT_REASONS.includes(reason)) throw new Error('invalid_reason');
  unwrap(await supabase.from('reports').insert({
    reported_id: userId, reason, detail: detail ?? null, room_id: roomId ?? null,
  }));
  return true;
}

// 차단하면 서로 지도·요청함에서 사라지고, 채팅방에 더 이상 메시지를 보낼 수 없다
export async function blockUser(userId) {
  const { error } = await supabase.from('blocks').insert({ blocked_id: userId });
  if (error && error.code !== '23505') throw error; // 이미 차단돼 있으면 무시
  return true;
}

export async function unblockUser(userId) {
  unwrap(await supabase.from('blocks').delete().eq('blocked_id', userId));
  return true;
}

export async function getMyBlocks() {
  return unwrap(await supabase.from('blocks').select('blocked_id, created_at').order('created_at', { ascending: false }));
}
