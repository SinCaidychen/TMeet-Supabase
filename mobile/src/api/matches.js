import { apiClient } from "./client";

export function getNearby() {
  return apiClient.get("/api/matches/nearby").then((r) => r.data);
}

export function requestConsent(otherUserId, { roughCity, roughDateRange }) {
  return apiClient
    .post(`/api/matches/${otherUserId}/consent/request`, { roughCity, roughDateRange })
    .then((r) => r.data);
}

export function respondConsent(roomId, status) {
  return apiClient
    .post(`/api/matches/consent/${roomId}/respond`, { status })
    .then((r) => r.data);
}

export function submitDetail(roomId, detail) {
  return apiClient.post(`/api/matches/consent/${roomId}/detail`, detail).then((r) => r.data);
}

export function getConsent(roomId) {
  return apiClient.get(`/api/matches/consent/${roomId}`).then((r) => r.data);
}

export function getConsentByUser(otherUserId) {
  return apiClient.get(`/api/matches/consent/by-user/${otherUserId}`).then((r) => r.data);
}
