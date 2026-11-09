// TMeet · Kết nối Supabase / Supabase 접속 설정 (C 담당: src/lib/supabase.js)
//
// VI: Cài đặt thư viện / KR: 설치
//   npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill
//
// VI: Hai giá trị dưới đây đọc từ file .env (xem .env.example). Đây là khóa công khai, có RLS bảo vệ.
// KR: 아래 두 값은 .env 파일에서 읽는다 (.env.example 참고). 공개 키이며 RLS로 보호된다.
import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import { AppState } from 'react-native';

const url = process.env.EXPO_PUBLIC_SUPABASE_URL;
const key = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;
if (!url || !key) {
  throw new Error('EXPO_PUBLIC_SUPABASE_URL / EXPO_PUBLIC_SUPABASE_ANON_KEY 가 .env 에 없습니다. (Thiếu trong file .env)');
}

export const supabase = createClient(url, key, {
  auth: {
    storage: AsyncStorage,       // VI: mở lại app vẫn giữ đăng nhập / KR: 앱을 다시 열어도 로그인 유지 (FR-02)
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

// VI: Chỉ tự làm mới token khi app đang mở ở phía trước
// KR: 앱이 앞에 있을 때만 토큰 자동 갱신
AppState.addEventListener('change', (state) => {
  if (state === 'active') supabase.auth.startAutoRefresh();
  else supabase.auth.stopAutoRefresh();
});
