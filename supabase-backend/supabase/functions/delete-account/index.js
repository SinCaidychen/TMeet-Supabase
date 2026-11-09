// =====================================================================
// TMeet · Edge Function: delete-account  (FR-42, NFR-16 · 2순위)
// 담당: C (부이휘황) · C-15
//
// 앱 호출:  await supabase.functions.invoke('delete-account', { body: { confirm: true } })
// 동작:     프로필 사진(avatars/{id}/*) 삭제 → auth 사용자 삭제.
//           DB는 외래키로 함께 정리된다: profiles · 요청 · 보낸 메시지 · 차단 삭제,
//           상대 채팅방의 내 자리는 null → 앱에서 "탈퇴한 사용자"로 표시.
// =====================================================================
import { createClient } from 'jsr:@supabase/supabase-js@2';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};
const json = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...CORS, 'Content-Type': 'application/json' } });

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const admin = createClient(
    Deno.env.get('SUPABASE_URL'),
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  const token = (req.headers.get('Authorization') || '').replace(/^Bearer\s+/i, '');
  const { data: userData, error: authError } = await admin.auth.getUser(token);
  if (authError || !userData?.user) return json({ error: 'not_authenticated' }, 401);
  const userId = userData.user.id;

  let body = {};
  try { body = await req.json(); } catch { /* 비어 있으면 아래에서 거절 */ }
  if (body?.confirm !== true) return json({ error: 'confirm_required' }, 400);

  // 1) 사진 삭제
  const { data: files } = await admin.storage.from('avatars').list(userId, { limit: 100 });
  if (files?.length) {
    await admin.storage.from('avatars').remove(files.map((f) => `${userId}/${f.name}`));
  }

  // 2) 계정 삭제 (profiles 이하 데이터는 DB 외래키로 함께 삭제)
  const { error } = await admin.auth.admin.deleteUser(userId);
  if (error) {
    console.error('delete-account error', error);
    return json({ error: 'delete_failed' }, 500);
  }
  return json({ deleted: true });
});
