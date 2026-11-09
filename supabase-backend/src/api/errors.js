// TMeet · Mã lỗi server → key dịch / 서버 오류 코드 → 번역 키
//
// VI: A thêm câu thông báo cho từng key 'errors.<mã>' vào locales/ko.json và en.json.
// KR: A의 locales/ko.json, en.json 에 'errors.<코드>' 로 문구를 추가한다.
//
// VI: Cách dùng / KR: 사용법
//   catch (e) { Alert.alert(t(toErrorKey(e))) }
const KNOWN = new Set([
  'not_authenticated', 'profile_incomplete', 'invalid_target', 'target_not_found', 'blocked',
  'location_required', 'location_consent_required', 'invalid_coordinates', 'too_far',
  'already_connected', 'duplicate_pending', 'incoming_pending', 'rate_limited', 'message_too_long',
  'request_not_found', 'already_responded', 'ai_tags_remove_only',
]);

export function toErrorKey(error) {
  const msg = String(error?.message || error || '');
  // VI: Mã lỗi do hàm RPC của mình trả về / KR: 우리 RPC 함수가 돌려주는 코드
  for (const code of KNOWN) if (msg.includes(code)) return `errors.${code}`;
  // VI: Lỗi của Supabase Auth / KR: Supabase Auth 오류
  if (msg.includes('Email not confirmed')) return 'errors.email_not_confirmed';
  if (msg.includes('Invalid login credentials')) return 'errors.invalid_login';
  if (msg.includes('User already registered')) return 'errors.email_taken';
  // VI: Lỗi chung của DB / KR: DB 공통 오류
  if (msg.includes('violates check constraint')) return 'errors.invalid_input';
  if (msg.includes('row-level security')) return 'errors.not_allowed';
  return 'errors.unknown';
}

// VI: Kết quả gọi supabase có error thì ném lỗi, không thì trả về data
// KR: supabase 호출 결과에서 error 가 있으면 throw, 아니면 data 반환
export function unwrap({ data, error }) {
  if (error) throw error;
  return data;
}
