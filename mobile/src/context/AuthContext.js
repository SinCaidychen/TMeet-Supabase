import React, { createContext, useContext, useEffect, useState, useCallback } from "react";
import * as SecureStore from "expo-secure-store";
import { setAuthToken } from "../api/client";
import { login as apiLogin, register as apiRegister } from "../api/auth";
import { getMe } from "../api/users";
import { connectSocket, disconnectSocket } from "../socket";

const TOKEN_KEY = "tmeet_token";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true); // đang khôi phục phiên đăng nhập lúc mở app

  // Lúc app mở lên, thử đọc token đã lưu để tự động đăng nhập lại.
  useEffect(() => {
    (async () => {
      try {
        const token = await SecureStore.getItemAsync(TOKEN_KEY);
        if (token) {
          setAuthToken(token);
          const me = await getMe();
          setUser(me);
          connectSocket(token);
        }
      } catch (e) {
        // token cũ không hợp lệ -> coi như chưa đăng nhập
        await SecureStore.deleteItemAsync(TOKEN_KEY);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const afterAuthSuccess = useCallback(async ({ token, user: newUser }) => {
    await SecureStore.setItemAsync(TOKEN_KEY, token);
    setAuthToken(token);
    connectSocket(token);
    setUser(newUser);
  }, []);

  const login = useCallback(
    async (email, password) => afterAuthSuccess(await apiLogin({ email, password })),
    [afterAuthSuccess]
  );

  const register = useCallback(
    async (email, password, name) =>
      afterAuthSuccess(await apiRegister({ email, password, name })),
    [afterAuthSuccess]
  );

  const refreshUser = useCallback(async () => {
    const me = await getMe();
    setUser(me);
    return me;
  }, []);

  const logout = useCallback(async () => {
    await SecureStore.deleteItemAsync(TOKEN_KEY);
    setAuthToken(null);
    disconnectSocket();
    setUser(null);
  }, []);

  // Đã điền onboarding chưa (có tags rồi) -> quyết định vào Onboarding hay vào Map
  const isOnboarded = !!user?.tags;

  return (
    <AuthContext.Provider
      value={{ user, loading, isOnboarded, login, register, logout, refreshUser }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside <AuthProvider>");
  return ctx;
}
