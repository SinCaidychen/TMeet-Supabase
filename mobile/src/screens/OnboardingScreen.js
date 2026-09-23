import React, { useState } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Alert,
} from "react-native";
import * as Location from "expo-location";
import { colors } from "../theme/colors";
import { TRAVEL_TAGS } from "../constants/tags";
import { updateOnboarding, updateLocation } from "../api/users";
import { summarizePersonality } from "../utils/personality";
import { useAuth } from "../context/AuthContext";

export default function OnboardingScreen() {
  const { refreshUser } = useAuth();
  const [selectedTags, setSelectedTags] = useState([]);
  const [motto, setMotto] = useState("");
  const [submitting, setSubmitting] = useState(false);

  function toggleTag(tag) {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  }

  async function handleContinue() {
    if (selectedTags.length === 0) {
      return Alert.alert("Chọn ít nhất 1 tag", "Chọn phong cách du lịch của bạn để tiếp tục");
    }
    setSubmitting(true);
    try {
      // TODO: đây là chỗ sẽ gọi OpenAI API thật (phần việc của 오승화) - xem utils/personality.js
      const personality = summarizePersonality(selectedTags, motto);
      await updateOnboarding({ motto, tags: selectedTags, personality });

      // Xin quyền vị trí và lưu lên server để bản đồ hoạt động được.
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status === "granted") {
        const pos = await Location.getCurrentPositionAsync({});
        await updateLocation({ lat: pos.coords.latitude, lng: pos.coords.longitude });
      }

      await refreshUser(); // user.tags giờ đã có -> RootNavigator tự chuyển sang Map
    } catch (e) {
      Alert.alert("Có lỗi", e?.response?.data?.error || e.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Bạn là kiểu du khách nào?</Text>
      <Text style={styles.subtitle}>Chọn các tag phù hợp (chọn được nhiều)</Text>

      <View style={styles.tagWrap}>
        {TRAVEL_TAGS.map((tag) => {
          const selected = selectedTags.includes(tag);
          return (
            <TouchableOpacity
              key={tag}
              onPress={() => toggleTag(tag)}
              style={[styles.tag, selected && styles.tagSelected]}
            >
              <Text style={[styles.tagText, selected && styles.tagTextSelected]}>{tag}</Text>
            </TouchableOpacity>
          );
        })}
      </View>

      <Text style={styles.label}>Motto du lịch của bạn (1 câu)</Text>
      <TextInput
        style={styles.input}
        placeholder="Vd: Đi để lạc, không phải để đến"
        value={motto}
        onChangeText={setMotto}
      />

      <TouchableOpacity style={styles.button} onPress={handleContinue} disabled={submitting}>
        <Text style={styles.buttonText}>{submitting ? "Đang lưu..." : "Tiếp tục"}</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { padding: 24, paddingTop: 60, backgroundColor: colors.background },
  title: { fontSize: 24, fontWeight: "700", color: colors.text },
  subtitle: { color: colors.textMuted, marginTop: 6, marginBottom: 20 },
  tagWrap: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 24 },
  tag: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 20,
    paddingVertical: 8,
    paddingHorizontal: 14,
    marginRight: 8,
    marginBottom: 8,
  },
  tagSelected: { backgroundColor: colors.primary, borderColor: colors.primary },
  tagText: { color: colors.text },
  tagTextSelected: { color: "#fff", fontWeight: "600" },
  label: { fontWeight: "600", color: colors.text, marginBottom: 8 },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 12,
    padding: 14,
    marginBottom: 24,
    fontSize: 16,
  },
  button: { backgroundColor: colors.primary, borderRadius: 12, padding: 16, alignItems: "center" },
  buttonText: { color: "#fff", fontWeight: "700", fontSize: 16 },
});
