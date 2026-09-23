require("dotenv").config();
const http = require("http");
const express = require("express");
const cors = require("cors");
const { Server } = require("socket.io");

const authRoutes = require("./routes/auth.routes");
const usersRoutes = require("./routes/users.routes");
const matchesRoutes = require("./routes/matches.routes");
const chatRoutes = require("./routes/chat.routes");
const { registerChatSocket } = require("./sockets/chat.socket");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/api/auth", authRoutes);
app.use("/api/users", usersRoutes);
app.use("/api/matches", matchesRoutes);
app.use("/api/chat", chatRoutes);

const server = http.createServer(app);
const io = new Server(server, { cors: { origin: "*" } });
registerChatSocket(io);

const PORT = process.env.PORT || 4000;
server.listen(PORT, () => console.log(`TMeet backend listening on :${PORT}`));
