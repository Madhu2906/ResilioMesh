package com.resiliomesh.controller;

import com.resiliomesh.service.FcmService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/api/sos")
@CrossOrigin(origins = "*")
public class SosController {

    @Autowired
    private FcmService fcmService;

    // In-memory list to hold active SOS alerts
    private final List<Map<String, Object>> activeAlerts = Collections.synchronizedList(new ArrayList<>());

    @PostMapping("/trigger")
    public ResponseEntity<Map<String, String>> triggerSos(@RequestBody Map<String, Object> payload) {
        // Assign an ID if not present
        payload.put("id", UUID.randomUUID().toString());

        activeAlerts.add(payload);

        System.out.println("🚨 NEW SOS ALERT STORED!");
        System.out.println("Alert Details: " + payload);

        // Safely extract coordinates and category for FCM broadcast
        String alertType = (String) payload.getOrDefault("alertType", "GENERAL");
        double lat = payload.containsKey("latitude") ? ((Number) payload.get("latitude")).doubleValue() : 0.0;
        double lon = payload.containsKey("longitude") ? ((Number) payload.get("longitude")).doubleValue() : 0.0;

        // Broadcast Push Notification via FCM
        fcmService.broadcastSosAlert(alertType, lat, lon);

        return ResponseEntity.ok(Map.of(
            "status", "SUCCESS",
            "message", "Emergency SOS alert received and broadcasted successfully."
        ));
    }

    // GET Endpoint to fetch all active SOS alerts
    @GetMapping("/active")
    public ResponseEntity<List<Map<String, Object>>> getActiveAlerts() {
        return ResponseEntity.ok(activeAlerts);
    }
}