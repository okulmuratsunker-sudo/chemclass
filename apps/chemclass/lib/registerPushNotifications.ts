import { Platform } from "react-native"
import * as Device from "expo-device"
import * as Notifications from "expo-notifications"
import Constants from "expo-constants"
import { savePushToken } from "@chemclass/shared"

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowBanner: true,
    shouldShowList: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
  }),
})

export async function registerForPushNotificationsAsync(userId: string) {
  if (!Device.isDevice) return null

  const { status: existingStatus } = await Notifications.getPermissionsAsync()
  let finalStatus = existingStatus
  if (existingStatus !== "granted") {
    const { status } = await Notifications.requestPermissionsAsync()
    finalStatus = status
  }
  if (finalStatus !== "granted") return null

  if (Platform.OS === "android") {
    await Notifications.setNotificationChannelAsync("default", {
      name: "default",
      importance: Notifications.AndroidImportance.MAX,
    })
  }

  const projectId = Constants.expoConfig?.extra?.eas?.projectId
  const tokenResponse = await Notifications.getExpoPushTokenAsync(projectId ? { projectId } : undefined)
  const token = tokenResponse.data

  await savePushToken(userId, token)
  return token
}
