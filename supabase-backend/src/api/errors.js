// 서버 오류 코드 → 번역 키 (A의 locales/ko.json, en.json 에 'errors.<코드>' 로 문구 추가)
// 사용: catch (e) { Alert.alert(t(toErrorKey(e))) }
const KNOWN = new Set([
  'not_authenticated', 'profile_incomplete', 'invalid_target', 'target_not_found', 'blocked',
  'location_required', 'location_consent_required', 'invalid_coordinates', 'too_far',
  'already_connected', 'duplicate_pending', 'incoming_pending', 'rate_limited', 'message_too_long',
  'request_not_found', 'already_responded', 'ai_tags_remove_only',
]);

export function toErrorKey(error) {
  const msg = String(error?.message || error || '');
  for (const code of KNOWN) if (msg.includes(code)) return `errors.${code}`;
  if (msg.includes('Email not confirmed')) return 'errors.email_not_confirmed';
  if (msg.includes('Invalid login credentials')) return 'errors.invalid_login';
  if (msg.includes('User already registered')) return 'errors.email_taken';
  if (msg.includes('violates check constraint')) return 'errors.invalid_input';
  if (msg.includes('row-level security')) return 'errors.not_allowed';
  return 'errors.unknown';
}

// supabase 호출 결과에서 error 가 있으면 throw, 아니면 data 반환
export function unwrap({ data, error }) {
  if (error) throw error;
  return data;
}
