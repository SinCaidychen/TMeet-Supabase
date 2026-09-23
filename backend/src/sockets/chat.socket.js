const jwt = require("jsonwebtoken");
const prisma = require("../config/prisma");

// Dùng chung 1 cơ chế room cho cả 1:1 (DIRECT) lẫn group chat (GROUP) - client join
// theo roomId, server chỉ việc broadcast trong room đó.
function registerChatSocket(io) {
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) return next(new Error("Missing auth token"));
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = payload.sub;
      next();
    } catch (err) {
      next(new Error("Invalid or expired token"));
    }
  });

  io.on("connection", (socket) => {
    socket.on("room:join", async (roomId) => {
      const isMember = await prisma.chatMember.findUnique({
        where: { roomId_userId: { roomId, userId: socket.userId } },
      });
      if (!isMember) return socket.emit("error", "Not a member of this room");
      socket.join(roomId);
    });

    socket.on("message:send", async ({ roomId, content }) => {
      const isMember = await prisma.chatMember.findUnique({
        where: { roomId_userId: { roomId, userId: socket.userId } },
      });
      if (!isMember) return socket.emit("error", "Not a member of this room");

      const message = await prisma.message.create({
        data: { roomId, senderId: socket.userId, content },
      });

      io.to(roomId).emit("message:new", message);
    });

    socket.on("disconnect", () => {
      // no-op for now; hook presence/online-status tracking here later if needed
    });
  });
}

module.exports = { registerChatSocket };
