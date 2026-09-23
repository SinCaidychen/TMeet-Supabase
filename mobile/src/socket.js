import { io } from "socket.io-client";
import { API_BASE_URL } from "./api/client";

let socket = null;

// 1 socket dùng chung cho cả app, tạo lại mỗi lần login (cần token mới) và
// đóng lại lúc logout. sockets.js của backend (registerChatSocket) yêu cầu
// auth token ngay lúc connect - xem backend/src/sockets/chat.socket.js.
export function connectSocket(token) {
  if (socket) socket.disconnect();
  socket = io(API_BASE_URL, { auth: { token }, transports: ["websocket"] });
  return socket;
}

export function getSocket() {
  return socket;
}

export function disconnectSocket() {
  if (socket) socket.disconnect();
  socket = null;
}
