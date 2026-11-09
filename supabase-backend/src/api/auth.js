// 로그인·회원가입·이메일 인증 (FR-01, FR-02, FR-39, FR-40) — 화면은 A(S02, S03)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// 가입: 만 18세·약관 체크가 둘 다 true 여야 함. 동의 시각은 서버 트리거가 기록한다.
export async function signUp({ email, password, ageConfirmed, termsAgreed, appLanguage = 'ko' }) {
  if (!ageConfirmed || !termsAgreed) throw new Error('consent_required');
  if (!password || password.length < 8) throw new Error('password_too_short');
  return unwrap(await supabase.auth.signUp({
    email,
    password,
    options: { data: { age_confirmed: true, terms_agreed: true, app_language: appLanguage } },
  }));
  // 결과의 session 이 null 이면 → "인증 메일을 확인하세요" 화면
}

export async function signIn(email, password) {
  return unwrap(await supabase.auth.signInWithPassword({ email, password }));
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

// 인증 메일 재전송 (FR-39)
export async function resendConfirmation(email) {
  return unwrap(await supabase.auth.resend({ type: 'signup', email }));
}

export async function getSession() {
  return unwrap(await supabase.auth.getSession()).session;
}

// 로그인 상태 변화 구독 (AuthContext 에서 사용). 반환값으로 구독 해제
export function onAuthChange(callback) {
  const { data } = supabase.auth.onAuthStateChange((_event, session) => callback(session));
  return () => data.subscription.unsubscribe();
}
