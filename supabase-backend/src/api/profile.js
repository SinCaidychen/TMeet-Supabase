// 프로필·온보딩·AI 분석·사진·동의·탈퇴 (FR-03~11, 26, 27, 40~42) — 화면은 A
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

async function myId() {
  const { data } = await supabase.auth.getUser();
  if (!data?.user) throw new Error('not_authenticated');
  return data.user.id;
}

export async function getMyProfile() {
  const id = await myId();
  return unwrap(await supabase.from('profiles').select('*').eq('id', id).single());
}

// 상세 프로필(M3)용: 다른 사람 프로필 (차단 관계면 null)
export async function getProfile(userId) {
  return unwrap(await supabase.from('profiles')
    .select('id, nickname, photo_url, tagline, bio, languages, interests, style_pace, style_planning, style_budget, meet_types, group_size, ai_interests, ai_meet_types, ai_style, ai_keywords, city_name, travel_until, is_demo')
    .eq('id', userId).maybeSingle());
}

// 온보딩 저장·프로필 수정. 고칠 수 있는 칸:
// nickname, photo_url, bio, tagline, languages, app_language, interests, style_pace, style_planning,
// style_budget, meet_types, group_size, is_visible, travel_until
// bio 가 바뀌면 서버가 ai_status 를 'none' 으로 되돌리므로, 저장 후 analyzeBio() 를 부른다 (FR-26)
export async function updateMyProfile(fields) {
  const id = await myId();
  return unwrap(await supabase.from('profiles').update(fields).eq('id', id).select().single());
}

// AI 자기소개 분석 (FR-08). 결과: { status: 'done'|'cached'|'skipped'|'failed', reason?, result? }
// 'failed' 면 O6 화면에 "다시 시도" 버튼, 그래도 매칭은 선택값만으로 동작 (FR-10)
export async function analyzeBio() {
  return unwrap(await supabase.functions.invoke('analyze-bio', { body: {} }));
}

// O6: 틀린 AI 태그 지우기 (FR-09). 추가는 막혀 있음
export async function removeAiTag(tag) {
  const p = await getMyProfile();
  return updateMyProfile({
    ai_interests: p.ai_interests.filter((t) => t !== tag),
    ai_meet_types: p.ai_meet_types.filter((t) => t !== tag),
  });
}

// 프로필 사진 업로드 (NFR-13: jpg·png, 5MB 이하, avatars/{내 id}/photo.jpg)
// uri: expo-image-picker 결과의 assets[0].uri, mimeType: assets[0].mimeType
export async function uploadAvatar(uri, mimeType = 'image/jpeg') {
  if (!['image/jpeg', 'image/png'].includes(mimeType)) throw new Error('invalid_image_type');
  const id = await myId();
  const ext = mimeType === 'image/png' ? 'png' : 'jpg';
  const path = `${id}/photo.${ext}`;
  const body = await (await fetch(uri)).arrayBuffer();
  if (body.byteLength > 5 * 1024 * 1024) throw new Error('image_too_large');
  unwrap(await supabase.storage.from('avatars').upload(path, body, { contentType: mimeType, upsert: true }));
  const { data } = supabase.storage.from('avatars').getPublicUrl(path);
  const photo_url = `${data.publicUrl}?v=${Date.now()}`; // 캐시 무효화
  await updateMyProfile({ photo_url });
  return photo_url;
}

// 동의 기록 (FR-40, FR-41). 가입 때 약관 동의가 기록되지 않았으면 agreeTerms() 호출
export async function agreeTerms() {
  return unwrap(await supabase.rpc('agree_terms'));
}
export async function agreeLocation() {
  return unwrap(await supabase.rpc('agree_location'));
}

// 회원 탈퇴 (FR-42) — 확인 창을 거친 뒤 호출. 성공하면 signOut 처리
export async function deleteAccount() {
  const res = unwrap(await supabase.functions.invoke('delete-account', { body: { confirm: true } }));
  await supabase.auth.signOut();
  return res;
}
