package com.resiliomesh.service;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.google.firebase.messaging.Notification;
import com.resiliomesh.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AlertService {

    private static final Logger log = LoggerFactory.getLogger(AlertService.class);
    private final UserRepository userRepository;

    public AlertService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Finds users within a specific radius of a disaster zone and sends an FCM broadcast.
     * Matches the method call in AdminAlertController.
     */
    public int sendGeoTargetedAlert(double latitude, double longitude, double radiusMeters, String title, String messageBody) {
        // 1. Fetch tokens of users within the disaster zone from PostGIS
        List<String> tokens = userRepository.findTokensInDisasterZone(latitude, longitude, radiusMeters);

        if (tokens == null || tokens.isEmpty()) {
            log.info("No active users found within {} meters of point ({}, {})", radiusMeters, latitude, longitude);
            return 0;
        }

        log.info("Found {} device tokens in disaster zone. Sending alerts...", tokens.size());

        // 2. FCM limits multicast messages to 500 tokens per batch
        int batchSize = 500;
        int totalSuccessCount = 0;

        for (int i = 0; i < tokens.size(); i += batchSize) {
            List<String> batch = tokens.subList(i, Math.min(i + batchSize, tokens.size()));

            MulticastMessage message = MulticastMessage.builder()
                    .setNotification(Notification.builder()
                            .setTitle(title)
                            .setBody(messageBody)
                            .build())
                    .putData("type", "EMERGENCY_ALERT")
                    .putData("priority", "HIGH")
                    .addAllTokens(batch)
                    .build();

            try {
                BatchResponse response = FirebaseMessaging.getInstance().sendEachForMulticast(message);
                totalSuccessCount += response.getSuccessCount();
                log.info("Batch sent: {}/{} successful", response.getSuccessCount(), batch.size());
            } catch (Exception e) {
                log.error("Failed to send FCM multicast batch", e);
            }
        }

        return totalSuccessCount;
    }
}