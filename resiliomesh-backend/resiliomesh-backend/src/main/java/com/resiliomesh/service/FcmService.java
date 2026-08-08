package com.resiliomesh.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class FcmService {

    /**
     * Broadcasts emergency SOS alerts to all devices subscribed to "sos-alerts"
     */
    public void broadcastSosAlert(String alertType, double lat, double lon) {
        try {
            String title = "🚨 EMERGENCY " + alertType.toUpperCase() + " ALERT!";
            String body = "Live SOS signal detected at Lat: " + lat + ", Lon: " + lon + ". Tap to view map.";

            Message message = Message.builder()
                    .setTopic("sos-alerts")
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putData("type", alertType)
                    .putData("latitude", String.valueOf(lat))
                    .putData("longitude", String.valueOf(lon))
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("✅ FCM Push Broadcast sent successfully. ID: " + response);
        } catch (Exception e) {
            System.err.println("❌ FCM Broadcast failed: " + e.getMessage());
        }
    }

    /**
     * Sends targeted dispatch notification with ETA directly to the distressed user's device
     */
    public void sendEtaNotificationToUser(String fcmToken, Integer etaMinutes, String category) {
        if (fcmToken == null || fcmToken.trim().isEmpty() || fcmToken.equals("sample_token")) {
            System.out.println("⚠️ Invalid or missing FCM token for user. Skipping targeted push notification.");
            return;
        }

        try {
            String title = "🛡️ HELP IS ON THE WAY!";
            String body = "Emergency team dispatched for your " + category.toUpperCase() + " alert. Estimated arrival: " + etaMinutes + " mins.";

            Message message = Message.builder()
                    .setToken(fcmToken)
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(body)
                            .build())
                    .putData("type", "ETA_UPDATE")
                    .putData("etaMinutes", String.valueOf(etaMinutes))
                    .putData("category", category)
                    .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("✅ Targeted ETA Notification sent successfully to user. ID: " + response);
        } catch (Exception e) {
            System.err.println("❌ Failed to send targeted ETA notification: " + e.getMessage());
        }
    }
}