import { apiClient } from "./client";

export function getMe() {
  return apiClient.get("/api/users/me").then((r) => r.data);
}

export function updateOnboarding({ motto, tags, personality }) {
  return apiClient
    .patch("/api/users/me/onboarding", { motto, tags, personality })
    .then((r) => r.data);
}

export function updateLocation({ lat, lng }) {
  return apiClient.patch("/api/users/me/location", { lat, lng }).then((r) => r.data);
}
