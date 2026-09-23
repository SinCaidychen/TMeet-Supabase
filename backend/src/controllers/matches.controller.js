const prisma = require("../config/prisma");
const { encrypt, decrypt } = require("../utils/crypto");

// GET /api/matches/nearby
// Trả về các user khác kèm loại pin (하트/기본/상극) theo Compatibility đã tính sẵn.
// Chỉ trả toạ độ thô (lat/lng) của họ - không có gì liên quan lịch trình chi tiết ở đây.
async function nearby(req, res) {
  const userId = req.userId;
  const compats = await prisma.compatibility.findMany({
    where: { OR: [{ userAId: userId }, { userBId: userId }] },
    include: { userA: true, userB: true },
  });

  const result = compats.map((c) => {
    const other = c.userAId === userId ? c.userB : c.userA;
    return {
      userId: other.id,
      name: other.name,
      lat: other.lat,
      lng: other.lng,
      pinType: c.pinType,
      score: c.score,
    };
  });

  res.json(result);
}

// POST /api/matches/:otherUserId/consent/request
// Body: { roughCity, roughDateRange }
// Giai đoạn 1: mở (hoặc tái sử dụng) 1 phòng chat DIRECT giữa 2 người và ghi thông tin sơ bộ.
// Thông tin sơ bộ này hiển thị ngay, không cần đợi consent.
async function requestConsent(req, res) {
  const userAId = req.userId;
  const userBId = req.params.otherUserId;
  const { roughCity, roughDateRange } = req.body;

  if (userAId === userBId) {
    return res.status(400).json({ error: "Cannot request consent with yourself" });
  }

  let room = await findDirectRoom(userAId, userBId);
  if (!room) {
    room = await prisma.chatRoom.create({
      data: {
        type: "DIRECT",
        members: { create: [{ userId: userAId }, { userId: userBId }] },
      },
    });
  }

  const consent = await prisma.scheduleConsent.upsert({
    where: { roomId: room.id },
    update: { roughCity, roughDateRange },
    create: { roomId: room.id, userAId, userBId, roughCity, roughDateRange },
  });

  res.status(201).json({ roomId: room.id, consent: sanitizeConsent(consent) });
}

// POST /api/matches/consent/:roomId/respond
// Body: { status: "ACCEPTED" | "DECLINED" }
// Cả 2 phía đều có thể gọi endpoint này để đồng ý chia sẻ lịch trình chi tiết cho nhau.
async function respondConsent(req, res) {
  const { status } = req.body;
  if (!["ACCEPTED", "DECLINED"].includes(status)) {
    return res.status(400).json({ error: "status must be ACCEPTED or DECLINED" });
  }

  const consent = await getConsentForUser(req.params.roomId, req.userId);
  if (!consent) return res.status(404).json({ error: "Consent record not found" });

  const updated = await prisma.scheduleConsent.update({
    where: { roomId: req.params.roomId },
    data: { status },
  });

  res.json({ consent: sanitizeConsent(updated) });
}

// POST /api/matches/consent/:roomId/detail
// Body: { location, startTime, endTime, notes }
// Giai đoạn 2: chỉ cho phép ghi/đọc chi tiết SAU KHI status === ACCEPTED.
// Chi tiết được mã hoá AES-256-GCM trước khi lưu DB (utils/crypto.js).
async function submitDetail(req, res) {
  const consent = await getConsentForUser(req.params.roomId, req.userId);
  if (!consent) return res.status(404).json({ error: "Consent record not found" });
  if (consent.status !== "ACCEPTED") {
    return res.status(403).json({ error: "Both users must accept before sharing details" });
  }

  const { ciphertext, iv, authTag } = encrypt(req.body);
  const updated = await prisma.scheduleConsent.update({
    where: { roomId: req.params.roomId },
    data: { detailEncrypted: ciphertext, detailIv: iv, detailAuthTag: authTag },
  });

  res.json({ consent: sanitizeConsent(updated) });
}

// GET /api/matches/consent/:roomId
// Luôn trả về roughCity/roughDateRange. Chỉ giải mã và trả detail nếu status === ACCEPTED
// và người gọi là 1 trong 2 bên của phòng chat này.
async function getConsent(req, res) {
  const consent = await getConsentForUser(req.params.roomId, req.userId);
  if (!consent) return res.status(404).json({ error: "Consent record not found" });

  const payload = sanitizeConsent(consent);

  if (consent.status === "ACCEPTED" && consent.detailEncrypted) {
    payload.detail = decrypt({
      ciphertext: consent.detailEncrypted,
      iv: consent.detailIv,
      authTag: consent.detailAuthTag,
    });
  }

  res.json(payload);
}

// --- helpers ---

async function findDirectRoom(userAId, userBId) {
  return prisma.chatRoom.findFirst({
    where: {
      type: "DIRECT",
      AND: [
        { members: { some: { userId: userAId } } },
        { members: { some: { userId: userBId } } },
      ],
    },
  });
}

async function getConsentForUser(roomId, userId) {
  const consent = await prisma.scheduleConsent.findUnique({ where: { roomId } });
  if (!consent) return null;
  if (consent.userAId !== userId && consent.userBId !== userId) return null; // not a party to it
  return consent;
}

function sanitizeConsent(consent) {
  // Never leak the encrypted blob / iv / authTag directly to the client.
  const { detailEncrypted, detailIv, detailAuthTag, ...rest } = consent;
  return rest;
}

module.exports = { nearby, requestConsent, respondConsent, submitDetail, getConsent };
