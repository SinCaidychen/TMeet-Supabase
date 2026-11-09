# TMeet 백엔드 (Supabase) — C 부이휘황

기획서 v2.0(11/7) 기준 C 담당 작업(C-1 ~ C-17 중 1·2순위)을 Supabase로 구현한 결과물입니다.
A·B는 **`src/api/` 함수만 import 해서** 화면에 연결하면 됩니다. 표를 직접 다루지 않아도 됩니다.

- 프로젝트: `tmeet` · 리전 Seoul(ap-northeast-2) · 무료 플랜
- URL: `https://gcweoxxtsgealkrvjits.supabase.co`
- 앱 키: `.env.example` 참고 (공개 키만. 관리자 키·AI 키는 Edge Function Secrets 에만)

## 1. 팀 저장소에 넣는 방법

```
supabase-backend/src/lib/supabase.js   →  (팀 repo) src/lib/supabase.js
supabase-backend/src/api/*             →  (팀 repo) src/api/
supabase-backend/supabase/*            →  (팀 repo) supabase/
supabase-backend/.env.example          →  (팀 repo) .env.example  (복사해서 .env 로, .gitignore 에 .env 확인)
```

```bash
npx expo install @supabase/supabase-js @react-native-async-storage/async-storage react-native-url-polyfill
```

DB·함수는 이미 Supabase 프로젝트에 적용돼 있습니다. `supabase/migrations` 는 기록·재현용입니다.

## 2. 담당 작업 현황

| 번호 | 할 일 | 상태 | 위치 |
|---|---|---|---|
| C-1 | Supabase 프로젝트 | ✅ 생성. **팀원 초대는 대시보드 > Organization > Members** | — |
| C-2 | DB·ERD (13장 대조) | ✅ 13장 필드 그대로 + `ai_bio_hash`, `ai_analyzed_at`, `created_at/updated_at` 추가 | `migrations/…0001` |
| C-3 | 로그인 설정 | ✅ 이메일+비밀번호, 가입 시 profiles 자동 생성 | `0001` 트리거 · `api/auth.js` |
| C-4 | RLS | ✅ 6개 표 전부, anon 접근 차단 | `0002` |
| C-5 | AI API 선정 | ✅ 아래 4장 | — |
| C-6·7 | AI Edge Function·예외 처리 | ✅ 배포됨 (**API 키만 넣으면 동작**) | `functions/analyze-bio` |
| C-8 | 주변 여행자 조회 | ✅ 10 km·24시간·차단/숨김 제외, 점수용 필드 포함 | `rpc get_nearby_travelers` |
| C-9 | 파리 가상 데이터 | ✅ 14명 입력됨 (하트 4·기본 8·상극 2) | `seed/demo-paris.sql` |
| C-10 | 연결 요청 + 현지 확인(NFR-20) | ✅ | `rpc send_request / respond_request` |
| C-11 | 채팅방·메시지 | ✅ 수락 시 자동 생성 | `rpc get_my_chat_rooms`, `api/chat.js` |
| C-12 | 2순위 데이터 | ✅ AI 재분석·위치 숨김·실시간 채팅·차단 | — |
| C-13 | 동의 기록 | ✅ `terms_agreed_at`, `location_agreed_at` | `rpc agree_terms / agree_location` |
| C-14 | 사진 저장 정책 | ✅ `avatars/{id}/`, jpg·png, 5 MB | `0002` |
| C-15 | 탈퇴 데이터 삭제 | ✅ | `functions/delete-account` |
| C-16 | 신고 저장 | ✅ | `reports` 표 · `api/safety.js` |
| C-17 | 미리 보기 (3순위) | ⏸ 시간 여유 시 | — |

## 3. A·B가 쓰는 함수

| 파일 | 함수 | 화면 | 담당 |
|---|---|---|---|
| `auth.js` | `signUp({email,password,ageConfirmed,termsAgreed,appLanguage})`, `signIn`, `signOut`, `resendConfirmation`, `onAuthChange` | S02, S03 | A |
| `profile.js` | `getMyProfile`, `getProfile(id)`, `updateMyProfile(fields)`, `analyzeBio()`, `removeAiTag(tag)`, `uploadAvatar(uri, mime)`, `agreeTerms`, `agreeLocation`, `deleteAccount` | O1–O6, M3, P1–P3 | A |
| `travelers.js` | `updateMyLocation(lat,lng,city)`, `getNearbyTravelers({radiusKm, includeDemo})`, `PARIS` | S04, M1, M2 | B |
| `requests.js` | `sendRequest(to, msg)`, `respondRequest(id, accept)` → 채팅방 id, `getMyRequests()` → `{received, sent}` | M4, R1 | A, B |
| `chat.js` | `getMyChatRooms`, `getMessages(roomId)`, `sendMessage(roomId, text)`, `subscribeMessages(roomId, cb)` | C1, C2 | B |
| `safety.js` | `reportUser(id, reason)`, `blockUser`, `unblockUser`, `getMyBlocks` | M3, C2 | A, B |
| `errors.js` | `toErrorKey(e)` → `'errors.too_far'` 같은 번역 키 | 모두 | A (문구) |

**흐름 예시**

```js
// 온보딩 마지막(O5 → O6)
await updateMyProfile({ nickname, interests, style_pace, style_planning, style_budget, meet_types, group_size, languages, tagline, bio });
const ai = await analyzeBio();            // { status: 'done' | 'skipped' | 'failed', result }

// 지도(S04 → M1)
await agreeLocation();                    // 위치정보 이용 동의 (1회)
await updateMyLocation(coords.latitude, coords.longitude, city);   // 시연 모드면 PARIS 좌표
const people = await getNearbyTravelers({ includeDemo: isDemoMode });
// → A의 matching.js 로 점수 계산 → B가 하트/기본 핀
```

**알아둘 규칙**
- 정확한 좌표는 서버가 받는 즉시 약 1 km 격자 + 사용자별 고정 오프셋으로 바꿉니다(NFR-01). 같은 사람은 항상 같은 오프셋.
- `send_request` 는 내 위치가 상대에게서 10 km 안일 때만 됩니다(NFR-20, 격자 오차 1 km 여유). 이미 만든 채팅방은 도시를 떠나도 계속 씁니다.
- 자기소개(`bio`)를 바꾸면 `ai_status` 가 자동으로 `none` 이 됩니다 → `analyzeBio()` 다시 호출(FR-26). 같은 글이면 AI를 다시 부르지 않습니다(비용).
- AI 태그는 사용자가 **지우기만** 가능합니다(FR-09). 좌표·`is_demo`·AI 결과·동의 시각은 앱에서 직접 못 고칩니다.
- 가상 여행자(`is_demo`)는 `includeDemo: true` 일 때만 보이고, 위치가 24시간 지나도 숨겨지지 않습니다.

## 4. AI API 선정 (C-5)

자기소개 1건 분석 ≈ 입력 700 토큰 + 출력 150 토큰.

| 모델 | 가격 (입력 / 출력, 100만 토큰당) | 1회 비용 | 1,000회 |
|---|---|---|---|
| Claude Haiku 5.5 (`claude-haiku-5-5`) | $0.10 / $0.50 | 약 $0.00015 | 약 $0.15 |
| OpenAI gpt-4.1-nano | $0.10 / $0.40 | 약 $0.00013 | 약 $0.13 |

→ 두 모델 모두 캡스톤 전체 사용량이 1달러 미만. **기본값은 Claude Haiku 5.5**(JSON 지시를 잘 지킴), 키가 OpenAI뿐이면 자동으로 OpenAI 사용.
설정: 대시보드 > Edge Functions > Secrets 에 `ANTHROPIC_API_KEY` (또는 `OPENAI_API_KEY`) 추가. 키가 없으면 `analyzeBio()` 는 `status: 'failed', reason: 'ai_not_configured'` 를 돌려주고 선택값만으로 매칭됩니다.

## 5. ERD

```
auth.users 1─1 profiles
profiles 1─N connection_requests (from_user, to_user)   ── 같은 상대 대기 중 요청은 1개만
connection_requests 1─0..1 chat_rooms (request_id)      ── 수락 시 생성, 두 사람 쌍당 1개
chat_rooms 1─N messages
profiles 1─N reports (reporter_id, reported_id)
profiles N─N profiles via blocks (blocker_id, blocked_id)
storage: avatars/{user_id}/photo.jpg|png
```

| 표 | 주요 칸 | RLS |
|---|---|---|
| profiles | 13장 체크리스트 전체 | 읽기: 나 / 숨김 아닌 사람(차단 제외) / 요청·채팅 상대. 수정: 나만, 허용된 칸만 |
| connection_requests | from_user, to_user, message, status, created_at, responded_at | 당사자만 읽기. 쓰기는 RPC만 |
| chat_rooms | user_a, user_b, request_id, last_message_at | 두 사람만 읽기. 생성은 RPC만. 탈퇴 시 해당 칸 null |
| messages | room_id, sender_id, content(1–1000자), created_at | 방 두 사람만 읽기·쓰기, 차단·탈퇴 후 쓰기 불가 |
| reports | reporter_id, reported_id, reason(spam/offensive/other), detail, room_id | 본인 명의로만 쓰기, 내가 쓴 것만 읽기 |
| blocks | blocker_id, blocked_id | 내가 한 차단만 보기·추가·해제 |

## 6. 검증한 것 (실제 DB에서 2~3명 계정으로 시뮬레이션)

가입 트리거·동의 기록, 남의 좌표/`is_demo` 수정 차단, 동의 전 위치 저장 차단, 잘못된 태그 거부, 좌표 뭉개기 멱등성,
주변 조회(0.8 km 상대 검색, 시연 모드 14명, 반경 3 km 필터), 요청 중복·자기 수락·직접 INSERT 차단, 수락→채팅방→메시지,
제3자의 메시지·요청·신고 열람/쓰기 차단, 차단 후 지도·프로필·채팅에서 양쪽 모두 사라짐, 비로그인(anon) 전면 차단.
Supabase Security Advisor 경고 정리 완료(남은 항목: 로그인 사용자가 부르도록 만든 RPC — 의도된 것).

## 7. 남은 설정 (대시보드에서 1~2분)

1. **AI 키 등록** — 4장 참고.
2. **팀원 초대** — Organization > Members (C-1).
3. **인증 메일** — 무료 플랜 기본 메일 서버는 시간당 발송 수가 적습니다. 시연용 계정은 미리 만들어 두고, 필요하면 Authentication > SMTP 에 학교/Gmail SMTP 연결.
4. (선택) Authentication > URL Configuration 의 Site URL 을 인증 완료 안내 페이지로 변경.
