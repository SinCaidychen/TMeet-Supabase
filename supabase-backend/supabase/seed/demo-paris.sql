-- =====================================================================
-- TMeet · Người du lịch giả lập ở Paris / 파리 가상 여행자 (FR-24 시연 모드, 기획서 6-4) · C-9
--
-- VI: 14 người giả lập cho chế độ demo. Khi B (바야르) làm xong data/demo-paris.json có thể thay
--     nội dung bằng dữ liệu đó, giữ nguyên cấu trúc.
-- KR: 시연 모드용 가상 여행자 14명. B(바야르)의 data/demo-paris.json 이 나오면 그 값으로 바꿔도 된다. 구조는 그대로.
--
-- VI: Cách chạy: dán vào Supabase Dashboard → SQL Editor → Run (chạy nhiều lần cũng không bị trùng).
-- KR: 실행: Supabase 대시보드 SQL Editor 에 붙여넣고 Run (여러 번 실행해도 중복되지 않음).
--
-- VI: Tài khoản giả lập không đăng nhập được (không có mật khẩu). Vì is_demo = true nên chỉ hiện trên bản đồ
--     khi bật chế độ demo: get_nearby_travelers(p_include_demo => true).
-- KR: 가상 여행자는 로그인할 수 없는 계정이다(비밀번호 없음). is_demo = true 라서
--     시연 모드(get_nearby_travelers(p_include_demo => true))에서만 지도에 보인다.
--
-- VI: Điểm dưới đây tính theo hồ sơ "tôi" ở ví dụ 9-5 (trái tim 4 · thường 8 · khắc 2).
-- KR: 아래 점수는 기획서 9-5의 "나" 프로필 기준 계산값 (하트 4 · 기본 8 · 상극 2).
--   Alex: 88%
--   수아: 95%
--   Léa: 97%
--   Daniel: 67%
--   Yuki: 51%
--   민준: 52%
--   Sofia: 28%
--   Tom: 18%
--   지은: 46%
--   Marco: 47%
--   Chloé: 49%
--   Ben: 8%
--   Ryan: 8%
--   Hana: 93%
-- =====================================================================
begin;

-- VI: Tạo 14 tài khoản giả lập (trigger tự tạo profiles) / KR: 가상 계정 14개 생성 (트리거가 profiles 자동 생성)

insert into auth.users (id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data, email_confirmed_at, created_at, updated_at)
values
  ('d0000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo01@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo02@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo03@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo04@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo05@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo06@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo07@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo08@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo09@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000010', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo10@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000011', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo11@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000012', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo12@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000013', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo13@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now()),
  ('d0000000-0000-4000-8000-000000000014', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'demo14@demo.tmeet', '{"provider":"email","providers":["email"],"is_demo":true}', '{}', now(), now(), now())
on conflict (id) do nothing;

-- VI: Điền hồ sơ, tag, vị trí đã làm mờ quanh Paris / KR: 프로필·태그·파리 주변 뭉갠 위치 입력
with demo (id, nickname, app_language, tagline, bio, languages, interests, ai_interests,
           style_pace, style_planning, style_budget, ai_style, meet_types, group_size, ai_keywords, lat, lng) as (
  values
  ('d0000000-0000-4000-8000-000000000001'::uuid, 'Alex', 'en', 'Museums by day, cafés by night', 'I love slow mornings in local cafés and wandering small galleries. Hidden neighborhoods over landmarks.', array['en','fr']::text[], array['museum','cafe','food']::text[], array['museum','local']::text[], 0, 2, 1, null, array['cafe_chat','meal','sightseeing']::text[], 'small_group', '{"ko":["현지 카페","미술관 산책"],"en":["local cafés","gallery walks"]}'::jsonb, 48.8606, 2.3422),
  ('d0000000-0000-4000-8000-000000000002'::uuid, '수아', 'ko', '카페 투어하면서 사진 찍어요', '파리 골목 카페를 천천히 돌면서 필름 카메라로 사진 찍는 걸 좋아해요. 미술관도 하루 하나씩!', array['ko','en']::text[], array['cafe','photo','museum']::text[], array['cafe','photo','local']::text[], 0, 1, 1, '{"pace":0,"planning":null,"budget":null}'::jsonb, array['cafe_chat','photo_mate']::text[], 'small_group', '{"ko":["필름 사진","골목 카페"],"en":["film photos","alley cafés"]}'::jsonb, 48.8486, 2.3582),
  ('d0000000-0000-4000-8000-000000000003'::uuid, 'Léa', 'en', 'Art lover, slow traveler', 'Musée d’Orsay twice already. Happy to share a coffee and swap photo spots.', array['en','fr','es']::text[], array['museum','cafe','history','photo']::text[], array['museum','history']::text[], 0, 1, 1, null, array['cafe_chat','sightseeing','photo_mate']::text[], 'any', '{"ko":["미술 애호가","느린 여행"],"en":["art lover","slow travel"]}'::jsonb, 48.8686, 2.3562),
  ('d0000000-0000-4000-8000-000000000004'::uuid, 'Daniel', 'en', 'Coffee & architecture nerd', 'Spending a week walking Paris neighborhoods, tasting coffee and reading about old buildings.', array['en','de']::text[], array['cafe','history','local']::text[], array['cafe','history','local']::text[], 0, 2, 1, null, array['cafe_chat','sightseeing']::text[], 'one_on_one', '{"ko":["건축 산책","커피 투어"],"en":["architecture","coffee tour"]}'::jsonb, 48.8416, 2.3402),
  ('d0000000-0000-4000-8000-000000000005'::uuid, 'Yuki', 'en', 'Markets and street food!', 'Looking for people to explore markets and try local food together. Bit of photography too.', array['ja','en']::text[], array['food','market','photo']::text[], array['food','market']::text[], 1, 1, 0, null, array['meal','photo_mate']::text[], 'small_group', '{"ko":["시장 구경","길거리 음식"],"en":["markets","street food"]}'::jsonb, 48.8766, 2.3502),
  ('d0000000-0000-4000-8000-000000000006'::uuid, '민준', 'ko', '랜드마크 다 보고 갈 거예요', '에펠탑, 개선문, 몽마르트까지 일정 꽉 채워서 돌아다녀요. 같이 사진 찍어줄 분!', array['ko','en']::text[], array['landmark','photo','history']::text[], array['landmark','photo']::text[], 2, 0, 1, '{"pace":2,"planning":0,"budget":null}'::jsonb, array['sightseeing','photo_mate']::text[], 'any', '{"ko":["랜드마크 정복","인생샷"],"en":["landmarks","photo spots"]}'::jsonb, 48.8526, 2.3702),
  ('d0000000-0000-4000-8000-000000000007'::uuid, 'Sofia', 'en', 'Concerts and late dinners', 'In Paris for a jazz festival. Love dinner with new people, then a show.', array['es','en']::text[], array['show','food','festival']::text[], array['show','nightlife']::text[], 1, 2, 2, null, array['meal','night_out']::text[], 'small_group', '{"ko":["재즈 공연","늦은 저녁"],"en":["jazz shows","late dinners"]}'::jsonb, 48.8816, 2.3672),
  ('d0000000-0000-4000-8000-000000000008'::uuid, 'Tom', 'en', 'Parks, runs and picnics', 'Morning runs along the Seine, afternoons in parks. Open to a picnic or a casual walk.', array['en']::text[], array['nature','activity','food']::text[], array['nature','activity']::text[], 1, 1, 0, null, array['meal','activity_mate']::text[], 'one_on_one', '{"ko":["센강 러닝","공원 피크닉"],"en":["Seine runs","picnics"]}'::jsonb, 48.8346, 2.3482),
  ('d0000000-0000-4000-8000-000000000009'::uuid, '지은', 'ko', '쇼핑 & 맛집 탐방', '쇼핑하다가 맛집 찾아다니는 여행 중이에요. 저녁에 같이 밥 먹어요!', array['ko']::text[], array['shopping','food','cafe']::text[], array['shopping','food']::text[], 1, 0, 2, null, array['meal','cafe_chat']::text[], 'any', '{"ko":["쇼핑","맛집 탐방"],"en":["shopping","food hunt"]}'::jsonb, 48.8626, 2.3282),
  ('d0000000-0000-4000-8000-000000000010'::uuid, 'Marco', 'en', 'History buff on a budget', 'Backpacking Europe cheaply. Free museums, old churches, long walks.', array['en','es']::text[], array['history','museum','landmark']::text[], array['history','museum']::text[], 1, 0, 0, null, array['sightseeing']::text[], 'small_group', '{"ko":["역사 탐방","가성비 여행"],"en":["history","budget trip"]}'::jsonb, 48.8266, 2.3622),
  ('d0000000-0000-4000-8000-000000000011'::uuid, 'Chloé', 'en', 'Festival hopper', 'Here for events and concerts. Spontaneous plans only!', array['fr','en']::text[], array['festival','show','local']::text[], array['festival','show']::text[], 1, 2, 1, null, array['night_out','sightseeing']::text[], 'any', '{"ko":["축제","즉흥 여행"],"en":["festivals","spontaneous"]}'::jsonb, 48.8726, 2.3782),
  ('d0000000-0000-4000-8000-000000000012'::uuid, 'Ben', 'en', 'Beer, bars and big nights', 'Out every night trying bars. Packed days, no plans, big spending.', array['en']::text[], array['nightlife','shopping','activity']::text[], array['nightlife','shopping']::text[], 2, 0, 2, '{"pace":2,"planning":0,"budget":2}'::jsonb, array['night_out','activity_mate']::text[], 'one_on_one', '{"ko":["바 투어","나이트라이프"],"en":["bar hopping","nightlife"]}'::jsonb, 48.8466, 2.3222),
  ('d0000000-0000-4000-8000-000000000013'::uuid, 'Ryan', 'en', 'Shopping marathon', 'Three days, every outlet and mall. Tight schedule planned to the minute.', array['en','zh']::text[], array['shopping','nightlife']::text[], array['shopping']::text[], 2, 0, 2, null, array['night_out']::text[], 'one_on_one', '{"ko":["쇼핑 마라톤","계획형"],"en":["shopping run","planner"]}'::jsonb, 48.8866, 2.3342),
  ('d0000000-0000-4000-8000-000000000014'::uuid, 'Hana', 'en', 'Photo walks & quiet cafés', 'Exchange student visiting Paris. I like calm cafés, small museums and taking photos of streets.', array['ja','ko','en']::text[], array['photo','cafe','local']::text[], array['photo','cafe','museum']::text[], 0, 1, 0, null, array['cafe_chat','photo_mate','sightseeing']::text[], 'small_group', '{"ko":["거리 사진","조용한 카페"],"en":["street photos","quiet cafés"]}'::jsonb, 48.8386, 2.3762)
)
update public.profiles p
   set nickname = d.nickname, app_language = d.app_language, tagline = d.tagline, bio = d.bio,
       languages = d.languages, interests = d.interests,
       style_pace = d.style_pace, style_planning = d.style_planning, style_budget = d.style_budget,
       meet_types = d.meet_types, group_size = d.group_size,
       ai_interests = d.ai_interests, ai_meet_types = '{}', ai_style = d.ai_style, ai_keywords = d.ai_keywords,
       ai_status = 'done', ai_analyzed_at = now(),
       approx_lat = (public.tmeet_fuzz_coord(d.id, d.lat, d.lng)).lat,
       approx_lng = (public.tmeet_fuzz_coord(d.id, d.lat, d.lng)).lng,
       city_name = 'Paris', location_updated_at = now(),
       is_demo = true, is_visible = true,
       terms_agreed_at = coalesce(p.terms_agreed_at, now()), location_agreed_at = coalesce(p.location_agreed_at, now())
  from demo d
 where p.id = d.id;

commit;

-- VI: Kiểm tra / KR: 확인:
--   select nickname, interests, approx_lat, approx_lng from public.profiles where is_demo order by nickname;
-- VI: Xóa dữ liệu giả lập / KR: 지우기:
--   delete from auth.users where id::text like 'd0000000-0000-4000-8000-%';
