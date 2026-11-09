// TMeet · Đăng nhập, đăng ký, xác thực email / 로그인·회원가입·이메일 인증
// (FR-01, FR-02, FR-39, FR-40) — Màn hình / 화면: A (S02, S03)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// VI: Đăng ký. Ô "đủ 18 tuổi" và "đồng ý điều khoản" đều phải true.
//     Thời điểm đồng ý do trigger trên server ghi lại.
//     Nếu kết quả có session = null → chuyển sang màn hình "Hãy kiểm tra email xác thực".
// KR: 가입. 만 18세·약관 체크가 둘 다 true 여야 한다. 동의 시각은 서버 트리거가 기록한다.
//     결과의 session 이 null 이면 → "인증 메일을 확인하세요" 화면.
export async function signUp({ email, password, ageConfirmed, termsAgreed, appLanguage = 'ko' }) {
  if (!ageConfirmed || !termsAgreed) throw new Error('consent_required');
  if (!password || password.length < 8) throw new Error('password_too_short');
  return unwrap(await supabase.auth.signUp({
    email,
    password,
    options: { data: { age_confirmed: true, terms_agreed: true, app_language: appLanguage } },
  }));
}

// VI: Đăng nhập / KR: 로그인
export async function signIn(email, password) {
  return unwrap(await supabase.auth.signInWithPassword({ email, password }));
}

// VI: Đăng xuất / KR: 로그아웃
export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

// VI: Gửi lại email xác thực (FR-39) / KR: 인증 메일 재전송
export async function resendConfirmation(email) {
  return unwrap(await supabase.auth.resend({ type: 'signup', email }));
}

// VI: Phiên đăng nhập hiện tại (null nếu chưa đăng nhập) / KR: 현재 로그인 세션 (없으면 null)
export async function getSession() {
  return unwrap(await supabase.auth.getSession()).session;
}

// VI: Theo dõi thay đổi đăng nhập (dùng trong AuthContext). Gọi hàm trả về để hủy theo dõi.
// KR: 로그인 상태 변화 구독 (AuthContext 에서 사용). 반환값으로 구독 해제.
export function onAuthChange(callback) {
  const { data } = supabase.auth.onAuthStateChange((_event, session) => callback(session));
  return () => data.subscription.unsubscribe();
}
