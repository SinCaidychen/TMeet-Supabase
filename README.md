# TMeet (GlobalT)

AI 및 위치 기반 글로벌 즉석 여행 밋업 플랫폼 — Capstone Design, Gwangju University (앵커사업단), team **GlobalT**.

## Team

| Thành viên | Vai trò |
|---|---|
| 오승화 (team lead) | Tổng chỉ huy, Figma UI/UX, tích hợp OpenAI API, frontend |
| 바야라 | Frontend app screens, tích hợp Google Maps API + hiển thị pin |
| 부이휘황 | Backend/DB, chat server real-time, logic bảo mật 2 giai đoạn |

## Cấu trúc repo

```
AppTMeet/
├── backend/     # Node.js + Express API, Socket.IO chat, PostgreSQL (Prisma), auth, 2-stage security logic
└── mobile/      # Mobile app (frontend) — Figma UI/UX, OpenAI onboarding, Google Maps pins
```

## Backend — quick start

```bash
cd backend
cp .env.example .env      # điền JWT_SECRET, DATABASE_URL, ENCRYPTION_KEY
docker compose up -d db   # chạy PostgreSQL (chạy lệnh này ở thư mục gốc repo)
npm install
npx prisma migrate dev --name init
npm run dev
```

Server chạy ở `http://localhost:4000`, WebSocket chat cùng port qua Socket.IO.

## Ý tưởng cốt lõi

- Onboarding: chọn tag phong cách du lịch + 1 câu motto → OpenAI phân tích tính cách du lịch
- Bản đồ: Google Maps hiển thị user gần đó, pin phân loại theo độ tương hợp (하트/기본/상극), có filter ẩn pin 상극
- Chat: 1:1 trực tiếp + group chat mở
- **Bảo mật 2 giai đoạn**: mặc định chỉ lộ thông tin lịch trình sơ bộ (thành phố + khoảng thời gian); thông tin chi tiết (địa điểm/giờ cụ thể) chỉ hiện sau khi cả 2 bên đồng ý (consent) trong chat 1:1 — xem `backend/src/controllers/matches.controller.js`.
