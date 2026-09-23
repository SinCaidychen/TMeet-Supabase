import React, { useCallback, useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
} from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import {
  requestConsent,
  respondConsent,
  submitDetail,
  getConsent,
  getConsentByUser,
} from "../api/matches";
import { colors } from "../theme/colors";

const PIN_LABEL = { HEART: "하트 (độ tương hợp cao)", BASIC: "기본", OPPOSITE: "상극 (lệch tính cách)" };

// Đây là màn hình thể hiện rõ nhất logic "bảo mật 2 giai đoạn" của đề tài:
// Giai đoạn 1 (roughCity/roughDateRange) hiện ngay sau khi request.
// Giai đoạn 2 (detail: địa điểm/giờ cụ thể) chỉ hiện sau khi CẢ HAI bên bấm "Đồng ý".
export default function MatchDetailScreen({ route, navigation }) {
  const { userId, name, pinType } = route.params;

  const [roomId, setRoomId] = useState(null);
  const [consent, setConsent] = useState(null);
  const [roughCity, setRoughCity] = useState("");
  const [roughDateRange, setRoughDateRange] = useState("");
  const [detailLocation, setDetailLocation] = useState("");
  const [detailTime, setDetailTime] = useState("");
  const [busy, setBusy] = useState(false);

  const loadExisting = useCallback(async () => {
    const { room, consent: existing } = await getConsentByUser(userId);
    if (room) setRoomId(room.id);
    if (existing) setConsent(existing);
  }, [userId]);

  useFocusEffect(
    useCallback(() => {
      loadExisting().catch(() => {});
    }, [loadExisting])
  );

  async function handleRequest() {
    if (!roughCity || !roughDateRange) {
      return Alert.alert("Thiếu thông tin", "Nhập thành phố và khoảng thời gian sơ bộ");
    }
    setBusy(true);
    try {
      const res = await requestConsent(userId, { roughCity, roughDateRange });
      setRoomId(res.roomId);
      setConsent(res.consent);
    } catch (e) {
      Alert.alert("Lỗi", e?.response?.data?.error || e.message);
    } finally {
      setBusy(false);
    }
  }

  async function handleRespond(status) {
    setBusy(true);
    try {
      const res = await respondConsent(roomId, status);
      setConsent(res.consent);
    } catch (e) {
      Alert.alert("Lỗi", e?.response?.data?.error || e.message);
    } finally {
      setBusy(false);
    }
  }

  async function handleSubmitDetail() {
    setBusy(true);
    try {
      await submitDetail(roomId, { location: detailLocation, time: detailTime });
      const full = await getConsent(roomId);
      setConsent(full);
    } catch (e) {
      Alert.alert("Lỗi", e?.response?.data?.error || e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.name}>{name}</Text>
      <Text style={styles.pin}>{PIN_LABEL[pinType] || pinType}</Text>

      {!consent && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Giai đoạn 1 · Thông tin sơ bộ</Text>
          <Text style={styles.hint}>Chỉ chia sẻ thành phố + khoảng thời gian, chưa lộ địa điểm/giờ cụ thể.</Text>
          <TextInput style={styles.input} placeholder="Thành phố (vd: Seoul)" value={roughCity} onChangeText={setRoughCity} />
          <TextInput style={styles.input} placeholder="Khoảng thời gian (vd: giữa tháng 10)" value={roughDateRange} onChangeText={setRoughDateRange} />
          <TouchableOpacity style={styles.button} onPress={handleRequest} disabled={busy}>
            <Text style={styles.buttonText}>Gửi yêu cầu kết nối</Text>
          </TouchableOpacity>
        </View>
      )}

      {consent && (
        <View style={styles.card}>
          <Text style={styles.cardTitle}>Giai đoạn 1 · Đã chia sẻ</Text>
          <Text>Thành phố: {consent.roughCity}</Text>
          <Text>Thời gian: {consent.roughDateRange}</Text>
          <Text style={styles.status}>Trạng thái: {consent.status}</Text>

          {consent.status === "PENDING" && (
            <View style={styles.row}>
              <TouchableOpacity style={[styles.button, styles.buttonSmall]} onPress={() => handleRespond("ACCEPTED")} disabled={busy}>
                <Text style={styles.buttonText}>Đồng ý chia sẻ chi tiết</Text>
              </TouchableOpacity>
              <TouchableOpacity style={[styles.button, styles.buttonSmall, styles.buttonDanger]} onPress={() => handleRespond("DECLINED")} disabled={busy}>
                <Text style={styles.buttonText}>Từ chối</Text>
              </TouchableOpacity>
            </View>
          )}

          {consent.status === "ACCEPTED" && (
            <View style={styles.stage2}>
              <Text style={styles.cardTitle}>Giai đoạn 2 · Chi tiết lịch trình</Text>
              {consent.detail ? (
                <View>
                  <Text>Địa điểm: {consent.detail.location}</Text>
                  <Text>Giờ: {consent.detail.time}</Text>
                </View>
              ) : (
                <Text style={styles.hint}>Chưa ai điền chi tiết. Điền của bạn bên dưới:</Text>
              )}
              <TextInput style={styles.input} placeholder="Địa điểm cụ thể" value={detailLocation} onChangeText={setDetailLocation} />
              <TextInput style={styles.input} placeholder="Giờ cụ thể" value={detailTime} onChangeText={setDetailTime} />
              <TouchableOpacity style={styles.button} onPress={handleSubmitDetail} disabled={busy}>
                <Text style={styles.buttonText}>Lưu chi tiết của tôi</Text>
              </TouchableOpacity>
            </View>
          )}

          <TouchableOpacity
            style={[styles.button, styles.buttonOutline]}
            onPress={() => navigation.navigate("ChatRoom", { roomId, title: name })}
          >
            <Text style={[styles.buttonText, styles.buttonOutlineText]}>Mở chat</Text>
          </TouchableOpacity>
        </View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 20, backgroundColor: colors.background },
  name: { fontSize: 22, fontWeight: "700", color: colors.text },
  pin: { color: colors.textMuted, marginBottom: 20 },
  card: {
    backgroundColor: colors.backgroundMuted,
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
  },
  cardTitle: { fontWeight: "700", fontSize: 16, marginBottom: 8, color: colors.text },
  hint: { color: colors.textMuted, marginBottom: 12, fontSize: 13 },
  status: { marginTop: 8, fontWeight: "600" },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
    backgroundColor: "#fff",
  },
  button: { backgroundColor: colors.primary, borderRadius: 10, padding: 14, alignItems: "center", marginTop: 6 },
  buttonSmall: { flex: 1, marginHorizontal: 4 },
  buttonDanger: { backgroundColor: colors.danger },
  buttonOutline: { backgroundColor: "transparent", borderWidth: 1, borderColor: colors.primary, marginTop: 12 },
  buttonOutlineText: { color: colors.primary },
  buttonText: { color: "#fff", fontWeight: "700" },
  row: { flexDirection: "row", marginTop: 8 },
  stage2: { marginTop: 16, borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 16 },
});
