package com.resiliomesh.controller;

import com.resiliomesh.service.AlertService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/alert")
public class AdminAlertController {

    private final AlertService alertService;

    public AdminAlertController(AlertService alertService) {
        this.alertService = alertService;
    }

    @PostMapping("/broadcast")
    public ResponseEntity<?> broadcastGeoAlert(@RequestBody Map<String, Object> payload) {
        try {
            // Safely parse JSON numbers (handles both Integer & Double from Jackson)
            double latitude = ((Number) payload.get("latitude")).doubleValue();
            double longitude = ((Number) payload.get("longitude")).doubleValue();
            double radiusMeters = ((Number) payload.get("radiusMeters")).doubleValue();
            
            String title = (String) payload.get("title");
            String message = (String) payload.get("message");

            // Dispatch alert and retrieve count of notified users
            int recipientCount = alertService.sendGeoTargetedAlert(
                latitude, 
                longitude, 
                radiusMeters, 
                title, 
                message
            );

            return ResponseEntity.ok(Map.of(
                "status", "SUCCESS",
                "recipientsReached", recipientCount,
                "message", "Geo-targeted emergency alert dispatched."
            ));
        } catch (NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of(
                "status", "ERROR",
                "message", "Missing required fields in payload (latitude, longitude, radiusMeters, title, message)."
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "ERROR",
                "message", "Failed to send alert: " + e.getMessage()
            ));
        }
    }
}