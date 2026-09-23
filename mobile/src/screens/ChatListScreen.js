import React, { useCallback, useState } from "react";
import { View, Text, FlatList, TouchableOpacity, StyleSheet } from "react-native";
import { useFocusEffect } from "@react-navigation/native";
import { listRooms } from "../api/chat";
import { useAuth } from "../context/AuthContext";
import { colors } from "../theme/colors";

function roomLabel(room, myUserId) {
  if (room.type === "GROUP") return room.name || "Nhóm chat";
  const other = room.members.find((m) => m.userId !== myUserId);
  return other?.user?.name || "Trực tiếp";
}

export default function ChatListScreen({ navigation }) {
  const { user } = useAuth();
  const [rooms, setRooms] = useState([]);
  const [loading, setLoading] = useState(true);

  useFocusEffect(
    useCallback(() => {
      let active = true;
      setLoading(true);
      listRooms()
        .then((data) => active && setRooms(data))
        .catch(() => {})
        .finally(() => active && setLoading(false));
      return () => {
        active = false;
      };
    }, [])
  );

  return (
    <View style={styles.container}>
      <FlatList
        data={rooms}
        keyExtractor={(r) => r.id}
        contentContainerStyle={{ padding: 16 }}
        ListEmptyComponent={
          !loading && (
            <Text style={styles.empty}>
              Chưa có cuộc trò chuyện nào. Vào tab Bản đồ, chọn 1 người rồi gửi yêu cầu kết nối.
            </Text>
          )
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            style={styles.row}
            onPress={() => navigation.navigate("ChatRoom", { roomId: item.id, title: roomLabel(item, user.id) })}
          >
            <Text style={styles.roomBadge}>{item.type === "GROUP" ? "👥" : "💬"}</Text>
            <Text style={styles.roomName}>{roomLabel(item, user.id)}</Text>
          </TouchableOpacity>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingVertical: 14,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  roomBadge: { fontSize: 20, marginRight: 12 },
  roomName: { fontSize: 16, color: colors.text, fontWeight: "600" },
  empty: { textAlign: "center", color: colors.textMuted, marginTop: 40, paddingHorizontal: 20 },
});
