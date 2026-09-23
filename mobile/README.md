# TMeet mobile app

App di động cho TMeet, viết bằng **React Native + Expo** (managed workflow, chạy trực tiếp bằng app **Expo Go** trên điện thoại, không cần Mac/Xcode để test).

## Chạy lần đầu

```powershell
cd mobile
npm install
npx expo install @react-navigation/native @react-navigation/native-stack @react-navigation/bottom-tabs react-native-screens react-native-safe-area-context react-native-maps expo-secure-store expo-location axios socket.io-client
```

Sửa file `src/api/client.js`, đổi `LAN_IP` thành IP thật của máy bạn (lấy bằng `ipconfig` trên PowerShell, tìm dòng "IPv4 Address", dạng `192.168.x.x`). Điện thoại và máy tính phải cùng 1 mạng WiFi thì mới gọi API được.

Backend (`../backend`) phải đang chạy (`npm run dev`) trước khi mở app.

```powershell
npx expo start
```

Quét mã QR hiện ra bằng app **Expo Go** (tải trên App Store/CH Play) trên điện thoại để xem app chạy thật.

## Cấu trúc

```
mobile/
├── App.js                     # entry point
├── src/
│   ├── api/                   # gọi REST API backend (auth, users, matches, chat)
│   ├── context/AuthContext.js # quản lý đăng nhập, lưu token, tự đăng nhập lại
│   ├── socket.js              # kết nối Socket.IO cho chat real-time
│   ├── navigation/            # điều hướng: Login/Register -> Onboarding -> Map/Chat tabs
│   ├── screens/                # các màn hình
│   ├── constants/tags.js      # danh sách tag phong cách du lịch (onboarding)
│   ├── utils/personality.js   # TODO: chỗ 오승화 sẽ nối OpenAI API thật vào
│   └── theme/colors.js        # bảng màu dùng chung
```

## Trạng thái hiện tại / còn thiếu

- **Đăng ký/đăng nhập, onboarding (chọn tag + motto), bản đồ hiện user khác kèm pin 하트/기본/상극, xin-đồng ý xem lịch trình chi tiết (bảo mật 2 giai đoạn), chat 1:1 real-time** — đã có, gọi thẳng API backend thật.
- **Chưa có**: phân tích tính cách bằng OpenAI thật (đang là hàm giả lập trong `utils/personality.js`), giao diện Figma chính thức (đang dùng UI đơn giản tự viết), group chat UI riêng (mới có chat 1:1 qua MatchDetail), Google Maps API key thật (cần điền vào `app.json` → `android.config.googleMaps.apiKey` để bản đồ hiện đúng trên Android — iOS dùng Apple Maps nên không cần key).
- Build ra APK/IPA thật để nộp App Store cần thêm bước `eas build` (Expo Application Services) — chưa làm, để sau khi app đã hoàn thiện hơn.
