import { apiClient } from "./client";

export function listRooms() {
  return apiClient.get("/api/chat/rooms").then((r) => r.data);
}

export function listMessages(roomId) {
  return apiClient.get(`/api/chat/rooms/${roomId}/messages`).then((r) => r.data);
}

export function createGroupRoom({ name, memberIds }) {
  return apiClient.post("/api/chat/rooms/group", { name, memberIds }).then((r) => r.data);
}
