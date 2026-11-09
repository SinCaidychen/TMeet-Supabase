// TMeet · Lưu vị trí, tìm người gần / 위치 저장·주변 여행자 조회
// (FR-13, FR-14, FR-24) — Màn hình và xử lý tọa độ / 화면·좌표 처리: B (src/lib/location.js)
import { supabase } from '../lib/supabase';
import { unwrap } from './errors';

// VI: B có thể truyền thẳng tọa độ lấy từ expo-location. Server tự làm tròn 2 chữ số + offset cố định
//     theo người dùng rồi mới lưu (NFR-01). Phải gọi agreeLocation() một lần trước đó.
//     Trả về: { approx_lat, approx_lng, city_name, location_updated_at }
// KR: B가 expo-location 으로 얻은 좌표를 그대로 넘겨도 된다. 서버가 소수점 둘째 자리 + 사용자별
//     고정 오프셋으로 뭉갠 뒤 저장한다 (NFR-01). 먼저 agreeLocation() 이 한 번 호출돼 있어야 한다.
//     반환: { approx_lat, approx_lng, city_name, location_updated_at }
export async function updateMyLocation(lat, lng, cityName) {
  const rows = unwrap(await supabase.rpc('update_my_location', { p_lat: lat, p_lng: lng, p_city: cityName ?? null }));
  return rows?.[0] ?? null;
}

// VI: Chế độ demo (FR-24): lưu vị trí bằng tọa độ Paris này rồi tìm với includeDemo = true
// KR: 시연 모드(FR-24): 이 파리 좌표로 위치를 저장하고 includeDemo = true 로 조회
export const PARIS = { lat: 48.8566, lng: 2.3522, city: 'Paris' };

// VI: Trong bán kính 1~10 km (mặc định 10), cập nhật trong 24 giờ, bỏ bản thân / người chặn nhau / người ẩn.
//     Sắp xếp gần → xa. Mỗi người có đủ trường cho matching.js của A:
// KR: 반경(1~10 km, 기본 10) 안, 24시간 안 갱신, 본인·차단·숨김 제외. 가까운 순.
//     각 항목에 A의 matching.js 가 쓰는 필드가 모두 들어 있다:
//   interests, ai_interests, style_pace/planning/budget, ai_style, meet_types, ai_meet_types, group_size, languages
export async function getNearbyTravelers({ radiusKm = 10, includeDemo = false } = {}) {
  return unwrap(await supabase.rpc('get_nearby_travelers', { p_radius_km: radiusKm, p_include_demo: includeDemo }));
}
