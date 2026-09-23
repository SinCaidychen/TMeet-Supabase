import React, { useEffect, useRef, useState } from "react";
import {
  View,
  Text,
  FlatList,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { listMessages } from "../api/chat";
import { getSocket } from "../socket";
import { useAuth } from "../context/AuthContext";
import { colors } from "../theme/colors";

export default function ChatRoomScreen({ route, navigation }) {
  const { roomId, title } = route.params;
  const { user } = useAuth();
  const [messages, setMessages] = useState([]);
  const [text, setText] = useState("");
  const listRef = useRef(null);

  useEffect(() => {
    navigation.setOptions({ title: title || "Chat" });
  }, [navigation, title]);

  useEffect(() => {
    listMessages(roomId).then(setMessages).catch(() => {});

    const socket = getSocket();
    if (!socket) return;

    socket.emit("room:join", roomId);

    function onNewMessage(msg) {
      if (msg.roomId === roomId) {
        setMessages((prev) => [...prev, msg]);
      }
    }
    socket.on("message:new", onNewMessage);
    return () => socket.off("message:new", onNewMessage);
  }, [roomId]);

  function handleSend() {
    const content = text.trim();
    if (!content) return;
    const socket = getSocket();
    socket?.emit("message:send", { roomId, content });
    setText("");
  }

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
      keyboardVerticalOffset={90}
    >
      <FlatList
        ref={listRef}
        data={messages}
        keyExtractor={(m) => m.id}
        contentContainerStyle={{ padding: 16 }}
        onContentSizeChange={() => listRef.current?.scrollToEnd({ animated: true })}
        renderItem={({ item }) => {
          const mine = item.senderId === user.id;
          return (
            <View style={[styles.bubble, mine ? styles.bubbleMine : styles.bubbleTheirs]}>
              <Text style={mine ? styles.bubbleTextMine : styles.bubbleText}>{item.content}</Text>
            </View>
          );
        }}
      />
      <View style={styles.inputRow}>
        <TextInput
          style={styles.input}
          placeholder="Nhắn gì đó..."
          value={text}
          onChangeText={setText}
          onSubmitEditing={handleSend}
        />
        <TouchableOpacity style={styles.sendButton} onPress={handleSend}>
          <Text style={styles.sendText}>Gửi</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  bubble: { maxWidth: "75%", padding: 12, borderRadius: 16, marginBottom: 8 },
  bubbleMine: { backgroundColor: colors.primary, alignSelf: "flex-end" },
  bubbleTheirs: { backgroundColor: colors.backgroundMuted, alignSelf: "flex-start" },
  bubbleTextMine: { color: "#fff" },
  bubbleText: { color: colors.text },
  inputRow: {
    flexDirection: "row",
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: colors.border,
    alignItems: "center",
  },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 20,
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginRight: 8,
  },
  sendButton: { backgroundColor: colors.primary, borderRadius: 20, paddingHorizontal: 16, paddingVertical: 10 },
  sendText: { color: "#fff", fontWeight: "700" },
});
