import React from "react";
import { View, ActivityIndicator } from "react-native";
import { NavigationContainer } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { useAuth } from "../context/AuthContext";
import { colors } from "../theme/colors";

import LoginScreen from "../screens/LoginScreen";
import RegisterScreen from "../screens/RegisterScreen";
import OnboardingScreen from "../screens/OnboardingScreen";
import MapScreen from "../screens/MapScreen";
import ChatListScreen from "../screens/ChatListScreen";
import MatchDetailScreen from "../screens/MatchDetailScreen";
import ChatRoomScreen from "../screens/ChatRoomScreen";

const RootStack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function MainTabs() {
  return (
    <Tab.Navigator screenOptions={{ headerShown: false, tabBarActiveTintColor: colors.primary }}>
      <Tab.Screen name="Map" component={MapScreen} options={{ title: "Bản đồ" }} />
      <Tab.Screen name="Chats" component={ChatListScreen} options={{ title: "Tin nhắn" }} />
    </Tab.Navigator>
  );
}

// Điều hướng gốc: chưa đăng nhập -> Login/Register; đã đăng nhập nhưng chưa
// onboarding (chưa chọn tag) -> Onboarding; xong hết -> Tabs (Map/Chats) + các
// màn hình con (MatchDetail, ChatRoom) đẩy chồng lên trên.
export default function RootNavigator() {
  const { user, loading, isOnboarded } = useAuth();

  if (loading) {
    return (
      <View style={{ flex: 1, justifyContent: "center", alignItems: "center" }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  return (
    <NavigationContainer>
      <RootStack.Navigator screenOptions={{ headerShown: false }}>
        {!user ? (
          <>
            <RootStack.Screen name="Login" component={LoginScreen} />
            <RootStack.Screen name="Register" component={RegisterScreen} />
          </>
        ) : !isOnboarded ? (
          <RootStack.Screen name="Onboarding" component={OnboardingScreen} />
        ) : (
          <>
            <RootStack.Screen name="Main" component={MainTabs} />
            <RootStack.Screen
              name="MatchDetail"
              component={MatchDetailScreen}
              options={{ headerShown: true, title: "" }}
            />
            <RootStack.Screen
              name="ChatRoom"
              component={ChatRoomScreen}
              options={{ headerShown: true }}
            />
          </>
        )}
      </RootStack.Navigator>
    </NavigationContainer>
  );
}
