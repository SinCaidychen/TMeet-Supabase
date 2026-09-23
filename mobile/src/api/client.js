import axios from "axios";

// !!! ĐỔI GIÁ TRỊ NÀY khi test trên điện thoại thật qua Expo Go !!!
// Điện thoại và máy tính phải cùng 1 mạng WiFi. Không dùng "localhost" vì đó là
// localhost CỦA ĐIỆN THOẠI, không phải của máy tính chạy backend.
// Lấy IP máy tính bằng lệnh `ipconfig` (Windows) -> tìm dòng "IPv4 Address" (vd 192.168.1.23).
const LAN_IP = "192.168.1.23"; // <-- sửa thành IP thật của máy bạn
export const API_BASE_URL = `http://${LAN_IP}:4000`;

export const apiClient = axios.create({ baseURL: API_BASE_URL });

// Gắn token vào mọi request (trừ lúc chưa có token, ví dụ trước khi login)
let authToken = null;
export function setAuthToken(token) {
  authToken = token;
  if (token) {
    apiClient.defaults.headers.common.Authorization = `Bearer ${token}`;
  } else {
    delete apiClient.defaults.headers.common.Authorization;
  }
}
