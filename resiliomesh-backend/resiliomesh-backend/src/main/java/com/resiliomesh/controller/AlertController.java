package com.resiliomesh.controller;

import com.google.firebase.messaging.*;
import com.resiliomesh.repository.UserRepository;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alerts")
public class AlertController {

    private final UserRepository userRepository;

    public AlertController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/broadcast")
    public String sendDisasterAlert(
            @RequestParam String title,
            @RequestParam String body,
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam double radiusMeters) {

        List<String> targetTokens = userRepository.findTokensInDisasterZone(lat, lon, radiusMeters);

        if (targetTokens.isEmpty()) {
            return "No devices found within " + radiusMeters + " meters of the disaster target area.";
        }

        // 1. Android High Priority Config (Bypasses Doze Mode)
        AndroidConfig androidConfig = AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setNotification(AndroidNotification.builder()
                        .setSound("default")
                        .setChannelId("high_importance_channel")
                        .setPriority(AndroidNotification.Priority.MAX)
                        .build())
                .build();

        // 2. iOS APNS High Priority Config
        ApnsConfig apnsConfig = ApnsConfig.builder()
                .setAps(Aps.builder().setSound("default").setContentAvailable(true).build())
                .putHeader("apns-priority", "10")
                .build();

        // 3. Build Message
        MulticastMessage message = MulticastMessage.builder()
                .setNotification(Notification.builder()
                        .setTitle("⚠️ " + title)
                        .setBody(body)
                        .build())
                .setAndroidConfig(androidConfig)
                .setApnsConfig(apnsConfig)
                .putData("type", "DISASTER_ALERT")
                .putData("title", "⚠️ " + title)
                .putData("body", body)
                .addAllTokens(targetTokens)
                .build();

        try {
            BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
            return "Alert sent to " + response.getSuccessCount() + " active devices out of " + targetTokens.size();
        } catch (Exception e) {
            return "Error broadcasting alert: " + e.getMessage();
        }
    }
}