const prisma = require("../config/prisma");

async function listRooms(req, res) {
  const rooms = await prisma.chatRoom.findMany({
    where: { members: { some: { userId: req.userId } } },
    include: { members: { include: { user: true } } },
  });
  res.json(rooms);
}

// POST /api/chat/rooms/group  Body: { name, memberIds: string[] }
async function createGroupRoom(req, res) {
  const { name, memberIds = [] } = req.body;
  const allMemberIds = Array.from(new Set([req.userId, ...memberIds]));

  const room = await prisma.chatRoom.create({
    data: {
      type: "GROUP",
      name,
      members: { create: allMemberIds.map((userId) => ({ userId })) },
    },
    include: { members: true },
  });

  res.status(201).json(room);
}

async function listMessages(req, res) {
  const { roomId } = req.params;
  const isMember = await prisma.chatMember.findUnique({
    where: { roomId_userId: { roomId, userId: req.userId } },
  });
  if (!isMember) return res.status(403).json({ error: "Not a member of this room" });

  const messages = await prisma.message.findMany({
    where: { roomId },
    orderBy: { createdAt: "asc" },
    take: 100,
  });
  res.json(messages);
}

module.exports = { listRooms, createGroupRoom, listMessages };
