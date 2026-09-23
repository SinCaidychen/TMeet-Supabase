import { apiClient } from "./client";

export function register({ email, password, name }) {
  return apiClient.post("/api/auth/register", { email, password, name }).then((r) => r.data);
}

export function login({ email, password }) {
  return apiClient.post("/api/auth/login", { email, password }).then((r) => r.data);
}
