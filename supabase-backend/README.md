# TMeet 백엔드 / Backend TMeet (Supabase) — C 부이휘황

> **KR** 기획서 v2.0(11/7) 기준 C 담당 작업(C-1 ~ C-17 중 1·2순위)을 Supabase로 구현한 결과물입니다. A·B는 **`src/api/` 함수만 import 해서** 화면에 연결하면 됩니다. 표를 직접 다루지 않아도 됩니다.
>
> **VI** Phần việc của C (C-1 ~ C-17, ưu tiên 1 và 2) theo bản kế hoạch v2.0 (11/7), làm trên Supabase. A và B chỉ cần **import các hàm trong `src/api/`** để nối vào màn hình, không cần đụng trực tiếp vào bảng.

- 프로젝트 / Project: `tmeet` · Seoul (ap-northeast-2) · 무료 플랜 / gói Free
- URL: `https://gcweoxxtsgealkrvjits.supabase.co`
- 앱 키 / Khóa cho app: `.env.example` (공개 키만 / chỉ khóa công khai. 관리자 키·AI 키는 Edge Function Secrets 에만 / khóa quản trị và khóa AI chỉ để ở Edge Function Secrets)

## 1. 팀 저장소에 넣는 방법 / Cách đưa vào repo nhóm

```
supabase-backend/src/lib/supabase.js   →  (팀 repo / repo nhóm) src/lib/supabase.js
supabase-backend/src/api/*             →  (팀 repo / repo nhóm) src/api/
supabase-backend/supabase/*            →  (팀 repo / repo nhóm) supabase/
supabase-backend/.env.example          →  (팀 repo / repo nhóm) .env.example  → 복사해서 .env / sao chép thành .env
```

```bash
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill
```

**KR** DB·함수는 이미 Supabase 프로젝트에 적용돼 있습니다. `supabase/migrations` 는 기록·재현용이며 번호 순서(01 → 04)대로 실행합니다.
**VI** DB và các hàm đã được áp dụng lên project Supabase. `supabase/migrations` để lưu lại và dựng lại khi cần, chạy theo số thứ tự (01 → 04).

| 파일 / File | 내용 / Nội dung |
|---|---|
| `01_core_schema.sql` | 테이블·태그 사전·트리거 / Bảng, từ điển tag, trigger |
| `02_rls_storage.sql` | RLS·권한·사진 저장소 / RLS, quyền, kho ảnh |
| `03_rpc.sql` | 앱이 부르는 서버 함수 / Hàm server app gọi |
| `04_hardening.sql` | 보안 점검 후 보강 / Gia cố sau kiểm tra bảo mật |

## 2. 담당 작업 현황 / Tình trạng công việc

| 번호 / Mã | 할 일 / Việc | 상태 / Trạng thái | 위치 / Ở đâu |
|---|---|---|---|
| C-1 | Supabase 프로젝트 / Project Supabase | ✅ 생성 / Đã tạo. 팀원 초대 / Mời thành viên: Organization > Members | — |
| C-2 | DB·ERD (13장 대조 / đối chiếu chương 13) | ✅ 13장 필드 + `ai_bio_hash`, `ai_analyzed_at`, `created_at/updated_at` | `01_core_schema.sql` · `docs/` |
| C-3 | 로그인 설정 / Cài đặt đăng nhập | ✅ 이메일+비밀번호, 가입 시 profiles 자동 생성 / Email + mật khẩu, tự tạo profiles khi đăng ký | `01` 트리거/trigger · `api/auth.js` |
| C-4 | RLS | ✅ 6개 표 전부, anon 차단 / Cả 6 bảng, chặn anon | `02_rls_storage.sql` |
| C-5 | AI API 선정 / Chọn AI API | ✅ 4장 / mục 4 | — |
| C-6·7 | AI Edge Function·예외 처리 / xử lý lỗi | ✅ 배포됨 / Đã deploy (**API 키만 넣으면 동작 / chỉ cần thêm API key**) | `functions/analyze-bio` |
| C-8 | 주변 여행자 조회 / Tìm người gần | ✅ 10 km · 24시간/giờ · 차단·숨김 제외 / bỏ người chặn, người ẩn | `rpc get_nearby_travelers` |
| C-9 | 파리 가상 데이터 / Dữ liệu giả lập Paris | ✅ 14명/người (하트/trái tim 4 · 기본/thường 8 · 상극/khắc 2) | `seed/demo-paris.sql` |
| C-10 | 연결 요청 + 현지 확인 / Lời mời + kiểm tra ở gần (NFR-20) | ✅ | `rpc send_request / respond_request` |
| C-11 | 채팅방·메시지 / Phòng chat, tin nhắn | ✅ 수락 시 자동 생성 / Tự tạo khi chấp nhận | `rpc get_my_chat_rooms` · `api/chat.js` |
| C-12 | 2순위 데이터 / Dữ liệu ưu tiên 2 | ✅ AI 재분석·위치 숨김·실시간 채팅·차단 / Phân tích lại, ẩn vị trí, chat realtime, chặn | — |
| C-13 | 동의 기록 / Ghi đồng ý | ✅ `terms_agreed_at`, `location_agreed_at` | `rpc agree_terms / agree_location` |
| C-14 | 사진 저장 정책 / Chính sách ảnh | ✅ `avatars/{id}/`, jpg·png, 5 MB | `02_rls_storage.sql` |
| C-15 | 탈퇴 데이터 삭제 / Xóa dữ liệu khi rời app | ✅ | `functions/delete-account` |
| C-16 | 신고 저장 / Lưu báo cáo | ✅ | `reports` · `api/safety.js` |
| C-17 | 미리 보기 / Xem trước (3순위/ưu tiên 3) | ⏸ 시간 여유 시 / Khi còn thời gian | — |

## 3. A·B가 쓰는 함수 / Hàm cho A và B

| 파일 / File | 함수 / Hàm | 화면 / Màn hình | 담당 / Ai dùng |
|---|---|---|---|
| `auth.js` | `signUp({email,password,ageConfirmed,termsAgreed,appLanguage})`, `signIn`, `signOut`, `resendConfirmation`, `onAuthChange` | S02, S03 | A |
| `profile.js` | `getMyProfile`, `getProfile(id)`, `updateMyProfile(fields)`, `analyzeBio()`, `removeAiTag(tag)`, `uploadAvatar(uri, mime)`, `agreeTerms`, `agreeLocation`, `deleteAccount` | O1–O6, M3, P1–P3 | A |
| `travelers.js` | `updateMyLocation(lat,lng,city)`, `getNearbyTravelers({radiusKm, includeDemo})`, `PARIS` | S04, M1, M2 | B |
| `requests.js` | `sendRequest(to, msg)`, `respondRequest(id, accept)` → 채팅방 id / id phòng, `getMyRequests()` → `{received, sent}` | M4, R1 | A, B |
| `chat.js` | `getMyChatRooms`, `getMessages(roomId)`, `sendMessage(roomId, text)`, `subscribeMessages(roomId, cb)` | C1, C2 | B |
| `safety.js` | `reportUser(id, reason)`, `blockUser`, `unblockUser`, `getMyBlocks` | M3, C2 | A, B |
| `errors.js` | `toErrorKey(e)` → `'errors.too_far'` (번역 키 / key dịch) | 모두 / Tất cả | A (문구 / câu chữ) |

**흐름 예시 / Ví dụ luồng**

```js
// 온보딩 마지막 / Cuối onboarding (O5 → O6)
await updateMyProfile({ nickname, interests, style_pace, style_planning, style_budget, meet_types, group_size, languages, tagline, bio });
const ai = await analyzeBio();            // { status: 'done' | 'skipped' | 'failed', result }

// 지도 / Bản đồ (S04 → M1)
await agreeLocation();                    // 위치정보 이용 동의 (1회) / Đồng ý dùng vị trí (1 lần)
await updateMyLocation(coords.latitude, coords.longitude, city);   // 시연 모드면 PARIS / chế độ demo thì dùng PARIS
const people = await getNearbyTravelers({ includeDemo: isDemoMode });
// → A의 matching.js 로 점수 계산 → B가 하트/기본 핀
// → matching.js của A tính điểm → B vẽ pin trái tim / thường
```

**알아둘 규칙 / Quy tắc cần nhớ**

| KR | VI |
|---|---|
| 정확한 좌표는 서버가 받는 즉시 약 1 km 격자 + 사용자별 고정 오프셋으로 바꿉니다 (NFR-01). | Tọa độ chính xác vừa tới server đã bị đổi thành ô ~1 km + offset cố định theo người dùng (NFR-01). |
| `send_request` 는 내 위치가 상대에게서 10 km 안일 때만 됩니다 (NFR-20). 이미 만든 채팅방은 도시를 떠나도 계속 씁니다. | `send_request` chỉ chạy khi tôi cách người kia ≤ 10 km (NFR-20). Phòng chat đã có thì rời thành phố vẫn chat tiếp được. |
| 자기소개를 바꾸면 `ai_status` 가 `none` 이 됩니다 → `analyzeBio()` 다시 호출 (FR-26). 같은 글이면 AI를 다시 부르지 않습니다. | Đổi tự giới thiệu thì `ai_status` về `none` → gọi lại `analyzeBio()` (FR-26). Bài không đổi thì không gọi AI lại. |
| AI 태그는 **지우기만** 가능 (FR-09). 좌표·`is_demo`·AI 결과·동의 시각은 앱에서 직접 못 고칩니다. | Tag AI chỉ được **xóa** (FR-09). Tọa độ, `is_demo`, kết quả AI, thời điểm đồng ý thì app không sửa trực tiếp được. |
| 가상 여행자(`is_demo`)는 `includeDemo: true` 일 때만 보이고 24시간이 지나도 숨겨지지 않습니다. | Người giả lập (`is_demo`) chỉ hiện khi `includeDemo: true` và không bị ẩn sau 24 giờ. |

## 4. AI API 선정 / Chọn AI API (C-5)

**KR** 자기소개 1건 분석 ≈ 입력 700 토큰 + 출력 150 토큰.
**VI** Mỗi lần phân tích ≈ 700 token đầu vào + 150 token đầu ra.

| 모델 / Model | 가격 / Giá (입력/vào · 출력/ra, 100만 토큰 / 1 triệu token) | 1회 / 1 lần | 1,000회 / lần |
|---|---|---|---|
| Claude Haiku 5.5 (`claude-haiku-5-5`) | $0.10 / $0.50 | ≈ $0.00015 | ≈ $0.15 |
| OpenAI gpt-4.1-nano | $0.10 / $0.40 | ≈ $0.00013 | ≈ $0.13 |

**KR** 두 모델 모두 캡스톤 전체 사용량이 1달러 미만. **기본값은 Claude Haiku 5.5**, OpenAI 키만 있으면 자동으로 OpenAI 사용. 대시보드 > Edge Functions > Secrets 에 `ANTHROPIC_API_KEY` (또는 `OPENAI_API_KEY`) 추가. 키가 없으면 `analyzeBio()` 는 `failed / ai_not_configured` 를 돌려주고 선택값만으로 매칭됩니다.
**VI** Cả hai đều tốn chưa tới 1 USD cho cả học kỳ. **Mặc định dùng Claude Haiku 5.5**, nếu chỉ có khóa OpenAI thì tự chuyển sang OpenAI. Thêm `ANTHROPIC_API_KEY` (hoặc `OPENAI_API_KEY`) ở Dashboard → Edge Functions → Secrets. Chưa có khóa thì `analyzeBio()` trả `failed / ai_not_configured` và app ghép bằng lựa chọn onboarding.

## 5. ERD

```
auth.users 1─1 profiles
profiles 1─N connection_requests (from_user, to_user)   ── 대기 중 요청은 쌍당 1개 / mỗi cặp 1 lời mời đang chờ
connection_requests 1─0..1 chat_rooms (request_id)      ── 수락 시 생성 / tạo khi chấp nhận
chat_rooms 1─N messages
profiles 1─N reports (reporter_id, reported_id)
profiles N─N profiles via blocks (blocker_id, blocked_id)
storage: avatars/{user_id}/photo.jpg|png
```

**KR** 자세한 ERD 그림과 컬럼 설명은 `docs/` 의 DB 설명서를 보세요.
**VI** Sơ đồ ERD và giải thích từng cột xem trong tài liệu DB ở thư mục `docs/`.

| 표 / Bảng | RLS (KR) | RLS (VI) |
|---|---|---|
| profiles | 읽기: 나 / 숨김 아닌 사람(차단 제외) / 요청·채팅 상대. 수정: 내 줄, 허용된 칸만 | Đọc: mình / người không ẩn (trừ người chặn nhau) / người đã mời hoặc chat. Sửa: dòng của mình, cột cho phép |
| connection_requests | 당사자만 읽기, 쓰기는 RPC만 | Chỉ hai bên đọc, ghi chỉ qua RPC |
| chat_rooms | 두 사람만 읽기, 생성은 RPC만, 탈퇴 시 해당 칸 null | Chỉ hai người đọc, tạo qua RPC, rời app thì ô đó null |
| messages | 방 두 사람만 읽기·쓰기, 차단·탈퇴 후 쓰기 불가 | Chỉ hai người đọc/gửi, chặn hoặc rời app thì không gửi được |
| reports | 본인 명의로만 쓰기, 내가 쓴 것만 읽기 | Chỉ ghi dưới tên mình, chỉ đọc báo cáo của mình |
| blocks | 내가 한 차단만 보기·추가·해제 | Chỉ xem, thêm, bỏ lượt chặn của mình |

## 6. 검증한 것 / Đã kiểm tra

**KR** 실제 DB에서 2~3명 계정으로 시뮬레이션: 가입 트리거·동의 기록, 남의 좌표/`is_demo` 수정 차단, 동의 전 위치 저장 차단, 잘못된 태그 거부, 좌표 뭉개기 멱등성, 주변 조회(0.8 km 상대, 시연 모드 14명, 반경 3 km), 요청 중복·자기 수락·직접 INSERT 차단, 수락 → 채팅방 → 메시지, 제3자 열람·쓰기 차단, 차단 후 양쪽 모두 사라짐, 비로그인 전면 차단. Supabase Security Advisor 경고 정리 완료.

**VI** Giả lập 2~3 tài khoản trên DB thật: trigger đăng ký và ghi đồng ý, chặn sửa tọa độ/`is_demo`, chặn lưu vị trí khi chưa đồng ý, từ chối tag sai, làm mờ tọa độ ổn định, tìm người gần (người cách 0,8 km, chế độ demo 14 người, bán kính 3 km), chặn lời mời trùng / tự chấp nhận / ghi thẳng vào bảng, chấp nhận → phòng chat → tin nhắn, người ngoài không đọc/ghi được, chặn xong hai bên biến mất khỏi nhau, người chưa đăng nhập bị chặn hoàn toàn. Đã xử lý các cảnh báo của Supabase Security Advisor.

## 7. 남은 설정 / Việc còn lại (Dashboard, 1~2분/phút)

1. **AI 키 등록 / Thêm khóa AI** — 4장 / mục 4.
2. **팀원 초대 / Mời thành viên** — Organization > Members (C-1).
3. **비밀번호 최소 길이 8 / Mật khẩu tối thiểu 8 ký tự** — Authentication > Providers > Email.
4. **인증 메일 / Email xác thực** — **KR** 무료 플랜 기본 메일 서버는 시간당 발송 수가 적으니 시연용 계정은 미리 만들어 둡니다. **VI** Gói Free gửi được rất ít email mỗi giờ, nên tạo sẵn tài khoản demo trước buổi thuyết trình.
