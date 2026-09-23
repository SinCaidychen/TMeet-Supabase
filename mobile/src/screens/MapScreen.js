import React, { useCallback, useEffect, useState } from "react";
import { View, Text, StyleSheet, ActivityIndicator, TouchableOpacity } from "react-native";
import MapView, { Marker, PROVIDER_GOOGLE } from "react-native-maps";
import * as Location from "expo-location";
import { useFocusEffect } from "@react-navigation/native";
import { getNearby } from "../api/matches";
import { colors } from "../theme/colors";

const PIN_COLOR = {
  HEART: colors.pinHeart,
  BASIC: colors.pinBasic,
  OPPOSITE: colors.pinOpposite,
};

export default function MapScreen({ navigation }) {
  const [region, setRegion] = useState(null);
  const [others, setOthers] = useState([]);
  const [hideOpposite, setHideOpposite] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const { status } = await Location.requestForegroundPermissionsAsync();
      if (status === "granted") {
        const pos = await Location.getCurrentPositionAsync({});
        setRegion({
          latitude: pos.coords.latitude,
          longitude: pos.coords.longitude,
          latitudeDelta: 0.05,
          longitudeDelta: 0.05,
        });
      } else {
        // fallback: trung tâm Gwangju nếu không có quyền vị trí
        setRegion({ latitude: 35.1595, longitude: 126.8526, latitudeDelta: 0.1, longitudeDelta: 0.1 });
      }
    })();
  }, []);

  // Load lại danh sách user gần đó mỗi lần quay về tab Map (vd sau khi xin consent xong).
  useFocusEffect(
    useCallback(() => {
      let active = true;
      setLoading(true);
      getNearby()
        .then((data) => active && setOthers(data))
        .catch(() => {})
        .finally(() => active && setLoading(false));
      return () => {
        active = false;
      };
    }, [])
  );

  const visibleOthers = hideOpposite ? others.filter((o) => o.pinType !== "OPPOSITE") : others;

  if (!region) {
    return (
      <View style={styles.center}>
        <ActivityIndicator color={colors.primary} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <MapView
        provider={PROVIDER_GOOGLE}
        style={StyleSheet.absoluteFill}
        initialRegion={region}
        showsUserLocation
      >
        {visibleOthers.map((o) => (
          <Marker
            key={o.userId}
            coordinate={{ latitude: o.lat, longitude: o.lng }}
            pinColor={PIN_COLOR[o.pinType] || colors.pinBasic}
            title={o.name}
            description={o.pinType === "HEART" ? "Độ tương hợp cao" : o.pinType === "OPPOSITE" ? "Lệch tính cách" : "Chưa rõ độ tương hợp"}
            onCalloutPress={() => navigation.navigate("MatchDetail", { userId: o.userId, name: o.name, pinType: o.pinType })}
          />
        ))}
      </MapView>

      {loading && (
        <View style={styles.loadingBadge}>
          <ActivityIndicator color="#fff" size="small" />
        </View>
      )}

      <TouchableOpacity
        style={[styles.filterButton, hideOpposite && styles.filterButtonActive]}
        onPress={() => setHideOpposite((v) => !v)}
      >
        <Text style={[styles.filterText, hideOpposite && styles.filterTextActive]}>
          {hideOpposite ? "Đang ẩn pin 상극" : "Ẩn pin 상극"}
        </Text>
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  center: { flex: 1, justifyContent: "center", alignItems: "center" },
  loadingBadge: {
    position: "absolute",
    top: 60,
    alignSelf: "center",
    backgroundColor: "rgba(0,0,0,0.5)",
    borderRadius: 20,
    padding: 8,
  },
  filterButton: {
    position: "absolute",
    bottom: 24,
    alignSelf: "center",
    backgroundColor: "#fff",
    borderRadius: 24,
    paddingVertical: 10,
    paddingHorizontal: 18,
    borderWidth: 1,
    borderColor: colors.border,
    elevation: 3,
    shadowColor: "#000",
    shadowOpacity: 0.15,
    shadowRadius: 4,
  },
  filterButtonActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  filterText: { color: colors.text, fontWeight: "600" },
  filterTextActive: { color: "#fff" },
});
